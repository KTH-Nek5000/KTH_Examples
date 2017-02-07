!> @file noisebx.f
!! @ingroup noise_box
!> @brief Adding white noise in a box
!! @author Adam Peplinski
!! @date Feb 2, 2017
!=======================================================================
!> @brief Set noise_box parameters
!! @ingroup noise_box
      subroutine nse_box_param_get
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'        ! ISIZE, WDSIZE, LSIZE,CSIZE
      include 'NOISEBXD'

!     local variables
      integer il, ip  ! loop index
!     dictionary operations
      integer ifnd, i_out
      real d_out
      character*132 lkey
      logical ifsec
!     for broadcasting
      integer llen, lsent
      parameter (lsent = (2+2*LDIM))
      real rtmp(lsent)
!-----------------------------------------------------------------------
!     default values
      NSEB_TIM = 0.0
      NSEB_AMP = 0.0
      do il=1,NDIM
         NSEB_BMIN(il) = 0.0
         NSEB_BMAX(il) = 0.0
      enddo

!     dictionary
      if (NID.eq.0) then
!     check consistency
         call rprm_check(nseb_nkeys, nseb_dictkey, nseb_n3dkeys,
     $           nseb_l3dkey, ifsec)

!     if section present read parameters
         if (ifsec) then
!     time
            lkey = trim(adjustl(nseb_dictkey(1)))//':'//
     $             trim(adjustl(nseb_dictkey(2)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               nseb_tim = abs(d_out)
            endif

!     amplitude
            lkey = trim(adjustl(nseb_dictkey(1)))//':'//
     $             trim(adjustl(nseb_dictkey(3)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               nseb_amp = abs(d_out)
            endif

!     box corners
            do il=1,NDIM
               lkey = trim(adjustl(nseb_dictkey(1)))//':'//
     $                trim(adjustl(nseb_dictkey(3+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  nseb_bmin(il) = d_out
               endif
            enddo

!     box corners
            do il=1,NDIM
               lkey = trim(adjustl(nseb_dictkey(1)))//':'//
     $                trim(adjustl(nseb_dictkey(6+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  nseb_bmax(il) = d_out
               endif
            enddo
         endif

!     print prarameters values
         write(*,*) '[',trim(nseb_dictkey(1)),']'
         write(*,*) trim(nseb_dictkey(2)),' = ',nseb_tim
         write(*,*) trim(nseb_dictkey(3)),' = ',nseb_amp
         do il=1,NDIM
            write(*,*) trim(nseb_dictkey(3+il)),' = ',nseb_bmin(il)
         enddo
         do il=1,NDIM
            write(*,*) trim(nseb_dictkey(6+il)),' = ',nseb_bmax(il)
         enddo
      endif ! NID

!     broadcast data
      if (NID.eq.0) then
         ip = 1
         rtmp(ip) = NSEB_TIM
         ip = ip +1
         rtmp(ip) = NSEB_AMP
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = NSEB_BMIN(il)
         enddo
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = NSEB_BMAX(il)
         enddo
      endif
      llen = lsent*WDSIZE
      call bcast(rtmp,llen)
      if (NID.ne.0) then
         ip = 1
         NSEB_TIM = rtmp(ip)
         ip = ip +1
         NSEB_AMP = rtmp(ip)
         do il=1,NDIM
            ip = ip +1
            NSEB_BMIN(il) = rtmp(ip)
         enddo
         do il=1,NDIM
            ip = ip +1
            NSEB_BMAX(il) = rtmp(ip)
         enddo
      endif

      return
      end
!=======================================================================
!> @brief Add noise to velocity field in a box
!! @ingroup noise_box
      subroutine nse_box_add()
      implicit none

      include 'SIZE'            ! NX1, NY1, NZ1, NELV, NID
      include 'TSTEP'           ! TIME, DT
      include 'PARALLEL'        ! LGLEL
      include 'INPUT'           ! IF3D
      include 'SOLN'            ! VX, VY, VZ, VMULT
      include 'GEOM'            ! XM1, YM1, ZM1
      include 'NOISEBXD'

!     local variables
      integer iel, ieg, il, jl, kl, nl
      real xl(LDIM)
      logical ifadd
      real fcoeff(3)            !< coefficients for random distribution

!     functions
      real mth_rand
!-----------------------------------------------------------------------
!     add noise
      if (NSEB_AMP.gt.0.0) then
         if (NSEB_TIM.ge.TIME.and.NSEB_TIM.le.(TIME+DT)) then

            if (NIO.eq.0) write(6,*) 'Adding noise; eps= ', NSEB_AMP

            do iel=1,NELV
               do kl=1,NZ1
                  do jl=1,NY1
                     do il=1,NX1
                        ieg = LGLEL(iel)
                        xl(1) = XM1(il,jl,kl,iel)
                        xl(2) = YM1(il,jl,kl,iel)
                        if (IF3D) xl(NDIM) = YM1(il,jl,kl,iel)
                        ifadd = .TRUE.
                        diml: do nl=1,NDIM
                           if (xl(nl).lt.NSEB_BMIN(nl).or.
     $                          xl(nl).gt.NSEB_BMAX(nl)) then
                              ifadd = .FALSE.
                              exit diml
                           endif
                        enddo diml

                        if (ifadd) then
                           fcoeff(1)=  3.0e4
                           fcoeff(2)= -1.5e3
                           fcoeff(3)=  0.5e5
                           VX(il,jl,kl,iel)=VX(il,jl,kl,iel)+NSEB_AMP*
     $                          mth_rand(il,jl,kl,ieg,xl,fcoeff)
                           fcoeff(1)=  2.3e4
                           fcoeff(2)=  2.3e3
                           fcoeff(3)= -2.0e5
                           VY(il,jl,kl,iel)=VY(il,jl,kl,iel)+NSEB_AMP*
     $                          mth_rand(il,jl,kl,ieg,xl,fcoeff)
                           if (IF3D) then
                              fcoeff(1)= 2.e4
                              fcoeff(2)= 1.e3
                              fcoeff(3)= 1.e5
                              VZ(il,jl,kl,iel)=VZ(il,jl,kl,iel)+
     $                             NSEB_AMP*
     $                             mth_rand(il,jl,kl,ieg,xl,fcoeff)
                           endif
                        endif

                     enddo
                  enddo
               enddo
            enddo


!     face averaging
            call opdssum(VX,VY,VZ)
            call opcolv (VX,VY,VZ,VMULT)
         endif
      endif

      return
      end
!=======================================================================
