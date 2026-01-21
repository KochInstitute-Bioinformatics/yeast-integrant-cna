#!/usr/bin/env python3
"""
summarize_cna.py - Summarize copy number analysis from samtools coverage output

This script calculates transgene copy number by comparing transgene coverage
to average chromosomal coverage.
"""

import sys
import csv
from pathlib import Path


def parse_coverage_file(coverage_file):
    """
    Parse samtools coverage output file.
    
    Returns:
        dict: Dictionary with keys 'chr_coverage' (list of coverage values) 
              and 'transgene_coverage' (single value or None)
    """
    chr_coverages = []
    transgene_coverage = None
    transgene_name = None
    
    with open(coverage_file, 'r') as f:
        reader = csv.DictReader(f, delimiter='\t')
        for row in reader:
            rname = row['#rname']
            # Use meandepth for coverage calculation (not coverage percentage)
            mean_depth = float(row['meandepth'])
            
            # Chromosome entries start with 'chr'
            if rname.startswith('chr'):
                chr_coverages.append(mean_depth)
            else:
                # Assume non-chr entries are transgenes
                transgene_name = rname
                transgene_coverage = mean_depth
    
    return {
        'chr_coverages': chr_coverages,
        'transgene_coverage': transgene_coverage,
        'transgene_name': transgene_name
    }


def calculate_cna(sample_name, coverage_file):
    """
    Calculate copy number analysis metrics.
    
    Args:
        sample_name: Sample identifier (Strain_Length)
        coverage_file: Path to samtools coverage output
        
    Returns:
        dict: Dictionary with CNA metrics
    """
    data = parse_coverage_file(coverage_file)
    
    # Calculate average chromosomal coverage
    if data['chr_coverages']:
        avg_chr_coverage = sum(data['chr_coverages']) / len(data['chr_coverages'])
    else:
        avg_chr_coverage = 0.0
    
    # Get transgene coverage
    transgene_coverage = data['transgene_coverage'] if data['transgene_coverage'] is not None else 0.0
    
    # Calculate transgene copy number
    if avg_chr_coverage > 0:
        transgene_copy_number = transgene_coverage / avg_chr_coverage
    else:
        transgene_copy_number = 0.0
    
    return {
        'Strain_Length': sample_name,
        'AvgChrCoverage': round(avg_chr_coverage, 2),
        'TransgeneCoverage': round(transgene_coverage, 2),
        'TransgeneCopyNumber': round(transgene_copy_number, 4)
    }


def main():
    if len(sys.argv) != 3:
        print("Usage: summarize_cna.py <sample_name> <coverage_file>", file=sys.stderr)
        sys.exit(1)
    
    sample_name = sys.argv[1]
    coverage_file = sys.argv[2]
    
    # Validate input file exists
    if not Path(coverage_file).exists():
        print(f"Error: Coverage file not found: {coverage_file}", file=sys.stderr)
        sys.exit(1)
    
    # Calculate CNA metrics
    try:
        results = calculate_cna(sample_name, coverage_file)
        
        # Write output to stdout (will be captured by Nextflow)
        fieldnames = ['Strain_Length', 'AvgChrCoverage', 'TransgeneCoverage', 'TransgeneCopyNumber']
        writer = csv.DictWriter(sys.stdout, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerow(results)
        
    except Exception as e:
        print(f"Error processing {coverage_file}: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == '__main__':
    main()
