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
            exit
         endif
      enddo

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
      include 'INPUT'           ! IFREGUO
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
#ifdef MPIIO
      rfileo = 1
#else
      rfileo = NFILEO
#endif
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
         ierr = 1
         return
      endif

!     Add file-id holder and .f appendix
      fname = trim(fname)//six(1:ndigit)//'.f'

      return
      end
!=======================================================================
!> @brief Open file at a given process only
!! @details It is a modified version of @ref mbyte_open from ic.f but
!! without equivalence and MPIIO part; I need it for some tools
!! because processor independent part is saved only by master.
!! @ingroup io_tools
!! @param[in]   hname      file name
!! @param[in]   fid        node id
!! @param[out]  ierr       error mark
      subroutine io_mbyte_open_srl(hname,fid,ierr)
      implicit none

      include 'SIZE'            ! NID
      include 'TSTEP'           ! ISTEP

!     argumnt list
      integer fid, ierr
      character*132 hname

!     local variables
      character (LEN=8) eight,fmt,s8
      save         eight
      data         eight / "????????" /

      character(LEN=132) fname

      integer ipass, kl, itmp
!-----------------------------------------------------------------------
!     initialise variables
      ierr = 0
!     work on local copy
      fname = trim(adjustl(hname))

!     test string length
      itmp = len_trim(fname)
      if (itmp.eq.0) then
         write(*,*) 'ERROR: io_mbyte_open_srl; zero lenght fname.'
         ierr = 1
         return
      endif

      do ipass=1,2              ! 2nd pass, in case 1 file/directory
         kloop: do kl=8,1,-1
         itmp = index(fname,eight(1:kl))
         if (itmp.ne.0) then      ! found k??? string
            write(fmt,"('(i',i1,'.',i1,')')") kl,kl
            write(s8,fmt) fid
            fname(itmp:itmp+kl-1) = s8(1:kl)
            exit kloop
         endif
         enddo kloop
      enddo

!     add ending character; required by C
      fname = trim(fname)//CHAR(0)

      call byte_open(fname,ierr)
      write(6,"(2i8,' OPEN: ',A)") NID,ISTEP,trim(fname)

      return
      end
!=======================================================================
