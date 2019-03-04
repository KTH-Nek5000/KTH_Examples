# Linear stability tool for spectra calculation with Arnoldi algorithm

This example presents use of linear stability tool for spectra calculations applied
to 2D flow past circular cylinder.

## Usage:
To run this example copy mesh data (ext_cyl.re2) from 'ext_cyl_DNS' and base flow (baseflow.restart) from 'ext_cyl.LIN'. Next generate map file with use of genmap. This setup requres as well static libraries of ARPACK and PARPACK. To compile these libraries go to 'libs' directory in this example and follow steps in README. Finally copy 'libarpack_gcc_rst.a' and 'libparpack_MPI-gcc_rst.a' to the main example directory. Notice, the arpack version in this example is modified to allow for simulation restart. At this point one can compile the executable using 'compile_script' and perform tests.


## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [monitor](https://kth-nek5000.github.io/KTH_Framework/group__monitor.html) - monitoring tool: logging and timing
* [runparam](https://kth-nek5000.github.io/KTH_Framework/group__runparam.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [checkpoint](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint.html) - checkpointing main interface
* [dummy](https://kth-nek5000.github.io/KTH_Framework/group__chkptdummy.html) - dummy checkpointing routines
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [sponge_box](https://kth-nek5000.github.io/KTH_Framework/group__sponge__box.html) - sponge/fringe for simple box meshes
* [conht] - conjugated heat transfer tools
* [tstepper] - time stepper
* [arnoldi_arpack] - Arnildi algorithm using PARCPACK library for spectra clculation