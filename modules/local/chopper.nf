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
    # Run chopper - reads from stdin, writes to stdout
    cat ${fastq_file} | chopper -q ${quality} \\
        -l 0 \\
        --maxlength ${max_length} > ${sample_name}_filtered.fastq
    
    # Check output
    echo "Filtered ${sample_name}: \$(wc -l < ${sample_name}_filtered.fastq) lines"
    """
    
    stub:
    """
    touch ${sample_name}_filtered.fastq
    """
}