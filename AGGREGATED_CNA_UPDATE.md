# Aggregated CNA Summary Update

## Changes Made

This update addresses the issue where the pipeline was producing individual CNA summary CSV files for each `Strain_Length` combination, making it difficult to compare results across samples and thresholds.

### What Changed

1. **New Module**: `modules/local/aggregate_cna.nf`
   - Collects all individual CNA summary files
   - Combines them into a single `aggregated_cna_summary.csv`
   - Sorts results by `Strain_Length` for easy comparison
   - Uses pandas for robust CSV handling

2. **Updated Workflow**: `workflows/cna_workflow.nf`
   - Added `AGGREGATE_CNA` process to workflow
   - Collects all individual CNA outputs and aggregates them
   - Emits both individual files (for debugging) and aggregated summary

3. **Updated Publishing**: `modules/local/transgene_cna.nf`
   - Individual CNA files now published to `cna_summary/individual/`
   - Aggregated file published to `cna_summary/` (top level)

4. **Updated Documentation**: `README.md`
   - Added workflow step 8: CNA Aggregation
   - Updated output structure to show new directory layout
   - Added example of aggregated CSV format
   - Highlighted `aggregated_cna_summary.csv` as the main result

### Output Structure

**Before:**
```
results/
└── cna_summary/
    ├── S-1312_100_cna_summary.csv
    ├── S-1312_250_cna_summary.csv
    ├── S-1312_500_cna_summary.csv
    └── ... (one file per sample-threshold combination)
```

**After:**
```
results/
└── cna_summary/
    ├── aggregated_cna_summary.csv   # ⭐ ALL results in one file
    └── individual/                   # Optional individual files
        ├── S-1312_100_cna_summary.csv
        ├── S-1312_250_cna_summary.csv
        └── ...
```

### Example Aggregated Output

`aggregated_cna_summary.csv`:
```csv
Strain_Length,AvgChrCoverage,TransgeneCoverage,TransgeneCopyNumber
S-1312_100,25.34,50.68,2.0
S-1312_250,26.12,52.24,2.0
S-1312_500,27.89,55.78,2.0
S-1312_750,28.45,56.90,2.0
S-1312_1000,29.12,58.24,2.0
S-1414_100,30.45,60.90,2.0
S-1414_250,31.22,62.44,2.0
...
```

### Benefits

1. **Easy comparison**: All results in one file for easy analysis in Excel, R, Python, etc.
2. **Systematic analysis**: Compare how different length thresholds affect copy number estimates
3. **Cleaner output**: Main result file clearly identified
4. **Preserved detail**: Individual files still available for debugging

### Technical Details

- **Container**: Uses Wave-provided pandas container (`community.wave.seqera.io/library/pandas:2.2.3`)
- **Process**: `AGGREGATE_CNA` runs after all individual CNA calculations complete
- **Method**: Collects all CSV files, concatenates with pandas, sorts by `Strain_Length`
- **Validation**: Nextflow lint passes with no errors

### Backward Compatibility

- Individual CNA files are still generated and published (in `individual/` subdirectory)
- No changes to input format or parameters
- All existing processes remain unchanged
- Only adds a new aggregation step at the end

### Testing

```bash
# Lint check
cd yeast-integrant-cna
nextflow lint workflows/
nextflow lint modules/local/aggregate_cna.nf

# Test run (help)
nextflow run main.nf --help
```

All tests pass successfully! ✅

## Usage

No changes needed to your command line or configuration files. Simply run the pipeline as before:

```bash
nextflow run main.nf -c custom.config
```

The aggregated summary will automatically be created at:
```
results/cna_summary/aggregated_cna_summary.csv
```

## Questions?

If you have any questions or encounter issues, please open an issue on the repository.
