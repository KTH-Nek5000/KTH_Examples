!> @file runparam.f
!! @ingroup runparam
!! @brief Set of subroutines related to module's runtime parameters.
!! @author Adam Peplinski
!! @date Feb 5, 2017
!=======================================================================
!> @brief Check consistency of module's runtime parameters
!! @ingroup runparam
!! @param[in]    mod_nkeys    number of module's keys
!! @param[in]    mod_dictkey  module's dictionary keys
!! @param[in]    mod_n3dkeys  number of keys used for 3D run only
!! @param[in]    mod_l3dkey   list of positions of 3D keys
!! @param[out]   ifsec        is section present
!! @details Check if the section name shows up and runtime parameters are
!!  spelled correctly. Give warning if section is missing, or the key is
!!  unknown. Check possible 2D - 3D parameter mismatch.
!! @warning This routine should be executed within runtime parameter reader
!!  by the master node only
      subroutine rprm_check(mod_nkeys, mod_dictkey, mod_n3dkeys,
     $           mod_l3dkey, ifsec)
      implicit none

      include 'SIZE'
      include 'INPUT'    ! IF3D

!     argument list
      integer mod_nkeys, mod_n3dkeys, mod_l3dkey(mod_n3dkeys)
      character*132 mod_dictkey(mod_nkeys)
      logical ifsec

!     local variables
      integer il, jl, ip  ! loop index
!     dictionary operations
      integer nkey, ifnd, i_out
      real d_out
      character*132 key, lkey
      character*1024 val
      logical ifvar, if3dkey
!-----------------------------------------------------------------------

!     check consistency
!     key number in dictionary
      call finiparser_getdictentries(nkey)

!     set marker for finding module's section
      ifsec = .FALSE.
      do il=1,nkey
!     get a key
         call finiparser_getpair(key,val,il,ifnd)
         call capit(key,132)

!     does it belong to current module's section
         ifnd = index(key,trim(mod_dictkey(1)))
         if (ifnd.eq.1) then
!     section was found, check variable
            ifsec = .TRUE.
            ifvar = .FALSE.
            do ip = mod_nkeys,1,-1
               lkey = trim(adjustl(mod_dictkey(1)))
               if (ip.gt.1) lkey =trim(adjustl(lkey))//
     $            ':'//trim(adjustl(mod_dictkey(ip)))
               if(index(key,trim(lkey)).eq.1) then
                  ifvar = .TRUE.
!                  exit
                  goto 20
               endif
            enddo
 20         continue
            if (ifvar) then
!     check 2D versus 3D
               if (.not.IF3D) then
                  if3dkey = .FALSE.
                  do jl=1,mod_n3dkeys
                     if (ip.eq.mod_l3dkey(jl)) then
                        if3dkey = .TRUE.
!                        exit
                        goto 40
                     endif
                  enddo
 40               continue
                  if (if3dkey) then
                     write(*,*) 'Module ',trim(mod_dictkey(1))
                     write(*,*) '3D parameter specified for 2D run'
                     write(*,*) trim(key)
                  endif
               endif
            else
!     variable not found
               write(*,*) 'Module ',trim(mod_dictkey(1))
               write(*,*) 'Unknown runtime parameter:'
               write(*,*) trim(key)
            endif
         endif
      enddo

!     no parameter section; give warning
      if (.not.ifsec) then
         write(*,*) 'Module ',trim(mod_dictkey(1))
         write(*,*) 'runtime parameter section not found.'
      endif

      return
      end
!=======================================================================
