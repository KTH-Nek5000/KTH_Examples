# Nonlinear simulation of flow over periodic hill to collect time series for point set.

This example presents use of turbulence statistics tool.

## Usage:
To run this example first create the mesh using phill.box and genbox. Next generate map file with use of genmap and generate positions of interpolation points using writer_int_pos.py. Finally adjust include file TSRSD setting max size of the buffer, compile the executable using 'compile_script' and perform tests.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__mntr.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__rprm.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [chkpt](https://kth-nek5000.github.io/KTH_Framework/group__chkpt.html) - checkpointing main interface
* [chkptms](https://kth-nek5000.github.io/KTH_Framework/group__chkptms.html) - multi-step checkpointing
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [tsrs](https://kth-nek5000.github.io/KTH_Framework/group__tsrs.html) - point time series