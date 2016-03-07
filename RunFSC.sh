#!/bin/bash

#Laurent Excoffier February 2013
#Changed by Anthony Fries 2015
#



#it assumes it is in a folder with fsc executable, Model_files directory containing all est and tpl files, and an obs_files directory
#containing all sfs.

# Format of calling the script on the OSC:
# RunFSC.sh [-m] sfs_prefix model walltime popsize numruns 

#sfs_prefix	all text preceeding the '.obs' for the SFS to be run.
#model		the name of the model to be run (prefix of .est and .tpl files)
#walltime	estimated walltime for the run; format XX:YY:ZZ (i.e. 1:00:00 (one hour) - 20:00:00 (twenty hours))
#popsize	Sample sizes for the populations; if more than one, separate by commas.
#numruns	Number of independent fsc runs for each model.

#Get the path to where the script is
maindir=$PWD
# shorthand shortcut for the executable to be called later in the script.
fsc=fsc252
# generic counter for the loops below - This keeps track of the number of indepedent times that fsc.sh files are sent to a node.
jobcount=0

#-----------------------------
# This will create a directory in which all of the console output will be
# sent to. The notation "2>/dev/null" is a command in standard I/O 
# computing to redirect the standard error stream.
#mkdir consoleOutputs 2>/dev/null

#-------- Number of different runs per data set ------
# this should be the number of times you will be sending a process to a node
numRuns=$5 
# this is the run you are starting at
runBase=1 

#Prefix of the current SFS
sfsName=$1

#Model name
model=$2

#-------- Time for analysis --------
totaltime=$3 

#-------- Default run values ------
iniNumSims=10000                 #-n command line option
maxNumSims=10000                 #-N command line option
minNumCycles=5                   #-l command line option
maxNumCycles=10                   #-L command line option
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
dirname=${sfsName}_$model_`date +%F%T`



#Make a directory corresponding to the current SFS name and the time.
mkdir $maindir/$dirname

if [ ! -d "$maindir/Best_lhoods" ]; then
   mkdir $maindir/Best_lhoods
fi

#Make a directory that will get the .bestlhoods files to sort later
mkdir $maindir/Best_lhoods/$dirname
		
		
echo ""
echo "Created directory : $dirname in $maindir"
		
cd $maindir/$dirname	# Go into that directory (i.e. JENN_2016-03-01:10:05:15)
		
			
# Now you want to run the observed dataset through this model numRuns times

for (( runsDone=$runBase; runsDone<=$numRuns; runsDone++ ))	
		
	do
		runDir="run$runsDone"	# Make a variable holding what numRun you're on.
		mkdir $runDir 2>/dev/null	# Create a directory within Model_X directory for the run you are about to start.
		echo "--------------------------------------------------------------------"
		echo ""
		echo "Current file: $runDir" # Just to pretty up the output
		echo ""	
		cd $runDir	# Now you are going into that directory that you just created
		#currDir=$PWD	# Define your current working directory
		# Copying necessary files to the current run directory.
				
		cp ../../Model_files/$model.est ./
		cp ../../Model_files/$model.tpl ./
		cp ../../obs_files/$sfsName*.obs ./
		cp ../../fsc* ./
		#Need to sed here to get the tpl file updated with the sample size.

		
		#Renaming the .obs file so it matches the current model name.
		mv *.obs ${model}_MAFpop0.obs 2>/dev/null ###!!! This is important to make sure you have the right name of the SFS.
				
		# Increasing the dummy variable by 1 to use as the name of the shell script that is about to be created.
		let jobcount=jobcount+1
		jobName=${model}_${sfsName}_${jobcount}.sh

		#Creating bash file on the fly
		(
		echo "#!/bin/bash"
		echo ""
		echo "# specify resources needed"	
		echo "#PBS -l walltime=$totaltime"	# Was specified with the 2nd command line argument
		echo "#PBS -l nodes=1:ppn=6"	# !!!! THIS WOULD NEED TO CHANGE BETWEEN OAKLEY (12) AND GLENN (8)
		echo "#PBS -N fsc_${jobcount}"	# Generic name
		echo "#PBS -m bae"	# This is the email setting. b(begin job) e(end) a(abort)
		# echo "#PBS -j oe"	# Where to send the Output stream and the error stream... i.e. "j"=joint...just send it to the same output "oe"
		echo ""
		echo "set -x"	# OSC specific command to print the commands into the output
		echo ""
		echo "cp $HOME/$dirname/$runDir/* \$TMPDIR"	# Now you are going to copy the entire directory that you are in (i.e. $runDir) to the $TMPDIR... or rather the temporary computation node in which you are going to operate from. This will disappear when FSC is completed.
		# echo "cp /nfs/12/osu0378/local/fsc/fsc25221 \$TMPDIR" ## Don't think I need this because I already brought this over a few lines above.
		echo "cd \$TMPDIR"	# Now cd into the $TMPDIR for the chosen node
		echo "chmod +x ./$fsc"	# Was originally commented out by Excoffier
		echo ""
		echo "echo \"Analysis number $jobcount of file $sfsName for model $model\""
		echo "#Computing likelihood of the parameters using the ECM-Brent algorithm"
		echo "echo \"\""
		echo "echo \"./$fsc -t ${model}.tpl -n $iniNumSims -N $maxNumSims ${SFSfold} -e ${model}.est -M $stopCrit -l $minNumCycles -L $maxNumCycles -B ${batches} -q ${multiSFS} -c ${cores}\""
		echo "./$fsc -t ${model}.tpl -n $iniNumSims -N $maxNumSims ${SFSfold} -e ${model}.est -M $stopCrit -l $minNumCycles -L $maxNumCycles -B ${batches} -q ${multiSFS} -c ${cores}"                           
		echo ""
		echo "echo \"\""
		echo "rm ./$fsc"
		echo "cp -R * $HOME/$dirname/$runDir/"	# Copy Everything on the tempdir to the current Run directory on the main node.
		echo "cp $model/*.bestlhoods $maindir/Best_lhoods/$dirname/$model.$jobcount.bestlhoods"
		echo "echo \"Job $jobcount completed for $sfsName model $model.\""
		) > $jobName
		chmod +x $jobName	#All of the above was printed to the shell script named with the variable $jobName. Make this executable.

		echo "Bash file $jobName created"
				
				
		qsub ./${jobName}	# Now that the bash file is created we will send it to the computing node from the login mode to wait in queue
		#./${jobName}
		cd .. ; #move up out of current $runDir for next $runDir.	
done
cd .. #dirs

