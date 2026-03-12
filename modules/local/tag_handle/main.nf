process TAG_HANDLE {
    label 'process_medium'
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/artic:1.8.5--pyhdfd78af_0' :
        'biocontainers/artic:1.8.5--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(bam)


    output:
    tuple val(meta), path("${meta.id}.correct.bam") , emit: bam,  optional: true
    tuple val(meta), path("${meta.id}.correct.bam.bai") , emit: bai,  optional: true
    path "versions.yml", emit: versions

    script:
    """
    samtools view -h ${bam} \
    | mawk 'BEGIN{FS=OFS="\t"} /^@/{print;next} {split(\$1,n,":"); \$0=\$0"\tRX:Z:"n[length(n)]; print}' \
    | sed s/_/-/g \
    | samtools view -bS - > ${meta.id}.tag.bam

    picard AddOrReplaceReadGroups \
    -I ${meta.id}.tag.bam \
    -O ${meta.id}.correct.bam \
    --RGID 1 \
    --RGLB library1 \
    --RGPL ILLUMINA \
    --RGPU unit1 \
    --SM sample1

    samtools index ${meta.id}.correct.bam

    # Versions #
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tag_handle: \$(echo \$(tag_handle --version 2>&1) | sed 's/tag_handle //')
    END_VERSIONS
    """

    stub:
    """
    touch ${meta.id}.correct.bam
    touch ${meta.id}.correct.bam.bai

    # Versions #
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tag_handle: \$(echo \$(tag_handle --version 2>&1) | sed 's/tag_handle //')
    END_VERSIONS
    """
}
