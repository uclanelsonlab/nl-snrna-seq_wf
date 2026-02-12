process MULTIQC {
    label "multiqc"

    input:
        path fastp_json
        path cellranger_metrics

    output:
        path "multiqc_report.html", emit: report
        path "multiqc_data"       , emit: data

    script:
        """
        multiqc .
        """
}