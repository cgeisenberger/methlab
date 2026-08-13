library(data.table)

source(normalizePath(snakemake@params[["helpers"]]))

dist_mat <- readRDS(normalizePath(snakemake@params[["dist_mat"]]))
bed <- fread(normalizePath(snakemake@input[["bed"]]))

# compute top32
dist_top32 <- compute_topk_distance(dist_mat)
rownames(dist_top32) <- rownames(dist_mat)

# prepare bed
dat <- bed[, c(4, 11)]
setnames(dat, c("probes", "V11"))

p <- data.table(probes=rownames(dist_mat))
dat <- merge(p, dat, by = "probes", all.x = TRUE, all.y = FALSE)
dat_mat <- as.matrix(dat, rownames="probes")
dat_mat <- dat_mat[rownames(dist_mat), , drop=FALSE]

# impute
imputed <- impute_distance_topk(dat_mat, dist_top32, dist_mat)
imputed <- as.data.table(imputed, keep.rownames = "probes")

new_bed <- merge(bed[, !11], imputed,
                by.x = "V4", by.y = "probes",
                all.x = FALSE, all.y = TRUE)
setcolorder(new_bed, paste0("V", 1:11))
new_bed[is.na(new_bed)] <- "."
fwrite(new_bed, normalizePath(snakemake@output[["bed"]]),
       col.names = FALSE, scipen = 30, sep = "\t")