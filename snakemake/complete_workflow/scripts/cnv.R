# create CNV Plot from bed files

if(!interactive()) pdf(NULL)

library(data.table)
library(ggplot2)

color_selector <- function(x) {
    if (x > 0.1) {
        return("red")
    } else if (x < -0.1) {
       return("blue")
    } else {
       return("grey")
    }
}


ref_path <- normalizePath(snakemake@input[["ref"]])
sample_path <- normalizePath(snakemake@input[["bed"]])

#ref_path <- "/media/Leia/cgeisenberger/analysis/cnv-calling/normal_lung_1M.bed"
#sample_path <- "/media/Leia/cgeisenberger/analysis/cnv-calling/cnv_files/D00111_binned_1M.bed"

beader <- c("chr", "start", "stop", "reads", "counts", "length", "coverage")

ref_bed <- fread(ref_path)
names(ref_bed) <- beader
sample_bed <- fread(sample_path)
names(sample_bed) <- beader

big_bed <- merge(sample_bed,
                 ref_bed,
                 by = c("chr", "start", "stop", "length"),
                 suffixes = c(".sample", ".ref"))
big_bed$counts.sample <- big_bed$counts.sample + 1
big_bed$counts.ref <- big_bed$counts.ref + 1
# min max normalization
#big_bed[, normref := (counts.ref - min(counts.ref))/(max(counts.ref) - min(counts.ref))+0.000001]
#big_bed[, normsample := (counts.sample - min(counts.sample))/(max(counts.sample) - min(counts.sample))+0.000001]
big_bed[, zref := (counts.ref - mean(counts.ref))/sd(counts.ref)]
big_bed[, zsample := (counts.sample - mean(counts.sample))/sd(counts.sample)]
medref <- median(big_bed$counts.ref)
medsample <- median(big_bed$counts.sample)
big_bed[, fc := ((counts.sample /sum(counts.sample)) / (counts.ref / sum(counts.ref)))]
big_bed[, log2fc := log2(fc)]
big_bed$colorfc <- sapply(big_bed$log2fc, color_selector)

big_bed <- big_bed[chr %in% paste0("chr", c(1:22, "X", "Y"))]
big_bed$chr <- factor(gsub("chr", "",big_bed$chr), levels = c(as.character(1:22), "X", "Y"))

#ggplot(big_bed, aes(chr, log2fc, color = colorfc))+
#    geom_jitter(height=0)+
#    theme(axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
#    scale_color_manual(guide="none", values=c("blue", "red"))+
#    geom_hline(yintercept=0)

ggplot(big_bed, aes(x = start, y = log2fc,  color = colorfc)) +
  geom_point(size=0.7) + 
  facet_grid(. ~ chr, switch="x", space = "free_x"  , scales = "free_x")+
  scale_x_continuous(breaks = NULL, labels = NULL, name="Chromosome")+
  theme(panel.border = element_rect(fill = "transparent", 
                                    color = "black", linewidth = 0.5),
        panel.spacing = unit(0, 'points'),
        panel.background = element_rect(fill = NA),
        strip.background = element_rect(colour = "black", fill = "white"),
        axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1))+
  scale_color_manual(guide="none", values=c(red="red", blue="blue", grey="grey"))+
  geom_hline(yintercept=0)

ggsave(paste0("cnv_plots/", snakemake@wildcards["sample"], "_CNV_profile.png"),
       width = 18, height = 9)
#ggsave(paste0("cnv_plots/", "D00111", "_CNV_profile.png"), width=12)
