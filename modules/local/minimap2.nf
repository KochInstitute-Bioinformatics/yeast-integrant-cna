process MINIMAP2_ALIGN {
    tag "${sample_name}"
    
    input:
    tuple val(sample_name), path(fastq_file), val(transgene), path(reference)
    
    output:
    tuple val(sample_name), path("${sample_name}.bam"), emit: bam
    
    script:
    """
    # Align reads with minimap2 using ONT preset and convert to BAM
    minimap2 -ax map-ont -t ${task.cpus} \\
        ${reference} \\
        ${fastq_file} | \\
        samtools view -b -@ ${task.cpus} -o ${sample_name}.bam
    """
    
    stub:
    """
    touch ${sample_name}.bam
    """
}