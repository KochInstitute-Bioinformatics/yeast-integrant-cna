process COMBINE_REFERENCE {
    tag "${transgene}"
    publishDir "${params.outdir}/combined_references", mode: 'copy'
    
    input:
    tuple val(transgene), path(reference_genome), path(transgene_file)
    
    output:
    tuple val(transgene), path("${transgene}_combined_reference.fasta"), emit: combined_ref
    
    script:
    """
    # Combine reference genome and transgene into single FASTA
    cat ${reference_genome} > ${transgene}_combined_reference.fasta
    
    # Add transgene as an additional "chromosome"
    cat ${transgene_file} >> ${transgene}_combined_reference.fasta
    """
    
    stub:
    """
    touch ${transgene}_combined_reference.fasta
    """
}