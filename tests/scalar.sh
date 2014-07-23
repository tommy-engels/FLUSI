#!/bin/bash

#-------------------------------------------------------------------------------
# FLUSI (FSI) unit test
# This file contains one specific unit test, and it is called by unittest.sh
#-------------------------------------------------------------------------------

# set up mpi command (this may be machine dependent!!)
nprocs=$(nproc)
mpi_command="nice -n 19 ionice -c 3 mpiexec --np ${nprocs}"
# what parameter file
params="./passive_scalar/scalar.ini"

happy=0
sad=0


# list of prefixes the test generates
prefixes=(ux uy uz mask scalar)
# list of possible times (no need to actually have them)
times=(00000 00005 00010 00015 00020 00025 00030 00035 00040 00045 00050 00055 00060 00070 00075 00080 00085 00090 00095 00100)
# run actual test
${mpi_command} ./flusi ${params}
echo "============================"
echo "run done, analyzing data now"
echo "============================"


# loop over all HDF5 files an generate keyvalues using flusi
for p in ${prefixes[@]}
do  
  for t in ${times[@]}
  do
    echo "--------------------------------------------------------------------"
    # *.h5 file coming out of the code
    file=${p}"_"${t}".h5"
    # will be transformed into this *.key file
    keyfile=${p}"_"${t}".key"
    # which we will compare to this *.ref file
    reffile=./passive_scalar/${p}"_"${t}".ref" 
    
    if [ -f $file ]; then    
        # get four characteristic values describing the field
        ./flusi --postprocess --keyvalues ${file}        
        # and compare them to the ones stored
        if [ -f $reffile ]; then        
            ./flusi --postprocess --compare-keys $keyfile $reffile 
            result=$?
            if [ $result == "0" ]; then
              echo -e ":) Happy, this looks okay! " $keyfile $reffile 
              happy=$((happy+1))
            else
              echo -e ":[ Sad, this is failed! " $keyfile $reffile 
              sad=$((sad+1))
            fi
        else
            sad=$((sad+1))
            echo -e ":[ Sad: Reference file not found"
        fi
    else
        sad=$((sad+1))
        echo -e ":[ Sad: output file not found"
    fi
    echo " "
    echo " "
    
  done
done


echo -e "\thappy tests: \t" $happy 
echo -e "\tsad tests: \t" $sad

#-------------------------------------------------------------------------------
#                               RETURN
#-------------------------------------------------------------------------------
if [ $sad == 0 ] 
then
  exit 0
else
  exit 999
fi