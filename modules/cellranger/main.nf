process CELLRANGER_COUNT {
    tag "$meta.id"
    label "cellranger"

    input:
        tuple val(meta), path(reads)
        path transcriptome

    output:
        // Essential & Important files
        path "web_summary.html"             , emit: html
        path "metrics_summary.csv"          , emit: metrics
        path "filtered_feature_bc_matrix.h5", emit: counts_filtered
        path "molecule_info.h5"             , emit: mol_info
        path "cloupe.cloupe"                , emit: cloupe
        
        // Optional files (using glob patterns)
        path "raw_feature_bc_matrix.h5" , optional: true, emit: counts_raw
        path "possorted_genome_bam.bam*", optional: true, emit: bam_and_bai
        path "analysis/**"              , optional: true, emit: analysis_folder
        
        path "versions.yml"             , emit: versions

    script:
        // Use regex to fix the "Sample Not Found" issue by cleaning the ID
        def clean_id = meta.id.replaceAll(/_S\d+$/, "")
        
        def chemistry    = params.chemistry ? "--chemistry=${params.chemistry}" : ""
        def create_bam   = params.create_bam ? "--create-bam=true" : "--create-bam=false"
        def expect_cells = params.expect_cells ? "--expect-cells=${params.expect_cells}" : ""

        """
        # 1. Standardize FASTQ names to prevent the "Sample Not Found" crash
        mkdir -p fastq_staging
        ln -s \$(readlink -f ${reads[0]}) fastq_staging/${clean_id}_S1_L001_R1_001.fastq.gz
        ln -s \$(readlink -f ${reads[1]}) fastq_staging/${clean_id}_S1_L001_R2_001.fastq.gz

        # 2. Run Cell Ranger
        # --id: Must be the original meta.id for the folder name
        # --sample: Must be the clean_id for the file naming convention
        cellranger count \\
            --id=${meta.id} \\
            --fastqs=fastq_staging \\
            --sample=${clean_id} \\
            --transcriptome=${transcriptome} \\
            --localcores=${task.cpus} \\
            --localmem=${task.memory.toGiga()} \\
            ${chemistry} \\
            ${create_bam} \\
            ${expect_cells}
        
        # 3. CRITICAL: Move EVERYTHING from the 'outs' folder to the root work dir.
        # This makes the files visible to Nextflow's output block.
        mv ${meta.id}/outs/* .

        # 4. Cleanup temporary directory
        rm -rf ${meta.id} fastq_staging

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            cellranger: \$(cellranger --version | cut -d' ' -f2)
        END_VERSIONS
        """
}