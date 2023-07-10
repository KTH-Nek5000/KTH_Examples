# Nonlinear simulation of the flow past circular cylinder.

This example presents number of tools for DNS including framework, restarting from a checkpoint, sponge and white noise added to the flow.

## Usage:
To run this example generate map file with use of genmap. Next compile the executable using 'compile_script' and perform tests.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__mntr.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__rprm.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [chkpt](https://kth-nek5000.github.io/KTH_Framework/group__chkpt.html) - checkpointing main interface
* [chkptms](https://kth-nek5000.github.io/KTH_Framework/group__chkptms.html) - multi-step checkpointing
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [nseb](https://kth-nek5000.github.io/KTH_Framework/group__nseb.html) - white noise added to velocity
* [spnb](https://kth-nek5000.github.io/KTH_Framework/group__spnb.html) - sponge/fringe for simple box meshes