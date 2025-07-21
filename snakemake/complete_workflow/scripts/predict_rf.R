library(data.table)
library(randomForest)

# set paths
classifier_path <- normalizePath(snakemake@config[["BAITS"]])
# cov_path <- "../christina/GEI018/context_files_merged/"
rf_path <- normalizePath(snakemake@config[["RF_MODEL"]])
cpg_files <- snakemake@input[["context_files"]]
# mapping_path <- "../christina/GEI017/mapping_sample_idat.xlsx"
# mapping_path <- NULL

## output
pred_matrix_path <- snakemake@output[["mat"]]
top_class_path <- snakemake@output[["top"]]
# load data
rf_model_v11 <- readRDS(rf_path)

classifier <- fread(classifier_path)
names(classifier) <- c("chr", "start", "end", "probe", "V5")

cov_ls <- lapply(cpg_files, fread)
sample_names <- sub("CpG_context_", "", basename(cpg_files))
sample_names <- sub("_merged_trimmed_bismark_bt2.deduplicated.txt.gz", "", sample_names)
names(cov_ls) <- sample_names


# 1. impute missing CpGs --> take +-125bp average around CpGs (all CpGs, not just missing)

# average of betas in classifier range. If no results in range return 0.5 (neutral)
average_cpg <- function(chr_val, start_val, end_val, cv) {
  cv <- cv[chr==chr_val & start>=(start_val) & start <= (end_val) ]
  if (nrow(cv) == 0) {
    return(0.5)
  } else {
    b <- mean(cv$beta, na.rm=TRUE)
    return(b)
  }
}


cov_cpg_ls <- lapply(cov_ls, function(cov) {
  names(cov) <- c("chr", "position", "position2", "beta")
  cov$position2 <- NULL
  cov$beta <- cov$beta / 100
  
  # cov_cpg <- merge(cov, classifier, 
  #                  all.x = FALSE, all.y = TRUE,
  #                  by = c("chr", "start"))
  cov_cpg <- classifier[cov, on = .(chr, start <= position, end >= position), allow.cartesian = TRUE, nomatch = 0L]
  cov_cpg <- cov_cpg[, mean(beta, na.rm=TRUE), by = probe]
  names(cov_cpg) <- c("probe", "beta")
  miss <- setdiff(classifier$probe, cov_cpg$probe)
  cov_cpg <- rbind(cov_cpg, data.table(probe=miss, beta=NA))
  cov_cpg[is.na(beta)]$beta <- 0.5
  # apply average to all CpGs, even when primary CpG is present. For only missing change to cov_cpg[is.na(beta), ...].
  # cov_cpg[, beta := mapply(average_cpg, chr, start, end, MoreArgs=list(cv=cov))]
  return(cov_cpg)
})

cov_cpg <- rbindlist(cov_cpg_ls, idcol="sample_name")
cov_cpg <- cov_cpg[, c("sample_name", "probe", "beta")]
print(cov_cpg)
cpg_mat <- dcast(cov_cpg, formula = probe ~ sample_name)
cpg_mat <- as.matrix(cpg_mat, rownames = "probe")
print(cpg_mat[1:5, 1:5])
# 2. predict on rf_model_v11 (input order!!)
cpgs <- names(rf_model_v11[["forest"]][["ncat"]])

prediction <- predict(rf_model_v11, t(cpg_mat[cpgs,]), type="prob")

prediction <- as.data.table(prediction, keep.rownames="sample")
fwrite(prediction, pred_matrix_path)

# get top prediction 
prediction <- melt(prediction, id.vars="sample", variable.name="MC", value.name="score")
top <- prediction[prediction[, .I[which.max(score)], by = sample]$V1]
fwrite(top, top_class_path)
