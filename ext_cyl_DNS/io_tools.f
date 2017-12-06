!> @file io_tools.f
!! @ingroup io_tools
!! @brief Set of I/O related tools for KTH modules
!! @author Adam Peplinski
!! @date Mar 7, 2016
!=======================================================================
!> @brief Get free file unit number and store max unit value
!! @ingroup io_tools
!! @param[out] iunit     file unit
!! @param[out] ierr      error mark
!! @see io_file_close
      subroutine io_file_freeid(iunit, ierr)
      implicit none

!     argument list
      integer iunit
      integer ierr

!     keeep track of max iunit generated
      integer io_iunit_min, io_iunit_max
      common /io_iunit/ io_iunit_min, io_iunit_max

!     local variables
      logical ifcnnd            ! is unit connected
!-----------------------------------------------------------------------
!     initialize variables
      ierr=0
      iunit = io_iunit_min

      do
         inquire(unit=iunit,opened=ifcnnd,iostat=ierr)
         if(ifcnnd) then
            iunit = iunit +1
         else
!            exit
            goto 20
         endif
      enddo
 20   continue

      if (iunit.gt.io_iunit_max) io_iunit_max = iunit

      return
      end
!=======================================================================
!> @brief Close all opened files up to sotred max unit numer
!! @ingroup io_tools
!! @see io_file_freeid
      subroutine io_file_close()
      implicit none

!     keeep track of max iunit generated
      integer io_iunit_min, io_iunit_max
      common /io_iunit/ io_iunit_min, io_iunit_max

!     local variables
      integer iunit, ierr
      logical ifcnnd            ! is unit connected
!-----------------------------------------------------------------------
      do iunit = io_iunit_min, io_iunit_max
         inquire(unit=iunit,opened=ifcnnd,iostat=ierr)
         if(ifcnnd) close(iunit)
      enddo
      io_iunit_max = io_iunit_min

      return
      end
!=======================================================================
!> @brief Generate file name according to nek rulles without opening the file
!! @details It is a modified version of @ref mfo_open_files from prepost.f but
!! without equivalence and file opening part. I split file name generation
!! and file opening as different tools can require this.
!! @ingroup io_tools
!! @param[out]  fname     file name
!! @param[in]   bname     base name
!! @param[in]   prefix    prefix
!! @param[out]  ierr      error mark
      subroutine io_mfo_fname(fname,bname,prefix,ierr)
      implicit none

      include 'SIZE'
      include 'INPUT'           ! IFREGUO, IFMPIIO
      include 'RESTART'         ! NFILEO

!     argument list
      character*132  fname, bname
      character*3 prefix
      integer ierr

!     local variables
      integer ndigit, itmp
      real rfileo

      character*6  six
      save         six
      data         six / "??????" /
!-----------------------------------------------------------------------
!     initialize variables
      ierr = 0
      fname = ''

!     numbe or IO nodes
      if (IFMPIIO) then
        rfileo = 1
      else
        rfileo = NFILEO
      endif
      ndigit = log10(rfileo) + 1

!     Add directory
      if (ifdiro) fname = 'A'//six(1:ndigit)//'/'

!     Add prefix
      if (prefix(1:1).ne.' '.and.prefix(2:2).ne.' '
     $    .and.prefix(3:3).ne.' ')
     $     fname = trim(fname)//trim(adjustl(prefix))

!     Add SESSION
      fname = trim(fname)//trim(adjustl(bname))

      if (IFREGUO) fname = trim(fname)//'_reg'

!     test string length
      itmp = len_trim(fname)
      if (itmp.eq.0) then
         write(*,*) 'ERROR: io_mfo_fname; zero lenght fname.'
         ierr = 1
         return
      elseif ((itmp+ndigit+2+5).gt.132) then
         write(*,*) 'ERROR: io_mfo_fname; fname too long.'
         write(*,*) 'Fname: ',trim(fname)
         ierr = 2
         return
      endif

!     Add file-id holder and .f appendix
      fname = trim(fname)//six(1:ndigit)//'.f'

      return
      end
!=======================================================================
!> @brief Open field file
!! @details This routine opens the file (serial or parallel depending on
!!    parmeter set by @ref io_init) using Nek5000 C routines. I need it
!!    for a number of tools writing restart files that do not directly
!!    stick to the numbering scheme used in @ref mfo_open_files.
!! @ingroup io_tools
!! @param[in]   hname      file name
!! @param[out]  ierr       error mark
      subroutine io_mbyte_open(hname,ierr)
      implicit none

      include 'SIZE'            ! NID
      include 'INPUT'           ! ifmpiio
      include 'RESTART'         ! fid0, pid0, ifh_mbyte

!     argumnt list
      integer fid, ierr
      character*132 hname

!     local variables
      character*132 fname
      integer itmp
!-----------------------------------------------------------------------
!     initialise variables
      ierr = 0
!     work on local copy
      fname = trim(adjustl(hname))

!     test string length
      itmp = len_trim(fname)
      if (itmp.eq.0) then
         write(*,*) 'ERROR: io_mbyte_open; zero lenght fname.'
         ierr = 1
         return
      endif

!     add file number
      call addfid(fname,fid0)

      if(ifmpiio) then
        if(nio.eq.0)    write(6,*) '      FILE:',fname
        call byte_open_mpi(fname,ifh_mbyte,.false.,ierr)
      else
        if(nid.eq.pid0) write(6,*) '      FILE:',fname
!     add ending character; required by C
        fname = trim(fname)//CHAR(0)
        call byte_open(fname,ierr)
      endif

      return
      end
!=======================================================================
!> @brief Close field file
!! @details This routine closes the file (serial or parallel depending on
!!    parmeter set by @ref io_init) using Nek5000 C routines.
!! @ingroup io_tools
!! @param[out]  ierr       error mark
      subroutine io_mbyte_close(ierr)
      implicit none

      include 'SIZE'            ! NID
      include 'INPUT'           ! ifmpiio
      include 'RESTART'         ! pid0, ifh_mbyte

!     argumnt list
      integer ierr

!     local variables
      character*132 fname
      integer itmp
!-----------------------------------------------------------------------
!     initialise variables
      ierr = 0

!     close the file
      if (nid.eq.pid0) then
         if(ifmpiio) then
           call byte_close_mpi(ifh_mbyte,ierr)
         else
           call byte_close(ierr)
         endif
      endif

      return
      end
!=======================================================================
!> @brief Write single vector to the file
!! @details This routine is based on @ref mfo_outfld but can be used for
!!    writing 2D sections of 3D simulation.
!! @ingroup io_tools
!! @param[inout] offs               offset of global vector beginning
!! @param[in]    lvx,lvy,lvz        vector to write
!! @param[in]    lnx,lny,lnz        element dimensions
!! @param[in]    lnel               local number of filed elements
!! @param[in]    lnelg              global number of filed elements
!! @param[in]    lndim              written domain dimension
!! @remark This routine uses global scratch space \a SCRUZ.
      subroutine io_mfo_outv(offs,lvx,lvy,lvz,lnx,lny,lnz,
     $           lnel,lnelg,lndim)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'

!     argumnt list
      integer*8 offs
      integer lnx,lny,lnz,lnel,lnelg,lndim
      real lvx(lnx,lny,lnz,lnel), lvy(lnx,lny,lnz,lnel),
     $     lvz(lnx,lny,lnz,lnel)

!     local variables
      integer*8 loffs, wdsizo8
      integer il, ik, itmp

      real rvx(lxo*lxo*(1 + (ldim-2)*(lxo-1))*lelt),
     $     rvy(lxo*lxo*(1 + (ldim-2)*(lxo-1))*lelt),
     $     rvz(lxo*lxo*(1 + (ldim-2)*(lxo-1))*lelt)
      common /SCRUZ/ rvx, rvy, rvz
!-----------------------------------------------------------------------
      if (ifreguo) then
!     check size of mapping space
         if (nrg.gt.lxo) then
            if (nio.eq.0) write(6,*)
     &         'WARNING: io_mfo_outv; nrg too large, reset to lxo!'
            nrg = lxo
         endif

!     map to regular mesh
!     this code works with square element only
         itmp = nrg**lndim
         if (lndim.eq.2) then
            ik=1
            do il=1,lnel
               call map2reg_2di_e(rvx(ik),nrg,lvx(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
            ik=1
            do il=1,lnel
               call map2reg_2di_e(rvy(ik),nrg,lvy(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
         else
            ik = 1
            do il=1,lnel
               call map2reg_3di_e(rvx(ik),nrg,lvx(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
            ik = 1
            do il=1,lnel
               call map2reg_3di_e(rvy(ik),nrg,lvy(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
            ik = 1
            do il=1,lnel
               call map2reg_3di_e(rvz(ik),nrg,lvz(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
         endif

!     shift offset taking onto account elements on processes with smaller id
         itmp = 1 + (lndim-2)*(nrg-1)
!     to ensure proper integer prolongation
         wdsizo8 = wdsizo
         loffs = offs + lndim*nelB*wdsizo8*nrg*nrg*itmp
         call byte_set_view(loffs,ifh_mbyte)

!     write vector
         call mfo_outv(rvx,rvy,rvz,lnel,nrg,nrg,itmp)

!     update offset
         offs = offs + lndim*lnelg*wdsizo8*nrg*nrg*itmp
      else
!     shift offset taking onto account elements on processes with smaller id
!     to ensure proper integer prolongation
         wdsizo8 = wdsizo
         loffs = offs + lndim*nelB*wdsizo8*lnx*lny*lnz
         call byte_set_view(loffs,ifh_mbyte)

!     write vector
         call mfo_outv(lvx,lvy,lvz,lnel,lnx,lny,lnz)

!     update offset
         offs = offs + lndim*lnelg*wdsizo8*lnx*lny*lnz
      endif

      return
      end
!=======================================================================
!> @brief Write single scalar to the file
!! @details This routine is based on @ref mfo_outfld but can be used for
!!    writing 2D sections of 3D simulation.
!! @ingroup io_tools
!! @param[inout] offs               offset of global vector beginning
!! @param[in]    lvs                scalar to write
!! @param[in]    lnx,lny,lnz        element dimensions
!! @param[in]    lnel               local number of field elements
!! @param[in]    lnelg              global number of filed elements
!! @param[in]    lndim              written domain dimension
!! @remark This routine uses global scratch space \a SCRUZ.
      subroutine io_mfo_outs(offs,lvs,lnx,lny,lnz,lnel,lnelg,lndim)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'

!     argumnt list
      integer*8 offs
      integer lnx,lny,lnz,lnel,lnelg,lndim
      real lvs(lnx,lny,lnz,lnel)

!     local variables
      integer*8 loffs, wdsizo8
      integer il, ik, itmp

      real rvs(lxo*lxo*(1 + (ldim-2)*(lxo-1))*lelt)
      common /SCRUZ/ rvs
!-----------------------------------------------------------------------
      if (ifreguo) then
!     check size of mapping space
         if (nrg.gt.lxo) then
            if (nio.eq.0) write(6,*)
     &         'WARNING: io_mfo_outs; nrg too large, reset to lxo!'
            nrg = lxo
         endif

!     map to regular mesh
!     this code works with square element only
         itmp = nrg**lndim
         if (lndim.eq.2) then
            ik=1
            do il=1,lnel
               call map2reg_2di_e(rvs(ik),nrg,lvs(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
         else
            ik = 1
            do il=1,lnel
               call map2reg_3di_e(rvs(ik),nrg,lvs(1,1,1,il),lnx)
               ik = ik + itmp
            enddo
         endif

!     shift offset taking onto account elements on processes with smaller id
         itmp = 1 + (lndim-2)*(nrg-1)
!     to ensure proper integer prolongation
         wdsizo8 = wdsizo
         loffs = offs + nelB*wdsizo8*nrg*nrg*itmp
         call byte_set_view(loffs,ifh_mbyte)

!     write vector
         call mfo_outs(rvs,lnel,nrg,nrg,itmp)

!     update offset
         offs = offs + lnelg*wdsizo8*nrg*nrg*itmp
      else
!     shift offset taking onto account elements on processes with smaller id
!     to ensure proper integer prolongation
         wdsizo8 = wdsizo
         loffs = offs + nelB*wdsizo8*lnx*lny*lnz
         call byte_set_view(loffs,ifh_mbyte)

!     write vector
         call mfo_outs(lvs,lnel,lnx,lny,lnz)

!     update offset
         offs = offs + lnelg*wdsizo8*lnx*lny*lnz
      endif

      return
      end
!=======================================================================
!> @brief Read single vector to the file
!! @details This routine is based on @ref mfi but does not perform interpolation
!!    in the case nxr.ne.nx1 as for checkpointing I write raw data without
!!    interpolating to GLL grid (it concerns all axisymmetric and P_n-P_n-2
!!    simulations). Interpolation has to be performed as a separate step.
!! @ingroup io_tools
!! @param[inout] offs               offset of global vector beginning
!! @param[in]    lvx,lvy,lvz        vector to read
!! @param[in]    ifskip             do we wxport data
!! @remark This routine uses global scratch space \a SCRNS.
      subroutine io_mfi_getv(offs,lvx,lvy,lvz,ifskip)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'

!     argumnt list
      integer*8 offs
      integer lnel
      real lvx(lx1,ly1,lz1,lelv), lvy(lx1,ly1,lz1,lelv),
     $     lvz(lx1,ly1,lz1,lelv)
      logical ifskip

!     local variables
      integer*8 loffs, wdsizr8
      integer il, ik, itmp
      integer lnx1, lny1, lnz1

      integer lwk
      parameter (lwk = 7*lx1*ly1*lz1*lelt)
      real wk(lwk)
      common /SCRNS/ wk
!-----------------------------------------------------------------------
!     this code cannot be used to decrease polynomila order
      if ((nxr.gt.lx1).or.(nyr.gt.ly1).or.(nzr.gt.lz1)) then
         if (NIO.eq.0) write (*,*)
     $   'ERROR:  io_mfi_getv, element size in the checkpoint too big'
         call exitt
      endif

!     to avoid interpolation inside mfi_getv
      lnx1 = NX1
      lny1 = NY1
      lnz1 = NZ1
      NX1 = NXR
      NY1 = NYR
      NZ1 = NZR

!     shift offset taking onto account elements on processes with smaller id
!     to ensure proper integer prolongation
      wdsizr8 = wdsizr
      loffs = offs + ndim*nelBr*wdsizr8*nxr*nyr*nzr
      call byte_set_view(loffs,ifh_mbyte)

!     write vector
      call mfi_getv(lvx,lvy,lvz,wk,lwk,ifskip)

!     update offset
      offs = offs + ndim*nelgr*wdsizr8*nxr*nyr*nzr

!     put element size back
      NX1 = lnx1
      NY1 = lny1
      NZ1 = lnz1

      return
      end
!=======================================================================
!> @brief Read single scalar to the file
!! @details This routine is based on @ref mfi but does not perform interpolation
!!    in the case nxr.ne.nx1 as for checkpointing I write raw data without
!!    interpolating to GLL grid (it concerns all axisymmetric and P_n-P_n-2
!!    simulations). Interpolation has to be performed as a separate step.
!! @ingroup io_tools
!! @param[inout] offs               offset of global vector beginning
!! @param[in]    lvs                scalar to read
!! @param[in]    ifskip             do we wxport data
!! @remark This routine uses global scratch space \a SCRNS.
      subroutine io_mfi_gets(offs,lvs,ifskip)
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'

!     argumnt list
      integer*8 offs
      integer lnel
      real lvs(lx1,ly1,lz1,lelt)
      logical ifskip

!     local variables
      integer*8 loffs, wdsizr8
      integer il, ik, itmp
      integer lnx1, lny1, lnz1

      integer lwk
      parameter (lwk = 7*lx1*ly1*lz1*lelt)
      real wk(lwk)
      common /SCRNS/ wk
!-----------------------------------------------------------------------
!     this code cannot be used to decrease polynomila order
      if ((nxr.gt.lx1).or.(nyr.gt.ly1).or.(nzr.gt.lz1)) then
         if (NIO.eq.0) write (*,*)
     $   'ERROR:  io_mfi_gets, element size in the checkpoint too big'
         call exitt
      endif

!     to avoid interpolation inside mfi_gets
      lnx1 = NX1
      lny1 = NY1
      lnz1 = NZ1
      NX1 = NXR
      NY1 = NYR
      NZ1 = NZR

!     shift offset taking onto account elements on processes with smaller id
!     to ensure proper integer prolongation
      wdsizr8 = wdsizr
      loffs = offs + nelBr*wdsizr8*nxr*nyr*nzr
      call byte_set_view(loffs,ifh_mbyte)

!     write vector
      call mfi_gets(lvs,wk,lwk,ifskip)

!     update offset
      offs = offs + nelgr*wdsizr8*nxr*nyr*nzr

!     put element size back
      NX1 = lnx1
      NY1 = lny1
      NZ1 = lnz1

      return
      end
!=======================================================================

