# KTH_Examples

This repository contains set of examples demonstrating the use of Nek5000 framework and toolboxes developed at KTH.
The more in-depth description of the framework can be found at its [doxygen documentation page]
(https://kth-nek5000.github.io/KTH_Framework/index.html), which contains variety of important information starting at
downloading options and ending with detailed code description.

## Usage

All examples contain necessary files for code compilation and running the case except those, that can be easily recreated
using `genbox` or `genmap`. Moreover, to reduce a number of binary files in the repository, we do not include multiple copies
of the same file, so e.g. `ext_cyl.re2` exists only under `ext_cyl_DNS` and it has to be copied to `ext_cyl_LIN` or `ext_cyl_SFD`.

Each example consists of:
* required tools source and include files
* setup source file (e.g. `ext_cyl.usr`)
* required `SIZE` file containing definitions of static arrays dimensions
* compilation script `compile_script`
* `makefile_usr.inc` describing compilation rules for tools files
* runtime parameters file (e.g. `ext_cyl.par`)
* mesh description; it can be `setup.box` or `setup.re2`
* `README.md` listing all the tools

To compile the code:
* make sure `compile_script` has set execute bit (`chmode u+x compile_script`)
* edit `compile_script` to set proper compilers
* clean directory `./compile_script --clean` (with the first compilation on a given machine clean the libraries as well)
* build the code `./compile_script --all`

To run the code:
* regenerate the mesh using `genbox` if `###.re2` is not present
* generate map file using `genmap`
* execute the code using scripts from `Nek5000/bin/` directory

## Example list
* `ext_cyl_DNS` - nonlinear simulation of the flow past circular cylinder
* `ext_cyl_LIN` - linear simulation of the flow past circular cylinder
* `ext_cyl_SFD` - nonlinear simulation of the flow past circular cylinder with Sequential Frequency Damping to calculate base flow
* `phill_STAT`  - nonlinear simulation of flow over periodic hill to calculate turbulence statistics
* `phill_TRIP`  - nonlinear simulation of flow over periodic hill with tripping line