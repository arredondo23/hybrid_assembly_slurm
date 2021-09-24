#!/bin/bash

##to debug
#set -e
#set -v
#set -x


conda activate snakemake


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
     echo -e "\n"
     echo "Invalid option: -$OPTARG" >&2
     echo "Check that you have provided all the inputs"
     exit 1
     ;;
   :)
     echo -e "\n"
     echo "Error: Option -$OPTARG requires an argument." >&2
     exit 1
     ;;
 esac
done

if [ -z "$forward" ];
then
    echo -e "\n Error: Oops, it seems that you are missing the Illumina forward files.\n"
    exit
fi

if [ -z "$reverse" ];
then
    echo -e "\n Error: Oops, it seems that you are missing the Illumina reverse files.\n"
    exit
fi

if [ -z "$long" ];
then
    echo -e "\n Error: Oops, it seems that you are missing the ONT reads.\n"
    exit
fi

if [ -z "$coverage" ];
then
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



echo "##################################################################"

cp templates/assembly.yaml templates/"$name"_assembly.yaml
cp templates/template.yaml templates/"$name"_template.yaml


( echo "cat <<EOF >templates/"$name"_assembly.yaml";
  cat templates/"$name"_template.yaml;
  echo "EOF";
) > templates/"$name"_temp.yaml
. templates/"$name"_temp.yaml

#snakemake -n --use-conda -s assembly.smk -p long_read_assembly/"$name"_unicycler 

snakemake \
 --unlock \
 --configfile templates/"$name"_assembly.yaml \
 --snakefile assembly.smk \
 --latency-wait 60 \
 --verbose \
 -p long_read_assembly/"$name"_unicycler \
 --keep-going \
 --restart-times 1 \
 --use-conda \
 --cluster-config config_lsf.json \
 --cluster \
 'bsub -R {cluster.resources} -M {cluster.memory} -q {cluster.queue} -W {cluster.time} -J {cluster.name} -n {cluster.nCPUs} -e {cluster.error} -o {cluster.output}' \
 --jobs 10 2>&1


snakemake \
 --configfile templates/"$name"_assembly.yaml \
 --snakefile assembly.smk \
 --latency-wait 60 \
 --verbose \
 -p long_read_assembly/"$name"_unicycler \
 --keep-going \
 --restart-times 1 \
 --use-conda \
 --cluster-config config_lsf.json \
 --cluster \
 'bsub -R {cluster.resources} -M {cluster.memory} -q {cluster.queue} -W {cluster.time} -J {cluster.name} -n {cluster.nCPUs} -e {cluster.error} -o {cluster.output}' \
 --jobs 10 2>&1

