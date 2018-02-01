#!/bin/sh
# find-gamma-flows-one-router-one-day.sh

Data_Dir="/if13/sm8kk/throughput-mon/flowData" # location of records & flows
Prog_Dir="/if13/sm8kk/throughput-mon/scripts/concatenate" # location of this program
Java_Dir="$Prog_Dir/bin" # place to store Java .class files
Java_Log="$Java_Dir/javac.log" # compiler messages stored here

if [ ! $# -eq 3 ] && [ ! $# -eq 1 ]; then
    echo "Usage: $0 [year] [month] [day]" 2>&1
    echo "Example: $0 2014 07 01" 2>&1
    echo "To compile Java code only: $0 --compile"
    exit 1
fi

# compile Java to proper location if requested or not yet compiled
if [ $# -eq 1 ] || [ ! -d "$Java_Dir" ]; then
    if [ ! -d "$Java_Dir" ]; then
	mkdir -p "$Java_Dir"
    fi
    echo "** Compiling OneDayReports on `date`" >> "$Java_Log"
    javac -d "$Java_Dir" "$Prog_Dir"/*.java &>> "$Java_Log"
    echo "" >> "$Java_Log"
    exit 0
fi

Day=$1"-"$2"-"$3

# loation of LargeSmallRecords.txt file
Record_Dir=$Data_Dir/$Day
# output directory
Flow_Dir=$Data_Dir/$Day/'concatenated'
Log_Slurm_Dir=$Data_Dir/$Day/'slurm-logs'
Script_Slurm_Dir=$Data_Dir/$Day/'slurm-scripts'
filterRecordsList="/if13/sm8kk/throughput-mon/scripts/filterRecordsList.txt"

# exit if records don't exist
if [ ! -d "$Record_Dir" ]; then
    echo "$Record_Dir does not exist; aborting $0" 2>&1
    exit 1
fi

# exit if flows already exist
if [ -d "$Flow_Dir" ]; then
    echo "$Flow_Dir already exists; aborting $0" 2>&1
    exit 1
fi

mkdir -p $Flow_Dir
mkdir $Log_Slurm_Dir
mkdir $Script_Slurm_Dir

while read filterFlowRecFilename
do
    prefix=`echo $filterFlowRecFilename | awk 'BEGIN {FS = "-"} ; { print $2}' | awk 'BEGIN {FS = "."} ; { print $1}'`
    OFILE=$Log_Slurm_Dir/${prefix}.qout
    EFILE=$Log_Slurm_Dir/${prefix}.qerr
    SLURM_SCRIPT=$Script_Slurm_Dir/${prefix}.qpbs

    # Usage: java OneDayReports [input file] [output directory]
    #java --classpath "$Java_Dir" OneDayReports $Record_Dir/LargeSmallRecords.txt $Flow_Dir > $Flow_Dir/Log.txt
    #OpenJDK uses -classpath instead of --classpath
    logFile=${prefix}-Log.txt
    #CMD=/usr/bin/java -classpath "$Java_Dir" OneDayReports $Record_Dir/$filterFlowRecFilename $Flow_Dir $prefix > $Flow_Dir/$logFile
    CMD='time /usr/bin/java -classpath '${Java_Dir}' OneDayReports '${Record_Dir}/${filterFlowRecFilename}' '${Flow_Dir}' '${prefix}' > '${Flow_Dir}/${logFile}
    echo $CMD
    rm ${SLURM_SCRIPT}
    echo "#!/bin/sh" > ${SLURM_SCRIPT}
    echo '#SBATCH --nodes=2' >> ${SLURM_SCRIPT} #number of CPU's
    echo '#SBATCH --ntasks-per-node=1' >> ${SLURM_SCRIPT} # irrelevalnt because we want one task in one CPU
    echo '#SBATCH --time=1-00:0:00' >> ${SLURM_SCRIPT} # kills the task if it runs above this time limit
    echo '#SBATCH --mem=16' >> ${SLURM_SCRIPT} # give it more than your task would take
    echo '#SBATCH -o "'${OFILE}'"' >> ${SLURM_SCRIPT}
    echo '#SBATCH -e "'${EFILE}'"' >> ${SLURM_SCRIPT}
    echo '#SBATCH --mail-type=FAIL' >> ${SLURM_SCRIPT}
    echo '#SBATCH --mail-user=sm8kk@virginia.edu' >> ${SLURM_SCRIPT}
    echo ${CMD} >> ${SLURM_SCRIPT}
    sbatch ${SLURM_SCRIPT}
    #continue
    #java -classpath "$Java_Dir" OneDayReports $Record_Dir/sampleFilteredFlowRecords2.txt $Flow_Dir
done < $filterRecordsList
