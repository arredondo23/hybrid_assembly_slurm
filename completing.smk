rule total_bp:
    input:
        sum_genome="bioawk/{name}_total_genome.txt"
    output:
        desired_bp="bioawk/{name}_path_desired_bp.txt"
    params:
        desired_coverage=config["coverage"]
    conda:
        "hybrid_assembly.yaml"
    message:
        "Calculating the bp desired based on the coverage"
    shell:
        "genome_size=$(cat {input.sum_genome})"
        " && expr {params.desired_coverage} \* $genome_size > {output.desired_bp}"

rule extracting_contigs:
    input:
        "long_read_assembly/{name}_unicycler/assembly.gfa"
    output:
        "path_to_complete/{name}_nodes_from_graph.fasta"
    message:
        "Extracting the nodes from the graph"
    conda:
        "r_packages.yaml"
    log:
        "logs/{name}_log_nodes.txt"
    shell:
        """awk '{{if($1 == "S") print ">"$1$2"_"$4"_"$5"\\n"$3}}' {input}  1>> {output} 2>> {log}"""

rule extracting_links:
    input:
        "long_read_assembly/{name}_unicycler/assembly.gfa"
    output:
        "path_to_complete/{name}_links_from_graph.fasta"
    message:
        "Extracting the links from the graph {input}"
    conda:
        "r_packages.yaml"
    log:
        "logs/{name}_log_links.txt"
    shell:
        """awk -F "\\t" '{{if($1 == "L") print $N}}' {input}  1>> {output} 2>> {log}"""

rule path_retrieval:
    input:
        nodes="path_to_complete/{name}_nodes_from_graph.fasta",
        links="path_to_complete/{name}_links_from_graph.fasta"
    conda:
        "r_packages.yaml"
    output:
        nodes_to_complete="path_to_complete/{name}_nodes_to_complete.fasta"
    script:
        "completing_paths.R"

rule filtlong:
    input:
        path_completion="path_to_complete/{name}_nodes_to_complete.fasta",
        desired_bp="bioawk/{name}_path_desired_bp.txt"
    params:
        long_reads=config["long"]
    conda:
        "hybrid_assembly.yaml"
    output:
        gzip_reads="filtlong/{name}_completion_filt_long.fastq.gz"
    message:
        "Filtering the long reads using the coverage specified"
    shell:
        "size=$(cat {input.desired_bp})"
        " && filtlong -a {input.path_completion} \
        --min_length 500 --keep_percent 90 --mean_q_weight 20 \
	--target_bases $size {params.long_reads} | gzip > {output.gzip_reads}"

rule combine_fastq:
     input:
        original_fastq="filtlong/{name}_filt_long.fastq.gz",
        path_fastq="filtlong/{name}_completion_filt_long.fastq.gz"
     output:
        "filtlong/{name}_combination_long.fastq.gz"
     params:
        name=config["name"]
     message:
        "Combining the set of long-reads"
     shell:
        "gunzip {input.original_fastq}"
        "&& gunzip {input.path_fastq}"
        "&& cat filtlong/{params.name}*.fastq > {output}"
        "&& gzip filtlong/{params.name}*.fastq"

rule long_read_assembly:
    input:
        trimfw="trimmed_reads/{name}_trimgalore/{name}_val_1.fq.gz",
        trimrv="trimmed_reads/{name}_trimgalore/{name}_val_2.fq.gz",
        combi_long_reads="filtlong/{name}_combination_long.fastq.gz"
    output:
        long_unicycler_dir=directory("long_read_assembly/{name}_path_unicycler")
    params:
        mode=config["unicycler_mode"],
        name=config["name"]
    message:
        "Using Unicycler with the combination of long reads"
    conda:
        "hybrid_assembly.yaml"
    log:
        "logs/{name}_log_ontpart.txt"
    shell:
        "unicycler -1 {input.trimfw} -2 {input.trimrv} -l {input.combi_long_reads} \
         --mode {params.mode} --start_genes replicon_database.fasta --keep 2 \
         -o {output.long_unicycler_dir}"       
        

