#!/bin/bash

# ./PowerAnalysis_ModelTests.sh #simDatasets_in_SimulatedSFS_dir $dir_designation #fsc_runs_per_model walltime_per_run name_of_model_to_run
#may want to use the $dir_designation to indicate the model under which the data were generated.
#need dir 'Models' with all est and tpl files to be run, dir 'SimulatedSFS', and fsc252 executable
#output from run is in directory 'PowerAnalysisResults'

#check to make sure we're not going to overwrite anything we want

#if [ -d PowerAnalysisResults/$2 ]; then
#   echo "
#   exit;
#fi

if [ ! -d PowerAnalysisResults ]; then
   mkdir PowerAnalysisResults;
fi

if [ ! -d PowerAnalysisResults/$2 ]; then
   mkdir PowerAnalysisResults/$2;
fi

#get the model names
#cd Models/
#estnames=(*\.tpl)
#cd ../


#create shell script and send qsub command for each run (can't send more than 1000 each time)
time=$4

#get directory the script is in
scriptdir=$PWD

#for each simulated dataset
for i in $(eval echo {1..$1}); do
  if [ ! -d PowerAnalysisResults/$2/sim$i ]; then
     mkdir PowerAnalysisResults/$2/sim$i/;
  fi

  #for each model name
  #for j in ${estnames[@]}; do
  #   modelname=`echo $j | sed s/\.tpl$// | sed s/Models//`
  if [ -d PowerAnalysisResults/$2/sim$i/$5 ]; then
     echo "Directory PowerAnalysisResults/$2/sim$i/$5 already exists"
     exit;
  fi 
   
  mkdir PowerAnalysisResults/$2/sim$i/$5

  if [ ! -d PowerAnalysisResults/$2/sim$i/$5/Best_lhoods ]; then
      mkdir PowerAnalysisResults/$2/sim$i/$5/Best_lhoods
  fi

     #for each fsc run for the current model
     for run in $(eval echo {1..$3}); do
	mkdir PowerAnalysisResults/$2/sim$i/$5/run$run
	jobName=sim${i}_model${5}_run${run}.sh

	#Create bash file
	(
	echo "#!/bin/bash"
	echo "# specify resources needed"
	echo "#PBS -l walltime=$time"
	echo "#PBS -l nodes=1:ppn=6"
	echo "#PBS -N pwr_${i}_${5}_${run}"
	echo "#PBS -m a"
	echo ""
	echo "set -x"
	echo ""
        echo "cp $scriptdir/fsc252 \$TMPDIR"
        echo "cp $scriptdir/Models/$5.est \$TMPDIR"
        echo "cp $scriptdir/Models/$5.tpl \$TMPDIR"
        echo "cp $scriptdir/SimulatedSFS/*_${i}_*.obs \$TMPDIR/${5}_MAFpop0.obs"
	echo "cd \$TMPDIR"
	echo ""
	echo "echo Analysis for simulated dataset $i model $5 run $run."
	echo "echo \"./fsc252 -t ${5}.tpl -n 100 -N 100 -m -e ${5}.est -M 0.001 -l 10 -L 30 -B 12 -q -c 6\""
	echo "./fsc252 -t ${5}.tpl -n 100 -N 100 -m -e ${5}.est -M 0.001 -l 10 -L 30 -B 12 -q -c 6"
	echo "rm fsc252"
	echo "cp -R * $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run"
	echo "cp $5/*.bestlhoods $scriptdir/PowerAnalysisResults/$2/sim$i/$5/Best_lhoods/$5.$run.bestlhoods"
	#echo "sed -n '2,2p' $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/$modelname/$modelname.bestlhoods >> $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/Best_lhoods/All_Results.txt"
	#remove some files we probably don't need to keep
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/seed.txt"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/${5}.est"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/${5}.tpl"
	echo "rm $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/MRCAs.txt"
	echo "echo \"Job completed for simulated dataset $i model $5 run $run.\""
	) > $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/$jobName

	cd $scriptdir/PowerAnalysisResults/$2/sim$i/$5/run$run/
	chmod +x $jobName

	echo "Bash file $jobName created."

	qsub ./$jobName
	#cd $scriptdir/PowerAnalysisResults/$2/sim$i/$modelname/run$run/
	cd $scriptdir/
     done
#  done
done
