
# Post-processing of the turbulence statistics of the flow over a periodic hill 


## Tool list
* [frame](https://kth-nek5000.github.io/KTH_Framework/group__frame.html) - backbone of the toolbox
* [monitor](https://kth-nek5000.github.io/KTH_Framework/group__monitor.html) - monitoring tool: logging and timing
* [runparam](https://kth-nek5000.github.io/KTH_Framework/group__runparam.html) - runtime parameters
* [io_tool](https://kth-nek5000.github.io/KTH_Framework/group__io__tools.html) - simple I/O tools
* [pstat2d](https://kth-nek5000.github.io/KTH_Framework/group__postpr.html)- post processing for turbulence statistics tool

## Overview
The periodic hill is a 3D case with the periodic condition applied to both streamwise (x) and spanwise (z) directions. The flow statistics are computed by averaging over time and z-direction.  As a result, the final statistics are 2D and a function of x and y. 

To obtain the post-processed 2D turbulence statistics, the following steps are required:

1. **Step 1** - Flow simulation and gathering the statistics:
This needs running the Nek5000 case [`phill_STAT`](https://github.com/KTH-Nek5000/KTH_Examples/tree/master/phill_STAT). By gathering the statistics (averaged over time and z-direction), two sets of files are produced: `stsphill0.f*****` and `c2Dphill0.f*****`. 

2. **Step 2** - Merge the statistics data files and interpolate the data on the interpolation points:
These are achieved by running Nek5000 in [`./pp_Nek/`](https://github.com/KTH-Nek5000/KTH_Examples/tree/master/phill_PSTAT2D/pp_Nek), see below for the details. As a result of this step, `int_fld` is produced in `./pp_Nek/DATA/`. Note that the interpolation is from the GLL points in the simulation grid to a set of points specified in `int_pos`. For the list of fields written in `int_fld`, see [this list](https://github.com/KTH-Nek5000/KTH_Examples/blob/master/pipe_PSTAT2D/pp_python/nom_fields.txt).

3. **Step 3** - Extract mean, RMS, and other turbulence statistics from `int_fld`:
As detailed below, by running a set of `Python` scripts located in [`./pp_Python/`](https://github.com/KTH-Nek5000/KTH_Examples/tree/master/phill_PSTAT2D/pp_Python), the profiles of turbulence statistics on the interpolation points are constructed from the fields available in `int_fld`.

## Details of Step 2
* In `./pp_Python/modules/` run `writer_int_pos.py` to create `int_pos` which contains a set of points at which the gathered statistics are to be interpolated. `int_pos` will be created in `./pp_Nek/DATA/`. Before running the script, the parameters in `./pp_Python/inputs_phill_pp.in` should be set. The "Fluid Properties" and "Hill Geometry" parameters should be the same as what used in the flow simulation (i.e. in Step 1). Currently two sets of interpolation points are considered: 
  * (P-i) A set of streamwise locations `xpvrt` is considered at each `npvrt` points are created in the y-direction between the two walls. 
  * (P-ii)Adjacent to the lower wall and between the two hills,  `npwall` points are created in the streamwise direction.

* Copy `stsphill0.f*****` and `c2dphill0.f*****` files to `./pp_Nek/DATA/`.

* Run the Nek5000 to create `int_fld` in `../pp_Nek/DATA/`. In `../pp_Nek/` do these:
  * Set `lx1` and `lxd` in `SIZE` based on what is used in the flow simulation.
  * Set `lhis` in `SIZE` such that it is at least the same of as the total number of the interpolation points.
  * Set `viscosity` and `density` in `phill.par` as what is used in the simulation. Also, set the post-processing parameters under `[_PSTAT2D]`.
  * Compile the case by `./compile_script --all` and then run `nek5000`.
As a result, `int_fld` is generated which should then be moved to `/DATA/`.

## Details of Step 3
To extract the profiles of the turbulence statistics, the `Python` scripts in `./pp_Python/` are used:

  * The whole workflow is implemented in `main_pHill_PP.py`. Therefore, one can only run `python main_pHill_PP`. For different functions called in `main_pHill_PP.py`, see scripts in `/modules/`.
  * The only variable to set in `main_pHill_PP.py` is `data_path` which specifies where `int_fld` is located.
  * The input parameters and information about the interpolation points are read from `/pp/inputs_phill_pp.in`. 
  * The resulting database `dbProfs` and `dbWall` contain the turbulence statistics at the (P-i) and (P-ii) interpolation points, respectively, see above. For the complete set of quantities in these databases, print `dbProfs.keys()`.
  * A set of example plots are provided at the end of `main_pHill_PP.py`.
