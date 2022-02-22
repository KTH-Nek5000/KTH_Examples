# Power iterations for optimal initial condition calculations

This example presents use of linear stability tool for OIC calculations applied
to 2D flow past circular cylinder.

## Usage:
To run this example copy mesh data (ext_cyl.re2) from 'ext_cyl_DNS' and base flow (baseflow.restart) from 'ext_cyl.LIN'. Next generate map file with use of genmap. Finally compile the executable using 'compile_script' and perform tests.


## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__monitor.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__runparam.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [checkpoint](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint.html) - checkpointing main interface
* [mstep](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint__mstep.html) - multi-step checkpointing
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [spnb](https://kth-nek5000.github.io/KTH_Framework/group__sponge__box.html) - sponge/fringe for simple box meshes
* [cnht] - conjugated heat transfer tools
* [tstpr] - time stepper
* [pwit] - power iterations to calculate stronges mode