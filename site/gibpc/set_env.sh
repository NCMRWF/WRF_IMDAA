#!/bin/bash
export DIR=/home/gibies/Build_WRF/LIBRARIES
export CC=gcc
export CXX=g++
export FC=gfortran
export F77=gfortran

export FFLAGS=-m64
export FCFLAGS=-m64

#export FFLAGS=-fallow-argument-mismatch
#export FCLAGS=-fallow-argument-mismatch

export JASPERLIB=$DIR/grib2/lib
export JASPERINC=$DIR/grib2/include
export LDFLAGS=-L$DIR/grib2/lib
export CPPFLAGS=-I$DIR/grib2/include
export NETCDF=$DIR/netcdf/4.4.1.1

#export CPPFLAGS=-I${NETCDF}/include
#export LDFLAGS=-L${NETCDF}/lib

export PATH=$DIR/openmpi/4.1.5/bin:$DIR/grib2/bin:$DIR/curl/7.26.0/bin:$DIR/hdf5/1.8.17/bin:$DIR/netcdf/4.4.1.1/bin:$PATH

export LD_LIBRARY_PATH=$DIR/grib2/lib:$DIR/curl/7.26.0/lib:$DIR/hdf5/1.8.17/lib:$DIR/netcdf/4.4.1.1/lib:$LD_LIBRARY_PATH
