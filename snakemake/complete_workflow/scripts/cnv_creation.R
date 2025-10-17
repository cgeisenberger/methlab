if(!interactive()) pdf(NULL)

source("scripts/cnv.R")

ref_path <- normalizePath(snakemake@input[["ref"]])
sample_path <- normalizePath(snakemake@input[["bed"]])

cov <- read_binned_coverage(sample_path)

ref_cov <- read_binned_coverage(ref_path)

cnv_obj <- cnv_normalize_ref(cov, ref_cov)
cnv_obj <- cnv_normalize_score(cnv_obj)

cnv_obj <- cnv_filter_chr(cnv_obj)


cnv_obj <- cnv_add_genome_anno(cnv_obj)
cnv_obj <- cnv_segmentation(cnv_obj)

cnv_create_plot(cnv_obj)

# Save result
ggsave(paste0("cnv_plots/", snakemake@wildcards["sample"], "_CNV_profile.png"),
       width = 18, height = 9)