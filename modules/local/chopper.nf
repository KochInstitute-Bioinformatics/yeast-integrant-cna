process CHOPPER {
    tag "${sample_name}"
    publishDir "${params.outdir}/selected_fastq", mode: 'copy'
    
    input:
    tuple val(sample_name), path(fastq_file), val(transgene)
    
    output:
    tuple val(sample_name), path("${sample_name}_filtered.fastq"), val(transgene), emit: filtered_reads
    
    script:
    def quality = params.min_quality ?: 10
    def max_length = params.max_length ?: 5000
    
    """
    chopper -q ${quality} \\
        -l 0 \\
        -u ${max_length} \\
        -i ${fastq_file} > ${sample_name}_filtered.fastq
    """
    
    stub:
    """
    touch ${sample_name}_filtered.fastq
    """
}
