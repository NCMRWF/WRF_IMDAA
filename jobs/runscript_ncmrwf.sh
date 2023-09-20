#!/bin/bash
#----------------------------------------------------------------------------------------------------------------
# The purpose of this script is to produce metgrid output files in user-defined intervals from IMDAA data. 	|
# This generates separate intermediate files (by UNGRIB) for different parameters such as mean sea level 	|
# pressure, 2-meter  Relative humidity, 2-meter temperature, etc. Thereafter METGRID will be performed by taking|
# these different parameters together. The script follows GRIB parameter identities for the NCMRWF Unified Model|
# (NCUM) output conventions only. After successful completion of this script, the user should proceed for 	|
# REAL.EXE and WRF.EXE in the conventional way.									|
#														|
# This script performs 3 jobs only:										|
#														|
# 1. Run geogrid.exe												|
# 2. Run ungrib.exe for all parameters separately								|
# 3. Run metgrid.exe 												|
#														|
#-------------------------------------------	CONTACTS	------------------------------------------------|
#														|
# Team: V. Hazra, Gibies George, Syam Sankar, S. Indira Rani, Mohan S. Thota, John P. George, Sumit Kumar, 	|
#	Laxmikant Dhage												|
# National Centre for Medium-Range Weather Forecasting, ESSO, Ministry of Earth Sciences, Govt. of India	|
# Contact if any issue arises while running this script: vhazra@ncmrwf.gov.in					|
# Copyright @ NCMRWF, MoES, 2023										|
#														|
#-------------------------------------------	PREREQUISITES	------------------------------------------------|
# PREREQUISITES:												|
# (1) Installed WPS. The path needs to be given in wps_path.							|
# (2) Installed wgrib2 for sorting the data.									|
# (3) Installed NETCDF4 for checking data.									|
# (4) Installed openmpi or mpich for parallel run. Otherwise, go for a serial run.				|
# (5) Download the IMDAA data. Keep it as it is and mention the path in imdaa_data_path.			|
#														|
# The essential variables to run WRF are: 									|
#						U component wind in pressure level (IMDAA DATA NAME: UGRD-prl)	|
#						V component wind in pressure level (IMDAA DATA NAME: VGRD-prl)	|
#						Temperature in pressure level (IMDAA DATA NAME: TMP-prl)	|
#						Surface temperature (IMDAA DATA NAME: TMP-sfc)			|
#						Geopotential height in pressure level (IMDAA DATA NAME: HGT-prl)|
#						Relative humidity in pressure level (IMDAA DATA NAME: RH-prl)	|
#						2-meter Relative humidity (IMDAA DATA NAME: RH-2m)		|
#						Land mask file (IMDAA DATA NAME: LAND-sfc)			|
#						Surface pressure (IMDAA DATA NAME: PRES-sfc)			|
#						Mean sea level pressure (IMDAA DATA NAME: PRMSL-msl)		|
#						Soil temperature level 1 (IMDAA DATA NAME: TSOIL-L1)		|
#						Soil temperature level 2 (IMDAA DATA NAME: TSOIL-L2)		|
#						Soil temperature level 3 (IMDAA DATA NAME: TSOIL-L3)		|
#						Soil temperature level 4 (IMDAA DATA NAME: TSOIL-L4)		|
#						10-meter U wind (IMDAA DATA NAME: UGRD-10m) 			|
#						10-meter V wind (IMDAA DATA NAME: VGRD-10m)			|
#						Soil moisture level 1 (IMDAA DATA NAME: VSOILM-L1 or CISOILM-L1)|
#						Soil moisture level 2 (IMDAA DATA NAME: VSOILM-L2 or CISOILM-L2)|
#						Soil moisture level 3 (IMDAA DATA NAME: VSOILM-L3 or CISOILM-L3)|
#						Soil moisture level 4 (IMDAA DATA NAME: VSOILM-L4 or CISOILM-L4)|
#						Water equivalent accumulated snow depth				| 
#									(IMDAA DATA NAME: WEASD-sfc)		|
#														|
#------------------------------------------- USEAGE ------------------------------------------------------------|
# USAGE:													|
#														|
# (1) Create a folder in your preferred location and keep this script. Nothing else needs to be kept in this 	|
#     directory.													|
# (2) Give the path (in the user input section) where you have kept namelist.wps (preferably in a different 	|
#     location).												|
# (3) Download IMDAA data and keep all (single level and pressure level) in one directory. Then give this	| 
#     directory path in	"imdaa_data_path" in the user input section.						|
# (4) Provide all essential paths as required									|
# (5) Provide the number of processors if opting for parallel run 						|
# (6) chmod +x runscript_ncmrwf.sh 										|
# (7) ./runscript_ncmrwf.sh											|
# (8) Then go for real.exe and wrf.exe										|
#														|
#------------------------------------------ USEFUL INFORMATIONS ------------------------------------------------|
#														|
# Set relevant paths and data information under the "USER INPUT BEGIN HERE" section				|
# This script assumes you have installed wgrib2, netcdf4, openmpi or mpich (if parallel), and the WPS program 	|
# prior to running this script.											|
#														|
# Author : Vivekananda Hazra (vhazra@ncmrwf.gov.in)								|
# Version : 18-Sep-2023												|
#----------------------------------------------------------------------------------------------------------------


#----------------------------------------------------------------------------------------------------------------------------------------
# 											    						|
#                                                          USER INPUT BEGIN HERE                                       			|
# 																	|
#			(1) Fill in YEAR, MONTH, DATE, HOURS, and INTERVAL below as per the Namelist options.				|
#			(2) Provide only relevant paths in the path options.								|
#			(3) Provide the number of processors if opting for parallel.							|
#			(4) Do not change parameter names unless directed by this script.						|
# 																	|
#----------------------------------------------------------------------------------------------------------------------------------------

syyyy=2020 	# start year in four-digit: yyyy
eyyyy=2020 	# end year in four-digit: yyyy

smm=01 		# start month in two-digit: mm 
emm=01 		# end month in two-digit: mm 

start_date=01 	# start date in two-digit: dd
start_hour=00 	# start hour in two-digit: HH

end_date=01 	# end date in two-digit: dd
end_hour=18 	# end hour in two-digit: HH

intervals=6 	# in hours

setenvscript="/home/gibies/Build_WRF/set_env.sh"
RUNDIR="/home/gibies/Build_WRF/test_run/run_${syyyy}${smm}${start_date}_${start_hour}"
imdaa_data_path=/home/${USER}/Build_WRF/test_run/imdaa/20200101	# here kept all downloaded IMDAA data
wps_path=/home/${USER}/Build_WRF/WPS-4.5
wps_geog_path=/home/gibies/Build_WRF/WPS_GEOG
#ncum_Vtable_path=/home/gibies/Build_WRF/test_run/run
#ncum_metgrid_tbl_path=/home/gibies/Build_WRF/test_run/run
wps_namelist_path=/home/gibies/Build_WRF/test_run/run/namelist.wps	# Original namelist.wps kept in this folder so that it stays untouched
nproc=1 # number of processors if opt for parallel run

# IMDAA parameter names. Do not change unless you are getting any instruction after an unsuccessful Metgrid run
export parameters=(UGRD-prl VGRD-prl TMP-prl TMP-sfc HGT-prl RH-prl RH-2m LAND-sfc PRES-sfc PRMSL-msl RH-2m TSOIL-L1 TSOIL-L2 TSOIL-L3 TSOIL-L4 UGRD-10m VGRD-10m CISOILM-L1 CISOILM-L2 CISOILM-L3 CISOILM-L4 WEASD-sfc)

#----------------------------------------------------------------------------------------------------------------------------------------
#																	|
#                         END USER INPUT. ******  DO NOT CHANGE BELOW ******								|
# 																	|
#----------------------------------------------------------------------------------------------------------------------------------------


#----------------------------------------------------------------------------------------------------------------------------------------
set -x
ulimit -s unlimited
if [ ! -d ${RUNDIR} ]; then mkdir -p ${RUNDIR}; fi
cd ${RUNDIR}
currdir=`pwd`

source ${setenvscript}

BLUE='\033[0;34m'
WHITE='\033[0;37m'
RED='\033[0;31m'
BRed='\033[1;31m'
BGreen='\033[1;32m'

cat > METGRID.TBL << EOF
========================================
name=ST
	z_dim_name=num_st_layers
        derived=yes
# IF
        fill_lev =  10 : ST000010(200100)
        fill_lev =  40 : ST010040(200100)
        fill_lev = 100 : ST040100(200100)
        fill_lev = 200 : ST100200(200100)
# ELSE IF
        fill_lev =  10 : ST000010(200100)
        fill_lev =  35 : ST010035(200100)
        fill_lev = 100 : ST035100(200100)
        fill_lev = 300 : ST100300(200100)
# ELSE IF
        fill_lev =  10 : ST000010(200100)
        fill_lev = 200 : ST010200(200100)
# ELSE
        fill_lev =   7 : ST000007(200100)
        fill_lev =  28 : ST007028(200100)
        fill_lev = 100 : ST028100(200100)
        fill_lev = 255 : ST100255(200100)
========================================
name=SM
        z_dim_name=num_sm_layers
        derived=yes
# IF
        fill_lev =  10 : SM000010(200100)
        fill_lev =  40 : SM010040(200100)
        fill_lev = 100 : SM040100(200100)
        fill_lev = 200 : SM100200(200100)
# ELSE IF
        fill_lev =  10 : SM000010(200100)
        fill_lev =  35 : SM010035(200100)
        fill_lev = 100 : SM035100(200100)
        fill_lev = 300 : SM100300(200100)
# ELSE IF
        fill_lev =  10: SM000010(200100)
        fill_lev = 200 : SM010200(200100)
# ELSE
        fill_lev =   7 : SM000007(200100)
        fill_lev =  28 : SM007028(200100)
        fill_lev = 100 : SM028100(200100)
        fill_lev = 255 : SM100255(200100)
========================================
name=SW
        z_dim_name=num_sw_layers
        derived=yes
# IF
        fill_lev = 1 : SW000010(200100)
        fill_lev = 2 : SW010040(200100)
        fill_lev = 3 : SW040100(200100)
        fill_lev = 4 : SW100200(200100)
# ELSE IF
        fill_lev = 1 : SW000010(200100)
        fill_lev = 2 : SW010200(200100)
========================================
name=SOIL_LAYERS
        derived=yes
        z_dim_name=num_st_layers
        flag_in_output=FLAG_SOIL_LAYERS
        fill_lev=all:vertical_index; level_template=ST
========================================
name=SOILM
        z_dim_name=num_soilm_levels
        derived=yes
        fill_lev =   0 : SOILM000(200100)      
        fill_lev =   5 : SOILM005(200100)      
        fill_lev =  20 : SOILM020(200100)      
        fill_lev =  40 : SOILM040(200100)      
        fill_lev = 160 : SOILM160(200100)      
        fill_lev = 300 : SOILM300(200100)      
========================================
name=SOILT
        z_dim_name=num_soilt_levels
        derived=yes
        fill_lev =   0 : SOILT000(200100)      
        fill_lev =   5 : SOILT005(200100)      
        fill_lev =  20 : SOILT020(200100)      
        fill_lev =  40 : SOILT040(200100)      
        fill_lev = 160 : SOILT160(200100)      
        fill_lev = 300 : SOILT300(200100)      
        fill_lev =  49 : SOILT050(200100)
        fill_lev =  51 : SOILT050(200100)
========================================
name=SOIL_LEVELS
        derived=yes
        z_dim_name=num_soilt_levels
        flag_in_output=FLAG_SOIL_LEVELS
        fill_lev=all:vertical_index; level_template=SOILT
========================================
name=PRES
        z_dim_name=num_metgrid_levels
        derived=yes
        mandatory=yes    # MUST HAVE THIS FIELD
        fill_lev=all:PRESSURE
        fill_lev=200100:PSFC(200100)
        fill_lev=all:vertical_index; level_template=TT
========================================
name=LANDSEA 
        interp_option=nearest_neighbor
        fill_missing=-1.
        fill_lev=200100:LANDMASK(1)
========================================
name=XICE ; output_name=SEAICE  # If we get XICE, use entry from SEAICE and
                                #   write the field out as SEAICE
========================================
name=SEAICE 
        interp_option=four_pt+average_4pt
        interp_mask=LANDSEA(1) 
        masked=land
        missing_value=-1.E30
        fill_missing=0.
========================================
name=SNOW
        interp_option=four_pt+average_4pt
        masked=water 
        fill_missing=0.
        flag_in_output=FLAG_SNOW
========================================
name=SKINTEMP
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=both
        interp_land_mask  = LANDSEA(1)
        interp_water_mask = LANDSEA(0)
        fill_missing=0.
========================================
name=PSFC
        interp_option=four_pt+average_4pt
        fill_lev=200100:const(200100.)
        flag_in_output=FLAG_PSFC
========================================
name=VEGCAT
        interp_option=nearest_neighbor
        fill_missing=0.
        flag_in_output=FLAG_VEGCAT
========================================
name=CANWAT
        interp_option=four_pt
        fill_missing=0.
========================================
name=SOILCAT
        interp_option=nearest_neighbor
        fill_missing=0.
        flag_in_output=FLAG_SOILCAT
========================================
name=SW000010
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SW000010
========================================
name=SW010040
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SW010040
========================================
name=SW040100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SW040100
========================================
name=SW100200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SW100200
========================================
name=SW010200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SW010200
========================================
name=SM000010
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM000010
========================================
name=SM010035
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM010035
========================================
name=SM010040
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM010040
========================================
name=SM035100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM035100
========================================
name=SM040100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM040100
========================================
name=SM100200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM100200
========================================
name=SM100300
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM100300
========================================
name=SM010200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM010200
========================================
name=ST000010
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST000010
========================================
name=ST010035
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST010035
========================================
name=ST010040
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST010040
========================================
name=ST035100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST035100
========================================
name=ST040100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST040100
========================================
name=ST100200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST100200
========================================
name=ST100300
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST100300
========================================
name=ST010200
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST010200
========================================
name=SM000007
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SM000007
========================================
name=SM007028
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SM007028
========================================
name=SM028100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SM028100
========================================
name=SM100255
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=1.
        flag_in_output=FLAG_SM100255
========================================
name=ST000007
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_ST000007
========================================
name=ST007028
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_ST007028
========================================
name=ST028100
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_ST028100
========================================
name=ST100255
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        missing_value=-1.E30
        fill_missing=285.
        flag_in_output=FLAG_ST100255
========================================
name=SOILM000
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM000
========================================
name=SOILM005
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM005
========================================
name=SOILM020
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM020
========================================
name=SOILM040
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM040
========================================
name=SOILM160
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM160
========================================
name=SOILM300
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=1.
        flag_in_output=FLAG_SOILM300
========================================
name=SOILT000
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT000
========================================
name=SOILT005
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT005
========================================
name=SOILT020
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT020
========================================
name=SOILT040
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT040
========================================
name=SOILT160
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT160
========================================
name=SOILT300
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT300
========================================
name=SOILT050
        interp_option=sixteen_pt+four_pt+wt_average_4pt+wt_average_16pt+search
        masked=water
        interp_mask=LANDSEA(0)
        fill_missing=285.
        flag_in_output=FLAG_SOILT050
========================================
name=PMSL
        interp_option=sixteen_pt+four_pt+average_4pt
        flag_in_output=FLAG_SLP
========================================
name=RH
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(-1.E30)
========================================
name=SPECHUMD
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        missing_value=-1.E30
        fill_lev=200100:const(-1)
        flag_in_output=FLAG_SH
========================================
name=SPECCLDL
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        missing_value=-1.E30
        fill_lev=200100:const(-1)
        flag_in_output=FLAG_SPECCLDL
========================================
name=SPECCLDF
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        missing_value=-1.E30
        fill_lev=200100:const(-1)
        flag_in_output=FLAG_SPECCLDF
========================================
name=TAVGSFC
        interp_option=four_pt
        fill_missing=0.
        fill_lev=200100:TT(200100)
        flag_in_output=FLAG_TAVGSFC
========================================
name=T ; output_name=TT  # If we get T, use entry from TT and
                         #   write the field out as TT
========================================
name=TT
        mandatory=yes    # MUST HAVE THIS FIELD
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(-1.E30)
========================================
name=U ; output_name=UU  # If we get U, use entry from UU and
                         #   write the field out as UU
========================================
name=UU
        mandatory=yes    # MUST HAVE THIS FIELD
        interp_option=sixteen_pt+four_pt+average_4pt
        is_u_field=yes
        output_stagger=U
        fill_missing=0.
        fill_lev=200100:const(-1.E30)
========================================
name=V ; output_name=VV  # If we get V, use entry from VV and
                         #   write the field out as VV
========================================
name=VV
        mandatory=yes    # MUST HAVE THIS FIELD
        interp_option=sixteen_pt+four_pt+average_4pt
        is_v_field=yes
        output_stagger=V
        fill_missing=0.
        fill_lev=200100:const(-1.E30)
========================================
name=SST
        interp_option=sixteen_pt+four_pt
        fill_missing=0.
        missing_value=-1.E30
        flag_in_output=FLAG_SST
========================================
name=QV
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QV
========================================
name=QR
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QR
========================================
name=QC
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QC
========================================
name=QI
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QI
========================================
name=QS
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QS
========================================
name=QG
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QG
========================================
name=QNI
        interp_option=four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
        flag_in_output=FLAG_QNI
========================================
name=VPTMP
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:const(0.)
========================================
name=PRESSURE
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:PSFC(200100)
========================================
name=PRHO     
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:PSFC(200100)
        flag_in_output=FLAG_PRHO
========================================
name=GHT
        interp_option=sixteen_pt+four_pt+average_4pt
        fill_missing=0.
        fill_lev=200100:SOILHGT(200100)
        fill_lev=200100:HGT_M(1)
========================================
name=HGTT
        output=no
        interp_option=nearest_neighbor
========================================
name=SNOWH
        interp_option=four_pt+average_4pt
        masked=water 
        fill_missing=0.
        flag_in_output=FLAG_SNOWH
========================================
name=SOILHGT
        interp_option=four_pt+average_4pt
        flag_in_output=FLAG_SOILHGT
========================================
name=H0ML 
        interp_option=four_pt+average_4pt
        interp_mask=LANDSEA(1) 
        masked=land
        fill_missing=0.
========================================
name=TMOML
        interp_option=nearest_neighbor
#       interp_option=sixteen_pt+four_pt+wt_average_4pt+search
        masked=land
        interp_mask=landmask(1)
        missing_value=200.
        fill_missing=-20.
========================================
name=T0 
        interp_option=four_pt+average_4pt+search
        masked=land
        interp_mask=landmask(1)
        missing_value=200.
        fill_missing=-20.
========================================
name=QNWFA_JAN
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_FEB
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_MAR
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_APR
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_MAY
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_JUN
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_JUL
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_AUG
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_SEP
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_OCT
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_NOV
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNWFA_DEC
	z_dim_name=num_qnwfa_levels
        interp_option=four_pt+average_4pt
        flag_in_output=FLAG_QNWFA
========================================
name=QNIFA_JAN
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_FEB
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_MAR
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_APR
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_MAY
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_JUN
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_JUL
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_AUG
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_SEP
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_OCT
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_NOV
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
========================================
name=QNIFA_DEC
	z_dim_name=num_qnifa_levels
        interp_option=four_pt+average_4pt
        flag_in_output=FLAG_QNIFA
========================================
name=UTROP
        interp_option=four_pt
        is_u_field=yes
        output_stagger=U
        flag_in_output=FLAG_UTROP
========================================
name=VTROP
        interp_option=four_pt
        is_v_field=yes
        output_stagger=V
        flag_in_output=FLAG_VTROP
========================================
name=TTROP
        interp_option=four_pt
        flag_in_output=FLAG_TTROP
========================================
name=PTROP
        interp_option=four_pt
        flag_in_output=FLAG_PTROP
========================================
name=PTROPNN
        interp_option=nearest_neighbor
        flag_in_output=FLAG_PTROPNN
========================================
name=HGTTROP
        interp_option=four_pt
        flag_in_output=FLAG_HGTTROP
========================================
name=UMAXW
        interp_option=four_pt
        is_u_field=yes
        output_stagger=U
        flag_in_output=FLAG_UMAXW
========================================
name=VMAXW
        interp_option=four_pt
        is_v_field=yes
        output_stagger=V
        flag_in_output=FLAG_VMAXW
========================================
name=TMAXW
        interp_option=four_pt
        flag_in_output=FLAG_TMAXW
========================================
name=PMAXW
        interp_option=four_pt
        flag_in_output=FLAG_PMAXW
========================================
name=PMAXWNN
        interp_option=nearest_neighbor
        flag_in_output=FLAG_PMAXWNN
========================================
name=HGTMAXW
        interp_option=four_pt
        flag_in_output=FLAG_HGTMAXW
========================================
EOF

cat > Vtable << EOF
GRIB1| Level| From |  To  | metgrid  | metgrid | metgrid                                 |GRIB2|GRIB2|GRIB2|GRIB2|
Param| Type |Level1|Level2| Name     | Units   | Description                             |Discp|Catgy|Param|Level|
-----+------+------+------+----------+---------+-----------------------------------------+-----------------------+
  11 | 100  |   *  |      | TT       | K       | Temperature                             |  0  |  0  |  0  | 100 |
  33 | 100  |   *  |      | UU       | m s-1   | U                                       |  0  |  2  |  2  | 100 |
  34 | 100  |   *  |      | VV       | m s-1   | V                                       |  0  |  2  |  3  | 100 |
  52 | 100  |   *  |      | RH       | %       | Relative Humidity                       |  0  |  1  |  1  | 100 |
   7 | 100  |   *  |      | HGT      | m       | Height                                  |  0  |  3  |  5  | 100 |
  11 | 105  |   1  |      | TT       | K       | Temperature       at 2 m                |  0  |  0  |  0  | 103 |
  52 | 105  |   1  |      | RH       | %       | Relative Humidity at 2 m                |  0  |  1  |  1  | 103 |
  33 | 105  |  10  |      | UU       | m s-1   | U                 at 10 m               |  0  |  2  |  2  | 103 |
  34 | 105  |  10  |      | VV       | m s-1   | V                 at 10 m               |  0  |  2  |  3  | 103 |
   1 |   1  |   0  |      | PSFC     | Pa      | Surface Pressure                        |  0  |  3  |  0  |   1 |
   2 |   1  |   0  |      | PMSL     | Pa      | Sea-level Pressure                      |  0  |  3  |  1  | 101 |
 144 | 112  |   0  | 10   | SM000010 | m3 m-3  | Soil Moist 0-10 cm below grn layer (Up) |  2  |  0  | 25  | 106 |
 144 | 112  |  10  | 35   | SM010035 | m3 m-3  | Soil Moist 10-35 cm below grn layer     |  2  |  0  | 25  | 106 |
 144 | 112  |  35  | 100  | SM035100 | m3 m-3  | Soil Moist 35-100 cm below grn layer    |  2  |  0  | 25  | 106 |
 144 | 112  | 100  | 300  | SM100300 | m3 m-3  | Soil Moist 100-300 cm below gr layer    |  2  |  0  | 25  | 106 |
  11 | 112  |   0  |  10  | ST000010 | K       | T 0-10 cm below ground layer (Upper)    |  2  |  0  |  2  | 106 |
  11 | 112  |  10  |  35  | ST010035 | K       | T 10-35 cm below ground layer (Upper)   |  2  |  0  |  2  | 106 |
  11 | 112  |  35  | 100  | ST035100 | K       | T 35-100 cm below ground layer (Upper)  |  2  |  0  |  2  | 106 |
  11 | 112  | 100  | 300  | ST100300 | K       | T 100-300 cm below ground layer (Bottom)|  2  |  0  |  2  | 106 |
  91 |   1  |   0  |      | SEAICE   | proprtn | Ice flag                                | 10  |  2  |  0  |   1 |
  81 |   1  |   0  |      | LANDSEA  | proprtn | Land/Sea flag (1=land, 0 or 2=sea)      |  2  |  0  |  0  |   1 |
   7 |   1  |   0  |      | SOILHGT  | m       | Terrain field of source analysis        |  2  |  0  |  7  |   1 |
  11 |   1  |   0  |      | SKINTEMP | K       | Skin/Surface temperature                |  0  |  0  |  0  |   1 |
  65 |   1  |   0  |      | WEASDsfc | kg m-2  | Water equivalent snow depth             |  0  |  1  | 13  |   1 |
     |   1  |   0  |      | SNOWH    | m       | Physical Snow Depth                     |  0  |  1  |     |   1 |
-----+------+------+------+----------+---------+-----------------------------------------+-----------------------+
EOF

echo -e "Selecting serial or parallel run.

	For parallel run type: ${BGreen}yes${WHITE}
	For serial run type: ${BGreen}no${WHITE}
	\n"
read -p "Do you want to go for a parallel run? (yes/no) " choice
choice="${choice,,}"
mpich_check=$(mpirun --version 2>&1)
openmpi_check=$(mpirun --version 2>&1)
#-----------------  pre-requisite library checking ------------------------------------------------------------------
# checking for mpi
if [ "$choice" = "yes" ]; then
	echo -e "\n

        You have opted for a ${BGreen}parallel${WHITE} run ...

        The selected number of processors: $nproc

        \n"
	sleep 2
	if [[ $mpich_check == *"MPICH"* ]]; then
		echo -e "\n
	${BGreen}MPICH is installed.${WHITE} Proceeding ...
		\n"
		sleep 1
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
        	export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
        	export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif [[ $openmpi_check == *"Open MPI"* ]]; then
    		echo -e "\n
	${BGreen}OpenMPI is installed.${WHITE} Proceeding ...
		\n"
		sleep 1
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
        	export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
        	export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif command -v mpiifort &>/dev/null; then
		echo -e "\n
        ${BGreen}Intel C compiler is installed.${WHITE} Proceeding ...
		\n"
		sleep 1
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
                export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
                export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	elif command -v mpiicc &>/dev/null; then
		echo -e "\n
        ${BGreen}Intel Fortran compiler is installed.${WHITE} Proceeding ...
		\n"
		sleep 1
		export RUN_COMMAND1="mpirun -np 1 ./ungrib.exe "
                export RUN_COMMAND2="mpirun -np $nproc ./metgrid.exe "
                export RUN_COMMAND3="mpirun -np $nproc ./geogrid.exe "
	else
    		echo -e "\n
		\n
		\n
		\n
		\n
		\n
		${BRed}
					FATAL ERROR ${WHITE}
	
		Neither MPICH nor Openmpi nor Intel C compiler wrapper nor Intel 
		Fortran compiler wrapper is installed on this machine.

		${BGreen}Solution${WHITE}:

                	1. Please install either of them before opting for a parallel run.

		Preferred website:
                
		${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php${WHITE}
	       	
		Else go for ${BGreen}serial${WHITE} run.
		\n"
		exit
	fi
elif [ "$choice" = "no" ]; then
	echo -e "\n
	
	You have opted for a ${BGreen}serial${WHITE} run ...
	
	\n"
	sleep 1
	export RUN_COMMAND1="./ungrib.exe "
	export RUN_COMMAND2="./metgrid.exe "
	export RUN_COMMAND3="./geogrid.exe "
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    \n 
    ${BRed}
    Invalid choice. 
    
    ${WHITE}Please enter '${BRed}yes${WHITE}' for parallel run or '${BRed}no${WHITE}' for serial run.
    
    ${BRed}Exiting ...${WHITE}
    \n"
    exit 1
fi
# checking for wgrib2
if command -v wgrib2 &>/dev/null; then
    echo -e "\n
    	${BGreen}WGRIB2 is installed.${WHITE} Proceeding ...
	\n"
	sleep 1
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    ${BRed}wgrib2 is not installed.${WHITE} 
    
    ${BGreen}Solution${WHITE}:

    	1. Please install wgrib2 before proceeding.

    Preferred website:
    ${BLUE}https://www.cpc.ncep.noaa.gov/products/wesley/wgrib2/compile_questions.html#:~:text=1)%20Download%20ftp%3A%2F%2Fftp,1.2%20..
    \n"
    exit 1
fi

# checking for netcdf4
if command -v ncdump &>/dev/null; then
    echo -e "\n
        ${BGreen}NETCDF4 is installed.${WHITE} Proceeding ...
	\n"
	sleep 1
else
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    ${BRed}NETCDF4 is not installed.${WHITE}
    
    ${BGreen}Solution${WHITE}:

    	1. Please install NETCDF4 before proceeding.

    Preferred website:
    ${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php
    \n"
    exit 1
fi

# checking for the existence of Namelist
FILE=$wps_namelist_path
if [ ! -f $FILE ]
then
    echo -e "\n ${BRed}namelist.wps does not exist.${WHITE} \n"

    echo  -e "\n
    \n 
    \n 
    \n 
    \n 
    
    namelist.wps does not exist in the specified folder. 
    
    ${BGreen}Solution${WHITE}:

    Please provide correct path of the namelist.wps as described by the sample script. Then re-run the script.
    ----------------------------------------------------------------------------------------------------------
    \n"
    exit 1
else
	cp -rf $FILE namelist.wps.original
	cp -rf $FILE namelist.wps
fi

# checking for the existence of static data
staticdata=$wps_geog_path
if [ -d "$staticdata" ]; then
  if [ "$(ls -A "$staticdata")" ]; then
	echo -e "\n
	WPS_GEOG static data folder ${BGreen}exists${WHITE} and ${BGreen}not empty${WHITE}.
	
	Proceeding ...
	\n"
	sleep 1
  else
	echo -e "\n
    	\n 
    	\n 
    	\n 
    	\n 
	${BRed}WPS_GEOG directory exists but is empty. 
	${WHITE}

	${BGreen}Solution${WHITE}:
	
	Please check the containts of the WPS_GEOG folder and make sure it has all the static data.
	then re-run the script.

	Exiting ...
	\n"
    	exit 1
  fi
else
	echo -e "
	The WPS_GEOG folder does not exist. ${BRed}Exiting ...${WHITE} 
	\n"
	echo  -e "\n 
	\n
	\n
	\n
	\n
	${BRed}WPS_GEOG folder does not exist in the specified path:${WHITE} $wps_geog_path
	
	${BGreen}Solution${WHITE}:
	
	Please correctly fill the WPS_GEOG folder path as mentioned. Then re-run the script.
	-------------------------------------------------------------------------------------
	\n"
  	exit 1
fi

# Checking for the existence of the WPS program
wpsprogram=$wps_path
if [ ! -d $wpsprogram ]
then
    echo -e "\n
    \n 
    \n 
    \n 
    \n 
    The WPS program directory does not exist. ${BRed}Exiting ...${WHITE}
    \n"
    echo  -e "\n 
    \n 
    ${BRed}WPS program does not exist in the specified path:${WHITE} $wps_path
    Please fill all necessary fields correctly as mentioned. Then re-run the script.
    --------------------------------------------------------------------------------- 
    \n"
    exit 1
else
	wpsexe1=$wps_path/geogrid.exe
	wpsexe2=$wps_path/ungrib.exe
	wpsexe3=$wps_path/metgrid.exe
	if [ -x "$wpsexe1" ] && [ -x "$wpsexe2" ] && [ -x "$wpsexe3" ]; then
  		echo -e "\n
		${BGreen}geogrid.exe${WHITE}, ${BGreen}ungrib.exe${WHITE}, and ${BGreen}metgrid.exe${WHITE} exist and are executable. 
		
		Proceeding ...
		\n"
		sleep 1
	else
    		echo -e "\n WPS folder exists. But one or more of the required files are missing or not executable"
	    	echo  -e "\n ${BRed}
    		\n 
    		\n 
    		\n 
    		\n 
    		\n 
		Executables do not exist in the specified path:${WHITE} $wps_path
		
		${BGreen}Solution${WHITE}:
        	
		Please install the WPS suite properly so that all executables are build (geogrid.exe, ungrib.exe, and metgrid.exe).
		Then re-run the script.
		
		Preferred website:
		${BLUE}https://www2.mmm.ucar.edu/wrf/OnLineTutorial/compilation_tutorial.php${WHITE}
	       	--------------------------------------------------------------------------------------------------------------------- 
		
		${BRed}Exiting ...${WHITE}
		\n"
		exit 1
	fi
fi
# checking for Namelist inputs and script inputs
checkmatchstart=`awk '/'"start_date"'/ { print }' "namelist.wps"`
checkmatchend=`awk '/'"end_date"'/ { print }' "namelist.wps"`
checkinterval=`awk '/'"interval_seconds"'/ { print }' "namelist.wps"`
Linterval=`cut -d "=" -f2 <<< $checkinterval|grep -o " .*"|cut -c2-6`
sLyyyy=`cut -d "=" -f2 <<< $checkmatchstart|grep -o " '.*"|cut -c3-6`
sLmm=`cut -d "=" -f2 <<< $checkmatchstart|grep -o " '.*"|cut -c8-9`
sLdd=`cut -d "=" -f2 <<< $checkmatchstart|grep -o " '.*"|cut -c11-12`
sLHH=`cut -d "=" -f2 <<< $checkmatchstart|grep -o " '.*"|cut -c14-15`
eLyyyy=`cut -d "=" -f2 <<< $checkmatchend|grep -o " '.*"|cut -c3-6`
eLmm=`cut -d "=" -f2 <<< $checkmatchend|grep -o " '.*"|cut -c8-9`
eLdd=`cut -d "=" -f2 <<< $checkmatchend|grep -o " '.*"|cut -c11-12`
eLHH=`cut -d "=" -f2 <<< $checkmatchend|grep -o " '.*"|cut -c14-15`

if [ "$sLyyyy" -eq $syyyy ]; then
  echo -e "\n 
  ${BGreen}Simulation start year is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n ${BRed}
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between the entered year and the namelist.wps start year. Please correct it and re-run the script.${WHITE}

  Namelist start year: $sLyyyy
  Script start year: $syyyy
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$sLmm" -eq $smm ]; then
  echo -e "\n ${BGreen}Simulation start month is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered month and namelist.wps start month. Please correct it and re-run the script.${WHITE}

  Namelist start month: $sLmm
  Script start month: $smm

  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$sLdd" -eq $start_date ]; then
  echo -e "\n ${BGreen}Simulation start date is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered start date and namelist.wps start date. Please correct it and re-run the script.${WHITE}

  Namelist start date: $sLdd
  Script start date: $start_date
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$sLHH" -eq $start_hour ]; then
  echo -e "\n ${BGreen}Simulation start hour is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered start hour and namelist.wps start hour. Please correct it and re-run the script.${WHITE}

  Namelist start hour: $sLHH
  Script start hour: $start_hour

  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$eLyyyy" -eq $eyyyy ]; then
  echo -e "\n ${BGreen}Simulation end year is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered end year and namelist.wps end year. Please correct it and re-run the script.${WHITE}

  Namelist end year: $eLyyyy
  Script end year: $eyyyy
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$eLmm" -eq $emm ]; then
  echo -e "\n ${BGreen}Simulation end month is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Misimatch between entered end month and namelist.wps end month. Please correct it and re-run the script.${WHITE}

  Namelist end month: $eLmm
  Script end month: $emm
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$eLdd" -eq $end_date ]; then
  echo -e "\n ${BGreen}Simulation end date is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered end date and namelist.wps end date. Please correct it and re-run the script.${WHITE}

  Namelist end date: $eLdd
  Script end date: $end_date
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$eLHH" -eq $end_hour ]; then
  echo -e "\n ${BGreen}Simulation end hour is similar. ${WHITE}

  Proceeding ... \n"
sleep 1
else
  echo -e "\n 
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered end hour and namelist.wps end hour. Please correct it and re-run the script.${WHITE}

  Namelist end hour: $sLHH
  Script end hour: $end_hour
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

if [ "$(($Linterval/3600))" -eq $intervals ]; then
  echo -e "\n ${BGreen}Data interval is similar. ${WHITE}

  Proceeding ... 
  \n"
sleep 1
else
  echo -e "\n
  \n 
  \n 
  \n 
  \n 
  ${BRed}Mismatch between entered interval and namelist.wps interval. Please correct it and re-run the script${WHITE}

  	Script interval: "$((intervals*3600))"
  	Namelist interval: $Linterval
  
  ${BRed}Exiting ...${WHITE} \n"
  exit 1
fi

sed -i 's/fg_name.*/fg_name =/g' namelist.wps
ln -sf ${wps_path}/*.exe .
ln -sf ${wps_path}/geogrid/GEOGRID.TBL.ARW GEOGRID.TBL 
rm -rf $currdir/rundata
mkdir $currdir/rundata
#-------------------------------- sorting imdaa data ---------------------------------------------------
for ((iyy=${syyyy#0} ; iyy <= ${eyyyy#0} ; iyy=iyy+1))  
do
	for ((imm=${smm#0} ; imm <= ${emm#0} ; imm=imm+1))
	do
		for ((ig=${start_date#0} ; ig <= ${end_date#0} ; ig=ig+1))  
		do
			echo $ig
			for param in ${parameters[@]}
			do
				subset="${param}"
				echo -e "\n
					Extracting ${BGreen}$subset${WHITE} from IMDAA ...
					\n"
					sleep 1
		        	found_file=$(find "$imdaa_data_path" -type f -name "*_${subset}_*")
				if [ -e "$found_file" ]; then
					for hour in $(eval echo "{$start_hour..$end_hour..$intervals}")
	        			do 
						if [[ ( "$imm" -lt 10 && "$ig" -lt 10 ) ]]
						then
							date=${iyy}0${imm}0${ig}
					       	        rundate=${date}${hour}
        			        		echo "$date of $hour"
					                echo $rundate
			        		        wgrib2 ${imdaa_data_path}/*_${param}_* -match_fs "=${rundate}" -match_fs "anl" -grib_out $currdir/rundata/${param}_${date}_${hour}.grib2
						elif [[ ( "$imm" -lt 10 && "$ig" -ge 10 ) ]]
						then
                			       		date=${iyy}0${imm}${ig}
				                        rundate=${date}${hour}
                				        echo "$date of $hour"
		                	        	echo $rundate
					                wgrib2 ${imdaa_data_path}/*_${param}_* -match_fs "=${rundate}" -match_fs "anl" -grib_out $currdir/rundata/${param}_${date}_${hour}.grib2
						elif [[ ( "$imm" -ge 10 && "$ig" -lt 10 ) ]]
						then
		        		      		date=${iyy}${imm}0${ig}
	        		               		rundate=${date}${hour}
			        	                echo "$date of $hour"
		                		        echo $rundate
                				        wgrib2 ${imdaa_data_path}/*_${param}_* -match_fs "=${rundate}" -match_fs "anl" -grib_out $currdir/rundata/${param}_${date}_${hour}.grib2
						elif [[ ( "$imm" -ge 10 && "$ig" -ge 10 ) ]]
						then
		        				date=${iyy}${mm}${ig}
			       			        rundate=${date}${hour}
					                echo "$date of $hour"
                					echo $rundate
			        		        wgrib2 ${imdaa_data_path}/*_${param}_* -match_fs "=${rundate}" -match_fs "anl" -grib_out $currdir/rundata/${param}_${date}_${hour}.grib2
						fi
					done
				else
				echo -e "\n
  				\n 
  				\n 
  				\n 
  				\n 
  				\n 
  				\n 
				${BRed}$param ${WHITE}does not found in ${BRed}${imdaa_data_path}${WHITE}.
				
				${BGreen}Solutions${WHITE}:
                                1. Either keep all downloaded files in a single folder, or
                                2. Correct the data path provided in the user input section.

       	                        ${BRed}Exiting ...${WHITE}

               	                \n"
				exit 1
				fi
			done
		done
	done
done

#---------------------------------------------- geogrid section ------------------------------------------------------
rm geo_em.d0* .log_geogrid.out
sed -i "s|geog_data_path.*|geog_data_path = '$wps_geog_path',|g" namelist.wps
sed -i "s|opt_output_from_geogrid_path.*|opt_output_from_geogrid_path = '$currdir',|g" namelist.wps
sed -i "s|opt_geogrid_tbl_path.*|opt_geogrid_tbl_path = '$currdir',|g" namelist.wps
sed -i "s|opt_output_from_metgrid_path.*|opt_output_from_metgrid_path = '$currdir',|g" namelist.wps
sed -i "s|opt_metgrid_tbl_path.*|opt_metgrid_tbl_path = '$currdir',|g" namelist.wps
echo -e "\n
Going for ${BGreen}GEOGRID${WHITE} run ...
\n"

${RUN_COMMAND3}  > .log_geogrid.out 2>&1

export GEOFILE1=geogrid.log
export GEOFILE2=geogrid.log.0000
if [ -f "$GEOFILE1" ]; then
        until [[ ( ! -z $geogridlog ) ]]
        do
                geogridlog=`cat $GEOFILE1 |tail -n100 |grep  "Successful completion of program geogrid.exe"`
                if [[ ( -z $geogridlog ) ]]
                then
                        echo -e "\n
  			\n 
  			\n 
  			\n 
  			\n 
  			\n 
			${BGreen}GEOGRID${WHITE} is not successfully finished.

			${BGreen}Possible solutions${WHITE}:
             
     				1. Check for GEOGRID.TBL if it exists?
                                2. Issue in WPS_GEOG static data, maybe some necessary folders are missing.
				3. Check namelist.wps for any incorrect entry.
				4. Check for data resolutions: 1deg/10m/5m/2m/30s
				5. Check whether GEOGRID.TBL.ARW exists in $wps_path/geogrid? 
				6. Could be due to incorrect mpi operation, try with serial run.
			\n"
                        exit 1
                else
                        echo -e "\n 
			${BGreen}GEOGRID${WHITE} is finished. 
			
			Going for ${BGreen}UNGRIB${WHITE} run ...
			\n"
                        rm .log_geogrid.out
                        break
                fi
        done
elif [ -f "$GEOFILE2" ]; then
        until [[ ( ! -z $geogridlog ) ]]
        do
                geogridlog=`cat $GEOFILE2 |tail -n100 |grep  "Successful completion of program geogrid.exe"`
                if [[ ( -z $geogridlog ) ]]
                then
                        echo -e "\n
  			\n 
  			\n 
  			\n 
  			\n 
			${RED}GEOGRID${WHITE} is not successfully finished.
			
                        ${BGreen}Possible solutions${WHITE}:
                                1. Check for GEOGRID.TBL if it exists?
                                2. Issue in WPS_GEOG static data, maybe some necessary folders are missing.
                                3. Check namelist.wps for any incorrect entry.
                                4. Check for data resolutions: 1deg/10m/5m/2m/30s
				5. Check whether GEOGRID.TBL.ARW exists in $wps_path/geogrid? 
				6. Could be due to incorrect mpi operation, try with serial run.
			\n"
                        exit 1
                else
                        echo -e "\n
			${BGreen}GEOGRID${WHITE} is finished. 
		
			Going for ${BGreen}UNGRIB${WHITE} run ...
			\n"
                        rm .log_geogrid.out
                        break
                fi
        done
else
        sleep 5
        echo  -e "\n 
  	\n 
  	\n 
  	\n 
  	\n 
	${BRed}FATAL ERROR. ${WHITE}
		
	GEOGRID is not completed. 
	
	${BGreen}Possible solutions${WHITE}: 
		1. Check .log_geogrid.out file to locate the error source 
	\n"
	exit 1
fi

#------------------------------- ungrib section -------------------------------------------------------------------
rm .log_ungrib_*
for param in ${parameters[@]} 
do
	echo -e "\n Running ungrib for ${param} ..."
	sed -i "s/prefix.*/prefix = '${param}',/g" namelist.wps
	sleep 1
	str0=`cat namelist.wps|grep fg_name`
	str1="${str0}"
	str2=${param}
	str3=${str1}\'${str2}\'
	sed -i "s/ fg_name.*/${str3},/g" namelist.wps
	rm GRIBFILE.* ${param}:* 
	${wps_path}/link_grib.csh $currdir/rundata/${param}_*
	
	${RUN_COMMAND1}  > .log_ungrib_${param}.out 2>&1

	until [[ ( ! -z $ungriblog ) ]]
		do
		ungriblog=`cat .log_ungrib_${param}.out |tail -n100 |grep  "Successful completion of ungrib."`
		if [[ ( -z $ungriblog ) ]] 
			then
			echo -e "\n
  			\n 
  			\n 
  			\n 
  			\n 
			${BRed}ungrib for ${param} ${WHITE}is not finished, exiting ...

			${BGreen}Possible actions${WHITE}:
		                1. Check .log_ungrib_${param}.out file to locate the error source.
				2. If nothing traced, might be due to data inconsistency. Solution is not in your hand. Contact NCMRWF.
			\n"
			exit 1
		else
			continue 
		fi
	done
	echo -e "\n
	Ungrib for ${BGreen}${param} ${WHITE} is finished. Going for the next variable ...
	\n"
done

#------------------------------- metgrid section -------------------------------------------------------------------
rm .log_metgrid.out
cat > unsuccess_message << EOF
#!/bin/bash
echo -e "\n	
\n
\n
\n
\n
\n

		${RED}${BRed}FATAL ERROR

		Can not go for Metgrid...
		${WHITE}
                --------------------------------------------------------------------------------------------------------------
                The reason for not proceeding with metgrid is due to the below red-colored file/files.
                Either remove this particular variable defined in ${BGreen}parameters${WHITE} option for proceeding to metgrid.
                
		P.S.: Raise a concern to NCMRWF for clarifications related to this/these dataset/datasets.

                ------------------------------------------------------------------------------------------------------------- \n"
EOF

all_non_zero=true
rm .z
for file in "${parameters[@]}"; do
	for hour in $(eval echo "{$start_hour..$end_hour..$intervals}")
        do
        	ss=("$file":"$syyyy"-"$smm"-"$start_date"_"$hour")
                if [ -e "$ss" ]; then
			file_size=$(stat -c %s "$ss")
			if [ "$file_size" -eq 0 ]; then
				all_non_zero=false
				echo -e "File ${RED}$ss ${WHITE}is empty. "  >> .z
			fi
		else
			echo -e "\n
			\n
			\n
			\n
			\n
			File ${BRed}$ss${WHITE} does not exist.
			\n"
			all_non_zero=false
        	fi
	done
done

if $all_non_zero; then
	echo -e "\n
	Successfully finished ${BGreen} Ungrib ${WHITE}for all parameters.

	Proceeding for ${BGreen}METGRID${WHITE} run ...
	\n"
	
	${RUN_COMMAND2}  > .log_metgrid.out 2>&1
	sleep 2
else
	echo -e "\n
	\n
	\n
	\n
	\n
        ${BLUE}Successfully finished UNGRIB for all parameters.${WHITE}

        But, ${BRed}some files have zero size${WHITE}. Hence, can not proceed with the METGRID.
	
	Checking for files that have issues ...
        \n"
	bash unsuccess_message
	cat .z
	rm .z
    	exit 1
fi

# checking for success of WPS
cat > .success << EOF
#!/bin/bash

echo -e '\n	--------------------------------------------------------------------------------------------------------------------------
	
	${BGreen}SUCCESS${WHITE}
	
	Creating intermediate files using ungrib and metgrid is done. 
	Please proceed with ${BGreen}real.exe${WHITE} and ${BGreen}wrf.exe${WHITE} in the conventional way. 

	--------------------------------------------------------------------------------------------------------------------------- \n'
EOF
chmod +x .success
metfile1=(met_em.d01."$syyyy"-"$smm"-"$start_date"_"$start_hour":00:00.nc)
echo $metfile1
ncdump -h $metfile1>.metfile2

val=`awk '/'"NUM_METGRID_SOIL_LEVELS = "'/ { print }' ".metfile2" |cut -c30`
export METFILE1=metgrid.log
export METFILE2=metgrid.log.0000
if [ -f "$METFILE1" ]; then
        until [[ ( ! -z $metgridlog ) ]]
        do
                metgridlog=`cat $METFILE1 |tail -n100 |grep  "Successful completion of program metgrid.exe"`
                if [[ ( -z $metgridlog ) ]]
                then
                        echo -e "\n
			\n
			\n
			\n
			\n
			
			${RED}METGRID is not successful. ${WHITE}

			Check for missing of any ${RED}essential variable${WHITE}
			in the ${BLUE}parameters${WHITE} option
			
			Please add all essential parameters to the list.
					
			\n"
			exit 1
                else
                        echo -e "\n 
			${BGreen}METGRID${WHITE} is finished. 
			\n
			\n
			Checking for accuracy ... 
			\n"
			if [ "$val" -gt 0 ]; then
				bash .success
				rm .log_* GRIBFILE.* .metfile2
				break
			else
				echo -e "\n
			       	The metgrid is finished.
			       	However, there is an issue with the ${BRed}metgrid soil level${WHITE}. 
				
				Do not go for the WRF run.
				\n"
				exit 1
			fi
                fi
        done
elif [ -f "$METFILE2" ]; then
        until [[ ( ! -z $metgridlog ) ]]
        do
                metgridlog=`cat $METFILE2 |tail -n100 |grep  "Successful completion of program metgrid.exe"`
                if [[ ( -z $metgridlog ) ]]
                then
                        echo -e "\n
			\n
			\n
			\n
			\n

                        ${RED}METGRID is not successful. 
			${WHITE}Check for missing of any ${RED}essential variable${WHITE} in the ${BLUE}parameters${WHITE} option
		
			
			Please add all essential parameters to the list.
		
                        
			\n"
                        exit 1
                else
			echo -e "\n ${BGreen}
			METGRID${WHITE} is finished.
			\n
			\n
			Checking for accuracy ... 
			\n"
                        if [ "$val" -gt 0 ]; then
                                bash .success
                                rm .log_* GRIBFILE.* .metfile2
                                break
                        else
                                echo -e "\n
			       	Metgrid is finished, however, there is an issue in the ${BRed}metgrid soil level${WHITE}. 
				
				Do not go for the WRF run.
				\n"
                                exit 1
                        fi			
                fi
        done
else
        sleep 5
        echo  -e "\n 
	\n
	\n
	\n
	\n
	${BRed}
	FATAL ERROR. METGRID not completed${WHITE}. 
		
	Check for issues in .log_ungrib_* and .log_metgrid*  files to know the error source. 
	Else contact NCMRWF.
	\n"
fi
rm .success 
