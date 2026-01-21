process TRANSGENE_CNA {
    tag "${sample_name}"
    publishDir "${params.outdir}/cna_summary/individual", mode: 'copy'
    container 'bumproo/general_genomics:latest'
    
    input:
    tuple val(sample_name), path(coverage_file)
    
    output:
    tuple val(sample_name), path("${sample_name}_cna_summary.csv"), emit: cna_summary
    
    script:
    """
    summarize_cna.py ${sample_name} ${coverage_file} > ${sample_name}_cna_summary.csv
    """
    
    stub:
    """
    echo "Strain_Length,Strain,Length,Transgene,AvgChrCoverage,TransgeneCoverage,TransgeneCopyNumber" > ${sample_name}_cna_summary.csv
    echo "${sample_name},S-1077,500,A-vector,25.5,51.0,2.0" >> ${sample_name}_cna_summary.csv
    """
}
