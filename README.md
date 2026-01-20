# yeast-integrant-cna

Oxford Nanopore workflow for calculating copy numbers of yeast chromosomes and plasmids.

This simplified workflow filters ONT reads, combines reference genomes with transgene sequences, aligns reads with minimap2, and produces sorted/indexed BAM files for IGV visualization.

## Overview

This pipeline is a streamlined off-shoot of the [yeast-integrant-eval](https://github.com/KochInstitute-Bioinformatics/yeast-integrant-eval) workflow, focusing specifically on copy number analysis without the assembly and evaluation steps.

### Workflow Steps

1. **Read Filtering (Chopper)**: Filters ONT reads with max length of 5000bp and minimum quality of 10
2. **Quality Control (NanoPlot)**: Generates QC metrics and plots for filtered reads
3. **Reference Preparation**: Combines reference genome with sample-specific transgene into a single FASTA file
4. **Alignment (minimap2)**: Aligns filtered reads to combined reference using ONT-specific preset
5. **BAM Processing (samtools)**: Sorts and indexes BAM files for IGV visualization

## Requirements

- Nextflow (>=23.04.0)
- Singularity or Conda
- SLURM cluster (for production runs)

## Quick Start

### 1. Prepare your samples CSV

Create a `samples.csv` file with the following format:

```csv
name,fastq,transgene
S-1312,/path/to/sample1.fastq,A-vector_herceptin_pEY345
S-1414,/path/to/sample2.fastq,A-vector_herceptin_pEY345
S-2133,/path/to/sample3.fastq,A-vector_herceptin_pEY345
```

**Required columns:**
- `name`: Sample identifier
- `fastq`: Full path to input FASTQ file
- `transgene`: Name of transgene (must match filename in transgene_dir without .fasta extension)

### 2. Configure your environment

Edit `custom.config` to match your environment:

```groovy
params {
    samples = "/path/to/samples.csv"
    transgene_dir = "/path/to/transgenes"
    reference_genome = "/path/to/reference.fa"
    outdir = "/path/to/output"
}
```

### 3. Run the pipeline

**Local execution (testing):**
```bash
nextflow run main.nf \
    --samples samples.csv \
    --reference_genome /path/to/reference.fa \
    --transgene_dir /path/to/transgenes \
    --outdir results
```

**Cluster execution with custom config:**
```bash
nextflow run main.nf -c custom.config
```

## Output Structure

```
results/
├── selected_fastq/          # Filtered FASTQ files
│   └── {sample}_filtered.fastq
├── nanoplot/                # QC reports for filtered reads
│   └── {sample}/
│       ├── NanoStats.txt
│       └── *.html, *.png
├── combined_references/     # Reference + transgene FASTA files
│   └── {sample}_combined_reference.fasta
├── alignments/              # Unsorted BAM files
│   └── {sample}.bam
├── sorted_bams/             # Final sorted and indexed BAMs for IGV
│   ├── {sample}_sorted.bam
│   └── {sample}_sorted.bam.bai
└── pipeline_info/           # Execution reports
    ├── execution_timeline.html
    ├── execution_report.html
    ├── execution_trace.txt
    └── pipeline_dag.svg
```

## Parameters

### Required Parameters

| Parameter | Description |
|-----------|-------------|
| `--samples` | Path to CSV file with sample information |
| `--reference_genome` | Path to reference genome FASTA file |
| `--transgene_dir` | Directory containing transgene FASTA files |

### Optional Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `--outdir` | `results` | Output directory |
| `--min_quality` | `10` | Minimum quality score for read filtering |
| `--max_length` | `5000` | Maximum read length for filtering |

## Visualizing Results in IGV

1. Open IGV (Integrative Genomics Viewer)
2. Load the combined reference: `File > Load Genome from File > {sample}_combined_reference.fasta`
3. Load the sorted BAM: `File > Load from File > {sample}_sorted.bam`
4. Navigate to chromosomes or transgene to visualize coverage and copy numbers

The transgene will appear as an additional "chromosome" in the alignment, allowing you to assess both genomic and plasmid copy numbers simultaneously.

## Container Images

The pipeline uses the following containers:

- **Chopper/NanoPlot**: `bumproo/nanoplotchopper`
- **minimap2**: `quay.io/biocontainers/minimap2:2.26--he4a0461_2`
- **samtools**: `quay.io/biocontainers/samtools:1.18--h50ea8bc_1`

## Troubleshooting

### Transgene file not found

Ensure transgene FASTA files are named correctly in `transgene_dir`:
- CSV: `transgene_name` → File: `{transgene_dir}/transgene_name.fasta`

### Memory issues

Adjust process resources in `nextflow.config` or `custom.config`:

```groovy
process {
    withName: 'MINIMAP2_ALIGN' {
        memory = '32 GB'
        cpus = 16
    }
}
```

### SLURM queue issues

Check your SLURM configuration in `custom.config`:

```groovy
process {
    executor = 'slurm'
    queue = 'your_queue_name'
}
```

## Differences from yeast-integrant-eval

This workflow **removes**:
- Flye assembly and preflight checks
- Assembly evaluation steps
- Downsampling and bootstrap replicates
- BLAST-based transgene detection
- Multiple size range filtering

This workflow **adds**:
- Direct reference + transgene combination
- Streamlined alignment workflow
- Focus on BAM output for visualization

## Citation

If you use this workflow, please cite:
- [minimap2](https://github.com/lh3/minimap2)
- [samtools](http://www.htslib.org/)
- [NanoPlot](https://github.com/wdecoster/NanoPlot)
- [chopper](https://github.com/wdecoster/chopper)

## License

This workflow is provided as-is for research purposes.

## Contact

For issues or questions, please open an issue on the repository.
