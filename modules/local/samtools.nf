process SAMTOOLS_SORT {
    tag "${sample_name}"
    publishDir "${params.outdir}/sorted_bams", mode: 'copy'
    
    input:
    tuple val(sample_name), path(bam)
    
    output:
    tuple val(sample_name), path("${sample_name}_sorted.bam"), emit: sorted_bam
    
    script:
    """
    samtools sort -@ ${task.cpus} -o ${sample_name}_sorted.bam ${bam}
    """
    
    stub:
    """
    touch ${sample_name}_sorted.bam
    """
}

process SAMTOOLS_INDEX {
    tag "${sample_name}"
    publishDir "${params.outdir}/sorted_bams", mode: 'copy'
    
    input:
    tuple val(sample_name), path(sorted_bam)
    
    output:
    tuple val(sample_name), path(sorted_bam), path("${sorted_bam}.bai"), emit: indexed_bam
    
    script:
    """
    samtools index -@ ${task.cpus} ${sorted_bam}
    """
    
    stub:
    """
    touch ${sorted_bam}.bai
    """
}
