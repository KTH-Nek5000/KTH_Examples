!> @file spongebx.f
!! @ingroup sponge_box
!! @brief Sponge/fringe for simple box mesh
!! @author Adam Peplinski
!! @date Feb 1, 2017
!=======================================================================
!> @brief Set sponbge_box parameters
!! @ingroup sponge_box
      subroutine spng_box_param_get()
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'        ! ISIZE, WDSIZE, LSIZE,CSIZE
      include 'SPONGEBXD'

!     local variables
      integer il, ip  ! loop index
!     dictionary operations
      integer ifnd, i_out
      real d_out
      character*132 lkey
      logical ifsec
!     for broadcasting
      integer llen, lsent
      parameter (lsent = (1+4*LDIM))
      real rtmp(lsent)
!-----------------------------------------------------------------------
!     default values
      SPNG_STR = 0.0
      do il=1,NDIM
         SPNG_WL(il) = 0.0
         SPNG_WR(il) = 0.0
         SPNG_DL(il) = 0.0
         SPNG_DR(il) = 0.0
      enddo

!     dictionary
      if (NID.eq.0) then
!     check consistency
         call rprm_check(spng_nkeys, spng_dictkey, spng_n3dkeys,
     $           spng_l3dkey, ifsec)

!     if section present read parameters
         if (ifsec) then
!     strenght
            lkey = trim(adjustl(spng_dictkey(1)))//':'//
     $             trim(adjustl(spng_dictkey(2)))
            call finiparser_getDbl(d_out,trim(lkey),ifnd)
            if (ifnd.eq.1) then
               spng_str = abs(d_out)
            endif

!     sponge width
            do il=1,NDIM
               lkey = trim(adjustl(spng_dictkey(1)))//':'//
     $                trim(adjustl(spng_dictkey(2+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  spng_wl(il) = d_out
               endif
            enddo

!     sponge width
            do il=1,NDIM
               lkey = trim(adjustl(spng_dictkey(1)))//':'//
     $                trim(adjustl(spng_dictkey(5+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  spng_wr(il) = d_out
               endif
            enddo

!     drop/rise width
            do il=1,NDIM
               lkey = trim(adjustl(spng_dictkey(1)))//':'//
     $                trim(adjustl(spng_dictkey(8+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  spng_dl(il) = d_out
               endif
            enddo

!     drop/rise width
            do il=1,NDIM
               lkey = trim(adjustl(spng_dictkey(1)))//':'//
     $                trim(adjustl(spng_dictkey(11+il)))
               call finiparser_getDbl(d_out,trim(lkey),ifnd)
               if (ifnd.eq.1) then
                  spng_dr(il) = d_out
               endif
            enddo
         endif

!     print prarameters values
         write(*,*) '[',trim(spng_dictkey(1)),']'
         write(*,*) trim(spng_dictkey(2)),' = ',spng_str
         do il=1,NDIM
            write(*,*) trim(spng_dictkey(2+il)),' = ',spng_wl(il)
         enddo
         do il=1,NDIM
            write(*,*) trim(spng_dictkey(5+il)),' = ',spng_wr(il)
         enddo
         do il=1,NDIM
            write(*,*) trim(spng_dictkey(8+il)),' = ',spng_dl(il)
         enddo
         do il=1,NDIM
            write(*,*) trim(spng_dictkey(11+il)),' = ',spng_dr(il)
         enddo
      endif ! NID

!     broadcast data
      if (NID.eq.0) then
         ip = 1
         rtmp(ip) = SPNG_STR
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = SPNG_WL(il)
         enddo
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = SPNG_WR(il)
         enddo
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = SPNG_DL(il)
         enddo
         do il=1,NDIM
            ip = ip +1
            rtmp(ip) = SPNG_DR(il)
         enddo
      endif
      llen = lsent*WDSIZE
      call bcast(rtmp,llen)
      if (NID.ne.0) then
         ip = 1
         SPNG_STR = rtmp(ip)
         do il=1,NDIM
            ip = ip +1
            SPNG_WL(il) = rtmp(ip)
         enddo
         do il=1,NDIM
            ip = ip +1
            SPNG_WR(il) = rtmp(ip)
         enddo
         do il=1,NDIM
            ip = ip +1
            SPNG_DL(il) = rtmp(ip)
         enddo
         do il=1,NDIM
            ip = ip +1
            SPNG_DR(il) = rtmp(ip)
         enddo
      endif

      return
      end
!=======================================================================
!> @brief Init sponge variables in the box domain
!! @ingroup sponge_box
!! @param[in] lvx, lvy, lvz   velocity field to be stored as reference field
      subroutine spng_box_init(lvx,lvy,lvz)
      implicit none

      include 'SIZE'
      include 'GEOM'            ! [XYZ]M1
      include 'INPUT'           ! IF3D
      include 'SPONGEBXD'        !

!     argument list
!     reference velocity field
      real lvx(LX1*LY1*LZ1*LELV),lvy(LX1*LY1*LZ1*LELV),
     $     lvz(LX1*LY1*LZ1*LELV)

!     local variables
      integer ntot, il, jl
      real bmin(LDIM), bmax(LDIM)

      real rtmp, xxmax, xxmax_c, xxmin, xxmin_c, arg
      real lcoord(LX1*LY1*LZ1*LELV)

      logical ltmp

!     functions
      real glmin, glmax, mth_stepf
!-----------------------------------------------------------------------
!     get box size
      ntot = NX1*NY1*NZ1*NELV
      bmin(1) = glmin(XM1,ntot)
      bmax(1) = glmax(XM1,ntot)
      bmin(2) = glmin(YM1,ntot)
      bmax(2) = glmax(YM1,ntot)
      if(IF3D) then
         bmin(NDIM) = glmin(ZM1,ntot)
         bmax(NDIM) = glmax(ZM1,ntot)
      endif

!     zero SPNG_FUN
      call rzero(SPNG_FUN,ntot)
            
      if(SPNG_STR.gt.0.0) then

!     stamp the file
         if (NIO.eq.0) then
            write(*,*)
            write(*,*) 'SPONGE TURNED ON'
            write(*,*) 'sponge strenght = ' , SPNG_STR
            write(*,*) 'Left section'
            write(*,*) 'sponge width = ', SPNG_WL
            write(*,*) 'sponge drop/rise width = ', SPNG_DL
            write(*,*) 'Right section'
            write(*,*) 'sponge width = ', SPNG_WR
            write(*,*) 'sponge drop/rise width = ', SPNG_DR
            write(*,*)
         endif

!     save reference field
         call copy(SPNG_VR(1,1),lvx, ntot)
         call copy(SPNG_VR(1,2),lvy, ntot)
         if (IF3D) call copy(SPNG_VR(1,NDIM),lvz, ntot)

!     for every dimension
         do il=1,NDIM

            if (SPNG_WL(il).gt.0.0.or.SPNG_WR(il).gt.0.0) then
               if (SPNG_WL(il).lt.SPNG_DL(il).or.
     $              SPNG_WR(il).lt.SPNG_DR(il)) then
                  if (NIO.eq.0) then
                     write(*,*) 'ERROR; wrong sponge parameters'
                  endif
                  call exitt
               endif

!     sponge beginning (rise at xmax; right)
               xxmax = bmax(il) - SPNG_WR(il)
!     end (drop at xmin; left)
               xxmin = bmin(il) + SPNG_WL(il)
!     beginnign of constant part (right)
               xxmax_c = xxmax + SPNG_DR(il)
!     beginnign of constant part (left)
               xxmin_c = xxmin - SPNG_DL(il)

!     get SPNG_FUN
               if (xxmax.le.xxmin) then
                  if (NIO.eq.0) write(6,*) 'ERROR; sponge to wide'
                  call exitt
               else
!     this should be done by pointers, but for now I avoid it
                  if (il.eq.1) then
                     call copy(lcoord,XM1, ntot)
                  elseif (il.eq.2) then
                     call copy(lcoord,YM1, ntot)
                  elseif (il.eq.3) then
                     call copy(lcoord,ZM1, ntot)
                  endif

                  do jl=1,ntot
                     rtmp = lcoord(jl)
                     if(rtmp.le.xxmin_c) then ! constant; xmin
                        rtmp=SPNG_STR
                     elseif(rtmp.lt.xxmin) then ! fall; xmin
                        arg = (xxmin-rtmp)/SPNG_WL(il)
                        rtmp = mth_stepf(arg)
                     elseif (rtmp.le.xxmax) then ! zero
                        rtmp = 0.0
                     elseif (rtmp.lt.xxmax_c) then ! rise
                        arg = (rtmp-xxmax)/SPNG_WR(il)
                        rtmp = mth_stepf(arg)
                     else    ! constant
                        rtmp = SPNG_STR
                     endif
                     SPNG_FUN(jl)=max(SPNG_FUN(jl),rtmp)
                  enddo

               endif         ! xxmax.le.xxmin

            endif            ! SPNG_W(il).gt.0.0
         enddo

      endif                  ! SPNG_STR.gt.0.0

#ifdef DEBUG
!     for debugging
      ltmp = ifto
      ifto = .TRUE.
      call outpost2(SPNG_VR,SPNG_VR(1,2),SPNG_VR(1,NDIM),SPNG_FUN,
     $              SPNG_FUN,1,'spg')
      ifto = ltmp
#endif

      return
      end

!=======================================================================
!> @brief Calcualte sponge forcing
!! @ingroup sponge_box
!! @param[inout] ffx,ffy,ffz     forcing; x,y,z component
!! @param[in]    ix,iy,iz        GLL point index
!! @param[in]    ieg             global element number
      subroutine spng_box_forcing(ffx,ffy,ffz,ix,iy,iz,ieg)
      implicit none

      include 'SIZE'            !
      include 'INPUT'           ! IF3D
      include 'PARALLEL'        ! GLLEL
      include 'SOLN'            ! JP
      include 'SPONGEBXD'

!     argument list
      real ffx, ffy, ffz
      integer ix,iy,iz,ieg

!     local variables
      integer e, ip
      real rtmp
!-----------------------------------------------------------------------
      if (SPNG_STR.gt.0.0) then
         e=GLLEL(ieg)
         ip=ix+NX1*(iy-1+NY1*(iz-1+NZ1*(e-1)))

         if (JP.eq.0) then
!     dns
            ffx = ffx + SPNG_FUN(ip)*(SPNG_VR(ip,1) - VX(ix,iy,iz,e))
            ffy = ffy + SPNG_FUN(ip)*(SPNG_VR(ip,2) - VY(ix,iy,iz,e))
            if (IF3D) ffz = ffz + SPNG_FUN(ip)*
     $           (SPNG_VR(ip,NDIM) - VZ(ix,iy,iz,e))
         else
!     perturbation
            ffx = ffx - SPNG_FUN(ip)*VXP(ip,JP)
            ffy = ffy - SPNG_FUN(ip)*VYP(ip,JP)
            if(IF3D) ffz = ffz - SPNG_FUN(ip)*VZP(ip,JP)
         endif

      endif

      return
      end
!=======================================================================
