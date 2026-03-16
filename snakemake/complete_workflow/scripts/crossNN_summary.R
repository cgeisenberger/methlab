library(data.table)
library(dplyr)
library(ggplot2)

# load ground truth
# gt needs to be manually created to match with cohort names
# expected format: identifier | methylation class abbreviation
gt <- fread(normalizePath(snakemake@params["ground_truth"]))
setnames(gt, c("id", "mc"))

# load crossNN result function
load_crossNN <- function(files) {
    cnn <- lapply(files, fread)
    names(cnn) <- basename(files) %>%
        sub("_crossNN_votes.tsv", "", .)
    cnn <- rbindlist(cnn, idcol = "sample")
    setnames(cnn, "V1", "rank")
    return(cnn)
}

review_gt <- function(cnn, gt) {
    cnn <- cnn[rank == 0,]
    cnn <- merge(cnn, gt,
                 by.x = "sample", by.y = "id",
                 all = FALSE)
    return(cnn)
}


cnn_normal <- load_crossNN(normalizePath(snakemake@input[["normal"]]))

