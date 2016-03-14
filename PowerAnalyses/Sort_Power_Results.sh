#!/bin/bash

# ./Sort_Power_Resultss.sh #simDatasets_in_SimulatedSFS_dir $dir_designation 
#may want to use the $dir_designation to indicate the model under which the data were generated.
#need dir 'Models' with all est and tpl files to be run, dir 'SimulatedSFS', and fsc252 executable
#output from run is in directory 'PowerAnalysisResults_Sorted'

#check to make sure we're not going to overwrite anything we want

if [ ! -d PowerAnalysisResults_Sorted ]; then
   mkdir PowerAnalysisResults_Sorted;
fi

#get the model names
cd Models/
estnames=(*\.tpl)
cd ../

#for each simulated dataset
for i in $(eval echo {1..$1}); do

   #for each model

   for j in ${estnames[@]}; do
     #remove the tpl extension on the model name
     modelname=`echo $j | sed s/\.tpl$//`

     #clear out any AllResults.txt files or they will be appended to.
     if [ -f PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/AllResults.txt ]; then
         rm PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/AllResults.txt;
     fi

     #get array with names of all the bestlhoods files
     bestlhoodfiles=(PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/*\.bestlhoods)

     #for each bestlhoods file, append the second line to file AllResults.txt
     for file in ${bestlhoodfiles[@]}; do sed -n '2,2p' $file >> PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/AllResults.txt; done

     #get the column number to sort
     colnum=`head -1 PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/$modelname.1.bestlhoods | wc -w`
     colnum=$[colnum-1]
     #print a header to the file that will store the sorted data
     head -1 PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/$modelname.1.bestlhoods >> PowerAnalysisResults_Sorted/${2}_${modelname}_sim${i}.txt
     #sort the data
     sort -k $colnum PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/AllResults.txt >> PowerAnalysisResults_Sorted/${2}_${modelname}_sim${i}.txt

   done
done
