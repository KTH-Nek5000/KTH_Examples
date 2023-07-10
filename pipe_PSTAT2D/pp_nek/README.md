# Post-processing of turbulence statistics files for the turbulent pipe case.

This example presents use of 2D post-processing routines for turbulence statistics tool.

## Usage:
To run this example first create the mesh using gmsh and gmsh2nek converter. To get it run gmsh - ./turbPipe.geo' and next execute gmsh2nek. Next make sure phill_STAT was set for time and span-wise averaging, create DATA directory and copy all the ststurbpipe0.f##### files to this direcotry properly ordering and renumberring the files (in the case you user results of more than a single run collecting the statistics). Notice the file numberring has to be continuous. Finally generate positions of interpolation points using python script, move the resulting file to DATA, compile the executable using 'compile_script' and perform tests.

## Tool list:
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [mntr](https://kth-nek5000.github.io/KTH_Framework/group__mntr.html) - monitoring tool: logging and timing
* [rprm](https://kth-nek5000.github.io/KTH_Framework/group__rprm.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [pstat2d](https://kth-nek5000.github.io/KTH_Framework/group__pstat2d.html)- post processing for turbulence statistics tool
