library(tidyverse)
library(DNAcopy)


# Bismark Data Processing Pipeline ---------------------------------------------
guess_sample_name_cnv <- function(path){
  # will look sample name followed by '_' and further information
  
  sample <- basename(path)
  # sample <- str_extract(string = sample, 
  #                      pattern = "^[^_]*")
  sample <- sub("_binned_1M.bed", "", sample)
  return(sample)
}

read_binned_coverage <- function(file, guess_name = TRUE){
  # reads a coverage file as produced by calling bamtools coverage -a [ref] -b [bam]
  
  cnames <- c("chr", "start", "end", "n_reads", "bases_cov", "bases_total", "bases_ratio")
  
  sn <- guess_sample_name_cnv(path = file)
  
  data <- read_table(file = file, col_names = cnames)
  data <- data %>% 
    mutate(bin = row_number(), .before = 1)
  
  if (guess_name){
    data <- data %>% 
      mutate(sample = sn, .before = 1)
  }
  
  # package as list
  cnv_obj <- list()
  cnv_obj[["data"]] <- data
  return(cnv_obj)
}


# Conumee Integration ----------------------------------------------------------

conumee_to_tibble <- function(cnv_object, add_sample_name = TRUE){
  
  # create tibble from Conumee object 
  
  # extract information about genomic bins from object 
  # initially created with conumee::CNV.create_anno()
  anno <- cnv_object@anno@bins %>% 
    as.data.frame %>% 
    as_tibble(rownames = "bin") %>% 
    mutate(nr = row_number(), .before = 1)
  
  # extract information about genome from object
  chr <- cnv_object@anno@genome %>% 
    as_tibble() %>% 
    rename(chr = "seqnames", 
           pq = "centromere", 
           size = "chr_size")
  
  # combine
  anno <- left_join(anno, chr)
  
  # add actual values per bin
  data <- anno %>% 
    add_column(ratio = cnv_object@bin$ratio - cnv_object@bin$shift)
  
  
  if (add_sample_name) {
    data <- data %>% 
      mutate(sample_id =  as.character(cnv_object@name))
  }
  
  return(data)
}


# Normalization ----------------------------------------------------------------

cnv_normalize_ref <- function(query_obj, reference_obj){
  
  # compare coverage data to non-neoplastic control and perform z-score normalization
  s <- query_obj[["data"]]
  ref <- reference_obj[["data"]]
  
  # rename reference data columns before merging data
  ref <- ref %>% 
    select(chr, bin, n_reads, bases_ratio) %>% 
    rename(n_reads_ctrl = "n_reads", 
           bases_ratio_ctrl = "bases_ratio")
  
  s <- left_join(s, ref, by = c("chr", "bin"))
  
  # normalize
  s <- s %>% 
    mutate(fc_reads_log2 = log2(n_reads / n_reads_ctrl), 
           bases_ratio_norm = bases_ratio / bases_ratio_ctrl) %>% 
    select(-c(n_reads_ctrl, bases_ratio_ctrl))
  
  query_obj[["data"]] <- s
  return(query_obj)
}

cnv_normalize_score <- function(cnv_obj){
  
  mean2 <- function(vec) return(mean(vec[!is.infinite(vec)], na.rm = TRUE))
  sd2 <- function(vec) return(sd(vec[!is.infinite(vec)], na.rm = TRUE))
  
  cnv_obj$data$fc_reads_log2[is.infinite(cnv_obj$data$fc_reads_log2)] <- NA
  
  cnv_obj$data <- cnv_obj$data %>% 
    mutate(fc_reads_log2_adj = fc_reads_log2 - mean2(fc_reads_log2), 
           bases_ratio_norm_zscore = (bases_ratio_norm - mean2(bases_ratio_norm))/sd(bases_ratio_norm))
  return(cnv_obj)
  
}

cnv_filter_chr <- function(cnv_obj, chr = NULL){
  # will only keep autosomes by default
  if (is.null(chr)) {
    CHR = c(paste0("chr", 1:22)) 
  } else {
    CHR = chr
  }
  
  cnv_obj$data <- cnv_obj$data %>% 
    filter(chr %in% CHR)
  return(cnv_obj)
}



# CNV Analysis ----------------------------------------------------------------

cnv_add_genome_anno <- function(cnv_obj){
  
  genome_anno <- cnv_obj$data %>% 
    group_by(chr) %>% 
    summarise(midpoints = median(bin), 
              min = min(bin), 
              max = max(bin)) %>% 
    arrange(midpoints)
  
  cnv_obj[["genome_anno"]] <- genome_anno
  return(cnv_obj)
  
}

cnv_segmentation <- function(cnv_obj){
  
  # perform segmentation
  bin_size <- cnv_obj$data$end[1] - cnv_obj$data$start[1]
  
  seg <- DNAcopy::CNA(genomdat = cnv_obj$data$fc_reads_log2_adj,
                      chrom = cnv_obj$data$chr,
                      maploc = cnv_obj$data$start + bin_size/2,
                      presorted = TRUE)
  
  seg_smoothened <- DNAcopy::smooth.CNA(seg)
  seg_smoothened <- DNAcopy::segment(seg_smoothened, verbose = 1)
  
  seg_data <- with(seg_smoothened, cbind(output, segRows)) %>% 
    as_tibble
  
  # add segmentation to object
  cnv_obj$seg <- seg_data
  return(cnv_obj)
}

cnv_create_plot <- function(cnv_obj, min_reads = 25, expand = FALSE){
  
  # simple wrapper around ggplot2
  n_bins <- max(cnv_obj$data$bin)
  
  if (!expand) {
    EX = c(0, 0)
  } else {
    EX = c(0.05, 0.05)
  }
  
  cnv_obj$data %>% 
    filter(n_reads > min_reads) %>% 
    ggplot(aes(bin, fc_reads_log2_adj, col = fc_reads_log2_adj)) +
    scale_color_gradient2(low = "blue", high = "red", mid = "grey") +
    theme_bw(base_size = 22) +
    theme(legend.position = "none", panel.grid = element_blank()) +
    geom_point(size = 3) +
    scale_x_continuous(breaks = cnv_obj$genome_anno$midpoints, 
                       labels = cnv_obj$genome_anno$chr,
                       expand = EX) +
    geom_vline(xintercept = c(cnv_obj$genome_anno$min, max(cnv_obj$genome_anno$max)), lty = 5, lwd = 0.1) +
    theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1)) +
    labs(x = NULL, y = "Normalized coverage") +
    geom_segment(data = cnv_obj$seg, aes(x = startRow, xend = endRow, y = seg.mean, yend = seg.mean), col = "black", lwd = 1) +
    ylim(-2, 2)
}


# CNV Object Accessor Functions ------------------------------------------------

cnv_extract_data <- function(cnv_obj){
  return(cnv_obj$data)
}

