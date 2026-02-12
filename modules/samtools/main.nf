process BAM_TO_CRAM {
    tag "$meta.id"
    label "samtools_cram"

    input:
        tuple val(meta), path(bam), path(bai)
        path transcriptome

    output:
        tuple val(meta), path("*.cram"), path("*.cram.crai") , emit: cram
        path "versions.yml"                                  , emit: versions

    script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        
        """
        # Extract reference fasta from transcriptome directory
        REFERENCE_FASTA=\$(find ${transcriptome} -type f -name "genome.fa" -o -name "*.fasta" -o -name "*.fa" | head -n 1)
        
        if [ -z "\$REFERENCE_FASTA" ]; then
            echo "ERROR: Could not find reference FASTA in transcriptome directory"
            exit 1
        fi

        # Convert BAM to CRAM
        samtools view \\
            -@ ${task.cpus} \\
            -T \$REFERENCE_FASTA \\
            -C \\
            --output-fmt-option normal \\
            -o ${prefix}.cram \\
            ${bam}

        # Index the CRAM file
        samtools index \\
            -@ ${task.cpus} \\
            ${prefix}.cram

        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            samtools: \$(samtools --version | head -n 1 | cut -d' ' -f2)
        END_VERSIONS
        """
}