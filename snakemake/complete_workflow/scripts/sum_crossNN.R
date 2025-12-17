library(data.table)
library(ggplot2)

crossnn_res_folder <- "/mnt/nas/shared/targeted_bisulfite_data/CHIMAL001/crossNN/"

files <- list.files(crossnn_res_folder, pattern = ".*_crossNN_votes.tsv", full.names = TRUE)
file_names <- sub("_crossNN_votes.tsv", "", basename(files))

result <- lapply(files, fread)
names(result) <- file_names

result <- rbindlist(result, idcol = "sample")

ggplot(result[V1==0], aes(sample, class, fill = score))+
  geom_tile()

mng <- result[V1==0]
mng <- mng[!grepl("CTRL", sample)]

mng[, mng := ifelse(class == "MNG", TRUE, FALSE)]
mng[, sig := ifelse(score >= 0.2, TRUE, FALSE)]

mng[, .N, by = c("mng", "sig")]

mng[, correct := ifelse(mng == TRUE & sig == TRUE, TRUE, FALSE)]


cutoff <- lapply(seq(0, 1, 0.01), function(x) {
  return(data.table(cutoff=x,
    correct=length(mng[class=="MNG" & score >= x]$sample),
    incorrect=length(mng[class!="MNG" & score >= x]$sample)))
})
cutoff <- rbindlist(cutoff)
cutoff <- melt(cutoff, id.vars = "cutoff", variable.name = "prediction", value.name = "num_cases")
ggplot(cutoff, aes(cutoff, num_cases, color = prediction))+
  geom_line()+
  geom_vline(xintercept=0.2, linetype = "dashed")+
  scale_color_manual(values = c("black", "red"))+
  labs(title = "CrossNN prediction on Meningioma Cohort - Cutoff Selection")
