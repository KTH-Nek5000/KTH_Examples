!-----------------------------------------------------------------------
!
!     user subroutines required by nek5000
!
!     Parameters used by this set of subroutines:
!-----------------------------------------------------------------------
      subroutine uservp (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! UDIFF, UTRANS

      UDIFF =0.0
      UTRANS=0.0

      return
      end
!-----------------------------------------------------------------------
      subroutine userf  (ix,iy,iz,ieg)
      
      include 'SIZE'
      include 'NEKUSE'          ! FF[XYZ]

      integer ix,iy,iz,ieg

      ffx = 0.0
      ffy = 0.0
      ffz = 0.0

      return
      end
!-----------------------------------------------------------------------
      subroutine userq  (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! QVOL

      QVOL   = 0.0

      return
      end
!-----------------------------------------------------------------------
      subroutine userchk
      implicit none
      include 'SIZE'            !
      include 'TSTEP'           ! ISTEP, lastep, time
      include 'INPUT'           ! IF3D, PARAM
      
!     start framework
      if (ISTEP.eq.0) call frame_start

!     monitor simulation
      call frame_monitor

!     post processing step
      call pstat_main()
      
!     finish simulation
      LASTEP=1

!     finalise framework
      if (ISTEP.eq.NSTEPS.or.LASTEP.eq.1) then
         call frame_end
      endif
      
      call exitt0
     
      return
      end
!-----------------------------------------------------------------------
      subroutine userbc (ix,iy,iz,iside,eg)
      include 'SIZE'
      include 'NEKUSE'          ! UX, UY, UZ, TEMP, X, Y

!     velocity
      ux =  0.0
      uy =  0.0
      uz =  0.0

      return
      end
!-----------------------------------------------------------------------
      subroutine useric (ix,iy,iz,ieg)
      include 'SIZE'
      include 'NEKUSE'          ! UX, UY, UZ, TEMP, Z

!     argument list
      integer ix,iy,iz,ieg

      ux = 1.
      uy = 0.
      uz = 0.

      return
      end
!-----------------------------------------------------------------------
      subroutine usrdat
      include 'SIZE'

      call setbc(1,1,'W  ')

      return
      end
!-----------------------------------------------------------------------
      subroutine usrdat2
      include 'SIZE'

      return
      end
!-----------------------------------------------------------------------
      subroutine usrdat3
      include 'SIZE'
      
      return
      end
!======================================================================
!> @brief Register user specified modules
      subroutine frame_usr_register
      implicit none

      include 'SIZE'
      include 'FRAMELP'
!-----------------------------------------------------------------------
!     register modules
      call io_register()
      call pstat_register()

      return
      end subroutine
!======================================================================
!> @brief Initialise user specified modules
      subroutine frame_usr_init
      implicit none

      include 'SIZE'
      include 'FRAMELP'
      include 'SOLN'
!-----------------------------------------------------------------------
!     initialise modules
      call pstat_init()

      return
      end subroutine
!======================================================================
!> @brief Finalise user specified modules
      subroutine frame_usr_end
      implicit none

      include 'SIZE'
      include 'FRAMELP'
!-----------------------------------------------------------------------
!     finalise modules
      
      return
      end subroutine


c automatically added by makenek
      subroutine usrdat0() 

      return
      end

c automatically added by makenek
      subroutine usrsetvert(glo_num,nel,nx,ny,nz) ! to modify glo_num
      integer*8 glo_num(1)

      return
      end

c automatically added by makenek
      subroutine userqtl

      call userqtl_scig

      return
      end
