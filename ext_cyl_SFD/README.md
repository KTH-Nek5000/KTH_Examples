# Nonlinear simulation of the flow past circular cylinder with Selective Frequency Damping.

This example presents use of SFD to calculate base flow.

## Usage:
  - To run this example copy mesh data (ext_cyl.re2) from 'ext_cyl_DNS'. Next generate map file with use of genmap. Finally compile the executable using 'compile_script' and perform tests.
  - SFDconv.out describes convergence history, showing time and L2 norm per grid points (for vx and vy). It has to be deleted before a new run, otherwise you get the error _Error opening convergence file_.
  - Set the number of time steps large enough to reach the desired tolerance.
  - Outputs: `SFDconv.out` with the convergence history, the last `ext_cyl0.f0*` has the converged base flow, `vdfext_cyl0.f0*` show the tolerance field (the difference between the flow solution and the temporally low-pass filtered counterpart), `SFDext_cyl0.f0*` are the checkpoint restarts.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [monitor](https://kth-nek5000.github.io/KTH_Framework/group__monitor.html) - monitoring tool: logging and timing
* [runparam](https://kth-nek5000.github.io/KTH_Framework/group__runparam.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [checkpoint](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint.html) - checkpointing main interface
* [mstep](https://kth-nek5000.github.io/KTH_Framework/group__chkpoint__mstep.html) - multi-step checkpointing
* [sfd](https://kth-nek5000.github.io/KTH_Framework/group__sfd.html) - Selective Frequency Damping tool
