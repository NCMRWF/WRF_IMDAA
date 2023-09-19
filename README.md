# WRF_IMDAA
# WRF preprocessing (WPS) tool using IMDAA initial conditions and lateral boundary forcing.

The purpose of this shell script is to run the WPS program with IMDAA data to produce metgrid output files in user-defined intervals. This generates separate intermediate files (by UNGRIB) for different parameters such as mean sea level pressure, skin temperature, 2-meter Relative humidity, 2-meter temperature, etc. Thereafter, GEOGRID is performed to put all static data into user-defined grid points, followed by METGRID, which will be performed by taking these different parameters together along with GEOGRID output. The script follows GRIB2 parameter identities for the NCMRWF Unified Model (NCUM) output conventions only. To comply with that, the user must download the Vtable.NCUM and METGRID.TBL_NCUM table from this repository and mention the paths in the user input section. After successful completion of this script, the user should conventionally proceed for REAL.EXE and WRF.EXE.

# This script performs 3 jobs:
1. Run geogrid.exe
2. Run ungrib.exe for all parameters separately
3. Run metgrid.exe

# PREREQUISITES
1. Installed WPS. The path needs to be given in "wps_path".
2. Installed wgrib2 for sorting the data.
3. Installed NETCDF4 for checking data.
4. Installed openmpi or mpich or intel C or Intel Fortran for parallel run. Otherwise, go for a serial run.
5. Download IMDAA data and keep all files (single-level data and pressure-level data) in one directory. Give this directory path in "imdaa_data_path" in the user input section. Do not keep single and pressure-level data separately in different directories.
6. Create a folder in your preferred location and keep this script. Nothing else needs to be kept in this directory.
7. Download Vtable.NCUM and METGRID.TBL_NCUM from this repository and keep them in a folder. Give this path in "ncum_Vtable_path" and "ncum_metgrid_tbl_path".
8. Give the directory path in the user input section where you have kept namelist.wps (preferably in a different location so that it stays unchanged).

# How to use:
1. chmod +x runscript_ncmrwf.sh
2. ./runscript_ncmrwf.sh or bash runscript_ncmrwf.sh
