process AGGREGATE_CNA {
    publishDir "${params.outdir}/cna_summary", mode: 'copy'
    container 'bumproo/general_genomics:latest'
    
    input:
    path(cna_files)  // All individual CNA summary CSV files
    
    output:
    path("aggregated_cna_summary.csv"), emit: aggregated_summary
    
    script:
    """
    #!/usr/bin/env python3
    import pandas as pd
    from pathlib import Path
    
    # Read all CSV files
    cna_files = [f for f in Path('.').glob('*_cna_summary.csv')]
    
    if not cna_files:
        raise ValueError("No CNA summary files found to aggregate")
    
    # Read and concatenate all dataframes
    dfs = []
    for file in sorted(cna_files):
        df = pd.read_csv(file)
        dfs.append(df)
    
    # Combine all results
    combined_df = pd.concat(dfs, ignore_index=True)
    
    # Sort by Strain_Length for better readability
    combined_df = combined_df.sort_values('Strain_Length')
    
    # Write aggregated results
    combined_df.to_csv('aggregated_cna_summary.csv', index=False)
    
    print(f"Successfully aggregated {len(dfs)} CNA summary files")
    """
    
    stub:
    """
    echo "Strain_Length,AvgChrCoverage,TransgeneCoverage,TransgeneCopyNumber" > aggregated_cna_summary.csv
    echo "S-1312_250,25.5,51.0,2.0" >> aggregated_cna_summary.csv
    echo "S-1312_500,26.2,52.4,2.0" >> aggregated_cna_summary.csv
    echo "S-1414_250,30.1,60.2,2.0" >> aggregated_cna_summary.csv
    """
}
