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

workflow CNA_WORKFLOW {
    take:
    samples_ch  // channel: [ sample_name, fastq_path, transgene ]
    
    main:
    // 1. Filter reads with chopper (maxlength=5000, quality=10)
    CHOPPER(samples_ch)
    
    // 2. Run QC on filtered reads
    NANOPLOT(CHOPPER.out.filtered_reads)
    
    // 3. Prepare combined reference (genome + transgene)
    // Create channel with sample info and reference genome path
    def reference_ch = CHOPPER.out.filtered_reads
        .map { sample_name, _fastq, transgene ->
            tuple(sample_name, transgene, file(params.reference_genome))
        }
    
    COMBINE_REFERENCE(reference_ch)
    
    // 4. Align filtered reads to combined reference with minimap2
    // Combine filtered reads with their corresponding combined reference
    def alignment_input = CHOPPER.out.filtered_reads
        .map { sample_name, fastq, transgene ->
            tuple(sample_name, fastq, transgene)
        }
        .join(
            COMBINE_REFERENCE.out.combined_ref.map { sample_name, ref ->
                tuple(sample_name, ref)
            }
        )
        .map { sample_name, fastq, transgene, ref ->
            tuple(sample_name, fastq, transgene, ref)
        }
    
    MINIMAP2_ALIGN(alignment_input)
    
    // 5. Sort BAM files
    SAMTOOLS_SORT(MINIMAP2_ALIGN.out.bam)
    
    // 6. Index sorted BAM files
    SAMTOOLS_INDEX(SAMTOOLS_SORT.out.sorted_bam)
    
    emit:
    sorted_indexed_bams = SAMTOOLS_INDEX.out.indexed_bam
    nanoplot_results = NANOPLOT.out.nanoplot_results
}
