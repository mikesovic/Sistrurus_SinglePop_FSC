#!/bin/bash

#Run this script with  ./Simulate_SFS.sh par_file_name [# of sim datasets to generate]
#needs a par file that is indicated as the first argument on the command line and the fsc252 executable.


if [ $2 ]; then		#if we are simulating multiple sfs from a single par file
    if [ ! -d SimlatedSFS ]; then
      mkdir SimulatedSFS	#store the simulated sfs here;
    fi

    for sim in $(eval echo "{1..$2}"); do
      mkdir sim$sim			#make a temporary directory to do the simulation
      cp fsc252 *.par sim$sim
      cd sim$sim
      ./fsc252 -i $1 -n 1 -s 0 -m	#perform the simulation with fsc
      model=`echo $1 | sed s/\.par//` 
      rm $model/*Sites.obs
      mv $model/*.obs ../SimulatedSFS/${model}_${sim}_MAFpop0.obs 	#copy the simulated sfs to the SimulatedSFS directory that stores all the simulated sfs.
      cd ..
      rm -r sim$sim
    done;

else 			#only performing one simulation from the par file
    ./fsc252 -i $1 -n 1 -s 0 -m

fi
