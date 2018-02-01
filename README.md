# slurmForCSCluster
An example of a slurm script for use in a cluster using a SLURM scheduler

Run this script from a power system, and an executable in "CMD" is run in each
node from the cluster.


The while loop causes each command "CMD" to be run in a different node in the cluster.
For every command it autogenerates a slurm script *qpbs and executes this script using sbatch.
Remember to have different names for log files as well as input and output error logs. 
