# WRF_IMDAA
# WRF preprocessing (WPS) tool using IMDAA initial conditions and lateral boundary forcing.

The purpose of this shell script is to run the WPS program with IMDAA data to produce metgrid output files at user-defined intervals. This generates separate intermediate files (by UNGRIB) for different parameters such as mean sea level pressure, skin temperature, 2-meter Relative humidity, 2-meter temperature, etc. Following GEOGRID, which converts all static data into user-defined grid points, comes METGRID, which uses these various parameters (in intermediate data form by UNGRIB) along with the GEOGRID output. The script follows GRIB2 parameter identities for the NCMRWF Unified Model (NCUM) output conventions. After successful completion of this script, the user should conventionally proceed with REAL.EXE and WRF.EXE.

# This script performs three jobs:
1. Run geogrid.exe
2. Run ungrib.exe for all parameters separately
3. Run metgrid.exe

# PREREQUISITES
1. Installed WPS. The path needs to be given in "wps_path".
2. Installed wgrib2 for sorting the data.
3. Installed NETCDF4 for checking data.
4. Installed openmpi or mpich or Intel C or Intel Fortran for parallel runs. Otherwise, go for a serial run.
5. Download IMDAA data and keep all files (single-level data and pressure-level data) in one directory. Give this directory path as "imdaa_data_path" in the user input section. Do not keep single and pressure-level data separately in different directories.
6. Create a folder in your preferred location and keep this script there. Nothing else needs to be kept in this directory.
7. Give the directory path in the user input section where you have kept namelist.wps (preferably in a different location so that it stays unchanged).

# How to use:
1. chmod +x runscript_ncmrwf.sh
2. ./runscript_ncmrwf.sh or bash runscript_ncmrwf.sh
