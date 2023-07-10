# Nonlinear simulation of flow over periodic hill with tripping.

This example presents use of tripping-line tool.

## Usage:
To run this example first create the mesh using phill.box and genbox. Next generate map file with use of genmap. Finally adjust include file TRIPLD setting max number of lines and max number of modes, compile the executable using 'compile_script' and perform tests.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__mntr.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__rprm.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [chkpt](https://kth-nek5000.github.io/KTH_Framework/group__chkpt.html) - checkpointing main interface
* [chkptms](https://kth-nek5000.github.io/KTH_Framework/group__chkptms.html) - multi-step checkpointing
* [tripl](https://kth-neks5000.github.io/KTH_Framework/group__tripl.html) - tripping-line tool