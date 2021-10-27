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

<code> git clone -b sanger https://github.com/arredondo23/hybrid_assembly_slurm.git </code>

__Ok, now let's go to the farm server!__ 

Do you have your own miniconda installation? The following command should point to your user. 

<code> which conda </code> 

Then, create a separate environment with snakemake. 
<code> conda env create -f hybrid_assembly.yml </code>

This environment is important since it will be the first one used in the pipeline to throw Snakemake. If there is no snakemake, it won't run the assembly. 

----

__**Modifying bash wrappers with your own path**__


----


__**Running a hybrid assembly**__

So if you want to run the pipeline, we created a bash wrapper that you should use in the following way:

<code> bsub -R "select[mem>500] rusage[mem=500]" -M 500 -hl -W 05:10 -o assembly.out -e assembly.err -n 1 -q normal -J checking "bash runassembly.sh -f path_forward_Illumina.fastq.gz -r path_reverse_Illumina.fastq.gz -l path_long_reads.fastq.gz -n name_isolate -c 40 -p 20" </code>

The arguments are the following:

  * '-f'. Path to the short forward reads
  * '-r'. Path to the short reverse reads
  * '-l'. Path to the long reads
  * '-c'. Integer. Coverage desired to filter out ONT reads. Higher coverage will take more time since Unicycler will need to map more reads into the graph  
  * '-n'. Name of the isolate

Basically this will generate: 

  - A mini job in the farm server in which the Snakemake pipeline is run 
  - A job per each rule present in the Snakemake pipeline. 
  - A log file per each job run in the farm server. 

The assembly file (*.gfa or *.fasta) with the hybrid assembly will be present in the folder:

  * long_read_assembly/name_isolate_unicycler

You can check the completion of the assembly by: 

<code> grep '>' long_read_assembly/name_isolate_unicycler/assembly.fasta  </code>

If all the contigs popping up have a flag saying 'circular=True', it means that you have a perfect assembly, great take a coffee. 


----

