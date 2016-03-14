#!/bin/bash

# ./PowerAnalysis_ModelTests.sh #simDatasets_in_SimulatedSFS_dir $dir_designation #fsc_runs_per_model walltime_per_run
#may want to use the $dir_designation to indicate the model under which the data were generated.
#need dir 'Models' with all est and tpl files to be run, dir 'SimulatedSFS', and fsc252 executable
#output from run is in directory 'PowerAnalysisResults'

#check to make sure we're not going to overwrite anything we want

if [ -d PowerAnalysisResults/$2 ]; then
   echo "Directory PowerAnalysisResults/$2 already exists. Either delete it prior to running, or choose another name."
   exit;
fi

if [ ! -d PowerAnalysisResults ]; then
   mkdir PowerAnalysisResults;
fi

mkdir PowerAnalysisResults/$2

#get the model names
cd Models/
estnames=(*\.tpl)
cd ../

#for each simulated dataset
for i in $(eval echo {1..$1}); do
   mkdir PowerAnalysisResults/$2/sim$i;

   #for each model

   for j in ${estnames[@]}; do
     modelname=`echo $j | sed s/\.tpl$//`
     mkdir PowerAnalysisResults/$2/sim$i/$modelname
     
     if [ ! -d PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods ]; then
        mkdir PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods
     fi

     for run in $(eval echo {1..$3}); do
	mkdir PowerAnalysisResults/$2/sim$i/$modelname/run$run
	cp fsc252 PowerAnalysisResults/$2/sim$i/$modelname/run$run
	cp Models/$modelname.est PowerAnalysisResults/$2/sim$i/$modelname/run$run
	cp Models/$modelname.tpl PowerAnalysisResults/$2/sim$i/$modelname/run$run
	cp SimulatedSFS/*_${i}_*.obs PowerAnalysisResults/$2/sim$i/$modelname/run$run/${modelname}_MAFpop0.obs
     done 
   done
done



#create shell script and send qsub command for each run (can't send more than 1000 each time)
time=$4

#get directory the script is in
scriptdir=$PWD

for i in $(eval echo {1..$1}); do
  for j in ${estnames[@]}; do
     modelname=`echo $j | sed s/\.tpl$// | sed s/Models//`

     for run in $(eval echo {1..$3}); do

	jobName=sim${i}_model${modelname}_run${run}.sh

	#Create bash file

	(
	echo "#!/bin/bash"
	echo "# specify resources needed"
	echo "#PBS -l walltime=$time"
	echo "#PBS -l nodes=1:ppn=6"
	echo "#PBS -N pwr_${i}_${j}_${run}"
	echo "#PBS -m a"
	echo ""
	echo "set -x"
	echo ""
	echo "cp $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/* \$TMPDIR"
	echo "cd \$TMPDIR"
	echo ""
	echo "echo Analysis for simulated dataset $i model $modelname run $run."
	echo "echo \"./fsc252 -t ${modelname}.tpl -n 100 -N 100 -m -e ${modelname}.est -M 0.001 -l 10 -L 30 -B 12 -q -c 6\""
	echo "./fsc252 -t ${modelname}.tpl -n 100 -N 100 -m -e ${modelname}.est -M 0.001 -l 10 -L 30 -B 12 -q -c 6"
	echo "rm fsc252"
	echo "cp -R * $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run"
	echo "cp $modelname/*.bestlhoods $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/$modelname.$run.bestlhoods"
	#echo "sed -n '2,2p' $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/$modelname/$modelname.bestlhoods >> $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/All_Results.txt"
	#remove some files we probably don't need to keep
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/seed.txt"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/${modelname}.est"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/${modelname}.tpl"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/MRCAs.txt"
	echo "echo \"Job completed for simulated dataset $i model $modelname run $run.\""
	) > $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/$jobName

	cd $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/
	chmod +x $jobName

	echo "Bash file $jobName created."

	qsub ./$jobName
	cd $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/
     done
  done
done
