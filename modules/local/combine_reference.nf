process COMBINE_REFERENCE {
    tag "${sample_name}"
    publishDir "${params.outdir}/combined_references", mode: 'copy'
    
    input:
    tuple val(sample_name), val(transgene), path(reference_genome)
    
    output:
    tuple val(sample_name), path("${sample_name}_combined_reference.fasta"), emit: combined_ref
    
    script:
    def transgene_file = "${params.transgene_dir}/${transgene}.fasta"
    
    """
    # Combine reference genome and transgene into single FASTA
    cat ${reference_genome} > ${sample_name}_combined_reference.fasta
    
    # Add transgene as an additional "chromosome"
    if [ -f "${transgene_file}" ]; then
        cat ${transgene_file} >> ${sample_name}_combined_reference.fasta
    else
        echo "Warning: Transgene file ${transgene_file} not found" >&2
        echo ">transgene_placeholder" >> ${sample_name}_combined_reference.fasta
        echo "N" >> ${sample_name}_combined_reference.fasta
    fi
    """
    
    stub:
    """
    touch ${sample_name}_combined_reference.fasta
    """
}
