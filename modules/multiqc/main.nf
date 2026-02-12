process MULTIQC {
    label "multiqc"

    input:
        path fastp_json
        path cellranger_html

    output:
        path "multiqc_report.html", emit: report
        path "multiqc_data"       , emit: data
        path "versions.yml"       , emit: versions

    script:
        """
        # Create a staging directory structure for MultiQC
        mkdir -p multiqc_input
        
        # Copy/link input files to staging area
        cp ${fastp_json} multiqc_input/ || true
        cp ${cellranger_html} multiqc_input/ || true
        
        # List files for debugging
        echo "Files available for MultiQC:"
        ls -lah multiqc_input/
        
        # Run MultiQC
        multiqc multiqc_input/ --force --verbose
        
        # Verify outputs were created
        if [ ! -f "multiqc_report.html" ]; then
            echo "ERROR: MultiQC report was not generated"
            echo "Available files:"
            ls -lah
            exit 1
        fi
        
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            multiqc: \$(multiqc --version | sed 's/multiqc, version //g')
        END_VERSIONS
        """
}