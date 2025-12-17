rule create_bedmethyl:
    input: ancient("context_files_merged/CpG_context_{sample}_merged_trimmed_bismark_bt2.deduplicated.txt.gz")
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

rule bedMethyl_target:
    input:
        bed = "bedMethyl/CpG_context_450K_{sample}.bed"
    output:
        "bedMethyl/CpG_context_450K_targets_{sample}.bed"
    params: 
        targets=config["BAITS"]
    shell: """
    cut -f1-11 {input.bed} | \
    bedtools intersect -a - -b {params.targets} -wa | \
    cut -f1-11 | \
    sort -k4,4 -u > {output}
    """

rule bedMethyl_untarget:
    input:
        bed = "bedMethyl/CpG_context_450K_{sample}.bed"
    output:
        "bedMethyl/CpG_context_450K_no_targets_{sample}.bed"
    params: 
        targets=config["BAITS"]
    shell: """
    cut -f1-11 {input.bed} | \
    bedtools intersect -a - -b {params.targets} -wa -v | \
    cut -f1-11 | \
    sort -k4,4 -u > {output}
    """

rule bedMethyl_probe_target:
    input:
        bed = "bedMethyl/CpG_context_450K_{sample}.bed"
    output:
        "bedMethyl/CpG_context_450K_probe_targets_{sample}.bed"
    params: 
        targets=config["BAITS_PROBE"]
    shell: """
    cut -f1-11 {input.bed} | \
    bedtools intersect -a - -b {params.targets} -wa | \
    cut -f1-11 | \
    sort -k4,4 -u > {output}
    """

rule impute_bedMethyl:
    input:
        bed = "bedMethyl/CpG_context_450K_probe_targets_{sample}.bed"
    output:
        bed = "bedMethyl/CpG_context_450K_imputed_{sample}.bed"
    params:
        helpers = config["IMP_HELPERS"],
        dist_mat = config["DIST_MAT"]
    conda: "envs/NN_model.yaml"
    script:
        "scripts/impute_bedMethyl.R"

use rule NN_classifier as NN_classifier_target with:
    input:
        bed="bedMethyl/CpG_context_450K_targets_{sample}.bed"
    output:
        txt="crossNN/{sample}_targets_crossNN_result.txt",
        votes="crossNN/{sample}_targets_crossNN_votes.tsv"

use rule NN_classifier as NN_classifier_untarget with:
    input:
        bed="bedMethyl/CpG_context_450K_no_targets_{sample}.bed"
    output:
        txt="crossNN/{sample}_no_targets_crossNN_result.txt",
        votes="crossNN/{sample}_no_targets_crossNN_votes.tsv"

use rule NN_classifier as NN_classifier_imputed with:
    input:
        bed="bedMethyl/CpG_context_450K_imputed_{sample}.bed"
    output:
        txt="crossNN/{sample}_imputed_crossNN_result.txt",
        votes="crossNN/{sample}_imputed_crossNN_votes.tsv"