!> @file sfd.f
!! @ingroup sfd
!! @brief Selective frequency damping (SFD) in nekton
!! @author Adam Peplinski
!! @date Feb 6, 2017
!=======================================================================
!> @brief Set sfd parameters
!! @ingroup sfd
      subroutine sfd_param_get()
      implicit none

      include 'SIZE'            !
      include 'PARALLEL'        ! ISIZE, WDSIZE, LSIZE,CSIZE
      include 'SFD'             ! IFSFD, SFDD, SFDCHI, SFDFCONV

!     argument list
      integer fid               ! file id

!     local variables
      integer il, ip  ! loop index
!     dictionary operations
      integer ifnd, i_out
      real d_out
      character*132 lkey
      logical ifsec
!     for broadcasting
      integer llen
      real rtmp(3)
!-----------------------------------------------------------------------
!     default values
      IFSFD = .FALSE.
      SFDD = 1.05000
      SFDCHI = 0.5
      SFDTOL = 1.0e-6
      SFDFCONV = 50


!     dictionary
      if (NID.eq.0) then
!     check consistency
         call rprm_check(sfd_nkeys, sfd_dictkey, sfd_n3dkeys,
     $           sfd_l3dkey, ifsec)

!     if section present read parameters
         if (ifsec) then
!     do we run SFD
            lkey = trim(adjustl(sfd_dictkey(1)))//':'//
     $             trim(adjustl(sfd_dictkey(2)))
            call finiparser_getBool(i_out,trim(lkey),ifnd)
            if (ifnd.eq.1.and.i_out.eq.1) then
               ifsfd = .TRUE.
            endif

!     filter width
            lkey = trim(adjustl(sfd_dictkey(1)))//':'//
     $             trim(adjustl(sfd_dictkey(3)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               sfdd = abs(d_out)
            endif

!     control coefficient
            lkey = trim(adjustl(sfd_dictkey(1)))//':'//
     $             trim(adjustl(sfd_dictkey(4)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               sfdchi = abs(d_out)
            endif

!     tolerance
            lkey = trim(adjustl(sfd_dictkey(1)))//':'//
     $             trim(adjustl(sfd_dictkey(5)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               sfdtol = abs(d_out)
            endif

!     log frequency
            lkey = trim(adjustl(sfd_dictkey(1)))//':'//
     $             trim(adjustl(sfd_dictkey(6)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               sfdfconv = int(d_out)
            endif

         endif

!     print prarameters values
         write(*,*) '[',trim(sfd_dictkey(1)),']'
         if (ifsfd) then
            lkey = 'yes'
         else
            lkey = 'no'
         endif
         write(*,*) trim(sfd_dictkey(2)),' = ',trim(lkey)
         write(*,*) trim(sfd_dictkey(3)),' = ',sfdd
         write(*,*) trim(sfd_dictkey(4)),' = ',sfdchi
         write(*,*) trim(sfd_dictkey(5)),' = ',sfdtol
         write(*,*) trim(sfd_dictkey(6)),' = ',sfdfconv

      endif ! NID

!     broadcast data
      if (NID.eq.0) then
         rtmp(1) = SFDD
         rtmp(2) = SFDCHI
         rtmp(3) = SFDTOL
      endif
      llen = 3*WDSIZE
      call bcast(rtmp,llen)
      if (NID.ne.0) then
         SFDD = rtmp(1)
         SFDCHI = rtmp(2)
         SFDTOL = rtmp(3)
      endif

      call bcast(SFDFCONV,ISIZE)
      call bcast(IFSFD,LSIZE)

      return
      end
!=======================================================================
!> @brief Main SFD interface
!! @ingroup sfd
      subroutine sfd_main
      implicit none


      include 'SIZE'
      include 'TSTEP'           ! ISTEP
      include 'SFD'
!-----------------------------------------------------------------------
      if (ISTEP.eq.0) then      ! before first step
!     initialisation of SFD
         call sfd_init
      else
!     SFD evolution
         if (IFSFD) then
            call sfd_solve
            call sfd_rst_save
            call sfd_end
         endif
      endif

      return
      end
!=======================================================================
!> @brief Calcualte SFD forcing
!! @ingroup sfd
!! @param[inout] ffx,ffy,ffz     forcing; x,y,z component
!! @param[in]    ix,iy,iz        GLL point index
!! @param[in]    ieg             global element number
      subroutine sfd_forcing(ffx,ffy,ffz,ix,iy,iz,ieg)
      implicit none

      include 'SIZE'            !
      include 'INPUT'           ! IF3D
      include 'PARALLEL'        ! GLLEL
      include 'SFD'

!     argument list
      real ffx, ffy, ffz
      integer ix,iy,iz,ieg

!     local variables
      integer iel
!-----------------------------------------------------------------------
      if (IFSFD) then
         iel=GLLEL(ieg)
         ffx = ffx - SFDCHI*BFSX(ix,iy,iz,iel)
         ffy = ffy - SFDCHI*BFSY(ix,iy,iz,iel)
         if (IF3D) ffz = ffz - SFDCHI*BFSZ(ix,iy,iz,iel)
      endif

      return
      end
!=======================================================================
!> @brief Initialise all SFD variables
!! @ingroup sfd
      subroutine sfd_init
      implicit none

      include 'SIZE'
      include 'SOLN'
      include 'INPUT'
      include 'TSTEP'           ! NSTEP
      include 'CHKPOINTD'       ! chpt_ifrst
      include 'SFD'

!     local variables
      integer ntot1, ilag, ierr

!     functions
      real dnekclock
!-----------------------------------------------------------------------
      ntot1 = nx1*ny1*nz1*nelv

!     should we perform SFD
      if(IFSFD) then

!     timing
         SFDTIME1=dnekclock()

!     check nekton parameters
         if (.not.IFTRAN) then
            if (NIO.eq.0) write(*,*)
     $           'ERROR: sfd_init; SFD requres transient equations'
            call exitt
         endif

         if (NSTEPS.eq.0) then
            if (NIO.eq.0) write(*,*)
     $           'ERROR: sfd_init; SFD requires NSTEPS>0'
            call exitt
         endif

         if (IFPERT) then
            if (NIO.eq.0) write(*,*)
     $      "ERROR: sfd_init; SFD shouldn't be run in perturbation mode"
            call exitt
         endif

!     open file for saving convergence history
         ierr=0
         if (NID.eq.0) then
!     find free unit
            call io_file_freeid(SFDFIDCNV, ierr)
!     get file name and open file
            if(ierr.eq.0) then
               open (unit=SFDFIDCNV,file='SFDconv.out',status='new',
     $              action='write',iostat=ierr)
            endif
         endif
         call err_chk(ierr,'ERROR opening SFDconv.out file.$')

!     delta
         if (SFDD.gt.0.0) then
            SFDD = 1.0/SFDD
         else
            if(NIO.eq.0) then
               write(*,*) 'SFD: ERROR'
               write(*,*) 'SFDD = ', SFDD
               write(*,*) 'Filter width must be positive.'
            endif
            call exitt
         endif

!     chi
         if (SFDCHI.le.0.0) then
            if(NIO.eq.0) then
               write(*,*) 'SFD: ERROR'
               write(*,*) 'SFDCHI = ', SFDCHI
               write(*,*) 'Forcing control must be positive.'
            endif
            call exitt
         endif

!     initialise arrays
!     place for restart
         if (chpt_ifrst) then
!     read checkpoint
            call sfd_rst_read
         else
            do ilag=1,3
               call rzero(VSXLAG(1,1,1,1,ilag),ntot1)
               call rzero(VSYLAG(1,1,1,1,ilag),ntot1)
               call rzero(VSZLAG(1,1,1,1,ilag),ntot1)
            enddo

            call opcopy (VSX,VSY,VSZ,VX,VY,VZ)
         endif

!     find the difference between V? and VS?
         call opsub3(BFSX,BFSY,BFSZ,VX,VY,VZ,VSX,VSY,VSZ)

!     print info
         if (NIO.eq.0) then
            write(*,*)
            write(*,*) 'SFD initialised'
            write(*,*) 'Parameters:'
            write(*,'(A15,G13.5)') 'DELTA = ',1.0/SFDD
            write(*,'(A15,G13.5)') 'CHI = ',SFDCHI
            write(*,'(A15,G13.5)') 'TOL = ',SFDTOL
            write(*,*)
         endif

!     timing
         SFDTIME2=dnekclock()
         SFDTIME = SFDTIME2 -SFDTIME1
      endif

      return
      end
!=======================================================================
!> @brief Update filtered velocity field.
!! @ingroup sfd
!! @details Sum up contributions to kth order extrapolation scheme and
!!   get new filtered velocity field.
!!   This subroutine is based on @ref makeabf and  @ref makebdf
!! @remark This routine uses global scratch space \a SCRUZ.
      subroutine sfd_solve
      implicit none

      include 'SIZE'
      include 'SOLN'
      include 'TSTEP'           ! ISTEP, TIME, NSTEPS, LASTEP
      INCLUDE 'INPUT'           ! IF3D
      include 'CHKPOINTD'       ! chpt_ifrst, chpt_step
      include 'CHKPTMSTPD'      ! chpm_nsnap
      include 'SFD'

!     temporary storage
      real  TA1 (LX1,LY1,LZ1,LELV), TA2 (LX1,LY1,LZ1,LELV),
     $      TA3 (LX1,LY1,LZ1,LELV)
      COMMON /SCRUZ/ TA1, TA2, TA3

!     local variables
!     storage of rhs
      real absx1(LX1,LY1,LZ1,LELV),absx2(LX1,LY1,LZ1,LELV),
     $     absy1(LX1,LY1,LZ1,LELV),absy2(LX1,LY1,LZ1,LELV),
     $     absz1(LX1,LY1,LZ1,LELV),absz2(LX1,LY1,LZ1,LELV)
      save absx1,absx2,absy1,absy2,absz1,absz2

      integer ntot1, ilag

      real ab0, ab1, ab2

      integer icalld
      save    icalld
      data    icalld  /0/
!     functions
      real dnekclock, gl2norm
!-----------------------------------------------------------------------
!     should we perform SFD
      if(IFSFD) then
!     timing
         SFDTIME1=dnekclock()

         ntot1 = NX1*NY1*NZ1*NELV

!     this is done only once
         if (icalld.eq.0) then
            icalld = icalld + 1

!     initialise arrays
            call rzero(absx1,ntot1)
            call rzero(absx2,ntot1)
            call rzero(absy1,ntot1)
            call rzero(absy2,ntot1)
            call rzero(absz1,ntot1)
            call rzero(absz2,ntot1)
         endif

!     A-B part
!     current rhs
!     I use BFS? vectors generated during the convergence tests
!     so skip this step
!         call opsub3(BFSX,BFSY,BFSZ,VXLAG,VYLAG,VZLAG,VSX,VSY,VSZ)
!     finish rhs
         call opcmult(BFSX,BFSY,BFSZ,SFDD)
!     old timesteps
         ab0 = AB(1)
         ab1 = AB(2)
         ab2 = AB(3)
         call add3s2 (TA1,absx1,absx2,ab1,ab2,ntot1)
         call add3s2 (TA2,absy1,absy2,ab1,ab2,ntot1)
!     save rhs
         call copy   (absx2,absx1,ntot1)
         call copy   (absy2,absy1,ntot1)
         call copy   (absx1,BFSX,ntot1)
         call copy   (absy1,BFSY,ntot1)
!     current
         call add2s1 (BFSX,TA1,ab0,ntot1)
         call add2s1 (BFSY,TA2,ab0,ntot1)
         if (IF3D) then
            call add3s2 (TA3,absz1,absz2,ab1,ab2,ntot1)
            call copy   (absz2,absz1,ntot1)
            call copy   (absz1,BFSZ,ntot1)
            call add2s1 (BFSZ,TA3,ab0,ntot1)
         endif
!     multiplication by timestep
         call opcmult(BFSX,BFSY,BFSZ,DT)

!     BD part
         ab0 = BD(2)
         call opadd2cm(BFSX,BFSY,BFSZ,VSX,VSY,VSZ,ab0)

         do ilag=2,NBD
            ab0 = BD(ilag+1)
            call opadd2cm(BFSX,BFSY,BFSZ,VSXLAG (1,1,1,1,ILAG-1),
     $           VSYLAG (1,1,1,1,ILAG-1),VSZLAG (1,1,1,1,ILAG-1),ab0)
         enddo
!     take into account restart option
         if (chpt_ifrst.and.(ISTEP.lt.chpm_nsnap))
     $        call opcopy (TA1,TA2,TA3,
     $        VSXLAG(1,1,1,1,chpm_nsnap-1),VSYLAG(1,1,1,1,chpm_nsnap-1),
     $        VSZLAG(1,1,1,1,chpm_nsnap-1))

!     Keep old filtered velocity fields
         do ilag=3,2,-1
            call opcopy(VSXLAG(1,1,1,1,ilag),VSYLAG(1,1,1,1,ilag),
     $           VSZLAG(1,1,1,1,ilag),
     $           VSXLAG(1,1,1,1,ilag-1),VSYLAG(1,1,1,1,ilag-1),
     $           VSZLAG(1,1,1,1,ilag-1))
         enddo

         call opcopy (VSXLAG,VSYLAG,VSZLAG,VSX,VSY,VSZ)

!     calculate new filtered velocity field
!     take into account restart option
         if (chpt_ifrst.and.(ISTEP.lt.chpm_nsnap)) then
            call opcopy (VSX,VSY,VSZ,TA1,TA2,TA3)
         else
            ab0 = 1.0/BD(1)
            call opcopy (VSX,VSY,VSZ,BFSX,BFSY,BFSZ)
            call opcmult(VSX,VSY,VSZ,ab0)
         endif

!     convergence test
!     find the difference between V? and VS?
         call opsub3(BFSX,BFSY,BFSZ,VX,VY,VZ,VSX,VSY,VSZ)

!     calculate L2 norms
         ab0 = gl2norm(BFSX,ntot1)
         ab1 = gl2norm(BFSY,ntot1)
         if (IF3D) ab2 = gl2norm(BFSZ,ntot1)
!     for tracking convergence
         if (NIO.eq.0.and.mod(ISTEP,SFDFCONV).eq.0) then 
            if (IF3D) then
               write(SFDFIDCNV,'(4E13.5)') TIME, ab0, ab1, ab2
            else
               write(SFDFIDCNV,'(3E13.5)') TIME, ab0, ab1
            endif
!     stamp logs
            write(*,*) 'SFD: Convergence (L2 norm per grid point):'
            write(*,'(A15,G13.5)') 'DVX = ',ab0
            write(*,'(A15,G13.5)') 'DVY = ',ab1
            if (IF3D) write(*,'(A15,G13.5)') 'DVZ = ',ab2
         endif

!     check stopping criteria
         if (ISTEP.gt.chpm_nsnap) then ! to ensure restart
            ab0 = max(ab0,ab1)
            if (IF3D) ab0 = max(ab0,ab2)
            if (ab0.lt.SFDTOL) then
               if (NIO.eq.0) write(*,*) 'SFD: stopping criteria reached'

!     should we shift checkpointing or shorten the run
               if (ISTEP.lt.(NSTEPS-2*chpm_nsnap)) then
                  ilag = ISTEP + chpt_step -1
!     shift checkpointing
                  if(mod(ilag,chpt_step).lt.(chpt_step-chpm_nsnap))then
                     NSTEPS = ISTEP+chpm_nsnap
                     chpt_step = NSTEPS
                     if (NIO.eq.0) write(*,*) 'SFD: shift checkpointing'
                  else
!     shortent the run
                     ilag = chpt_step - mod(ilag,chpt_step) - 1
                     if (ilag.eq.0) then
                        LASTEP = 1 ! it is a last step
                     else
                        NSTEPS = ISTEP+ilag
                     endif
                     if (NIO.eq.0) write(*,*) 'SFD: shorten simulation'
                  endif
               endif
            endif
         endif

!     timing
         SFDTIME2=dnekclock()
         SFDTIME = SFDTIME + SFDTIME2 -SFDTIME1

      endif                     ! IFSFD

      return
      end
!=======================================================================
!> @brief Create checkpoint
!! @ingroup sfd
      subroutine sfd_rst_save
      implicit none

      include 'SIZE'            ! NID, NDIM, NPERT
      include 'INPUT'           ! IFREGUO
      include 'TSTEP'           ! ISTEP, NSTEPS, LASTEP
      include 'CHKPOINTD'       ! chpt_step
      include 'CHKPTMSTPD'      ! chpm_nsnap
      include 'SFD'             !

!     local variables
      logical ifreguol

!     functions
      real dnekclock
!-----------------------------------------------------------------------
!     avoid writing for ISTEP.le.SFDNRSF
      if (ISTEP.le.chpm_nsnap) return

!     save checkpoint
      if (IFSFD.and.((ISTEP.eq.NSTEPS).or.
     $    (ISTEP.lt.(NSTEPS-2*chpm_nsnap).and.
     $     mod(ISTEP,chpt_step).eq.0))) then

!     timing
         SFDTIME1=dnekclock()

!     no regular mesh
         ifreguol= IFREGUO
         IFREGUO = .false.

!     initialise I/O data
         call io_init

         if (NIO.eq.0) write(*,*) 'SFD: writing checkpoint'

!     save filtered valocity field
         call sfd_mfo()

!     put parameters back
         IFREGUO = ifreguol

!     timing
         SFDTIME2=dnekclock()
         SFDTIME = SFDTIME + SFDTIME2 -SFDTIME1

      endif

      return
      end
!=======================================================================
!> @brief Read from checkpoint
!! @ingroup sfd
!! @remark This routine uses global scratch space \a SCRUZ.
      subroutine sfd_rst_read
      implicit none

      INCLUDE 'SIZE'            ! NID, NDIM, NPERT
      include 'INPUT'           ! IFREGUO
      INCLUDE 'TSTEP'           ! ISTEP, NSTEPS, LASTEP
      include 'CHKPTMSTPD'      ! chpm_nsnap
      INCLUDE 'SFD'             !

!     temporary storage
      real TA1 (LX1,LY1,LZ1,LELV), TA2 (LX1,LY1,LZ1,LELV),
     $     TA3 (LX1,LY1,LZ1,LELV)
      COMMON /SCRUZ/ TA1, TA2, TA3

!     local variables
      integer ilag

      logical ifreguol
!-----------------------------------------------------------------------
      if (IFSFD) then

         if (NIO.eq.0) write(*,*) 'SFD: reading checkpoint'

!     no regular mesh
         ifreguol= IFREGUO
         IFREGUO = .false.

!     initialise I/O data
         call io_init

!     read filtered velocity field
         call sfd_mfi()

!     put parameters back
         IFREGUO = ifreguol

!     move velcity fields to sotre oldest one in VS?
         call opcopy (TA1,TA2,TA3,
     $       VSXLAG(1,1,1,1,chpm_nsnap-1),VSYLAG(1,1,1,1,chpm_nsnap-1),
     $       VSZLAG(1,1,1,1,chpm_nsnap-1))

         do ilag=chpm_nsnap-1,2,-1
            call opcopy(VSXLAG(1,1,1,1,ilag),VSYLAG(1,1,1,1,ilag),
     $           VSZLAG(1,1,1,1,ilag),
     $           VSXLAG(1,1,1,1,ilag-1),VSYLAG(1,1,1,1,ilag-1),
     $           VSZLAG(1,1,1,1,ilag-1))
         enddo

         call opcopy (VSXLAG,VSYLAG,VSZLAG,VSX,VSY,VSZ)

         call opcopy (VSX,VSY,VSZ,TA1,TA2,TA3)

      endif

      return
      end
!=======================================================================
!> @brief Finalise SFD
!! @ingroup sfd
      subroutine sfd_end
      implicit none

      INCLUDE 'SIZE'            ! NID, NDIM, NPERT
      INCLUDE 'TSTEP'           ! ISTEP, NSTEPS, LASTEP
      INCLUDE 'INPUT'           ! IF3D
      include 'RESTART'
      INCLUDE 'SOLN'
      INCLUDE 'SFD'             ! BFS?

!     local variables
      integer ntot1, i
      real ab0, ab1, ab2

      logical lifxyo, lifpo, lifvo, lifto, lifreguo, lifpso(LDIMT1)
!     functions
      real gl2norm
!-----------------------------------------------------------------------
      if (IFSFD.and.(ISTEP.eq.NSTEPS.or.LASTEP.eq.1)) then

!     final convergence
         ntot1 = NX1*NY1*NZ1*NELV
!     calculate L2 norms
         ab0 = gl2norm(BFSX,ntot1)
         ab1 = gl2norm(BFSY,ntot1)
         if (IF3D) ab2 = gl2norm(BFSZ,ntot1)

         if (NIO.eq.0) then
            write(6,*) ''
            write(6,*) 'SFD: finalize'
            write(6,*) '   Time spent in SFD  ',SFDTIME
            write(6,*) '   Convergence (L2 norm per grid point):'
            write(6,'(A15,G13.5)') 'DVX = ',ab0
            write(6,'(A15,G13.5)') 'DVY = ',ab1
            if (IF3D) write(6,'(A15,G13.5)') 'DVZ = ',ab2
            write(6,*) ''
            write(6,*) 'SFD: saving velocity difference'
         endif

!     save the velocity difference for checking
         lifxyo= IFXYO
         IFXYO = .TRUE.
         lifpo= IFPO
         IFPO = .FALSE.
         lifvo= IFVO
         IFVO = .TRUE.
         lifto= IFTO
         IFTO = .FALSE.
         do i=1,LDIMT1
            lifpso(i)= IFPSO(i)
            IFPSO(i) = .FALSE.
         enddo

         call outpost2(BFSX,BFSY,BFSZ,PR,T,0,'VDF')

         IFXYO = lifxyo
         IFPO = lifpo
         IFVO = lifvo
         IFTO = lifto
         do i=1,LDIMT1
            IFPSO(i) = lifpso(i)
         enddo

!     close file with convergence history
         if (NID.eq.0) close(SFDFIDCNV)
      endif

      return
      end
!=======================================================================
!> @brief Store SFD restart file
!! @ingroup sfd
!! @details This rouotine is version of @ref mfo_outfld adjusted for SFD restart.
!! @note This routine uses standard header wirter so cannot pass additional
!!    information in the file header. That is why I save whole lag spce
!!    irrespective of  chpm_nsnap value.
      subroutine sfd_mfo()
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'TSTEP'
      include 'PARALLEL'
      include 'INPUT'
      include 'CHKPTMSTPD'        ! chpm_set_o
      INCLUDE 'SFD'

!     local variables
      character*132 fname, bname
      character*3 prefix
      character*6  str

      integer il, ierr, lwdsizo, ioflds, nout
      integer*8 offs

      logical lifxyo, lifpo, lifvo, lifto, lifpso(LDIMT1)
      real tiostart, tio, dnbyte

!     functions
      real dnekclock_sync, glsum
!-----------------------------------------------------------------------
      tiostart=dnekclock_sync()

!     copy and set I/O parameters
      lwdsizo= WDSIZO
      WDSIZO = 8
      lifxyo= IFXYO
      IFXYO = .false.
      lifpo= IFPO
      IFPO = .false.
      lifvo= IFVO
      IFVO = .true.
      lifto= IFTO
      IFTO = .false.
      do il=1,LDIMT1
         lifpso(il)= IFPSO(il)
         IFPSO(il) = .false.
      enddo

      nout = NELT
      NXO  = NX1
      NYO  = NY1
      NZO  = NZ1

!     get file name
      prefix = 'SFD'
      bname = trim(adjustl(SESSION))
      call io_mfo_fname(fname,bname,prefix,ierr)

      write(str,'(i5.5)') chpm_set_o+1
      fname=trim(fname)//trim(str(1:5))

!     open file
      ierr = 0
      call io_mbyte_open(fname,ierr)
      call err_chk(ierr,'ERROR: sfd_mfo; file not opened. $')

!     write a header and create element mapping
      call mfo_write_hdr

!     set offset
      offs = iHeaderSize + 4 + isize*nelgt
      ioflds = 0

!     write fields
!     current filtered velocity field
      call io_mfo_outv(offs,vsx,vsy,vsz,nx1,ny1,nz1,nelt,nelgt,ndim)
      ioflds = ioflds + NDIM

!     history
      do il=1,3
         call io_mfo_outv(offs,vsxlag(1,1,1,1,il),vsylag(1,1,1,1,il),
     $           vszlag(1,1,1,1,il),nx1,ny1,nz1,nelt,nelgt,ndim)
         ioflds = ioflds + NDIM
      enddo

      dnbyte = 1.*ioflds*nelt*wdsizo*nx1*ny1*nz1

!     put output variables back
      WDSIZO = lwdsizo
      IFXYO = lifxyo
      IFPO = lifpo
      IFVO = lifvo
      IFTO = lifto
      do il=1,LDIMT1
         IFPSO(il) = lifpso(il)
      enddo

!     close file
      call io_mbyte_close(ierr)
      call err_chk(ierr,'ERROR: sfd_mfo; file not closed. $')

      tio = dnekclock_sync()-tiostart
      if (tio.le.0) tio=1.

      dnbyte = glsum(dnbyte,1)
      dnbyte = dnbyte + iHeaderSize + 4. +ISIZE*NELGT
      dnbyte = dnbyte/1024/1024
      if(NIO.eq.0) write(6,7)  ISTEP,TIME,dnbyte,dnbyte/tio,
     &             NFILEO
    7 format(/,i9,1pe12.4,' done :: Write SFD checkpoint',/,
     &       30X,'file size = ',3pG12.2,'MB',/,
     &       30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &       30X,'io-nodes = ',i5,/)

      return
      end
!=======================================================================
!> @brief Load SFD restart file
!! @ingroup sfd
!! @details This rouotine is version of @ref mfi adjusted ofr SFD restart.
!! @note This routine uses standard header reader and cannot pass additiona
!!    information in the file. That is why I read whole lag spce irrespective
!!    of  chpm_nsnap value.
!! @remark This routine uses global scratch space \a SCRNS.
      subroutine sfd_mfi()
      implicit none

      include 'SIZE'
      INCLUDE 'INPUT'
      INCLUDE 'TSTEP'
      include 'PARALLEL'
      include 'RESTART'
      include 'CHKPTMSTPD'        ! chpm_set_i
      INCLUDE 'SFD'

!     local variables
      character*132 fname, bname
      character*3 prefix
      character*6  str

      integer il, ioflds, ierr
      integer*8 offs

      real tiostart, tio, dnbyte

      logical ifskip

!     functions
      real dnekclock_sync, glsum
!-----------------------------------------------------------------------
      tiostart=dnekclock_sync()

!     create file name
      prefix = 'SFD'
      bname = trim(adjustl(SESSION))
      call io_mfo_fname(fname,bname,prefix,ierr)
      if (chpm_set_i.lt.0) then
         if (NIO.eq.0) write(6,*)
     $        "ERROR; sfd_mfi file set not initialised"
         call exitt
      endif
      write(str,'(i5.5)') chpm_set_i+1
      fname=trim(fname)//trim(str(1:5))

!     open file, get header information and read mesh data
      call mfi_prepare(fname)

!     set header offset
      offs = iHeaderSize + 4 + isize*nelgr
      ioflds = 0
      ifskip = .FALSE.

!     read arrays
!     filtered velocity
      call io_mfi_getv(offs,vsx,vsy,vsz,ifskip)
      ioflds = ioflds + ndim

!     history
      do il=1,3
         call io_mfi_getv(offs,vsxlag(1,1,1,1,il),vsylag(1,1,1,1,il),
     $           vszlag(1,1,1,1,il),ifskip)
         ioflds = ioflds + ndim
      enddo

!     close file
      call io_mbyte_close(ierr)
      call err_chk(ierr,'ERROR: SFD_mfi; file not closed. $')

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
    7 format(/,i9,1pe12.4,' done :: Read SFD checkpoint',/,
     &       30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &       30X,'io-nodes = ',i5,/)

!     do we have to interpolate variables
      if ((nxr.ne.nx1).or.(nyr.ne.ny1).or.(nzr.ne.nz1))
     $     call sfd_interp()

      return
      end
!=======================================================================
!> @brief Interpolate checkpoint variables
!! @details This routine interpolates fields from nxr to nx1 (nx2) polynomial order
!! @ingroup sfd
!! @remark This routine uses global scratch space \a SCRCG.
!! @todo Finitsh interpolation to increase polynomial order
      subroutine sfd_interp()
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
         write(*,*) 'ERROR: sfd_interp; nothing done yet'
         call exitt
      endif

      return
      end
!=======================================================================
