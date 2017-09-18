!> @file chkpoint.f
!! @ingroup chkpoint
!! @brief Set of checkpoint routines
!! @details This is a main interface reading/writing runtime parameters
!! and calling proper submodule.
!=======================================================================
!> @brief Set checkpoint parameters
!! @ingroup chkpoint
      subroutine chkpt_param_get()
      implicit none

      include 'SIZE'            !
      include 'PARALLEL'        ! ISIZE, WDSIZE, LSIZE,CSIZE
      include 'CHKPOINTD'

!     local variables
      character*132 lkey, c_out
      integer i_out,ifnd, ierr, nhour, nmin
      real d_out
      logical ifsec
!-----------------------------------------------------------------------
!     default values
      chpt_step = 100
      chpt_ifrst = .FALSE.
      chpt_fnum = 1
      chpt_wtime = 0.0

!     dictionary
      if (NID.eq.0) then
!     check consistency
         call rprm_check(chpt_nkeys, chpt_dictkey, chpt_n3dkeys,
     $           chpt_l3dkey, ifsec)

!     if section present read parameters
         if (ifsec) then
!     checkpoint frequency
            lkey = trim(adjustl(chpt_dictkey(1)))//':'//
     $             trim(adjustl(chpt_dictkey(2)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               chpt_step = int(d_out)
            endif
!     do we restart
            lkey = trim(adjustl(chpt_dictkey(1)))//':'//
     $             trim(adjustl(chpt_dictkey(3)))
            call finiparser_getBool(i_out,trim(lkey),ifnd)
            if (ifnd.eq.1.and.i_out.eq.1) then
               chpt_ifrst = .TRUE.
            endif
!     restart file number
            lkey = trim(adjustl(chpt_dictkey(1)))//':'//
     $             trim(adjustl(chpt_dictkey(4)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               chpt_fnum = int(d_out)
            endif
!     simulation wall time
            lkey = trim(adjustl(chpt_dictkey(1)))//':'//
     $             trim(adjustl(chpt_dictkey(5)))
            call finiparser_getString(c_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               lkey = trim(adjustl(c_out))
!     check string format
               ierr = 0
               if (lkey(3:3).ne.':') ierr = 1
               if (.not.(LGE(lkey(1:1),'0').and.LLE(lkey(1:1),'9')))
     $             ierr = 1
               if (.not.(LGE(lkey(2:2),'0').and.LLE(lkey(2:2),'9')))
     $             ierr = 1
               if (.not.(LGE(lkey(4:4),'0').and.LLE(lkey(4:4),'9')))
     $             ierr = 1
               if (.not.(LGE(lkey(5:5),'0').and.LLE(lkey(5:5),'9')))
     $             ierr = 1

               if (ierr.eq.0) then
                  read(lkey(1:2),'(I2)') nhour
                  read(lkey(4:5),'(I2)') nmin
                  chpt_wtime = 60.0*(nmin +60*nhour)
               else
                  write(*,*)
     $              'WARNING: chkpt_param_get; wrong wall time format'
               endif
            endif
         endif

!     print prarameters values
         write(*,*) '[',trim(chpt_dictkey(1)),']'
         if (chpt_ifrst) then
            lkey = 'yes'
         else
            lkey = 'no'
         endif
         write(*,*) trim(chpt_dictkey(2)),' = ', chpt_step
         write(*,*) trim(chpt_dictkey(3)),' = ', trim(lkey)
         write(*,*) trim(chpt_dictkey(4)),' = ', chpt_fnum
         write(*,*) trim(chpt_dictkey(5)),' = ', chpt_wtime,' sec'
      endif

!     broadcast data
      call bcast(chpt_step,ISIZE)
      call bcast(chpt_fnum,ISIZE)
      call bcast(chpt_ifrst,LSIZE)
      call bcast(chpt_wtime,WDSIZE)

      return
      end
!=======================================================================
!> @brief Main checkpoint interface
!! @ingroup chkpoint
!! @note This routine should be called in userchk
      subroutine chkpt_main
      implicit none

      include 'CHKPOINTD'        ! chpt_ifrst

!     local variables
      logical ifcalled
      save ifcalled
      data ifcalled /.FALSE./
!-----------------------------------------------------------------------
      if(.not.ifcalled) then
        ifcalled=.TRUE.
        call chkpt_init
      endif

      if(chpt_ifrst) call chkpt_read

      call chkpt_write

      return
      end
!=======================================================================

