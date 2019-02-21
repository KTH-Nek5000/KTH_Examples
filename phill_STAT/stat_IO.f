!> @file stat_IO.f
!! @ingroup stat
!! @brief IO routines for 2D/3D statistics module
!! @details This is a set of routines to write 2D statistics to 
!!  the file. They are modiffication of the existing nek5000 routines
!! @note This code works for extruded meshes only
!! @author Prabal Negi, Adam Peplinski
!! @date Aug 15, 2018
!=======================================================================
!> @brief Main interface for saving statistics
!! @ingroup stat
      subroutine stat_mfo()
      implicit none
      
      include 'SIZE'
      include 'STATD'

      if (stat_rdim.eq.1) then
         call stat_mfo_outfld2D()
      else
         call stat_mfo_outfld3D()
      endif

      return
      end subroutine
!=======================================================================
!> @brief Statistics muti-file output of 3D data
!! @ingroup stat
      subroutine stat_mfo_outfld3D()
      implicit none

      include 'SIZE'
      include 'INPUT'           ! ifpo
      include 'SOLN'            ! pr
      include 'STATD'           ! 
      
!     local variables
      logical ifpo_tmp
!----------------------------------------------------------------------
      ifpo_tmp = ifpo
      ifpo=.FALSE.

!     Fields to outpost: <u>t, <v>t, <w>t, <p>t
      call outpost(stat_ruavg(1,1,1),stat_ruavg(1,1,2),
     $     stat_ruavg(1,1,3),pr,stat_ruavg(1,1,4),'s01')
      
!     Fields to outpost: <uu>t, <vv>t, <ww>t, <pp>t
      call outpost(stat_ruavg(1,1,5),stat_ruavg(1,1,6),
     $     stat_ruavg(1,1,7),pr,stat_ruavg(1,1,8),'s02')
      
!     Fields to outpost: <uv>t, <vw>t,<uw>t, <pu>t
      call outpost(stat_ruavg(1,1,9),stat_ruavg(1,1,10),
     $     stat_ruavg(1,1,11),pr,stat_ruavg(1,1,12),'s03')

!     Fields to outpost: <pv>t, <pw>t, <pdudx>t, <pdudy>t
      call outpost(stat_ruavg(1,1,13),stat_ruavg(1,1,14),
     $     stat_ruavg(1,1,15),pr,stat_ruavg(1,1,16),'s04')
      
!     Fields to outpost: <pdudz>t, <pdvdx>t, <pdvdy>t, <pdvdz>t
      call outpost(stat_ruavg(1,1,17),stat_ruavg(1,1,18),
     $     stat_ruavg(1,1,19),pr,stat_ruavg(1,1,20),'s05')

!     Fields to outpost: <pdwdx>t, <pdwdy>t, <pdwdz>t, <uuu>t
      call outpost(stat_ruavg(1,1,21),stat_ruavg(1,1,22),
     $     stat_ruavg(1,1,23),pr,stat_ruavg(1,1,24),'s06')

!     Fields to outpost:  <vvv>t, <www>t, <uuv>t, <uuw>t
      call outpost(stat_ruavg(1,1,25),stat_ruavg(1,1,26),
     $     stat_ruavg(1,1,27),pr,stat_ruavg(1,1,28),'s07')
      
!     Fields to outpost: <vvu>t, <vvw>t,  <wwu>t, <wwv>t
      call outpost(stat_ruavg(1,1,29),stat_ruavg(1,1,30),
     $     stat_ruavg(1,1,31),pr,stat_ruavg(1,1,32),'s08')
      
!     Fields to outpost:  <ppp>t, <pppp>t, <uvw>t, <uuuu>t
      call outpost(stat_ruavg(1,1,33),stat_ruavg(1,1,34),
     $     stat_ruavg(1,1,35),pr,stat_ruavg(1,1,36),'s09')
      
!     Fields to outpost: <vvvv>t, <wwww>t, <e11>t, <e22>t
      call outpost(stat_ruavg(1,1,37),stat_ruavg(1,1,38),
     $     stat_ruavg(1,1,39),pr,stat_ruavg(1,1,40),'s10')
      
!     Fields to outpost: <e33>t, <e12>t, <e13>t, <e23>t
      call outpost(stat_ruavg(1,1,41),stat_ruavg(1,1,42),
     $     stat_ruavg(1,1,43),pr,stat_ruavg(1,1,44),'s11')

      ifpo=ifpo_tmp

      return
      end subroutine      
!=======================================================================
!> @brief Statistics muti-file output of 2D data
!! @ingroup stat
!! @details This routine is just modification of mfo_outfld
      subroutine stat_mfo_outfld2D()
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'PARALLEL'
      include 'INPUT'
      include 'TSTEP'
      include 'MAP2D'
      include 'STATD'

!     local variables
!     temporary variables to overwrite global values
      logical ifreguol          ! uniform mesh
      logical ifxyol            ! write down mesh
      integer wdsizol           ! store global wdsizo
      integer nel2DB            ! running sum for owned 2D elements
      integer nelBl             ! store global nelB

      integer il, jl, kl        ! loop index
      integer itmp              ! dummy integer
      integer ierr              ! error mark
      integer nxyzo             ! element size

      character*3 prefix        ! file prefix

      integer*8 offs0, offs     ! offset      
      integer*8 stride,strideB  ! stride

      integer ioflds            ! fields count

      real dnbyte               ! byte sum
      real tiostart, tio        ! simple timing

!     dummy arrays
      real ur1(lx1,lz1,2*LELT)
      common /SCRUZ/  ur1

!     functions
      integer igl_running_sum
      real dnekclock_sync, glsum
!----------------------------------------------------------------------
!     simple timing
      tiostart=dnekclock_sync()

!     intialise I/O
      ifdiro = .false.

      ifmpiio = .false.
      if(abs(param(65)).eq.1 .and. abs(param(66)).eq.6) ifmpiio=.true.
#ifdef NOMPIIO
      ifmpiio = .false.
#endif

      if(ifmpiio) then
        nfileo  = np
        nproc_o = 1
        fid0    = 0
        pid0    = nid
        pid1    = 0
      else
        if(param(65).lt.0) ifdiro = .true. !  p65 < 0 --> multi subdirectories
        nfileo  = abs(param(65))
        if(nfileo.eq.0) nfileo = 1
        if(np.lt.nfileo) nfileo=np   
        nproc_o = np / nfileo              !  # processors pointing to pid0
        fid0    = nid/nproc_o              !  file id
        pid0    = nproc_o*fid0             !  my parent i/o node
        pid1    = min(np-1,pid0+nproc_o-1) !  range of sending procs
      endif

!     save and set global IO variables
!     no uniform mesh
      ifreguol = IFREGUO
      IFREGUO = .FALSE.

!     save mesh
      ifxyol = IFXYO
      IFXYO = .TRUE.

!     force double precission
      wdsizol = WDSIZO
!     for testing
      WDSIZO = WDSIZE

      nrg = lxo
      
!     get number of 2D elements owned by proceesor with smaller nid
      itmp = map2d_lown
      nel2DB = igl_running_sum(itmp)
      nel2DB = nel2DB - map2d_lown
!     replace value
      nelBl = NELB
      NELB = nel2DB

!     set element size
      NXO   = stat_nm2
      NYO   = stat_nm3
      NZO   = 1
      nxyzo = NXO*NYO*NZO

!     open files on i/o nodes
      prefix='sts'
      ierr=0
      if (nid.eq.pid0) call mfo_open_files(prefix,ierr)

      call mntr_check_abort(stat_id,ierr,
     $     'Error opening file in stat_mfo_outfld2D.')

!     write header, byte key, global ordering
      call stat_mfo_write_hdr2D

!     initial offset: header, test pattern, global ordering
      offs0 = iHeaderSize + 4 + isize*int(map2d_gnum,8)
      offs = offs0

!     stride
      strideB = int(nelb,8)*nxyzo*wdsizo
      stride  = int(map2d_gnum,8)*nxyzo*wdsizo

!     count fields
      ioflds = 0

!     write coordinates
      kl = 0
!     copy vector
      do il=1,map2d_lnum
         if(map2d_own(il).eq.nid) then
            call copy(ur1(1,1,2*kl+1),map2d_xm1(1,1,il),nxyzo)
            call copy(ur1(1,1,2*kl+2),map2d_ym1(1,1,il),nxyzo)
            kl = kl +1
         endif
      enddo

!     check consistency
      ierr = 0
      if (kl.ne.map2d_lown) ierr=1
      call mntr_check_abort(stat_id,ierr,'inconsistent map2d_lown 1')
      
!     offset
      kl = 2*kl
      offs = offs0 + stride*ioflds + 2*strideB
      call byte_set_view(offs,ifh_mbyte)
      call mfo_outs(ur1,kl,nxo,nyo,nzo)
      ioflds = ioflds + 2

!     write fields
      do jl=1,stat_nvar
         kl = 0
!     copy vector
         do il=1,map2d_lnum
            if(map2d_own(il).eq.nid) then
               kl = kl +1
               call copy(ur1(1,1,kl),stat_ruavg(1,il,jl),nxyzo)
            endif
         enddo

!     check consistency
         ierr = 0
         if (kl.ne.map2d_lown) ierr=1
         call mntr_check_abort(stat_id,ierr,'inconsistent map2d_lown 2')

!     offset
         offs = offs0 + stride*ioflds + strideB
         call byte_set_view(offs,ifh_mbyte)
         call mfo_outs(ur1,kl,nxo,nyo,nzo)
         ioflds = ioflds + 1
      enddo

!     write averaging data
      call stat_mfo_write_stat2d

!     count bytes
      dnbyte = 1.*ioflds*map2d_lown*wdsizo*nxyzo

      ierr = 0
      if (nid.eq.pid0) then
         if(ifmpiio) then
            call byte_close_mpi(ifh_mbyte,ierr)
         else
            call byte_close(ierr)
         endif
      endif
      call mntr_check_abort(stat_id,ierr,
     $     'Error closing file in stat_mfo_outfld2D.')

      tio = dnekclock_sync()-tiostart
      if (tio.le.0) tio=1.

      dnbyte = glsum(dnbyte,1)
      dnbyte = dnbyte + iHeaderSize + 4 + isize*map2d_gnum
      dnbyte = dnbyte/1024/1024
      if(NIO.eq.0) write(6,7) ISTEP,TIME,dnbyte,dnbyte/tio,
     &     NFILEO
    7 format(/,i9,1pe12.4,' done :: Write checkpoint',/,
     &     30X,'file size = ',3pG12.2,'MB',/,
     &     30X,'avg data-throughput = ',0pf7.1,'MB/s',/,
     &     30X,'io-nodes = ',i5,/)

!     set global IO variables back
      IFREGUO = ifreguol
      IFXYO = ifxyol
      WDSIZO = wdsizol
      NELB = nelBl

      return
      end subroutine
!=======================================================================
!> @brief Write hdr, byte key, global ordering of 2D data
!! @ingroup stat
!! @details This routine is just modification of mfo_write_hdr
      subroutine stat_mfo_write_hdr2D
      implicit none

      include 'SIZE'
      include 'INPUT'
      include 'RESTART'
      include 'PARALLEL'
      include 'TSTEP'
      include 'SOLN'
      include 'MAP2D'
      include 'STATD'


!     local variables
      real*4 test_pattern       ! byte key
      integer lglist(0:LELT)    ! dummy array
      common /ctmp0/ lglist
      integer idum, inelp
      integer nelo              ! number of elements to write
      integer nfileoo           ! number of files to create
      
      integer il, jl, kl        ! loop index
      integer mtype             ! tag

      integer ierr              ! error mark
      integer ibsw_out, len
      integer*8 ioff            ! offset
      logical if_press_mesh     ! pessure mesh mark

      character*132 hdr         ! header
!-----------------------------------------------------------------------
      if(ifmpiio) then
         nfileoo = 1            ! all data into one file
         nelo = map2d_gnum
      else
         nfileoo = nfileo
         if(nid.eq.pid0) then   ! how many elements to dump
            nelo = map2d_lown
            do jl = pid0+1,pid1
               mtype = jl
               call csend(mtype,idum,isize,jl,0) ! handshake
               call crecv(mtype,inelp,isize)
               nelo = nelo + inelp
            enddo
         else
            mtype = nid
            call crecv(mtype,idum,isize) ! hand-shake
            call csend(mtype,map2d_lown,isize,pid0,0) ! u4 :=: u8
         endif 
      endif

!     write header
      ierr = 0
      if(nid.eq.pid0) then
         call blank(hdr,132)

!     varialbe set
         call blank(rdcode1,10)

!     we save coordinates
         rdcode1(1)='X'
!     and set of fields marked as passive scalars
         rdcode1(2) = 'S'
         write(rdcode1(3),'(i1)') stat_nvar/10
         write(rdcode1(4),'(i1)') stat_nvar-(stat_nvar/10)*10

!     no pressure written so pressure format set to false
      if_press_mesh = .false.
         
         write(hdr,1) wdsizo,nxo,nyo,nzo,nelo,map2d_gnum,time,istep,
     $        fid0, nfileoo, (rdcode1(il),il=1,10),p0th,if_press_mesh
 1       format('#std',1x,i1,1x,i2,1x,i2,1x,i2,1x,i10,1x,i10,1x,
     $        e20.13,1x,i9,1x,i6,1x,i6,1x,10a,1pe15.7,1x,l1) 

!     write test pattern for byte swap
         test_pattern = 6.54321 

         if(ifmpiio) then
!     only rank0 (pid00) will write hdr + test_pattern + time list
            call byte_write_mpi(hdr,iHeaderSize/4,PID00,IFH_MBYTE,ierr)
            call byte_write_mpi(test_pattern,1,PID00,IFH_MBYTE,ierr)
         else
            call byte_write(hdr,iHeaderSize/4,ierr)
            call byte_write(test_pattern,1,ierr)
         endif

      endif

      call mntr_check_abort(stat_id,ierr,
     $     'Error writing header in stat_mfo_write_hdr2D.')

!     write global 2D elements numbering for this group
!     copy data
      lglist(0) = map2d_lown
      kl = 0
      do il=1,map2d_lnum
         if(map2d_own(il).eq.nid) then
            kl = kl +1
            lglist(kl) = map2d_gmap(il)
         endif
      enddo
!     check consistency
      ierr = 0
      if (kl.ne.map2d_lown) ierr=1

      call mntr_check_abort(stat_id,ierr,'inconsistent map2d_lown 3')

      if(nid.eq.pid0) then
         if(ifmpiio) then
            ioff = iHeaderSize + 4 + int(nelb,8)*isize
            call byte_set_view (ioff,ifh_mbyte)
            call byte_write_mpi (lglist(1),lglist(0),-1,ifh_mbyte,ierr)
         else
            call byte_write(lglist(1),lglist(0),ierr)
         endif

         do jl = pid0+1,pid1
            mtype = jl
            call csend(mtype,idum,isize,jl,0) ! handshake
            len = isize*(lelt+1)
            call crecv(mtype,lglist,len)
            if(ierr.eq.0) then
               if(ifmpiio) then
                  call byte_write_mpi
     $                 (lglist(1),lglist(0),-1,ifh_mbyte,ierr)
               else
                  call byte_write(lglist(1),lglist(0),ierr)
               endif
            endif
         enddo
      else
         mtype = nid
         call crecv(mtype,idum,isize) ! hand-shake

         len = isize*(map2d_lown+1)
         call csend(mtype,lglist,len,pid0,0)  
      endif 

      call mntr_check_abort(stat_id,ierr,
     $     'Error writing global nums in stat_mfo_write_hdr2D')

      return
      end subroutine
!=======================================================================
!> @brief Write additional data at the end of the file
!! @ingroup stat
      subroutine stat_mfo_write_stat2D
      implicit none

      include 'SIZE'
      include 'RESTART'
      include 'MAP2D'
      include 'STATD'
!-----------------------------------------------------------------------
!     to be added
      if(NID.eq.PID0) then


      endif

      return
      end subroutine
!=======================================================================
