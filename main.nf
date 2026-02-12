#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { FASTP } from './modules/fastp/main.nf'
include { CELLRANGER_COUNT } from './modules/cellranger/main.nf'
include { MULTIQC } from './modules/multiqc/main.nf'
include { BAM_TO_CRAM } from './modules/samtools/main.nf'

log.info """\
    R N A - S E Q _ W F   P I P E L I N E
    ===================================
    sample_name         : ${params.sample_name}
    fastq_r1            : ${params.fastq_r1}
    fastq_r2            : ${params.fastq_r2}
    transcriptome       : ${params.transcriptome}
    chemistry           : ${params.chemistry ?: 'auto-detect'}
    create_bam          : ${params.create_bam}
    """
    .stripIndent(true)

workflow {
    // 1. Validate required parameters
    if (!params.fastq_r1)      { error "Missing --fastq_r1" }
    if (!params.fastq_r2)      { error "Missing --fastq_r2" }
    if (!params.transcriptome) { error "Missing --transcriptome path (S3 or local)" }
    
    // 2. Prepare the input channel
    Channel
        .fromPath(params.fastq_r1)
        .map { fastq_r1 ->
            def meta = [:]
            meta.id = params.sample_name ?: fastq_r1.baseName
            def fastq_r2 = file(params.fastq_r2)
            [ meta, [fastq_r1, fastq_r2] ]
        }
        .set { ch_reads }
    
    // 3. Prepare the transcriptome channel (Value channel so it can be reused)
    ch_transcriptome = Channel.value(file(params.transcriptome))

    // 4. Run FASTP for Quality Control stats
    FASTP(ch_reads)

    // 5. Run CELLRANGER_COUNT
    CELLRANGER_COUNT(ch_reads, ch_transcriptome)
    
    // 6. Convert BAM to CRAM if create_bam is true
    if (params.create_bam) {
        // Prepare BAM channel - filter out empty emissions
        CELLRANGER_COUNT.out.bam_and_bai
            .filter { it.size() > 0 }  // Only proceed if BAM files exist
            .map { bam_files ->
                def meta = [:]
                meta.id = params.sample_name
                def bam = bam_files.find { it.name.endsWith('.bam') && !it.name.endsWith('.bai') }
                def bai = bam_files.find { it.name.endsWith('.bam.bai') }
                [ meta, bam, bai ]
            }
            .set { ch_bam }
        
        BAM_TO_CRAM(ch_bam, ch_transcriptome)
    }
    
    // 7. Run MULTIQC
    MULTIQC(
        FASTP.out.json.collect(),
        CELLRANGER_COUNT.out.html.collect()
    )
    
    // Optional: Print messages when done
    FASTP.out.html.view { "FastP report generated for: $it" }
    CELLRANGER_COUNT.out.html.view { "Cell Ranger HTML: $it" }
    MULTIQC.out.report.view { "MultiQC report generated: $it" }
    
    if (params.create_bam) {
        BAM_TO_CRAM.out.cram.view { "CRAM file created: ${it[1]}" }
    }
}