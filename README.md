# Single-Cell RNA-Seq Pipeline

A Nextflow pipeline for processing 10x Genomics single-cell RNA-seq data using Cell Ranger, with quality control and optional BAM to CRAM conversion.

## Pipeline Overview

This pipeline performs the following steps:

1. **Quality Control** - FastP for read quality assessment
2. **Cell Ranger Count** - Gene expression quantification and cell calling
3. **BAM to CRAM Conversion** - Optional compression of alignment files (when `create_bam: true`)
4. **MultiQC** - Aggregate quality control report

## Pipeline Features

- ✅ Automated FASTQ quality control with FastP
- ✅ Single-cell RNA-seq quantification with Cell Ranger
- ✅ Automatic BAM to CRAM conversion for space savings
- ✅ Comprehensive QC reporting with MultiQC
- ✅ AWS HealthOmics compatible
- ✅ S3 input/output support
- ✅ Configurable chemistry detection
- ✅ Optional alignment file generation

## Requirements

### Docker Images
The pipeline requires the following Docker images:
- FastP: `fastp:1.0.1--heae3180_0`
- MultiQC: `multiqc:1.30--pyhdfd78af_0`
- Cell Ranger: `cellranger:10.0.0`
- Samtools: `samtools:1.19.2--h50ea8bc_1`

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>
cd scrna-seq-pipeline
```

### 2. Prepare Your Parameters

Edit `run_parameters.json`:

```json
{
    "fastp_docker": "<account>.dkr.ecr.<region>.amazonaws.com/fastp:1.0.1--heae3180_0",
    "multiqc_docker": "<account>.dkr.ecr.<region>.amazonaws.com/multiqc:1.30--pyhdfd78af_0",
    "cellranger_docker": "<account>.dkr.ecr.<region>.amazonaws.com/cellranger:10.0.0",
    "samtools_docker": "<account>.dkr.ecr.<region>.amazonaws.com/samtools:1.19.2--h50ea8bc_1",
    "fastq_r1": "s3://your-bucket/path/to/sample_R1_001.fastq.gz",
    "fastq_r2": "s3://your-bucket/path/to/sample_R2_001.fastq.gz",
    "sample_name": "sample_name",
    "transcriptome": "s3://your-bucket/references/refdata-gex-GRCh38-2024-A/",
    "create_bam": true,
    "expect_cells": 5000
}
```

### 3. Run the Pipeline

#### AWS HealthOmics
```bash
aws omics start-run \
    --workflow-id <your-workflow-id> \
    --role-arn <your-role-arn> \
    --output-uri s3://your-bucket/results/ \
    --parameters file://run_parameters.json
```

## Parameters

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fastq_r1` | String | Path to Read 1 FASTQ file (local or S3) |
| `fastq_r2` | String | Path to Read 2 FASTQ file (local or S3) |
| `transcriptome` | String | Path to Cell Ranger transcriptome reference |
| `sample_name` | String | Sample identifier |

### Optional Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `chemistry` | String | auto-detect | 10x chemistry version (e.g., SC3Pv3, SC5P-R2) |
| `create_bam` | Boolean | false | Generate BAM alignment files and CRAM |
| `expect_cells` | Integer | 5000 | Expected number of recovered cells |
| `outdir` | String | /mnt/workflow/pubdir | Output directory path |

### Docker Image Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `fastp_docker` | String | FastP Docker image URI |
| `multiqc_docker` | String | MultiQC Docker image URI |
| `cellranger_docker` | String | Cell Ranger Docker image URI |
| `samtools_docker` | String | Samtools Docker image URI |

## Output Structure

```
output/
├── QC/
│   ├── <sample>_fastp.html          # FastP QC report
│   ├── <sample>_fastp.json          # FastP QC metrics
│   └── multiqc_report.html          # MultiQC aggregate report
└── CELLRANGER/
    ├── web_summary.html             # Cell Ranger summary report
    ├── metrics_summary.csv          # Key metrics CSV
    ├── filtered_feature_bc_matrix.h5 # Filtered count matrix
    ├── raw_feature_bc_matrix.h5     # Raw count matrix
    ├── molecule_info.h5             # Per-molecule information
    ├── cloupe.cloupe                # Loupe Browser file
    ├── <sample>.cram                # Alignment file (if create_bam: true)
    ├── <sample>.cram.crai           # CRAM index (if create_bam: true)
    ├── analysis/                    # Secondary analysis
    └── versions.yml                 # Software versions
```

## Pipeline Details

### FastP
- Performs quality control on raw FASTQ files
- Generates HTML and JSON reports
- No trimming applied (analysis only)

### Cell Ranger Count
- Aligns reads to transcriptome
- Performs cell calling and UMI counting
- Generates gene-barcode matrices
- Creates Loupe Browser files for visualization
- Optional BAM file generation

### BAM to CRAM Conversion
- Automatically triggered when `create_bam: true`
- Converts BAM to CRAM format (40-60% size reduction)
- Uses reference genome from transcriptome directory
- Creates indexed CRAM files (.cram.crai)
- **Note:** BAM files are NOT published to S3, only CRAM files

### MultiQC
- Aggregates QC metrics from FastP and Cell Ranger
- Generates comprehensive HTML report

## Resource Requirements

### Recommended Resources

| Process | CPUs | Memory | Notes |
|---------|------|--------|-------|
| FastP | 8 | 16 GB | Adjustable based on file size |
| Cell Ranger | 32 | 128 GB | Minimum recommended |
| Samtools | 16 | 32 GB | For CRAM conversion |
| MultiQC | 8 | 16 GB | Light computational needs |

## File Size Considerations

### Space Savings with CRAM

When `create_bam: true`:
- BAM file: ~20-50 GB (not published to S3)
- CRAM file: ~8-20 GB (published to S3)
- **Space savings: 40-60%**

### Typical File Sizes (per sample)

| File | Approximate Size |
|------|------------------|
| Raw FASTQ (R1 + R2) | 10-30 GB |
| Filtered matrix (.h5) | 50-500 MB |
| CRAM + index | 8-20 GB |
| Loupe file (.cloupe) | 100-500 MB |

## Configuration Files

### nextflow.config
Contains process-specific settings:
- Container images
- Resource allocations
- Publishing directories
- Process labels

### run_parameters.json
Contains run-specific parameters:
- Input file paths
- Sample information
- Pipeline options

## Advanced Usage

### Custom Chemistry
```json
{
    "chemistry": "SC3Pv3"
}
```

### Skip BAM/CRAM Generation
```json
{
    "create_bam": false
}
```

### Adjust Expected Cell Count
```json
{
    "expect_cells": 10000
}
```

## Citations

If you use this pipeline, please cite:

- **Cell Ranger**: 10x Genomics, https://support.10xgenomics.com/
- **FastP**: Chen et al. (2018) Bioinformatics, 34(17), i884-i890
- **MultiQC**: Ewels et al. (2016) Bioinformatics, 32(19), 3047-3048
- **Samtools**: Li et al. (2009) Bioinformatics, 25(16), 2078-2079
- **Nextflow**: Di Tommaso et al. (2017) Nature Biotechnology, 35, 316-319

## Support

For issues or questions:
- Open an issue on GitHub

## Version History

### v1.0.0
- Initial release
- FastP QC
- Cell Ranger count
- BAM to CRAM conversion
- MultiQC reporting
- AWS HealthOmics support