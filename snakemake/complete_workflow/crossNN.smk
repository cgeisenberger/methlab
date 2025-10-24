rule create_bedmethyl:
    input: "context_files_merged/CpG_context_{sample}_merged_trimmed_bismark_bt2.deduplicated.txt.gz"
    output: "bedMethyl/CpG_context_{sample}.bed.gz"
    shell: """
    zcat {input} | \
    tail -n+2 | \
    awk 'BEGIN{{OFS="\t"}} {{print $1, $2, $3, 0, 0, 0, 0, 0, 0, 0, $4}}' | \
    gzip > {output}
    """

rule annotate_bedmethyl:
    input:
        bed="bedMethyl/CpG_context_{sample}.bed.gz"
    output:
        "bedMethyl/CpG_context_450K_{sample}.bed"
    params:
        map=config["crossNN_mapping"]
    shell: """
    zcat {input.bed} | \
    cut -f1-11 | \
    bedtools intersect -a - -b {params.map} -wa -wb | \
    awk -v OFS='\t' '$4=$15' | \
    cut -f1-11 | \
    sort -k4,4 -u > {output}
    """

rule NN_classifier:
    input:
        bed="bedMethyl/CpG_context_450K_{sample}.bed"
    output:
        txt="crossNN/{sample}_crossNN_result.txt",
        votes="crossNN/{sample}_crossNN_votes.tsv"
    params:
        model=config["crossNN_trainingset"]
    conda: "envs/NN_model.yaml"
    script:
        "scripts/classify_NN_bedMethyl.py"