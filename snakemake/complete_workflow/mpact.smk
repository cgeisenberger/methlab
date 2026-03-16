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
