# Transgene Copy Number Analysis (CNA) Module

## Overview

The `TRANSGENE_CNA` module calculates transgene copy numbers by comparing transgene coverage to average chromosomal coverage from samtools coverage output files.

## Implementation

### Components

1. **Python Script**: `bin/summarize_cna.py`
   - Parses samtools coverage output
   - Calculates average chromosomal coverage
   - Extracts transgene coverage
   - Computes copy number ratio

2. **Nextflow Module**: `modules/local/transgene_cna.nf`
   - Wraps the Python script
   - Uses container: `bumproo/general_genomics:latest`
   - Publishes results to `${params.outdir}/cna_summary/`

### Workflow Integration

The module is integrated as step 8 in the `CNA_WORKFLOW`:

```
SAMTOOLS_COVERAGE → TRANSGENE_CNA
```

Each sample's coverage file is processed independently to generate a CNA summary.

## Output Format

The module generates a CSV file per sample: `{sample_name}_cna_summary.csv`

### Columns

| Column | Description | Calculation |
|--------|-------------|-------------|
| `Strain_Length` | Sample identifier (e.g., S-1312_1000) | From input |
| `AvgChrCoverage` | Average coverage across all chromosomes | Mean of meandepth for all chr* entries |
| `TransgeneCoverage` | Coverage of the transgene | meandepth for non-chr entry |
| `TransgeneCopyNumber` | Estimated copy number | TransgeneCoverage / AvgChrCoverage |

### Example Output

```csv
Strain_Length,AvgChrCoverage,TransgeneCoverage,TransgeneCopyNumber
S-1312_1000,25.38,50.76,2.0000
S-1312_2000,28.42,28.15,0.9905
S-1414_1000,22.91,45.82,2.0000
```

## Interpretation

- **Copy Number ≈ 1.0**: Single integration
- **Copy Number ≈ 2.0**: Two copies (or diploid with one integration per homolog)
- **Copy Number > 2.0**: Multiple integrations or episomal maintenance
- **Copy Number < 1.0**: Partial integration or mixed population

## Technical Details

### Coverage Calculation

The script uses the `meandepth` column from samtools coverage output rather than the `coverage` percentage column. This provides the actual sequencing depth which is more appropriate for copy number calculations.

### Chromosome Identification

- **Chromosomes**: All sequences with names starting with "chr" (e.g., chrI, chrII, chrIII)
- **Transgene**: Any sequence not starting with "chr" (assumed to be the transgene)

### Error Handling

- Missing coverage files generate errors
- Files without chromosomal data result in 0.0 average coverage
- Files without transgene data result in 0.0 transgene coverage
- Division by zero is handled (returns 0.0 copy number)

## Container Requirements

The module uses `bumproo/general_genomics:latest` which includes:
- Python 3.8+
- Standard library (csv, sys, pathlib)

No additional dependencies are required beyond Python's standard library.

## Usage in Workflow

The module automatically processes all samples after coverage calculation:

```nextflow
SAMTOOLS_COVERAGE(SAMTOOLS_INDEX.out.indexed_bam)
TRANSGENE_CNA(SAMTOOLS_COVERAGE.out.coverage)

emit:
cna_summary = TRANSGENE_CNA.out.cna_summary
```

Results are published to `results/cna_summary/` by default.

## Testing

### Stub Mode

The module includes a stub implementation for testing:

```bash
nextflow run main.nf -stub --samples samples.csv \
  --reference_genome ref.fa --transgene_dir transgenes/
```

Stub generates synthetic data with copy number = 2.0.

### Manual Testing

Test the Python script directly:

```bash
python3 bin/summarize_cna.py "Sample_1000" coverage_file.txt
```

## Multi-Threshold Analysis

When running with multiple length thresholds, each threshold generates a separate CNA summary:

```
results/cna_summary/
├── S-1312_100_cna_summary.csv
├── S-1312_200_cna_summary.csv
├── S-1312_500_cna_summary.csv
├── S-1312_1000_cna_summary.csv
└── ...
```

This allows comparison of how filtering stringency affects copy number estimates.
