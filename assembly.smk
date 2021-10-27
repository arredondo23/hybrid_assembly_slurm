rule trimming:
    input:
        fw=config["forward"],
        rv=config["reverse"]
    output:
        trim=directory("trimmed_reads/{name}_trimgalore")
    params:
        phred=config["phred_score"],
        name=config["name"]
    message:
        "Trimming the short-reads {input}"
    log:
        "logs/{name}_log_ontpart.txt"
    shell:
        "trim_galore --paired --quality {params.phred} --basename {params.name} --output_dir {output.trim} {input.fw} {input.rv}"

rule shortreadassembly:
    input:
        trim=directory("trimmed_reads/{name}_trimgalore")
    output:
        unicycler_dir=directory("short_read_assembly/{name}_unicycler"),
    params:
        mode=config["unicycler_mode"],
        name=config["name"]
    message:
        "Short read assembly using trimmed reads {input}"
    log:
        "logs/{name}_log_ontpart.txt"
    shell:
        "unicycler -1 trimmed_reads/{params.name}_trimgalore/{params.name}_val_1.fq.gz -2 trimmed_reads/{params.name}_trimgalore/{params.name}_val_2.fq.gz --mode {params.mode} --threads 16 --keep 2 -o {output.unicycler_dir}"

rule bioawkgenomesize:
    input:
        contigs=directory("short_read_assembly/{name}_unicycler")
    output:
        seq_length="bioawk/{name}_seq_length.txt"
    params:
        name=config["name"]
    message:
        "Calculating the genome size based on the assembly given by Unicycler using short-reads"
    shell:
        """bioawk -c fastx '{{ print $name, length($seq) }}' < short_read_assembly/{params.name}_unicycler/assembly.fasta > {output.seq_length} """

rule sumgenomesize:
    input:
        seq_length="bioawk/{name}_seq_length.txt"
    output:
        sum_genome="bioawk/{name}_total_genome.txt"
    message:
        "Sum of the genome size based on the assembly given by Unicycler using short-reads"
    shell:
        """awk '{{ sum += $2; }} END {{ print sum; }}' {input.seq_length} > {output.sum_genome} """

rule totalbp:
    input:
        sum_genome="bioawk/{name}_total_genome.txt"
    output:
        desired_bp="bioawk/{name}_desired_bp.txt"
    params:
        desired_coverage=config["coverage"]
    message:
        "Calculating the bp desired based on the coverage"
    shell:
        "genome_size=$(cat {input.sum_genome})"
        " && expr {params.desired_coverage} \* $genome_size > {output.desired_bp}"

rule porechop:	
    output:
        porechop_reads="porechop/{name}_porechop_long.fastq.gz"
    params:
        name=config["name"],
        long_reads=config["long"]
    message:
        "Trimming ONT barcodes"
    shell:
        "porechop -i {params.long_reads} -o {output.porechop_reads}"

rule filtlong:
    input:
        trim=directory("trimmed_reads/{name}_trimgalore"),
        long_reads="porechop/{name}_porechop_long.fastq.gz",
        desired_bp="bioawk/{name}_desired_bp.txt"
    params:
        name=config["name"]
    output:
        gzip_reads="filtlong/{name}_filt_long.fastq.gz"
    message:
        "Filtering the long reads using the coverage specified"
    shell:
        "size=$(cat {input.desired_bp})"
        " && filtlong -1 trimmed_reads/{params.name}_trimgalore/{params.name}_val_1.fq.gz -2 trimmed_reads/{params.name}_trimgalore/{params.name}_val_2.fq.gz \
        --min_length 1000 --keep_percent 90 --mean_q_weight 20 \
        --target_bases $size {input.long_reads} | gzip > {output.gzip_reads}"

rule longreadassembly:
    input:
        trim=directory("trimmed_reads/{name}_trimgalore"),
        filt_long_reads="filtlong/{name}_filt_long.fastq.gz"
    output:
        long_unicycler_dir=directory("long_read_assembly/{name}_unicycler")
    params:
        mode=config["unicycler_mode"],
        name=config["name"]
    message:
        "Using Unicycler with long reads"
    log:
        "logs/{name}_log_ontpart.txt"
    shell:
        "unicycler -1 trimmed_reads/{params.name}_trimgalore/{params.name}_val_1.fq.gz -2 trimmed_reads/{params.name}_trimgalore/{params.name}_val_2.fq.gz -l {input.filt_long_reads} --mode {params.mode} --threads 32 --keep 2 -o {output.long_unicycler_dir}"
