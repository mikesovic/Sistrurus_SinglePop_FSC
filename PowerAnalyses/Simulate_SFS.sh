#!/bin/bash

#Run this script with  ./Simulate_SFS.sh par_file_name [# of sim datasets to generate]
#needs a par file that is indicated as the first argument on the command line and the fsc252 executable.
#for now, still need to updated the value in the brace expansion in the line 'for sim in {1..X}'. Need to fix this.
#it should match the second argument given on the command line (the num of simulations to perform).

if [ $2 ]; then
    mkdir SimulatedSFS

    for sim in {1..10}; do
      mkdir sim$sim
      cp fsc252 *.par sim$sim
      cd sim$sim
      ./fsc252 -i $1 -n 1 -s 0 -m
      model=`echo $1 | sed s/\.par//` 
      rm $model/*Sites.obs
      mv $model/*.obs ../SimulatedSFS/${sim}_MAFpop0.obs 
      cd ..
    done;

else 
    ./fsc252 -i $1 -n 1 -s 0 -m

fi
