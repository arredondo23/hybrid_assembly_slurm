#!/bin/bash

## SGQ queue arguments
#$ -cwd                          ## change directory to the current directory
#$ -o /hpc/dla_mm/salonso/Faecalis_project/Faecalis_Snakemake                ## log files
#$ -e /hpc/dla_mm/salonso/Faecalis_project/Faecalis_Snakemake                ## log files
#$ -l h_vmem=2G                 ##memory request
#$ -m e                          ## When to send alerts b=beginning, e=end, a=abort, s=suspend
#$ -M S.ArredondoAlonso@umcutrecht.nl  ## email address for alerts
#$ -l h_rt=05:00:00               ##time slot requested
#$ -N complete_BRA3676


##to debug
#set -e
#set -v
#set -x

########################################
## A bash script to run the gplas pipeline
## This script has been converted and transformed from the script present in the gitlab repo 'bactofidia' by aschuerch

while getopts ":f:r::l:p:m:c:n:h" opt; do
 case $opt in
   h)
   echo -e "Let's do some hybrid assemblies\n"
   exit
   ;;
   f)
     forward=$OPTARG
     ;;
   r)
     reverse=$OPTARG
     ;;
   l)
     long=$OPTARG
     ;;
   p)
     phred_score=$OPTARG
     ;;
   c)
     coverage=$OPTARG
     ;;
   n)
     name=$OPTARG
     ;;
   h)
     help=$OPTARG
     ;;
   \?)
     ./gplas.sh -h
     echo -e "\n"
     echo "Invalid option: -$OPTARG" >&2
     echo "Check that you have provided all the inputs"
     exit 1
     ;;
   :)
     ./gplas.sh -h
     echo -e "\n"
     echo "Error: Option -$OPTARG requires an argument." >&2
     exit 1
cp templates/assembly.yaml templates/"$name"_assembly.yaml
cp templates/template.yaml templates/"$name"_template.yaml
     ;;
 esac
done

if [ -z "$forward" ];
then
    ./gplas.sh -h
    echo -e "\n Error: Oops, it seems that you are missing the Illumina forward files.\n"
    exit
fi

if [ -z "$reverse" ];
then
    ./gplas.sh -h
    echo -e "\n Error: Oops, it seems that you are missing the Illumina reverse files.\n"
    exit
fi

if [ -z "$long" ];
then
    ./gplas.sh -h
    echo -e "\n Error: Oops, it seems that you are missing the ONT reads.\n"
    exit
fi

if [ -z "$coverage" ];
then
    ./gplas.sh -h
    echo -e "\n Error: Oops, it seems that you are missing the coverage that you want to use to subset the ONT reads.\n"
    exit
fi

if [ -z "$phred_score" ];
then
    echo -e "A phred score of 20 will be used to trim the Illumina reads\n"
    phred_score=20
fi

if [ -z "$mode" ];
then
    echo -e "Unicycler will be run using normal mode\n"
    mode="normal"
fi


if [ -z "$mode" ];
then
    mode="normal"
fi

cp templates/assembly.yaml templates/"$name"_path_assembly.yaml
cp templates/template.yaml templates/"$name"_path_template.yaml


echo "##################################################################"

( echo "cat <<EOF >templates/"$name"_path_assembly.yaml";
  cat templates/"$name"_path_template.yaml;
  echo "EOF";
) > templates/"$name"_path_temp.yaml
. templates/"$name"_path_temp.yaml

#snakemake -n --use-conda -s assembly.smk -p long_read_assembly/"$name"_unicycler 

snakemake \
 --configfile templates/"$name"_path_assembly.yaml \
 --snakefile completing.smk \
 --latency-wait 60 \
 --verbose \
 --forceall \
 -p long_read_assembly/"$name"_path_unicycler \
 --keep-going \
 --restart-times 1\
 --use-conda \
 --cluster \
 'qsub -V -cwd -l h_vmem=32G -l h_rt=10:00:00 -e /hpc/dla_mm/salonso/Faecalis_project/Faecalis_Snakemake -o /hpc/dla_mm/salonso/Faecalis_project/Faecalis_Snakemake -M S.ArredondoAlonso@umcutrecht.nl' \
 --jobs 10 2>&1

