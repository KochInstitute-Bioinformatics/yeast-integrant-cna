/*
 * Yeast Integrant Copy Number Analysis Workflow
 * 
 * This workflow processes Oxford Nanopore data to calculate copy numbers
 * of yeast chromosomes and plasmids.
 */

include { CHOPPER } from '../modules/local/chopper'
include { NANOPLOT } from '../modules/local/nanoplot'
include { COMBINE_REFERENCE } from '../modules/local/combine_reference'
include { MINIMAP2_ALIGN } from '../modules/local/minimap2'
include { SAMTOOLS_SORT; SAMTOOLS_INDEX } from '../modules/local/samtools'
include { SAMTOOLS_COVERAGE } from '../modules/local/coverage'
include { TRANSGENE_CNA } from '../modules/local/transgene_cna'

workflow CNA_WORKFLOW {
    take:
    samples_ch  // channel: [ sample_name, fastq_path, transgene, length_threshold ]
    
    main:
    // 1. Filter reads with chopper (using length_threshold parameter)
    CHOPPER(samples_ch)
    
    // 2. Run QC on filtered reads
    NANOPLOT(CHOPPER.out.filtered_reads)
    
    // 3. Prepare combined reference (genome + transgene) - only once per unique transgene
    // Extract unique transgenes and create references
    def unique_transgenes_ch = samples_ch
        .map { _sample_name, _fastq, transgene, _length_threshold ->
            transgene
        }
        .unique()
        .map { transgene ->
            def transgene_file = file("${params.transgene_dir}/${transgene}.fa")
            if (!transgene_file.exists()) {
                error "Transgene file not found: ${transgene_file}\nExpected path: ${params.transgene_dir}/${transgene}.fa\nPlease check that the transgene name in your samples file matches the filename in ${params.transgene_dir}/"
            }
            tuple(transgene, file(params.reference_genome), transgene_file)
        }
    
    COMBINE_REFERENCE(unique_transgenes_ch)
    
    // 4. Align filtered reads to combined reference with minimap2
    // Join filtered reads with their corresponding combined reference using transgene as key
    def alignment_input = CHOPPER.out.filtered_reads
        .map { sample_name, fastq, transgene ->
            tuple(transgene, sample_name, fastq)
        }
        .combine(COMBINE_REFERENCE.out.combined_ref, by: 0)
        .map { transgene, sample_name, fastq, ref ->
            tuple(sample_name, fastq, transgene, ref)
        }
    
    MINIMAP2_ALIGN(alignment_input)
    
    // 5. Sort BAM files
    SAMTOOLS_SORT(MINIMAP2_ALIGN.out.bam)
    
    // 6. Index sorted BAM files
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.sorted_bam)
    
    // 7. Calculate coverage statistics per chromosome/transgene
    SAMTOOLS_COVERAGE(SAMTOOLS_INDEX.out.indexed_bam)
    
    // 8. Calculate transgene copy number analysis
    TRANSGENE_CNA(SAMTOOLS_COVERAGE.out.coverage)
    
    emit:
    sorted_indexed_bams = SAMTOOLS_INDEX.out.indexed_bam
    coverage_results = SAMTOOLS_COVERAGE.out.coverage
    cna_summary = TRANSGENE_CNA.out.cna_summary
    nanoplot_results = NANOPLOT.out.nanoplot_results
}