# Linear stability tool for spectra calculation with Arnoldi algorithm

This example presents use of linear stability tool for spectra calculations applied
to 2D flow past circular cylinder.

## Usage:
  - To run this example copy mesh data (ext_cyl.re2) from 'ext_cyl_DNS' and base flow (baseflow.restart) from 'ext_cyl.LIN'. Next generate map file with use of genmap. Alternatively, copy the latest solution field generated running 'ext_cyl_SFD' and rename it. 
  - This setup requires as well static libraries of ARPACK and PARPACK. To compile these libraries go to 'libs' directory in this example and follow steps in README. Finally copy 'libarpack_gcc_rst.a' and 'libparpack_MPI-gcc_rst.a' to the main example directory. Notice, the arpack version in this example is modified to allow for simulation restart.
  - At this point one can compile the executable using 'compile_script' and perform tests. 
  - In the .par file, the user can set: the stop criteria _MAXCYC_ and _TOL_, the dimension of the krylov subspace _NKRL_, the number of eigenvalues to compute _NEGV_ and the _MODE_. If the direct _DIR_ mode is selected only the eigenvalues spectrum is computed. In the _OIC_ mode, the optimal initial condition is computed as well. To get convergence it is required at least: _NEGV_ > _NKRL_/2.
  - The eigenvalues spectrum is saved in _eigenvalues.txt_. The real and imaginary parts of the Ritz value &sigma;<sub>i</sub> are saved in columns 2 and 3. In column 4, the ln(|&sigma;<sub>i</sub>|) is already divided by the time-stepper length _t_ and when the convergence is reached it corresponds to the real part of the eigenvalue &lambda;<sub>i</sub>. In column 5, the |&sigma;<sub>i</sub>| is also already divided by _t_, converging to the imaginary part of the correspondent eigenvalue &lambda;<sub>i</sub>. 

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__monitor.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__runparam.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [checkpoint](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint.html) - checkpointing main interface
* [dummy](https://kth-nek5000.github.io/KTH_Framework/group__chkptdummy.html) - dummy checkpointing routines
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [spnb](https://kth-nek5000.github.io/KTH_Framework/group__sponge__box.html) - sponge/fringe for simple box meshes
* [cnht] - conjugated heat transfer tools
* [tstpr] - time stepper
* [arna] - Arnildi algorithm using PARCPACK library for spectra clculation
