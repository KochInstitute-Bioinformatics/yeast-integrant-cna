process COMBINE_REFERENCE {
    tag "${sample_name}"
    publishDir "${params.outdir}/combined_references", mode: 'copy'
    
    input:
    tuple val(sample_name), path(reference_genome), path(transgene_file)
    
    output:
    tuple val(sample_name), path("${sample_name}_combined_reference.fasta"), emit: combined_ref
    
    script:
    """
    # Combine reference genome and transgene into single FASTA
    cat ${reference_genome} > ${sample_name}_combined_reference.fasta
    
    # Add transgene as an additional "chromosome"
    cat ${transgene_file} >> ${sample_name}_combined_reference.fasta
    """
    
    stub:
    """
    touch ${sample_name}_combined_reference.fasta
    """
}