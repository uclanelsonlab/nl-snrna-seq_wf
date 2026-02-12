process FASTP {
    tag "$meta.id"
    label "fastp"

    input:
        tuple val(meta), path(reads)
    
    output:
        path "*.html"       , emit: html
        path "*.json"       , emit: json
        path "versions.yml" , emit: versions
        
    script:
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        fastp \\
            -i ${reads[0]} \\
            -I ${reads[1]} \\
            --thread ${task.cpus} \\
            -h ${prefix}_fastp.html \\
            -j ${prefix}_fastp.json \\
            -A -Q -L  # Disables Adapter, Quality, and Length filtering
        
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed 's/^fastp //')
        END_VERSIONS
        """
    
    stub:
        def prefix = task.ext.prefix ?: "${meta.id}"
        """
        touch ${prefix}_fastp.html
        touch ${prefix}_fastp.json
        cat <<-END_VERSIONS > versions.yml
        "${task.process}":
            fastp: \$(fastp --version 2>&1 | sed 's/^fastp //')
        END_VERSIONS
        """
}