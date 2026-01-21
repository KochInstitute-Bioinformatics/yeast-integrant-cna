#!/usr/bin/env nextflow

/*
 * Yeast Integrant Copy Number Analysis Pipeline
 * 
 * Simplified workflow for calculating copy numbers of yeast chromosomes
 * and plasmids using Oxford Nanopore data.
 */

nextflow.enable.dsl = 2

// Include the main workflow
include { CNA_WORKFLOW } from './workflows/cna_workflow'

// Help message
def helpMessage() {
    log.info"""
    ===================================
    yeast-integrant-cna Pipeline
    ===================================
    
    Usage:
    nextflow run main.nf --samples <samples.csv> -c <custom.config>
    
    Required arguments:
      --samples               Path to CSV file with columns: name,fastq,transgene
      --reference_genome      Path to reference genome FASTA file
      --transgene_dir         Directory containing transgene FASTA files
      
    Optional arguments:
      --outdir                Output directory (default: results)
      --min_quality           Minimum quality score for filtering (default: 10)
      --length_thresholds     Array of max read lengths to test (default: [100, 200, 500, 750, 1000, 2000, 5000])
      --help                  Show this help message
    
    Example CSV format (samples.csv):
      name,fastq,transgene
      S-1312,/path/to/sample1.fastq,A-vector_herceptin_pEY345
      S-1414,/path/to/sample2.fastq,A-vector_herceptin_pEY345
    
    Example command:
      nextflow run main.nf \\
        --samples samples.csv \\
        -c custom.config
    
    """.stripIndent()
}

// Main workflow
workflow {
    // Show help if requested
    if (params.help) {
        helpMessage()
        exit 0
    }
    
    // Validate required parameters
    if (!params.samples) {
        error "ERROR: Please specify --samples parameter"
    }
    
    if (!params.reference_genome) {
        error "ERROR: Please specify --reference_genome parameter"
    }
    
    if (!params.transgene_dir) {
        error "ERROR: Please specify --transgene_dir parameter"
    }
    
    // Read samples from CSV and expand with length thresholds
    def samples_ch = channel
        .fromPath(params.samples)
        .splitCsv(header: true)
        .map { row ->
            tuple(row.name, file(row.fastq), row.transgene)
        }
        .combine(channel.fromList(params.length_thresholds))
        .map { sample_name, fastq, transgene, length_threshold ->
            tuple("${sample_name}_${length_threshold}", fastq, transgene, length_threshold)
        }
    
    // Run the workflow
    CNA_WORKFLOW(samples_ch)
    
    // Workflow completion message
    workflow.onComplete {
        log.info """
        ===================================
        Pipeline completed!
        ===================================
        Status:    ${workflow.success ? 'SUCCESS' : 'FAILED'}
        Duration:  ${workflow.duration}
        Output:    ${params.outdir}
        ===================================
        """.stripIndent()
    }
}
