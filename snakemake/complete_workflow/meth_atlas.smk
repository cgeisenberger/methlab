rule setup_meth_atlas:
  output: 
    directory("meth_atlas_program"),
    "meth_atlas/full_atlas.csv"
  shell: "mkdir -p resources/tools && \
  git clone https://github.com/nloyfer/meth_atlas.git meth_atlas_program && \
  gunzip meth_atlas_program/full_atlas.csv.gz && \
  mv meth_atlas_program/full_atlas.csv meth_atlas/"

AWK_TERM = r'{OFS = "," ; print $4, $11/100}'
rule bedMethyl_to_CSV:
  input: "bedMethyl/CpG_context_450K_{sample}.bed"
  output: "meth_atlas/{sample}.csv"
  shell: "echo 'CpG,{wildcards.sample}' > {output} && awk {AWK_TERM:q} {input} >> {output}"

rule meth_atlas:
  input:
    csv = "meth_atlas/{sample}.csv",
    ref = "meth_atlas/full_atlas.csv",
    tool = "meth_atlas_program"
  output: 
    out_csv = "meth_atlas/{sample}_deconv_output.csv",
    out_plot = "meth_atlas/{sample}_deconv_plot.png"
  conda: "envs/meth_atlas.yaml"
  shell: "python3.10 meth_atlas_program/deconvolve.py --atlas_path {input.ref} --out_dir meth_atlas {input.csv}"

