!> @file pstat.f
!! @ingroup pstat
!! @brief Post processing I/O routines for statistics module
!! @author Adam Peplinski
!! @date Mar 13, 2019
!=======================================================================
!> @brief Read nonconforming data from the file
!! @ingroup pstat
      subroutine pstat_mfi_crd2D
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'
      include 'PARALLEL'
      include 'PSTATD'

      ! global data structures
      integer mid,mp,nekcomm,nekgroup,nekreal
      common /nekmpi/ mid,mp,nekcomm,nekgroup,nekreal

      ! local variables
      integer il, jl, kl        ! loop index
      integer istepr            ! timestep in restart file
      integer ierr              ! error mark
      character*3 prefix        ! file prefix
      character*132 fname       ! file name
      character*132 bname       ! base name
      character*6  str          ! file number
      character*4 sdummy
      character*132 hdr         ! header

      real*4 test_pattern       ! byte key
      integer*8 offs0, offs     ! offset

      real*4 rbuff(4*LELT)      ! buffer for element centres read

      ! functions
      logical if_byte_swap_test
      integer igl_running_sum

!#define DEBUG
#ifdef DEBUG
      character*3 str1, str2
      integer iunit
      ! call number
      integer icalld
      save icalld
      data icalld /0/
#endif
!-----------------------------------------------------------------------
      ! no regular mesh; important for file name generation
      IFREGUO = .false.

      call io_init

      ierr=0
      ! open files on i/o nodes
      prefix='c2D'
      ! get base name (SESSION)
      bname = trim(adjustl(SESSION))
      call io_mfo_fname(fname,bname,prefix,ierr)

      write(str,'(i5.5)') pstat_crd_fnr
      fname = trim(fname)//trim(str)

      fid0 = 0
      call addfid(fname,fid0)
      ! add ending character; required by C
      fname = trim(fname)//CHAR(0)

      ! open file and read header on master node
      if (nid.eq.pid00) then
         call byte_open(fname,ierr)
         ! read header
         if (ierr.eq.0) then
            call blank     (hdr,iHeaderSize)
            call byte_read (hdr,iHeaderSize/4,ierr)
         endif
         if (ierr.eq.0) then
            call byte_read (test_pattern,1,ierr)
            if_byte_sw = if_byte_swap_test(test_pattern,ierr) ! determine endianess
         endif
         ! close the file
         if (ierr.eq.0) call byte_close(ierr)
      endif
      call mntr_check_abort(pstat_id,ierr,
     $     'Error reading header file in pstat_mfi_crd2D.')

      ! broadcast data
      call bcast(hdr,iHeaderSize)
      call bcast(if_byte_sw,lsize)

      ! extract data from header
      read(hdr,*) sdummy,wdsizr,nelr,nelgr,timer,istepr,
     $    ifiler,nfiler

      ! check element number
      if (nelgr.gt.(mp*lelt)) call mntr_abort(pstat_id,
     $     'Insufficient array sizes in pstat_mfi_crd2D.')

      ! initialise I/O data
      ! I support mpi IO only
      if (nfiler.ne.1) call mntr_abort(pstat_id,
     $     'Only MPI I/O supported in pstat_mfi_crd2D.')

      ifmpiio = .true.

      pid0r  = nid
      pid1r  = nid
      offs0  = iHeaderSize + 4
      nfiler = np

      ! number of elements to read
      nelr = nelgr/np
      do il = 0,mod(nelgr,np)-1
         if(il.eq.nid) nelr = nelr + 1
      enddo
      nelBr = igl_running_sum(nelr) - nelr

      call byte_open_mpi(fname,ifh_mbyte,.true.,ierr)

      call mntr_check_abort(pstat_id,ierr,
     $     'Error parrallel opening file in pstat_mfi_crd2D.')

      ! read global element number
      offs = offs0 + nelBr*isize
      call byte_set_view(offs,ifh_mbyte)
      call byte_read_mpi(er,nelr,-1,ifh_mbyte,ierr)
      call mntr_check_abort(pstat_id,ierr,
     $     'Error reading glnel in pstat_mfi_crd2D.')
      if(if_byte_sw) call byte_reverse(er,nelr,ierr)
      do il=1,nelr
        pstat_gnel(il) = er(il)
      enddo

      ! read global element level
      offs = offs0 + (nelgr+nelBr)*isize
      call byte_set_view(offs,ifh_mbyte)
      call byte_read_mpi(er,nelr,-1,ifh_mbyte,ierr)
      call mntr_check_abort(pstat_id,ierr,
     $     'Error reading level in pstat_mfi_crd2D.')
      if(if_byte_sw) call byte_reverse(er,nelr,ierr)
      do il=1,nelr
        pstat_lev(il) = er(il)
      enddo

      ! read global element centres
      offs = offs0 + 2*nelgr*isize+ nelBr*2*wdsizr
      kl = 2*nelr*wdsizr/4
      call byte_set_view(offs,ifh_mbyte)
      call byte_read_mpi(rbuff,kl,-1,ifh_mbyte,ierr)
      call mntr_check_abort(pstat_id,ierr,
     $     'Error reading element centres in pstat_mfi_crd2D.')
      if(if_byte_sw) call byte_reverse(rbuff,kl,ierr)
      if (wdsizr.eq.4) then         ! COPY
         call copy4r(pstat_cnt,rbuff,2*nelr)
      else
         call copy  (pstat_cnt,rbuff,2*nelr)
      endif

      call byte_close_mpi(ifh_mbyte,ierr)
      call mntr_check_abort(pstat_id,ierr,
     $     'Error parrallel closing file in pstat_mfi_crd2D.')

      ! save local and global element count
      pstat_nelg = nelgr
      pstat_nel = nelr

#ifdef DEBUG
      ! for testing
      ! to output refinement
      icalld = icalld+1
      call io_file_freeid(iunit, ierr)
      write(str1,'(i3.3)') NID
      write(str2,'(i3.3)') icalld
      open(unit=iunit,file='CRDmsh.txt'//str1//'i'//str2)

      write(iunit,*) nelgr, nelr
      do il=1,nelr
         write(iunit,*) il,pstat_gnel(il),pstat_lev(il),
     $    (pstat_cnt(jl,il),jl=1,2)
      enddo

      close(iunit)
#endif
#undef DEBUG

      return
      end subroutine
!=======================================================================
!> @brief Read interpolation points position and redistribute them
!! @ingroup pstat
      subroutine pstat_mfi_interp
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'PSTATD'

      ! global data structures
      integer mid,mp,nekcomm,nekgroup,nekreal
      common /nekmpi/ mid,mp,nekcomm,nekgroup,nekreal

      ! local variables
      integer il, jl       ! loop index
      integer ierr         ! error flag
      integer uidx, uidy   ! unit id
      integer nrec         ! record position
      integer npx, npy     ! number of points in the file
      integer npass        ! number of messages to send
      real rtmp_pts(ldim,lhis)
      real rtmp1, rtmp2
!-----------------------------------------------------------------------
      ! master opens files and gets point number
      ierr = 0
      if (nid.eq.0) then
         ! there is a problem with reading points in rank sections, so
         ! I have to open the files using direct access
         ! Find record length; this is fortran 90 feature
         inquire(iolength=jl) rtmp1
         call io_file_freeid(uidx, ierr)
         open(unit=uidx,form='unformatted',access='direct',recl=jl,
     $        file='ZSTAT/x.fort')
         call io_file_freeid(uidy, ierr)
         open(unit=uidy,form='unformatted',access='direct',recl=jl,
     $        file='ZSTAT/y.fort')
         read(uidx,rec=1) il,npx
         read(uidy,rec=1) il,npy
         if (npx.ne.npy) ierr = 1
         nrec = 3
      endif

      call mntr_check_abort(pstat_id,ierr,
     $       'pstat_mfi_interp: Error opening point files')

      ! broadcast points number and calculate point distribution
      ! it is post-processing done on small number of cores, so I assume npx >> mp
      call bcast(npx,isize)
      pstat_nptot = npx
      pstat_npt = npx/mp
      if (pstat_npt.gt.0) then
         pstat_npt1 = mod(pstat_nptot,pstat_npt)
      else
         pstat_npt1 = pstat_nptot
      endif
      if (nid.lt.pstat_npt1) pstat_npt = pstat_npt +1

      ierr = 0
      if (pstat_npt.gt.lhis) ierr = 1
      call mntr_check_abort(pstat_id,ierr,
     $       'pstat_mfi_interp: lhis too small')

      ! read and redistribute points
      ! this part is not optimised, but it is post-processing done locally, so I don't care
      if (nid.eq.0) then
         if (pstat_nptot.gt.0) then
            ! read points for the master rank
            do il=1,pstat_npt
               read(uidx,rec=nrec) rtmp1
               read(uidy,rec=nrec) rtmp2
               nrec = nrec + 1
               pstat_int_pts(1,il) = rtmp1
               pstat_int_pts(2,il) = rtmp2
            enddo

            ! redistribute rest of points
            npass = min(mp,pstat_nptot)
            do il = 1,npass-1
               npy = pstat_npt
               if (pstat_npt1.gt.0.and.il.ge.pstat_npt1) then
                  npy = pstat_npt -1
               endif
               do jl = 1,npy
                  read(uidx,rec=nrec) rtmp1
                  read(uidy,rec=nrec) rtmp2
                  nrec = nrec + 1
                  rtmp_pts(1,jl) = rtmp1
                  rtmp_pts(2,jl) = rtmp2
               enddo

               call csend(il,rtmp_pts,ldim*npy*wdsize,il,jl)
            enddo
         endif
      else
         if (pstat_npt.gt.0) then
            call crecv2(nid,pstat_int_pts,ldim*pstat_npt*wdsize,0)
         endif
      endif

      ! master closes files
      if (nid.eq.0) then
        close (uidx)
        close (uidy)
      endif

      return
      end subroutine
!=======================================================================
!> @brief Geather data and write it down
!! @ingroup pstat
      subroutine pstat_mfo_interp
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'PARALLEL'
      include 'GEOM'
      include 'PSTATD'

      ! global data structures
      integer mid,mp,nekcomm,nekgroup,nekreal
      common /nekmpi/ mid,mp,nekcomm,nekgroup,nekreal

      ! local variables
      integer il, jl, kl   ! loop index
      integer ierr         ! error flag
      integer uid          ! unit id
      character*532 head   ! file header
      character*532 ftm    ! header format
      integer npass        ! number of messages to send for single field
      integer npts         ! number of points for transfer
      integer itmp         ! temporary variables
      real rtmpv(lhis), rtmp
      real lx,ly,lz        ! box dimensions
      integer nlx,nly,nlz  ! for tensor product meshes
      integer iavfr

      ! functions
      real glmin, glmax
!-----------------------------------------------------------------------
      ! gether information for file header
      il = lx1*ly1*lz1*nelt
      lx = glmax(xm1,il) - glmin(xm1,il)
      ly = glmax(ym1,il) - glmin(ym1,il)
      if (if3D) then
         lz = glmax(zm1,il) - glmin(zm1,il)
      else
         lz = 0.0     ! this should be changed
      endif
      ! for tensor product meshes; element count
      nlx = pstat_nelg
      nly = 1
      nlz = 1
      ! frequency of averaging in steps
      iavfr = pstat_nstep
      ! stat averagign time
      rtmp = pstat_etime-pstat_stime
      ! this is far from optimal, but for post-processing I do not care
      ! master opens files and writes header
      ierr = 0
      if (nid.eq.0) then
         call io_file_freeid(uid, ierr)
         open(unit=uid,form='unformatted',file='ZSTAT/int_fld')

         ! write file's header
         ftm="(1p,'(Re =',e17.9,') (Lx, Ly, Lz =',3e17.9,"//
     $   "') (nelx, nely, nelz =',3i9,') (Polynomial order =',3i9,"//
     $   "') (Nstat =',i9,') (Nderiv =',i9,') (start time =',e17.9,"//
     $   "') (end time =',e17.9,') (effective average time =',e17.9,"//
     $   "') (time step =',e17.9,') (nrec =',i9"//
     $   "') (time interval =',e17.9,') (npoints =',i9,')')"
         write(head,ftm) 1.0/param(2),lx,ly,lz,nlx,nly,nlz,lx1,ly1,lz1,
     $    pstat_svar,pstat_dvar,pstat_stime,pstat_etime,rtmp/iavfr,
     $    rtmp/pstat_istepr,pstat_istepr/iavfr,rtmp,pstat_nptot
         write(uid) trim(head)
         write(uid) 1.0/param(2),lx,ly,lz,nlx,nly,nlz,lx1,ly1,lz1,
     $    pstat_svar,pstat_dvar,pstat_stime,pstat_etime,rtmp/iavfr,
     $    rtmp/pstat_istepr,pstat_istepr/iavfr,rtmp,pstat_nptot
      endif

      ! geather the data and write it down to the file
      ! averaged fields
      do il = 1,pstat_svar
         if (nid.eq.0) then
            ! first master writes its own data
            write(uid) (pstat_int_avg (jl,il),jl=1,pstat_npt)

            ! geather data from slaves
            npass = min(mp,pstat_nptot)
            do jl = 1,npass-1
               npts = pstat_npt
               if (pstat_npt1.gt.0.and.jl.ge.pstat_npt1) then
                  npts = pstat_npt -1
               endif
               call csend(jl,itmp,isize,jl,kl) ! hand shaiking
               call crecv2(jl,rtmpv,npts*wdsize,jl)

               ! write data
               write(uid) (rtmpv (kl),kl=1,npts)
            enddo
         else
            ! slaves send their data
            if (pstat_npt.gt.0) then
               call crecv2(nid,itmp,isize,0) ! hand shaiking
               call csend(nid,pstat_int_avg(1,il),pstat_npt*wdsize,0,
     $              itmp)
            endif
         endif
      enddo

      ! fields derivatives
      do il = 1,pstat_dvar
         if (nid.eq.0) then
            ! first master writes its own data
            write(uid) (pstat_int_der (jl,il),jl=1,pstat_npt)

            ! geather data from slaves
            npass = min(mp,pstat_nptot)
            do jl = 1,npass-1
               npts = pstat_npt
               if (pstat_npt1.gt.0.and.jl.ge.pstat_npt1) then
                  npts = pstat_npt -1
               endif
               call csend(jl,itmp,isize,jl,kl) ! hand shaiking
               call crecv2(jl,rtmpv,npts*wdsize,jl)

               ! write data
               write(uid) (rtmpv (kl),kl=1,npts)
            enddo
         else
            ! slaves send their data
            if (pstat_npt.gt.0) then
               call crecv2(nid,itmp,isize,0) ! hand shaiking
               call csend(nid,pstat_int_der(1,il),pstat_npt*wdsize,0,
     $              itmp)
            endif
         endif
      enddo


      ! master closes the file
      if (nid.eq.0) then
         close(uid)
      endif

      return
      end subroutine
!=======================================================================
