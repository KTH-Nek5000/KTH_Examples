# Nonlinear simulation of 3D periodic turbulent pipe to calculate turbulence statistics.

This example presents use of turbulence statistics tool.

## Usage:
To run this example first create the mesh using gmsh and gmsh2nek converter. To get it run gmsh - ./turbPipe.geo' and next execute gmsh2nek. There is one periodic boundary  pair consiting of bc 1 and 2. The translation vector is (0, 0, 8.16667). Next generate map file with use of genmap. Finally adjust include file STATD choosing between time average only and time-space average, compile the executable using 'compile_script' and perform tests.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__mntr.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__rprm.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [chkpt](https://kth-nek5000.github.io/KTH_Framework/group__chkpt.html) - checkpointing main interface
* [chkptms](https://kth-nek5000.github.io/KTH_Framework/group__chkptms.html) - multi-step checkpointing
* [math](https://kth-nek5000.github.io/KTH_Framework/group__math.html) - simple math tools
* [map2D](https://kth-nek5000.github.io/KTH_Framework/group__map2d.html) - 3D to 2D grid mapping for 2D-extruded meshes
* [stat](https://kth-nek5000.github.io/KTH_Framework/group__stat.html) - turbulence statistics tool
