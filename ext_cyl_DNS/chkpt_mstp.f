!> @file chkpt_mstp.f
!! @ingroup chkpoint_mstep
!! @brief Set of multi-file checkpoint routines for DNS, MHD and
!!    perturbation simulations
!! @details This module writes different file sets for DNS (rsX...),
!!    MHD (rbX...) and perturbation (rpX...). In perturbation mode only
!!    single perturbation (NPERT=1) is supported right now.
!=======================================================================
!> @brief Initialise multi-file checkpoint routines
!! @ingroup chkpoint_mstep
!! @note This interface is defined in @ref chkpt_main
!! @todo Add timestep reader to ensure proper restart
      subroutine chkpt_init
      implicit none

      include 'SIZE'            ! NID, NPERT
      include 'TSTEP'           ! ISTEP, NSTEPS
      include 'INPUT'           ! IFPERT, PARAM
      include 'CHKPOINTD'       ! chpt_step, chpt_ifrst, chpt_fnum
      include 'CHKPTMSTPD'      ! chpm_set_o, chpm_set_i, chpm_snmax,
                                ! chpm_nset, chpm_nsnap

!     local variables
      integer itmp
!-----------------------------------------------------------------------
!     get number of snapshots in a set
      if (PARAM(27).lt.0) then
         chpm_nsnap = NBDINP
      else
         chpm_nsnap = chpm_snmax
      endif

!     check number of steps and set size
      if (NSTEPS.lt.2*chpm_nsnap) then
         if (NIO.eq.0) write (*,*) 'Error: chkpt_init; ',
     $           'too short run for multi-file restart.'
         call exitt
      endif

!     check checkpoint frequency
      if (chpt_step.le.chpm_nsnap.or.chpt_step.gt.NSTEPS) then
         chpt_step = NSTEPS
         if (NIO.eq.0) write (*,*) 'WARNING: chkpt_init; ',
     $           'wrong chpt_step; resetting to ', chpt_step
      endif

!     to aviod possible problems at the end of the simulation
!     find max ISTEP for cyclic checkpoint writning
      chpm_nstep = NSTEPS-2*chpm_nsnap
      itmp = chpm_nstep + chpt_step -1
      if (mod(itmp,chpt_step).ge.(chpt_step-chpm_nsnap)) then
         itmp = chpm_nsnap + mod(itmp,chpt_step) + 1 - chpt_step
         chpm_nstep = chpm_nstep - itmp
      endif

!     we support only one perturbation
      if (IFPERT) then
         if (NPERT.gt.1) then
            if (NIO.eq.0) write(*,*)
     $         'ERROR: chkpt_init; only single perturbation supported'
            call exitt
         endif
      endif

      if (chpt_ifrst) then
!     get input set number
         chpm_set_i = chpt_fnum - 1
         if (chpm_set_i.ge.chpm_nset) then
            if (NIO.eq.0) write(*,*)
     $         'ERROR: chkpt_init; chpt_fnum must be in the range: 1-',
     $                    chpm_nset + 1
            call exitt
         endif

!     palce to get dt!!!!!!!

         chpm_set_o = mod(chpm_set_i+1,chpm_nset)
      else
         chpm_set_o = 0
      endif

!     set reset flag
      chpm_reset = -1

      return
      end
!=======================================================================
!> @brief Write full file restart set
!! @ingroup chkpoint_mstep
!! @note This interface is defined in @ref chkpt_main.
!! @note This is version of @ref full_restart_save routine.
      subroutine chkpt_write()
      implicit none

      include 'SIZE'            !
      include 'TSTEP'           ! ISTEP, NSTEPS
      include 'INPUT'           ! IFMVBD, IFREGUO
      include 'PARALLEL'        ! WDSIZE
      include 'CTIMER'          ! ETIMES
      include 'CHKPOINTD'       ! chpt_step
      include 'CHKPTMSTPD'      ! chpm_nsnap, chpm_set_o, chpm_nset

!     local variables
      integer il, ifile, itmp, fnum
      real rtmp
      character*132 fname(CHKPTNFMAX)
      logical ifcoord
      logical ifreguol

      integer icalldl
      save    icalldl
      data    icalldl  /0/

!     functions; for some reason allready declared in CTIMER
!      real dnekclock
!-----------------------------------------------------------------------
!     check simulation wall time
      if (chpt_wtime.gt.0.0) then
!     save wall time of the current step
         do il=chpm_nsnap,2,-1
            chpm_wtstep(il) = chpm_wtstep(il-1)
         enddo
         chpm_wtstep(1) = dnekclock() - ETIMES

!     check if simulation is going to exceed wall time
         if (ISTEP.gt.chpm_nsnap) then
!     it should be enough for the master to check condition
            if (NID.eq.0) rtmp = 2.0*chpm_wtstep(1) -
     $         chpm_wtstep(chpm_nsnap)
!     broadcast predicted time
            il = WDSIZE
            call bcast(rtmp,il)

            if (rtmp.gt.chpt_wtime) then
               if (NIO.eq.0)
     $             write(*,*) 'Checkpoint: wall clock reached.'

!     should we shift checkpointing or shorten the run
               if (ISTEP.lt.chpm_nstep) then
                  il = ISTEP + chpt_step -1
!     shift checkpointing
                  if(mod(il,chpt_step).lt.(chpt_step-chpm_nsnap))then
                     NSTEPS = ISTEP+chpm_nsnap
                     chpt_step = NSTEPS
                     chpm_nstep = ISTEP
                     if (NIO.eq.0)
     $                   write(*,*) 'Checkpoint: shift checkpointing'
                  else
!     shortent the run
                     il = chpt_step - mod(il,chpt_step) - 1
                     if (il.eq.0) then
                        LASTEP = 1 ! it is a last step
                     else
                        NSTEPS = ISTEP+il
                        chpm_nstep = ISTEP - chpm_nsnap
                     endif
                     if (NIO.eq.0)
     $                   write(*,*) 'Checkpoint: shorten simulation'
                  endif
               endif
            endif

         endif
      endif

!     no regular mesh
      ifreguol= IFREGUO
      IFREGUO = .false.

!     do we write a snapshot
      ifile = 0
      itmp = ISTEP + chpt_step -1
      if (ISTEP.gt.(NSTEPS-chpm_nsnap)) then
         ifile = chpm_nsnap + ISTEP - NSTEPS
      elseif (ISTEP.gt.chpm_nsnap.and.ISTEP.lt.chpm_nstep.and.
     $        mod(itmp,chpt_step).ge.(chpt_step-chpm_nsnap)) then
         ifile = chpm_nsnap + mod(itmp,chpt_step) + 1 - chpt_step
      endif

      if (ifile.gt.0) then

         if (ifile.eq.1.and.NIO.eq.0) write(*,*)
     $              'Writing checkpoint snapshot'

!     initialise I/O data
         call io_init

!     get set of file names in the snapshot
         call chkpt_set_name(fname, fnum, chpm_set_o, ifile)

!     do we wtrite coordinates; we save coordinates in DNS files only
         if (IFMVBD) then  ! moving boundaries save in every file
            ifcoord = .true.
         elseif (ifile.eq.1) then
! perturbation mode with constant base flow - only 1 rsX written
            if (ifpert.and.(.not.ifbase)) then
               if (icalldl.eq.0.and.(.not.chpt_ifrst)) then
                  icalldl = 1
                  ifcoord = .true.
               else
                  call chcopy (fname(1),fname(fnum),132)
                  fnum = 1
                  ifcoord = .false.
               endif
! DNS, MHD, perturbation with changing base flow - every first rsX file in snapshot
            else
               ifcoord = .true.
            endif
         else
            if (ifpert.and.(.not.ifbase)) then
               call chcopy (fname(1),fname(fnum),132)
               fnum = 1
            endif
            ifcoord = .false.
         endif

!     write down files
         call chkpt_restart_write(fname, fnum, ifcoord)

!     update output set number
!     we do it after the last file in the set was sucsesfully written
         if (ifile.eq.chpm_nsnap) then
            if (NIO.eq.0) write(*,*)
     $              'Written checkpoint snapshot number: ',chpm_set_o+1
            chpm_reset = mod(chpm_set_o+1,chpm_nset)
         endif
      elseif (chpm_reset.ge.0) then
         chpm_set_o = chpm_reset
         chpm_reset = -1
      endif

!     put parameters back
      IFREGUO = ifreguol

      return
      end
!=======================================================================
!> @brief Read full file restart set.
!! @ingroup chkpoint_mstep
!! @note This interface is defined in @ref chkpt_main
!! @note This is version of @ref full_restart routine.
      subroutine chkpt_read()
      implicit none

      include 'SIZE'            !
      include 'TSTEP'           ! ISTEP
      include 'INPUT'           ! IFREGUO, INITC
      include 'CHKPOINTD'       ! chpt_ifrst
      include 'CHKPTMSTPD'      ! chpm_nsnap, CHKPTNFMAX

!     local variables
      logical ifreguol
      integer ifile, fnum, fnuml, il
      character*132 fname(CHKPTNFMAX),fnamel(CHKPTNFMAX)
!-----------------------------------------------------------------------
!     no regular mesh; important for file name generation
      ifreguol= IFREGUO
      IFREGUO = .false.

      if (chpt_ifrst.and.(ISTEP.lt.chpm_nsnap)) then

         ifile = ISTEP+1  ! snapshot number

!     initialise I/O data
         call io_init

!     get set of file names in the snapshot
         call chkpt_set_name(fname, fnum, chpm_set_i, ifile)

! perturbation mode with constant base flow - only 1 rsX written
         if (ifpert.and.(.not.ifbase)) then
            if (ifile.eq.1) then
               il = 0
               call chkpt_set_name(fnamel, fnuml, il, ifile)
               call chcopy (fname(1),fnamel(1),132)
               fnum = 2
            else
               call chcopy (fname(1),fname(fnum),132)
               fnum = 1
            endif
         endif

         call chkpt_restart_read(fname, fnum)
      endif

!     put parameters back
      IFREGUO = ifreguol

      return
      end
!=======================================================================
!> @brief Generate set of restart file names in snapshot
!! @ingroup chkpoint_mstep
!! @param[out] fname  restart file names
!! @param[out] fnum   number of files in snapshot
!! @param[in]  nset   set number
!! @param[in]  ifile  snupshot numer
      subroutine chkpt_set_name(fname, fnum, nset, ifile)
      implicit none

      include 'SIZE'            ! NIO
      include 'INPUT'           ! IFMHD, IFPERT, IFBASE
      include 'CHKPTMSTPD'      ! CHKPTNFMAX

!     argument list
      character*132 fname(CHKPTNFMAX)
      integer fnum, nset, ifile

!     local variables
      integer ifilel, ierr

      character*132 bname
      character*3 prefix
!-----------------------------------------------------------------------
!     fill fname array with 'rsX' (DNS), 'rpX' (pert.) and 'rbX' (MHD) file names
      if (IFMHD) then
!     file number
         fnum = 2

!     prefix and name for fluid (DNS)
         prefix(1:2)='rs'
         call chkpt_fname(fname(1), prefix, nset, ifile, ierr)

         if (ierr.ne.0) then
            if (NIO.eq.0) write(*,*)
     $            'ERROR: chkpt_set_name; DNS file name error'
            call exitt
         endif

!     prefix and name for magnetic field (MHD)
         prefix(1:2)='rb'
         call chkpt_fname(fname(2), prefix, nset, ifile, ierr)

         if (ierr.ne.0) then
            if (NIO.eq.0) write(*,*)
     $            'ERROR: chkpt_set_name; MHD file name error'
            call exitt
         endif

      elseif (IFPERT) then
!     file number
!     I assume only single perturbation
         fnum = 2

!     prefix and name for base flow (DNS)
         prefix(1:2)='rs'
         if (IFBASE) then
            ifilel = ifile
         else
            ifilel =1
         endif
         call chkpt_fname(fname(1), prefix, nset, ifilel, ierr)

         if (ierr.ne.0) then
            if (NIO.eq.0) write(*,*)
     $            'ERROR: chkpt_set_name; base flow file name error'
            call exitt
         endif

!     prefix and name for perturbation
         prefix(1:2)='rp'
         call chkpt_fname(fname(2), prefix, nset, ifile, ierr)

         if (ierr.ne.0) then
            if (NIO.eq.0) write(*,*)
     $            'ERROR: chkpt_set_name; perturbation file name error'
            call exitt
         endif

      else                ! DNS
         fnum = 1

!     create prefix and name for DNS
         prefix(1:2)='rs'
         call chkpt_fname(fname(1), prefix, nset, ifile, ierr)

         if (ierr.ne.0) then
            if (NIO.eq.0) write(*,*)
     $            'ERROR: chkpt_set_name; DNS file name error'
            call exitt
         endif

      endif

      return
      end
!=======================================================================
!> @brief Generate single restart file name
!! @ingroup chkpoint_mstep
!! @param[out] fname  restart file name
!! @param[in]  prefix prefix
!! @param[in]  nset   set number
!! @param[in]  ifile  snupshot numer
!! @param[out] ierr   error mark
      subroutine chkpt_fname(fname, prefix, nset, ifile, ierr)
      implicit none

      include 'SIZE'            ! NIO
      include 'INPUT'           ! SESSION
      include 'CHKPTMSTPD'      ! chpm_nsnap, chpm_nset

!     argument list
      character*132 fname
      character*3 prefix
      integer nset, ifile, ierr

!     local variables
      character*132 bname    ! base name
      character*132 fnamel   ! local file name
      character*3 prefixl    ! local prefix
      integer itmp

      character*6  str

      character*17 kst
      save         kst
      data         kst / '0123456789abcdefx' /
!-----------------------------------------------------------------------
!     create prefix and name for DNS
      ierr = 0
      prefixl(1:2) = prefix(1:2)
      itmp=min(17,chpm_nset*chpm_nsnap) + 1
      prefixl(3:3)=kst(itmp:itmp)

!     get base name (SESSION)
      bname = trim(adjustl(SESSION))

      call io_mfo_fname(fnamel,bname,prefixl,ierr)
      if (ierr.ne.0) then
         if (NIO.eq.0) write(*,*) 'ERROR: chkpt_fname; file name error'
         return
      endif

      write(str,'(i5.5)') chpm_nsnap*nset+ifile
      fname = trim(fnamel)//trim(str)

      return
      end
!=======================================================================
!> @brief Write checkpoint snapshot.
!! @ingroup chkpoint_mstep
!! @param[out] fname   restart file name
!! @param[in]  fnum    number of files in snapshot
!! @param[in]  ifcoord do we save coordinates
      subroutine chkpt_restart_write(fname, fnum, ifcoord)
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'TSTEP'
      include 'INPUT'
      include 'CHKPTMSTPD'

!     argument list
      character*132 fname(CHKPTNFMAX)
      integer fnum
      logical ifcoord

!     local variables
      integer lwdsizo
      integer ipert, itmp, il
!     which set of variables do we write: DNS (1), MHD (2) or perturbation (3)
      integer chktype

      logical lif_full_pres, lifxyo, lifpo, lifvo, lifto,
     $        lifpsco(LDIMT1)
!-----------------------------------------------------------------------
!     adjust I/O parameters
      lwdsizo = WDSIZO
      WDSIZO  = 8
      lif_full_pres = IF_FULL_PRES
      IF_FULL_PRES = .true.
      lifxyo = IFXYO
      lifpo= IFPO
      IFPO = .TRUE.
      lifvo= IFVO
      IFVO = .TRUE.
      lifto= IFTO
      IFTO = IFHEAT
      do il=1,NPSCAL
         lifpsco(il)= IFPSCO(il)
         IFPSCO(il) = .TRUE.
      enddo

      if (IFMHD) then
!     DNS first
         IFXYO = ifcoord
         chktype = 1
         call chkpt_mfo(fname(1),chktype,ipert)

!     MHD
         IFXYO = .FALSE.
         chktype = 2
         call chkpt_mfo(fname(2),chktype,ipert)

      elseif (IFPERT) then
!     DNS first
         if (fnum.eq.2) then
            IFXYO = ifcoord
            chktype = 1
            call chkpt_mfo(fname(1),chktype,ipert)
         endif

!     perturbation
         IFXYO = .FALSE.
         chktype = 3
         ipert = 1
         call chkpt_mfo(fname(fnum),chktype,ipert)
      else ! DNS
!     write only one set of files
         if (fnum.ne.1) then
            if (NIO.eq.0 ) write(*,*)
     $            'ERROR: chkpt_restart_save; too meny files for DNS'
            call exitt
         endif

         IFXYO = ifcoord
         chktype = 1
         call chkpt_mfo(fname(1),chktype,ipert)
      endif

!     restore I/O parameters
      WDSIZO = lwdsizo
      IF_FULL_PRES = lif_full_pres
      IFXYO = lifxyo
      IFPO = lifpo
      IFVO = lifvo
      IFTO = lifto
      do il=1,NPSCAL
         IFPSCO(il) = lifpsco(il)
      enddo

      return
      end
!=======================================================================
!> @brief Read checkpoint snapshot.
!! @ingroup chkpoint_mstep
!! @param[out] fname   restart file name
!! @param[in]  fnum    number of files in snapshot
      subroutine chkpt_restart_read(fname, fnum)
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'TSTEP'
      include 'INPUT'
      include 'CHKPTMSTPD'

!     argument list
      character*132 fname(CHKPTNFMAX)
      integer fnum

!     local variables
      integer ndumps, ipert, itmp, il
!     which set of variables do we write: DNS (1), MHD (2) or perturbation (3)
      integer chktype
      character*132 fnamel
!-----------------------------------------------------------------------
      if (IFMHD) then
!     DNS first
         chktype = 1
         call sioflag(ndumps,fnamel,fname(1))
         call chkpt_mfi(fnamel,chktype,ipert)

!     MHD
         chktype = 2
         call sioflag(ndumps,fnamel,fname(2))
         call chkpt_mfi(fnamel,chktype,ipert)

      elseif (IFPERT) then
!     DNS first
         if (fnum.eq.2) then
            chktype = 1
            call sioflag(ndumps,fnamel,fname(1))
            call chkpt_mfi(fnamel,chktype,ipert)
         endif

!     perturbation
         chktype = 3
         ipert = 1
         call sioflag(ndumps,fnamel,fname(fnum))
         call chkpt_mfi(fnamel,chktype,ipert)
      else ! DNS
!     write only one set of files
         if (fnum.ne.1) then
            if (NIO.eq.0 ) write(*,*)
     $            'ERROR: chkpt_restart_read; too meny files for DNS'
            call exitt
         endif

         chktype = 1
         call sioflag(ndumps,fnamel,fname(1))
         call chkpt_mfi(fnamel,chktype,ipert)
      endif

      return
      end
!=======================================================================
!> @brief Write field to the file
!! @details This routine is based on @ref mfo_outfld but does not assume
!!    any file numbering. It is optimised for chekpoint writing.
!! @ingroup chkpoint_mstep
!! @param[in]   fname      file name
!! @param[in]   chktype    data type to write (DNS, MHD, perturbation)
!! @param[in]   ipert      index of perturbation field
!! @note Only one set of data (DNS, MHD or perturbation) can be saved in
!!    single file
!! @remark This routine uses global scratch space \a SCRCG.
      subroutine chkpt_mfo(fname,chktype,ipert)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'RESTART'
      include 'TSTEP'
      include 'GEOM'
      include 'SOLN'

!     argumnt list
      character*132 fname
      integer chktype, ipert

!     local variables
      integer ierr, il, itmp
      integer ioflds
      integer*8 offs,nbyte
      real dnbyte, tiostart, tio

!     functions
      real dnekclock_sync, glsum

      real pm1(lx1,ly1,lz1,lelv)
      common /SCRCG/ pm1
!-----------------------------------------------------------------------
!     simple timing
      tiostart=dnekclock_sync()

!     set elelemnt size
      NXO  = NX1
      NYO  = NY1
      NZO  = NZ1

!     open file
      call io_mbyte_open(fname,ierr)
      call err_chk(ierr,'ERROR: io_mfo; file not opened. $')

!     write a header and create element mapping
      call chkpt_mfo_write_hdr

!     set header offset
      offs = iHeaderSize + 4 + isize*nelgt
      ioflds = 0

!     write fields
!     coordinates
      if (ifxyo) then
         call io_mfo_outv(offs,xm1,ym1,zm1,nx1,ny1,nz1,nelt,nelgt,ndim)
         ioflds = ioflds + ndim
      endif

!     velocity, magnetic field, perturbation velocity
      if (ifvo) then
         if (chktype.eq.1) then
            call io_mfo_outv(offs,vx,vy,vz,nx1,ny1,nz1,nelt,nelgt,ndim)
         elseif(chktype.eq.2) then
            call io_mfo_outv(offs,bx,by,bz,nx1,ny1,nz1,nelt,nelgt,ndim)
         elseif(chktype.eq.3) then
            call io_mfo_outv(offs,vxp(1,ipert),vyp(1,ipert),
     $                       vzp(1,ipert),nx1,ny1,nz1,nelt,nelgt,ndim)
         endif
         ioflds = ioflds + ndim
      endif

!     pressure
      if (ifpo) then
         if (chktype.eq.1) then
!     copy array if necessary
            if (ifsplit) then
               itmp = nx1*ny1*nz1*lelv
               call io_mfo_outs(offs,pr,nx2,ny2,nz2,nelt,nelgt,ndim)
            else
               itmp = nx1*ny1*nz1*lelv
               call rzero(pm1,itmp)
               itmp = nx2*ny2*nz2
               do il=1,nelv
                  call copy(pm1(1,1,1,il),pr(1,1,1,il),itmp)
               enddo
               call io_mfo_outs(offs,pm1,nx1,ny1,nz1,nelt,nelgt,ndim)
            endif
         elseif(chktype.eq.2) then
!     copy array
            itmp = nx1*ny1*nz1*lelv
            call rzero(pm1,itmp)
            itmp = nx2*ny2*nz2
            do il=1,nelv
               call copy(pm1(1,1,1,il),pm(1,1,1,il),itmp)
            enddo
            call io_mfo_outs(offs,pm1,nx1,ny1,nz1,nelt,nelgt,ndim)
         elseif(chktype.eq.3) then
!     copy array
            itmp = nx1*ny1*nz1*lelv
            call rzero(pm1,itmp)
            itmp = nx2*ny2*nz2
            do il=1,nelv
               call copy(pm1(1,1,1,il),prp(1+itmp*(il-1),ipert),itmp)
            enddo
            call io_mfo_outs(offs,pm1,nx1,ny1,nz1,nelt,nelgt,ndim)
         endif
         ioflds = ioflds + 1
      endif

      if (chktype.ne.2) then
         if (ifto) then
            if (chktype.eq.1) then
               call io_mfo_outs(offs,t,nx1,ny1,nz1,nelt,nelgt,ndim)
            elseif(chktype.eq.3) then
               call io_mfo_outs(offs,tp(1,1,ipert),
     $                          nx1,ny1,nz1,nelt,nelgt,ndim)
            endif
            ioflds = ioflds + 1
         endif

         do il=1,ldimt-1
            if (ifpsco(il)) then
               if (chktype.eq.1) then
                  call io_mfo_outs(offs,t(1,1,1,1,il+1),
     $                 nx1,ny1,nz1,nelt,nelgt,ndim)
               elseif(chktype.eq.3) then
                  call io_mfo_outs(offs,tp(1,il+1,ipert),
     $                 nx1,ny1,nz1,nelt,nelgt,ndim)
               endif
               ioflds = ioflds + 1
            endif
         enddo
      endif
      dnbyte = 1.*ioflds*nelt*wdsizo*nx1*ny1*nz1

!     possible place for metadata

!     close file
      call io_mbyte_close(ierr)
      call err_chk(ierr,'ERROR: chkpt_mfo; file not closed. $')

      tio = dnekclock_sync()-tiostart
      if (tio.le.0) tio=1.

      dnbyte = glsum(dnbyte,1)
      dnbyte = dnbyte + iHeaderSize + 4. + isize*nelgt
      dnbyte = dnbyte/1024/1024
      if(nio.eq.0) write(6,7) istep,time,dnbyte,dnbyte/tio,
     &             nfileo
    7 format(/,i9,1pe12.4,' done :: Write checkpoint',/,
     &       30X,'file size = ',3pG12.2,'MB',/,
     &       30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &       30X,'io-nodes = ',i5,/)

      return
      end
!=======================================================================
!> @brief Write a header in the checkpoint file
!! @details This routine is a copy fo @ref mfo_write_hrd. I've made my
!!    own version of this routine to remove ambiguity between P_n-P_n
!!    and P_n-P_n-2 runs when it comes to the format of the pressure.
!!    Right now therer is a flag IF_FULL_PRES in the main nek release
!!    that controls pressure write format. Unfortunately it is not saved
!!    in the file and at the reding step the size of real indicates the
!!    pressure format. In some cases it can be insufficient, so I store
!!    values of IFSPLIT and IF_FULL_PRES.
!! @ingroup chkpoint_mstep
!! @remark This routine uses global scratch space \a CTMP0.
      subroutine chkpt_mfo_write_hdr
      implicit none

      include 'SIZE'
      include 'SOLN'
      include 'INPUT'
      include 'PARALLEL'
      include 'RESTART'
      include 'TSTEP'

!     local variables
      integer i, j, k, idum, mtype, ierr, ibsw_out, len, inelp
      integer nelo, nfileoo, npscalo
      integer lglist(0:lelt)
      common /ctmp0/ lglist

      real*4 test_pattern

      character*132 hdr
      integer*8 ioff
!-----------------------------------------------------------------------
      call nekgsync()
      idum = 1

      if(ifmpiio) then
        nfileoo = 1   ! all data into one file
        nelo = nelgt
      else
        nfileoo = nfileo
        if(nid.eq.pid0) then                ! how many elements to dump
          nelo = nelt
          do j = pid0+1,pid1
             mtype = j
             call csend(mtype,idum,4,j,0)   ! handshake
             call crecv(mtype,inelp,4)
             nelo = nelo + inelp
          enddo
        else
          mtype = nid
          call crecv(mtype,idum,4)          ! hand-shake
          call csend(mtype,nelt,4,pid0,0)   ! u4 :=: u8
        endif
      endif

      ierr = 0
      if(nid.eq.pid0) then

      call blank(hdr,132)              ! write header
      call blank(rdcode1,10)
      i = 1
      IF (IFXYO) THEN
         rdcode1(i)='X'
         i = i + 1
      ENDIF
      IF (IFVO) THEN
         rdcode1(i)='U'
         i = i + 1
      ENDIF
      IF (IFPO) THEN
         rdcode1(i)='P'
         i = i + 1
      ENDIF
      IF (IFTO) THEN
         rdcode1(i)='T'
         i = i + 1
      ENDIF
      IF (LDIMT.GT.1) THEN
         NPSCALO = 0
         do k = 1,ldimt-1
           if(ifpsco(k)) NPSCALO = NPSCALO + 1
         enddo
         IF (NPSCALO.GT.0) THEN
            rdcode1(i) = 'S'
            WRITE(rdcode1(i+1),'(I1)') NPSCALO/10
            WRITE(rdcode1(i+2),'(I1)') NPSCALO-(NPSCALO/10)*10
         ENDIF
      ENDIF

      write(hdr,1) wdsizo,nxo,nyo,nzo,nelo,nelgt,time,istep,fid0,nfileoo
     $            ,(rdcode1(i),i=1,10),p0th,ifsplit,if_full_pres
    1 format('#std',1x,i1,1x,i2,1x,i2,1x,i2,1x,i10,1x,i10,1x,e20.13,
     &       1x,i9,1x,i6,1x,i6,1x,10a,1pe15.7,1x,l1,1x,l1)

      ! if we want to switch the bytes for output
      ! switch it again because the hdr is in ASCII
      call get_bytesw_write(ibsw_out)
c      if (ibsw_out.ne.0) call set_bytesw_write(ibsw_out)
      if (ibsw_out.ne.0) call set_bytesw_write(0)

      test_pattern = 6.54321           ! write test pattern for byte swap

      if(ifmpiio) then
        ! only rank0 (pid00) will write hdr + test_pattern
        call byte_write_mpi(hdr,iHeaderSize/4,pid00,ifh_mbyte,ierr)
        call byte_write_mpi(test_pattern,1,pid00,ifh_mbyte,ierr)
      else
        call byte_write(hdr,iHeaderSize/4,ierr)
        call byte_write(test_pattern,1,ierr)
      endif

      endif

      call err_chk(ierr,'Error writing header in mfo_write_hdr. $')

      ! write global element numbering for this group
      if(nid.eq.pid0) then
        if(ifmpiio) then
          ioff = iHeaderSize + 4 + nelB*isize
          call byte_set_view (ioff,ifh_mbyte)
          call byte_write_mpi(lglel,nelt,-1,ifh_mbyte,ierr)
        else
          call byte_write(lglel,nelt,ierr)
        endif

        do j = pid0+1,pid1
           mtype = j
           call csend(mtype,idum,4,j,0)   ! handshake
           len = 4*(lelt+1)
           call crecv(mtype,lglist,len)
           if(ierr.eq.0) then
             if(ifmpiio) then
              call byte_write_mpi(lglist(1),lglist(0),-1,ifh_mbyte,ierr)
             else
              call byte_write(lglist(1),lglist(0),ierr)
             endif
           endif
        enddo
      else
        mtype = nid
        call crecv(mtype,idum,4)          ! hand-shake

        lglist(0) = nelt
        call icopy(lglist(1),lglel,nelt)

        len = 4*(nelt+1)
        call csend(mtype,lglist,len,pid0,0)
      endif

      call err_chk(ierr,'Error writing global nums in mfo_write_hdr$')
      return
      end
!=======================================================================
!> @brief Read field to the file
!! @details This routine is based on @ref mfi but supports perturbation
!!    as well. It is optimised for chekpoint reading.
!! @ingroup chkpoint_mstep
!! @param[in]   fname      file name
!! @param[in]   chktype    data type to read (DNS, MHD, preturbation)
!! @param[in]   ipert      index of perturbation field
!! @remark This routine uses global scratch space \a SCRCG.
      subroutine chkpt_mfi(fname,chktype,ipert)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'RESTART'
      include 'TSTEP'
      include 'GEOM'
      include 'SOLN'

!     argumnt list
      character*132 fname
      integer chktype, ipert

!     local variables
      integer ierr, il, itmp
      integer ioflds
      integer*8 offs0,offs,nbyte,stride
      real dnbyte, tiostart, tio
      logical ifskip

!     functions
      real dnekclock_sync, glsum

      real pm1(lx1,ly1,lz1,lelt)
      common /SCRCG/ pm1
!-----------------------------------------------------------------------
!     simple timing
      tiostart=dnekclock_sync()

!     open file
!      call io_mbyte_open(fname,ierr)
!      call err_chk(ierr,'ERROR: io_mfo_outfld; file not opened. $')
      call mfi_prepare(fname)

!     read a header and create element mapping
!      call chkpt_mfo_write_hdr

!     set header offset
      offs = iHeaderSize + 4 + isize*nelgr
      ioflds = 0

!     read fields
!     coordinates
      if (ifgetxr) then
         ifskip = .not.ifgetx
!     skip coordinates if you need to interpolate coordinates;
!     I assume current coordinates are more exact than the interpolated one
         if ((nxr.ne.nx1).or.(nyr.ne.ny1).or.(nzr.ne.nz1)) ifskip=.TRUE.
         call io_mfi_getv(offs,xm1,ym1,zm1,ifskip)
         ioflds = ioflds + ndim
      endif

!     velocity, magnetic field, perturbation velocity
      if (ifgetur) then
         ifskip = .not.ifgetu
         if (chktype.eq.1) then
            call io_mfi_getv(offs,vx,vy,vz,ifskip)
         elseif(chktype.eq.2) then
            call io_mfi_getv(offs,bx,by,bz,ifskip)
         elseif(chktype.eq.3) then
            call io_mfi_getv(offs,vxp(1,ipert),vyp(1,ipert),
     $                       vzp(1,ipert),ifskip)
         endif
         ioflds = ioflds + ndim
      endif

!     pressure
      if (ifgetpr) then
         ifskip = .not.ifgetp
         if (chktype.eq.1) then
!     copy array if necessary
            if (ifsplit) then
               call io_mfi_gets(offs,pr,ifskip)
            else
               call io_mfi_gets(offs,pm1,ifskip)
               if (ifgetp) then
               !  if copy then
                  itmp = nx2*ny2*nz2
                  do il=1,nelv
                     call copy(pr(1,1,1,il),pm1(1,1,1,il),itmp)
                  enddo
               !else mapping m1 to m2
               endif
            endif
         elseif(chktype.eq.2) then
!     copy array
            call io_mfi_gets(offs,pm1,ifskip)
            if (ifgetp) then
               itmp = nx2*ny2*nz2
               do il=1,nelv
                  call copy(pm(1,1,1,il),pm1(1,1,1,il),itmp)
               enddo
            endif
         elseif(chktype.eq.3) then
!     copy array
            call io_mfi_gets(offs,pm1,ifskip)
            if (ifgetp) then
               itmp = nx2*ny2*nz2
               do il=1,nelv
                 call copy(prp(1+itmp*(il-1),ipert),pm1(1,1,1,il),itmp)
               enddo
            endif
         endif
         ioflds = ioflds + 1
         offs = offs + stride
      endif

      if (chktype.ne.2) then
         if (ifgettr) then
            ifskip = .not.ifgett
            if (chktype.eq.1) then
               call io_mfi_gets(offs,t,ifskip)
            elseif(chktype.eq.3) then
               call io_mfi_gets(offs,tp(1,1,ipert),ifskip)
            endif
            ioflds = ioflds + 1
         endif

         do il=1,ldimt-1
            if (ifgtpsr(il)) then
                ifskip = .not.ifgtps(il)
               if (chktype.eq.1) then
                  call io_mfi_gets(offs,t(1,1,1,1,il+1),ifskip)
               elseif(chktype.eq.3) then
                  call io_mfi_gets(offs,tp(1,il+1,ipert),ifskip)
               endif
               ioflds = ioflds + 1
            endif
         enddo
      endif

      if (ifgtim) time = timer

!     close file
      call io_mbyte_close(ierr)
      call err_chk(ierr,'ERROR: chkpt_mfi; file not closed. $')

      tio = dnekclock_sync()-tiostart
      if (tio.le.0) tio=1.

      if(nid.eq.pid0r) then
         dnbyte = 1.*ioflds*nelr*wdsizr*nxr*nyr*nzr
      else
         dnbyte = 0.0
      endif

      dnbyte = glsum(dnbyte,1)
      dnbyte = dnbyte + iHeaderSize + 4. + isize*nelgt
      dnbyte = dnbyte/1024/1024
      if(nio.eq.0) write(6,7) istep,time,dnbyte/tio,nfiler
    7 format(/,i9,1pe12.4,' done :: Read checkpoint',/,
     &       30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &       30X,'io-nodes = ',i5,/)

!     do we have to interpolate variables
      if ((nxr.ne.nx1).or.(nyr.ne.ny1).or.(nzr.ne.nz1))
     $     call chkpt_interp(chktype,ipert)

      return
      end
!=======================================================================
!> @brief Interpolate checkpoint variables
!! @details This routine interpolates fields from nxr to nx1 (nx2) polynomial order
!! @ingroup chkpoint_mstep
!! @param[in]   fname      file name
!! @param[in]   chktype    data type to interpolate (DNS, MHD, preturbation)
!! @param[in]   ipert      index of perturbation field
!! @remark This routine uses global scratch space \a SCRCG.
!! @todo Finitsh interpolation to increase polynomial order
      subroutine chkpt_interp(chktype,ipert)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'RESTART'
      include 'TSTEP'
      include 'GEOM'
      include 'SOLN'

!     argumnt list
      character*132 fname
      integer chktype, ipert

!     local variables
      integer ierr, il, itmp
      integer ioflds
      integer*8 offs0,offs,nbyte,stride
      real dnbyte, tiostart, tio
      logical ifskip

!     functions
      real dnekclock_sync, glsum

      real pm1(lx1,ly1,lz1,lelt)
      common /SCRCG/ pm1
!-----------------------------------------------------------------------
      if (NIO.eq.0) then
         write(*,*) 'ERROR: chkpt_interp; nothing done yet'
         call exitt
      endif

      return
      end
!=======================================================================
!> @brief Map loaded variables from velocity to axisymmetric mesh
!! @ingroup chkpoint_mstep
!! @param[in] pm1    pressure loaded form the file
!! @note This is version of @ref axis_interp_ic taking into account fact
!! pressure does not have to be written on velocity mesh.
!! @remark This routine uses global scratch space \a CTMP0.
      subroutine axis_interp_ic_full_pres(pm1)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'TSTEP'
      include 'RESTART'
      include 'SOLN'
      include 'GEOM'
      include 'IXYZ'

!     argument list
      real pm1(lx1,ly1,lz1,lelv)

!     scratch space
      real axism1 (lx1,ly1)
      common /ctmp0/ axism1

!     local variables
      integer e, ips, is1
!-----------------------------------------------------------------------
      if (.not.ifaxis) return

      do e=1,nelv
         if (ifrzer(e)) then
           if (ifgetx) then
             call mxm   (xm1(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy  (xm1(1,1,1,e),axism1,nx1*ny1)
             call mxm   (ym1(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy  (ym1(1,1,1,e),axism1,nx1*ny1)
           endif
           if (ifgetu) then
             call mxm    (vx(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy   (vx(1,1,1,e),axism1,nx1*ny1)
             call mxm    (vy(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy   (vy(1,1,1,e),axism1,nx1*ny1)
           endif
           if (ifgetw) then
             call mxm    (vz(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy   (vz(1,1,1,e),axism1,nx1*ny1)
           endif
           if (ifgetp.and.(ifsplit.or.(.not.(if_full_pres)))) then
             call mxm    (pm1(1,1,1,e),nx1,iatlj1,ny1,axism1,ny1)
             call copy   (pm1(1,1,1,e),axism1,nx1*ny1)
           endif
           if (ifgett) then
             call mxm  (t (1,1,1,e,1),nx1,iatlj1,ny1,axism1,ny1)
             call copy (t (1,1,1,e,1),axism1,nx1*ny1)
           endif
           do ips=1,npscal
            is1 = ips + 1
            if (ifgtps(ips)) then
             call mxm (t(1,1,1,e,is1),nx1,iatlj1,ny1,axism1,ny1)
             call copy(t(1,1,1,e,is1),axism1,nx1*ny1)
            endif
           enddo
         endif
      enddo

      return
      end
!=======================================================================
!> @brief Map loaded pressure to the pressure mesh
!! @ingroup chkpoint_mstep
!! @param[in] pm1    pressure loaded form the file
!! @param[in] ifile  field pointer (nonlinear, mhd, perturbation;
!!   at the same time file number)
!! @note This is version of @ref map_pm1_to_pr including perturbation
      subroutine map_pm1_to_pr_pert(pm1,ifile)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'TSTEP'
      include 'RESTART'
      include 'SOLN'

!     argument list
      real pm1(lx1*ly1*lz1,lelv)
      integer ifile

!     local variables
      logical if_full_pres_tmp

      integer e, nxyz2, j, ie2
!-----------------------------------------------------------------------
      nxyz2 = nx2*ny2*nz2

      if (ifmhd.and.ifile.eq.2) then
         do e=1,nelv
            if (if_full_pres) then
               call copy  (pm(1,1,1,e),pm1(1,e),nxyz2)
            else
               call map12 (pm(1,1,1,e),pm1(1,e),e)
            endif
         enddo
      elseif (ifpert.and.ifile.ge.2) then
         j=ifile-1     ! pointer to perturbation field
         if (ifsplit) then
            call copy (prp(1,j),pm1,nx1*ny1*nz1*nelv)
         else
            do e=1,nelv
               ie2 = (e-1)*nxyz2+1
               if (if_full_pres) then
                  call copy(prp(ie2,j),pm1(1,e),nxyz2)
               else
                  call map12(prp(ie2,j),pm1(1,e),e)
               endif
            enddo
         endif
      elseif (ifsplit) then
         call copy (pr,pm1,nx1*ny1*nz1*nelv)
      else
         do e=1,nelv
            if (if_full_pres) then
               call copy  (pr(1,1,1,e),pm1(1,e),nxyz2)
            else
               call map12 (pr(1,1,1,e),pm1(1,e),e)
            endif
         enddo
      endif

      return
      end
!=======================================================================
