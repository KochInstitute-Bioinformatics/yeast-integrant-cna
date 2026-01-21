process SAMTOOLS_COVERAGE {
    tag "${sample_name}"
    publishDir "${params.outdir}/coverage", mode: 'copy'
    
    input:
    tuple val(sample_name), path(sorted_bam), path(bam_index)
    
    output:
    tuple val(sample_name), path("${sample_name}_coverage.txt"), emit: coverage
    
    script:
    """
    samtools coverage -Q 10 --ff 2048 --ff 256 ${sorted_bam} > ${sample_name}_coverage.txt
    """
    
    stub:
    """
    echo -e "#rname\\tstartpos\\tendpos\\tnumreads\\tcovbases\\tcoverage\\tmeandepth\\tmeanbaseq\\tmeanmapq" > ${sample_name}_coverage.txt
    echo -e "chr1\\t1\\t1000\\t100\\t1000\\t100\\t50.5\\t30\\t60" >> ${sample_name}_coverage.txt
    """
}
