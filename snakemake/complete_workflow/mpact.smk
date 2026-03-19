# install

rule install_mpact:
    output:
        "mpact/install_complete.txt"
    conda: "envs/mpact.yaml"
    shell: """
    pip install intervalframe
    pip install ngsfragments
    pip install MethylVerse
    touch {output}
    """

rule test_env:
    output:
        "mpact/test_success"
    conda: "envs/mpact.yaml"
    shell: """
    python -m MethylVerse MPACT -h > {output}
    """


rule methyldackel_bedgraph:
    input:
        bam = ancient("mapped_reads/{sample}_R1_001_trimmed_bismark_bt2.sorted.bam")
    output:
        bedgraph = "methyldackel/{sample}_CpG.bedGraph"
    threads: 8
    params:
        prefix = "methyldackel/{sample}",
        ref = config["GENOME_FASTA"]
    conda: "envs/mpact.yaml"
    shell:
        r"""
        mkdir -p methyldackel

        MethylDackel extract \
            {params.ref} \
            {input.bam} \
            -o {params.prefix} \
            -@ {threads} \
        """

rule mpact:
    input:
        bedgraph = "methyldackel/{sample}_CpG.bedGraph"
    output:
        "mpact/{sample}_classification.txt"
    conda: "envs/mpact.yaml"
    shell: """
    python -m MethylVerse MPACT {input.bedgraph} --out {output} --verbose
    """
    