# Multi-Length Threshold Testing Implementation

## Overview
This document describes the implementation of multi-length threshold testing for the yeast-integrant-cna pipeline. The workflow now tests multiple read length filtering thresholds for each sample to help optimize the filtering parameters.

## What Changed

### 1. Configuration (`nextflow.config`)
Added a new parameter to specify which length thresholds to test:
```groovy
// Length thresholds to test
length_thresholds = [100, 200, 500, 750, 1000, 2000, 5000]
```

You can customize this array in your custom config file or via command line:
```bash
--length_thresholds '[100,500,1000]'
```

### 2. Sample Expansion (`main.nf`)
The workflow now automatically expands each sample with all length thresholds:

**Before:**
- Input: `S-1312` → Output: `S-1312_filtered.fastq`

**After:**
- Input: `S-1312` → Output: 
  - `S-1312_100_filtered.fastq`
  - `S-1312_200_filtered.fastq`
  - `S-1312_500_filtered.fastq`
  - `S-1312_750_filtered.fastq`
  - `S-1312_1000_filtered.fastq`
  - `S-1312_2000_filtered.fastq`
  - `S-1312_5000_filtered.fastq`

### 3. Naming Convention
All output files follow the format: `{StrainName}_{LengthThreshold}`

Examples:
- Filtered reads: `S-1312_500_filtered.fastq`
- Alignment: `S-1312_500_aligned.bam`
- Coverage: `S-1312_500_coverage.txt`

### 4. Reference Optimization
The workflow intelligently creates combined references (genome + transgene) only **once per unique transgene**, not per sample or length threshold. This significantly reduces redundant work:

- If you have 2 samples with the same transgene tested at 7 length thresholds (14 total runs), only 1 combined reference is created
- References are reused across all samples and length thresholds that share the same transgene

## File Structure

### Modified Files:
1. **`nextflow.config`**
   - Added `length_thresholds` parameter

2. **`main.nf`**
   - Expanded samples channel with length thresholds
   - Updated help message
   - New channel structure: `[sample_name_lengthThreshold, fastq, transgene, length_threshold]`

3. **`modules/local/chopper.nf`**
   - Now accepts `length_threshold` parameter
   - Uses it for `--maxlength` filtering
   - Added threshold info to log output

### Important Technical Note:
The workflow uses `channel.fromList(params.length_thresholds)` to properly expand the list of thresholds into individual channel elements. This ensures each sample is tested with each threshold value separately.

4. **`modules/local/combine_reference.nf`**
   - Changed to key on transgene instead of sample_name
   - Creates reference once per unique transgene

5. **`workflows/cna_workflow.nf`**
   - Updated to handle 4-element sample tuples
   - Optimized reference creation and joining logic

## Usage

### Basic Usage
No changes needed! The default configuration will test all 7 length thresholds:
```bash
nextflow run main.nf --samples samples.csv -c custom.config
```

### Custom Length Thresholds
Test only specific thresholds:
```bash
nextflow run main.nf \
  --samples samples.csv \
  --length_thresholds '[500,1000,2000]' \
  -c custom.config
```

### Test a Single Threshold
To replicate the old behavior (single threshold):
```bash
nextflow run main.nf \
  --samples samples.csv \
  --length_thresholds '[500]' \
  -c custom.config
```

## Output Structure

```
results/
├── selected_fastq/
│   ├── S-1312_100_filtered.fastq
│   ├── S-1312_200_filtered.fastq
│   ├── S-1312_500_filtered.fastq
│   ├── ...
│   ├── S-1414_100_filtered.fastq
│   └── ...
├── nanoplot_results/
│   ├── S-1312_100/
│   ├── S-1312_200/
│   └── ...
├── combined_references/
│   └── A-vector_herceptin_pEY345_combined_reference.fasta  # Only one per transgene!
├── aligned_reads/
│   ├── S-1312_100_aligned.bam
│   └── ...
├── sorted_bam/
│   ├── S-1312_100_sorted.bam
│   └── ...
├── indexed_bam/
│   ├── S-1312_100_sorted.bam
│   ├── S-1312_100_sorted.bam.bai
│   └── ...
└── coverage/
    ├── S-1312_100_coverage.txt
    ├── S-1312_200_coverage.txt
    └── ...
```

## Analyzing Results

### Comparing Coverage Across Length Thresholds

Each coverage file contains per-chromosome/transgene statistics. To compare results:

```bash
# Extract mean depth for each threshold
for file in results/coverage/S-1312_*_coverage.txt; do
    echo "=== $(basename $file) ==="
    awk 'NR>1 {print $1, $7}' $file  # chromosome, meandepth
done
```

### Finding Optimal Threshold

Look for the threshold that provides:
1. Good coverage of reference genome
2. Good coverage of transgene
3. Minimal noise/artifacts
4. Reasonable data retention

Compare the `numreads`, `coverage`, and `meandepth` columns across different thresholds.

## Computational Considerations

### Runtime
- Each length threshold creates an independent analysis path
- 7 thresholds = 7× more work (but runs in parallel!)
- Estimated runtime: ~1-2 hours per sample-threshold combination

### Disk Space
- Each threshold generates:
  - Filtered FASTQ (~size depends on filtering)
  - BAM file (~size of original FASTQ)
  - Coverage files (small, <1MB)
- Combined references are shared (minimal overhead)

### Resource Optimization
The workflow is optimized to:
- Create combined references only once per unique transgene
- Run processes in parallel where possible
- Reuse the same reference across all samples and thresholds

## Example Workflow

Given `samples.csv`:
```csv
name,fastq,transgene
S-1312,/data/S-1312.fastq,A-vector_herceptin_pEY345
S-1414,/data/S-1414.fastq,A-vector_herceptin_pEY345
```

With default settings (7 thresholds), the workflow will:
1. Create 1 combined reference (shared by all)
2. Filter S-1312 at 7 different thresholds (in parallel)
3. Filter S-1414 at 7 different thresholds (in parallel)
4. Align, sort, index, and calculate coverage for all 14 combinations
5. Generate 14 coverage files for comparison

Total: **14 complete analysis paths** from 2 input samples!

## Best Practices

1. **Start Small**: Test with 1 sample and 2-3 thresholds first
2. **Check Disk Space**: Ensure you have enough space for all outputs
3. **Monitor Resources**: Watch CPU/memory usage during parallel execution
4. **Review Results**: Compare coverage statistics before analyzing all samples
5. **Document Findings**: Keep notes on which threshold works best for your data

## Troubleshooting

### Too Many Files
If generating too many outputs, reduce the number of thresholds:
```bash
--length_thresholds '[500,1000,2000]'
```

### Insufficient Resources
Adjust parallel execution in your custom config:
```groovy
process.maxForks = 4  // Limit concurrent processes
```

### Wrong Reference
Verify that:
- Transgene names in CSV match filenames in transgene_dir
- Each unique transgene has exactly one .fa file

## Summary of Benefits

✅ **Systematic Optimization**: Test multiple thresholds in one run
✅ **Reproducible**: All parameters documented in config
✅ **Efficient**: References created only once per transgene
✅ **Parallel**: All threshold tests run simultaneously
✅ **Organized**: Clear naming convention (Strain_Length)
✅ **Flexible**: Easy to add/remove thresholds via config

---

**Implementation Date**: 2026-01-21  
**Nextflow Version**: >=23.04.0  
**All files pass `nextflow lint` validation** ✅
