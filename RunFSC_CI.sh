#!/bin/bash

#Laurent Excoffier February 2013
#Changed by Anthony Fries 2015
#



#it assumes it is in a folder with fsc executable, Model_files directory containing all est and tpl files, and a subdirectory specified on the
#command line (resampfilelocation) that exists in a ResampledDatasets directory and containins all resampled sfs with names X.*.obs where X is a number.

# Format of calling the script on the OSC:
# RunFSC.sh [-m] sfs_prefix model walltime popsize numruns 

#resampfilelocaton	all text preceeding the '.obs' for the SFS to be run.
#model			the name of the model to be run (prefix of .est and .tpl files)
#walltime		estimated walltime for the run; format XX:YY:ZZ (i.e. 1:00:00 (one hour) - 20:00:00 (twenty hours))
#popsize		Sample sizes for the populations; if more than one, separate by commas.
#numruns		Number of independent fsc runs for each model.

#Get the path to where the script is
#maindir=$PWD
# shorthand shortcut for the executable to be called later in the script.
fsc=fsc252

#-------- Number of different fsc runs per resampled data set ------
# this should be the number of times you will be sending a process to a node
numRuns=$4 

# this is the run you are starting at for each resampled dataset
runBase=1 

# this is the resampled file number you're starting at
fileBase=6

#this is the last resampled file number to run
#### NOTE that ($lastFileNum-$fileBase+1)*$numRuns must be less than 1000 for osc.############# 
lastFileNum=8

#Name of the folder where the resampled SFS are stored (in ResampledDatasets directory)
resampfilelocation=$1

#Model name
model=$2

#-------- Time for analysis --------
totaltime=$3 

#-------- Default run values ------
iniNumSims=100000                 #-n command line option
maxNumSims=100000                 #-N command line option
minNumCycles=10                   #-l command line option
maxNumCycles=30                   #-L command line option
stopCrit=0.001                    #-M command line option
# minValidSFSEntry=1                #-C command line option
cores=6  			#-c command line option
batches=12

#----------multiSF------------
 multiSFS=""
#multiSFS="--multiSFS"            #--multiSFS command line option
#-----------------------------

#----------SFS Fold-----------
# UNFOLDED
#SFSfold="-d"
# FOLDED
 SFSfold="-m"


#make timestamped directory name
dirname=CI_${resampfilelocation}_$model


#Make a directory corresponding to the current $resampfilelocation name and the model.
if [ ! -d "$HOME/ResampledDatasets/$dirname" ]; then
   mkdir $HOME/ResampledDatasets/$dirname
fi

if [ ! -d "$HOME/ResampledDatasets/$dirname/Best_lhoods" ]; then
   mkdir $HOME/ResampledDatasets/$dirname/Best_lhoods
fi

# Now we want to select the first resampled file (with number $fileBase) and create a new directory for this dataset
#in ResampledDatasets/$dirname to run the dataset through the model numRuns times

for (( filesDone=$fileBase; filesDone<=$lastFileNum; filesDone++))
   do

   # generic counter for the loops below - This keeps track of the number of indepedent times that fsc.sh files are sent to a node.
   jobcount=0

   #stage the resampled .obs file and the other necessary files in the $dirname/fileX directory for the independent runs.
   mkdir $HOME/ResampledDatasets/$dirname/file$filesDone
   cp $HOME/ResampledDatasets/$resampfilelocation/$filesDone.*.obs $HOME/ResampledDatasets/$dirname/file$filesDone/${model}_MAFpop0.obs
   cp $HOME/Model_files/$model.est $HOME/ResampledDatasets/$dirname/file$filesDone
   cp $HOME/Model_files/$model.tpl $HOME/ResampledDatasets/$dirname/file$filesDone

   #make directory in Best_lhoods directory for the  current file.
   mkdir $HOME/ResampledDatasets/$dirname/Best_lhoods/file$filesDone
   #cp $HOME/fsc* $HOME/ResampledDatasets/$dirname/file$filesDone
   #Need to sed here to get the tpl file updated with the sample size.

   #copy .obs, tpl, est, and fsc files to run folders and create shell script for each - do this $numRuns times.

   for (( runsDone=$runBase; runsDone<=$numRuns; runsDone++ ))

	do
		runDir="run$runsDone"	# Make a variable holding what numRun you're on.
		mkdir $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir 2>/dev/null	# Create the run directory.
		echo "--------------------------------------------------------------------"
		echo ""
		echo "Current file: file $filesDone run $runDir" # Just to pretty up the output
		echo ""

		#copy all of the necessary files to the current run directory.
		cp $HOME/ResampledDatasets/$dirname/file$filesDone/$model.est $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir
		cp $HOME/ResampledDatasets/$dirname/file$filesDone/$model.tpl $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir
		cp $HOME/ResampledDatasets/$dirname/file$filesDone/*.obs $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir
		cp $HOME/$fsc $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir

		#cd to the current run directory so that the bash script that will be sent with qsub is sent from this directory, and then the error and output files will be stored there.
		cd $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir

		#generate a name for the current shell script.
		jobName=${model}_${resampfilelocation}_${filesRun}_${runsDone}.sh

		#Creating bash file on the fly
		(
		echo "#!/bin/bash"
		echo ""
		echo "# specify resources needed"
		echo "#PBS -l walltime=$totaltime"	# Was specified with the 2nd command line argument
		echo "#PBS -l nodes=1:ppn=6"	# !!!! THIS WOULD NEED TO CHANGE BETWEEN OAKLEY (12) AND GLENN (8)
		echo "#PBS -N fsc_${filesDone}_${runsDone}"	# Generic name
		echo "#PBS -m a"	# This is the email setting. b(begin job) e(end) a(abort)
		# echo "#PBS -j oe"	# Where to send the Output stream and the error stream... i.e. "j"=joint...just send it to the same output "oe"
		echo ""
		echo "set -x"	# OSC specific command to print the commands into the output
		echo ""
		echo "cp $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/* \$TMPDIR"	# Now you are going to copy the entire directory that you are in (i.e. $runDir) to the $TMPDIR... or rather the temporary computation node in which you are going to operate from. This will disappear when FSC is completed.
		# echo "cp /nfs/12/osu0378/local/fsc/fsc25221 \$TMPDIR" ## Don't think I need this because I already brought this over a few lines above.
		echo "cd \$TMPDIR"	# Now cd into the $TMPDIR for the chosen node
		echo "chmod +x ./$fsc"	# Was originally commented out by Excoffier
		echo ""
		echo "echo \"Analysis number $runDir of resampled file $filesDone for $resampfilelocation model $model\""
		echo "#Computing likelihood of the parameters using the ECM-Brent algorithm"
		echo "echo \"\""
		echo "echo \"./$fsc -t ${model}.tpl -n $iniNumSims -N $maxNumSims ${SFSfold} -e ${model}.est -M $stopCrit -l $minNumCycles -L $maxNumCycles -B ${batches} -q ${multiSFS} -c ${cores}\""
		echo "./$fsc -t ${model}.tpl -n $iniNumSims -N $maxNumSims ${SFSfold} -e ${model}.est -M $stopCrit -l $minNumCycles -L $maxNumCycles -B ${batches} -q ${multiSFS} -c ${cores}"                           
		echo ""
		echo "echo \"\""
		echo "rm ./$fsc"
		echo "cp -R * $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/"	# Copy Everything on the tempdir to the current Run directory on the main node.
		echo "cp $model/*.bestlhoods $HOME/ResampledDatasets/$dirname/Best_lhoods/file$filesDone/$model.$runsDone.bestlhoods"
		#remove some files we probably don't need to keep
		echo "rm $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/seed.txt"
		echo "rm $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/${model}.est"
		echo "rm $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/MRCAs.txt"
		echo "rm $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/${model}.tpl"
		echo "rm $HOME/ResampledDatasets/$dirname/file$filesDone/$runDir/*.obs"
		echo "echo \"Job completed for $resampfilelocation model $model file $filesDone run $runsDone.\""
		) > $jobName
		chmod +x $jobName	#All of the above was printed to the shell script named with the variable $jobName. Make this executable.

		echo "Bash file $jobName created"
				
				
		qsub ./${jobName}	# Now that the bash file is created we will send it to the computing node from the login mode to wait in queue
		#./${jobName}
		#cd .. ; #move up out of current $runDir for next $runDir.	
   done
done
cd .. #dirs

