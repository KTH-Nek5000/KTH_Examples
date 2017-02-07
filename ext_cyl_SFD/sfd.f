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
!> @brief Main SFd interface
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
     $           'ERROR: SFD requres transient equations'
            call exitt
         endif

         if (NSTEPS.eq.0) then
            if (NIO.eq.0) write(*,*)
     $           'ERROR: SFD requires NSTEPS>0'
            call exitt
         endif

         if (IFPERT) then
            if (NIO.eq.0) write(*,*)
     $           "ERROR: SFD shouldn't be run in perturbation mode"
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
      include 'TSTEP'           ! ISTEP, TIME, NSTEPS
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
!     so skip it
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
            if (ab0.lt.SFDTOL.and.NSTEPS.gt.(ISTEP+chpm_nsnap)) then
               NSTEPS = ISTEP+chpm_nsnap
               chpt_step = ISTEP+1
               if (NIO.eq.0) then
                  write(*,*) 'SFD: reached stopping criteria'
                  write(*,*) 'SFD: saving restart files'
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
      include 'TSTEP'           ! ISTEP, NSTEPS, LASTEP
      include 'CHKPOINTD'       ! chpt_step
      include 'CHKPTMSTPD'      ! chpm_nsnap
      include 'SFD'             !

!     functions
      real dnekclock
!-----------------------------------------------------------------------
!     avoid writing for ISTEP.le.SFDNRSF
      if (ISTEP.le.chpm_nsnap) return

!     save checkpoint
      if (IFSFD.and.mod(ISTEP,chpt_step).eq.(chpm_nsnap-1)) then

!     timing
         SFDTIME1=dnekclock()

         if (NIO.eq.0) write(*,*) 'SFD: writing checkpoint'

!     save filtered valocity field
         call mfo_sfd('SFD')

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
      INCLUDE 'TSTEP'           ! ISTEP, NSTEPS, LASTEP
      include 'CHKPTMSTPD'      ! chpm_nsnap
      INCLUDE 'SFD'             !

!     temporary storage
      real TA1 (LX1,LY1,LZ1,LELV), TA2 (LX1,LY1,LZ1,LELV),
     $     TA3 (LX1,LY1,LZ1,LELV)
      COMMON /SCRUZ/ TA1, TA2, TA3

!     local variables
      integer ilag
!-----------------------------------------------------------------------
      if (IFSFD) then

         if (NIO.eq.0) write(*,*) 'SFD: reading checkpoint'

!     read filtered velocity field
         call mfi_sfd('SFD')

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
!! @param[in]  prefix    file prefix
!! @details This rouotine is version of @ref mfo_outfld.
!! @note This routine uses standard header wirter and cannot pass additiona
!!   information in the file. That is why I save whole lag spce irrespective
!!   of  chpm_nsnap value.
      subroutine mfo_sfd(prefix)  ! muti-file output
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'TSTEP'
      include 'PARALLEL'
      include 'INPUT'
      include 'CHKPTMSTPD'        ! chpm_set_o
      INCLUDE 'SFD'

!     argument list
      character*3 prefix

!     local variables
      character(LEN=132) fname, bname

      character(LEN=6)  str

      integer i, ierr, lwdsizo, ioflds, nout
      integer*8 offs0,offs,nbyte,stride,strideB,nxyzo8

      logical lifxyo, lifpo, lifvo, lifto, lifreguo, lifpso(LDIMT1)
      real tiostart, tio, dnbyte
!     functions
      integer ltrunc
      real dnekclock_sync, glsum
!-----------------------------------------------------------------------
      tiostart=dnekclock_sync()

!     copy and set output parameters
      lwdsizo= WDSIZO
      WDSIZO = 8

      lifreguo= IFREGUO
      IFREGUO = .false.
      lifxyo= IFXYO
      IFXYO = .false.
      lifpo= IFPO
      IFPO = .false.
      lifvo= IFVO
      IFVO = .true.
      lifto= IFTO
      IFTO = .false.
      do i=1,LDIMT1
         lifpso(i)= IFPSO(i)
         IFPSO(i) = .false.
      enddo

      nout = NELT
      NXO  = NX1
      NYO  = NY1
      NZO  = NZ1

!     get file name
      bname = trim(adjustl(SESSION))!  Add SESSION
      call io_mfo_fname(fname,bname,prefix,ierr)

      write(str,'(i5.5)') chpm_set_o+1
      fname=trim(fname)//trim(str(1:5))//char(0)

!     set offset
      offs0 = iHeaderSize + 4 + isize*nelgt

      ierr = 0
      if (NID.eq.pid0) then
         call mbyte_open(fname,fid0,ierr) ! open files on i/o node
      endif
      call err_chk(ierr,'Error opening file in mfo_sfd. $')

      call mfo_write_hdr                     ! create element mapping +
                                             ! write hdr
      nxyzo8  = NXO*NYO*NZO
      strideB = nelB * nxyzo8*WDSIZO
      stride  = nelgt* nxyzo8*WDSIZO

      ioflds = 0
      ! dump all fields based on the t-mesh to avoid different
      ! topologies in the post-processor

!     current filtered velocity field
      offs = offs0 + NDIM*strideB
      call byte_set_view(offs,ifh_mbyte)

      call mfo_outv(VSX,VSY,VSZ,nout,NXO,NYO,NZO)
      ioflds = ioflds + NDIM

!     history
      do i=1,3
         offs = offs0 + ioflds*stride + NDIM*strideB
         call byte_set_view(offs,ifh_mbyte)

         call mfo_outv(VSXLAG(1,1,1,1,i),VSYLAG(1,1,1,1,i),
     $           VSZLAG(1,1,1,1,i),nout,NXO,NYO,NZO)
         ioflds = ioflds + NDIM
      enddo

      dnbyte = 1.*ioflds*nout*WDSIZO*NXO*NYO*NZO

!     put output variables back
      WDSIZO = lwdsizo

      IFREGUO = lifreguo
      IFXYO = lifxyo
      IFPO = lifpo
      IFVO = lifvo
      IFTO = lifto
      do i=1,LDIMT1
         IFPSO(i) = lifpso(i)
      enddo

      ierr = 0

      if (NID.eq.PID0) 
#ifdef MPIIO
     &   call byte_close_mpi(ifh_mbyte,ierr)
#else
     &   call byte_close(ierr)
#endif
      call err_chk(ierr,'Error closing file in mfo_sfd. Abort. $')

      tio = dnekclock_sync()-tiostart
      if (tio.le.0) tio=1.

      dnbyte = glsum(dnbyte,1)
      dnbyte = dnbyte + iHeaderSize + 4. +ISIZE*NELGT
      dnbyte = dnbyte/1024/1024
      if(NIO.eq.0) write(6,7)  ISTEP,TIME,dnbyte,dnbyte/tio,
     &             NFILEO
    7 format(/,i9,1pe12.4,' done :: Write checkpoint',/,
     &       30X,'file size = ',3pG12.2,'MB',/,
     &       30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &       30X,'io-nodes = ',i5,/)

      return
      end
!=======================================================================
!> @brief Load SFD restart file
!! @ingroup sfd
!! @param[in]  prefix    file prefix
!! @details This rouotine is version of @ref mfi.
!! @note This routine uses standard header reader and cannot pass additiona
!!   information in the file. That is why I read whole lag spce irrespective
!!   of  chpm_nsnap value.
!! @remark This routine uses global scratch space \a SCRNS.
      subroutine mfi_sfd(prefix)
      implicit none

      include 'SIZE'
      INCLUDE 'INPUT'
      INCLUDE 'TSTEP'
      include 'PARALLEL'
      include 'RESTART'
      include 'CHKPTMSTPD'        ! chpm_set_i
      INCLUDE 'SFD'

!     argument list
      character*3 prefix

!     local variables
      character(LEN=132) fname, bname

      character(LEN=6)  str

!     scratch space
      integer lwk
      parameter (lwk = 7*lx1*ly1*lz1*lelt)
      real wk(lwk)
      common /scrns/ wk
      integer e, i, iofldsr, ierr

      integer*8 offs0,offs,nbyte,stride,strideB,nxyzr8
      real tiostart, tio, dnbyte
!     functions
      integer ltrunc
      real dnekclock, glsum
!-----------------------------------------------------------------------
      tiostart=dnekclock()

!     create file name
      bname = trim(adjustl(SESSION)) !  Add SESSION
      call io_mfo_fname(fname,bname,prefix,ierr)
      if (chpm_set_i.lt.0) then
         if (NIO.eq.0) write(6,*)
     $        "ERROR; mfi_sfd file set not initialised"
         call exitt
      endif
      write(str,'(i5.5)') chpm_set_i+1
      fname=trim(fname)//trim(str(1:5))//char(0)

      call mfi_prepare(fname)       ! determine reader nodes +
                                    ! read hdr + element mapping 

      offs0   = iHeadersize + 4 + ISIZE*NELGR
      nxyzr8  = NXR*NYR*NZR
      strideB = nelBr* nxyzr8*WDSIZR
      stride  = nelgr* nxyzr8*WDSIZR


!     read arrays
      iofldsr = 0
!     filtered velocity
      offs = offs0 + NDIM*strideB
      call byte_set_view(offs,ifh_mbyte)
      call mfi_getv(VSX,VSY,VSZ,wk,lwk,.false.)

      iofldsr = iofldsr + NDIM

!     history
      do i=1,3
         offs = offs0 + iofldsr*stride + NDIM*strideB
         call byte_set_view(offs,ifh_mbyte)
         call mfi_getv(VSXLAG(1,1,1,1,i),VSYLAG(1,1,1,1,i),
     $           VSZLAG(1,1,1,1,i),wk,lwk,.false.)

         iofldsr = iofldsr + NDIM
      enddo

      nbyte = 0
      if(NID.eq.pid0r) nbyte = iofldsr*nelr*wdsizr*nxr*nyr*nzr


      ierr = 0
!     close files
#ifdef MPIIO
      if (NID.eq.pid0r) call byte_close_mpi(ifh_mbyte, ierr)
#else
      if (NID.eq.pid0r) call byte_close(ierr)
#endif
      call err_chk(ierr,'Error closing restart file, in mfi_sfd.$')
      tio = dnekclock()-tiostart

      dnbyte = nbyte
      nbyte = glsum(dnbyte,1)
      nbyte = nbyte + iHeaderSize + 4 + isize*nelgr

      if(NIO.eq.0) write(6,7) istep,time,
     &             nbyte/tio/1024/1024/10,
     &             nfiler
    7 format(/,i9,1pe12.4,' done :: Read checkpoint data',/,
     &       30X,'avg data-throughput = ',f7.1,'MBps',/,
     &       30X,'io-nodes = ',i5,/)

      return
      end
!=======================================================================
