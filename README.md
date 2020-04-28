__**Hybrid Assembly: Unicycler + Snakemake + HPC**__


----


__**Intro**: What are we trying to achieve?__

In order to perform hybrid assemblies, we came up with a Snakemake pipeline that integrates different steps:

  - **Trimming** Illumina reads with //trim_galore// 
  - Perform a **first short-read assembly** using //Unicycler//. It will only run //SPAdes// but will generate a *.fasta file from which we can estimate the genome size of the isolate. 
  - Calculate the **genome size** of the isolate using //bioawk//. 
  - **Filter ONT reads** using //filtlong// indicating the quality filtering the Illumina reads and indicating the **coverage** specified by the user. This is why the calculation of the genome size it is important. 
  - Perform a **hybrid assembly** using //Unicycler// using the trimmed Illumina reads and filtered ONT reads.


----


__**Before starting**__

First, you need to retrieve all the files required (snakemake files, yaml files for conda...). You can clone the following repo:

<code> git clone https://gitlab.com/mmb-umcu/hybrid_assembly.git </code>

__Ok, now let's go to the hpc!__ 

Do you have your own miniconda installation? The following command should point to your user. 

<code> which conda </code> 

Then, create a separate environment with snakemake. 
<code> conda activate my_env_with_snakemake </code>
<code> snakemake </code>

This environment is important since it will be the first one used in the pipeline to throw Snakemake. If there is no snakemake, it won't run the assembly. 

----

__**Modifying bash wrappers with your hpc credentials**__


**IMPORTANT!** There are two scripts that you need to modify by replacing the paths in which the logs from hpc jobs are going to be stored and also the mail that is going to use. Line 140 and 139 from the below files can also be changed depending on the job requirements that you need, if the long-read assembly is going to take a lot of time you can increase the time and memory in these lines.  

  * runassembly.sh (lines 4 to 10, lines 19 and 20, and line 141)
  * completeassembly.sh (lines 4 to 10, line 19 and 20, and line 143)

**Line 19 points to the your conda environment in which you have installed snakemake**

**Line 20 points to the path in which you have your git repo** 



----


__**Running a hybrid assembly**__

So if you want to run the pipeline, we created a bash wrapper that you should use in the following way:

<code> sbatch runassembly.sh -f path_forward_Illumina.fastq.gz -r path_reverse_Illumina.fastq.gz -l path_long_reads.fastq.gz -c 20 -p 20 -n name_isolate </code>

The arguments are the following:

  * '-f'. Path to the short forward reads
  * '-r'. Path to the short reverse reads
  * '-l'. Path to the long reads
  * '-c'. Integer. Coverage desired to filter out ONT reads. Higher coverage will take more time since Unicycler will need to map more reads into the graph. Start with something around 20 and only repeat with a higher coverage if you get some non-circular contigs in the ends.  
  * '-n'. Name of the isolate

Basically this will generate: 

  - A mini job in the hpc in which the Snakemake pipeline is run 
  - A job per each rule present in the Snakemake pipeline. 
  - A log file per each job run in the hpc. 

The assembly file (*.gfa or *.fasta) with the hybrid assembly will be present in the folder:

  * long_read_assembly/name_isolate_unicycler

You can check the completion of the assembly by: 

<code> grep '>' long_read_assembly/name_isolate_unicycler/assembly.fasta  </code>

If all the contigs popping up have a flag saying 'circular=True', it means that you have a perfect assembly, great take a coffee. 


----


__**Uncompleted assemblies**__

If you get uncircularised contigs in the final assembly, you can run the second bash script: 

<code> sbatch completeassembly.sh -f path_forward_Illumina.fastq.gz -r path_reverse_Illumina.fastq.gz -l path_long_reads.fastq.gz -c 5 -p 20 -n name_isolate </code>

This script will take the contigs 'uncircularised' from the graph, and take as many reads as indicated in the coverage (in the example 5). These reads will be combined with the reads that we used before. In this way we hope to put some extra reads in the uncompleted path that can help Unicycler to bridge it. The new results will be present as: 

  * long_read_assembly/name_isolate_path_unicycler/assembly.fasta 

If after this, you still get uncircularised contigs. There are two scenarios possible: 

  * You have a linear plasmid. This can be the case if the contig is a completely independent component in the graph. 
  * You need to increase the coverage. If that is the case, run 'runassembly.sh' with a coverage (flag -c) higher than 20. This is the case if you have a component in the graph in which you have several contigs connected by a link. 


----

