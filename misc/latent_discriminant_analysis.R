# load required packages -----
suppressMessages(library(topicmodels))
suppressMessages(library(R.utils))


# global defaults -----
input = "input.rds" # filename of input data
ouput = "lda_results.rds"
method = "Gibbs"
n_cluster = 20 # Number of clusters
seed = 321442 # seed (for reproducibility)


# parse command line arguments -----
args <- cmdArgs()
input <- cmdArg("in", input)
output <- cmdArg("out", ouput)
method = cmdArg("method", method)
n_cluster <- cmdArg("clusters", n_cluster)
seed <- cmdArg("seed", seed)

# Print arguments (for log)
cat("\n")
cat("### Arguments \n")
cat(paste0("Input file: ", input, "\n"))
cat(paste0("Output file: ", output, "\n"))
cat(paste0("Fitting method: ", method, "\n"))
cat(paste0("Number of clusters: ", n_cluster, "\n"))
cat(paste0("Seed value: ", seed, "\n\n"))


# load data -----
cat(paste0("Reading data... \n"))
count_mat <- readRDS(file.path("./", input))
count_mat <- as.matrix(count_mat)

# replace NAs with 0s
count_mat[is.na(count_mat)] <- 0

# save rownames (otherwise lost in next step)
row_names <- rownames(count_mat)

# make sure matrix contains integers (LDA crashes otherwise)
count_mat <- apply(count_mat, 2, as.integer)
cat(paste0("Done \n"))

# add rownames back
row.names(count_mat) <- row_names

# Report matrix dimensions
dm <- dim(count_mat)
dm <- paste0(dm, collapse = " x ")
cat(paste0("Dimensions of matrix: ", dm, " \n\n"))


# Run LDA -----
cat("Started LDA \n")
t0 <- Sys.time()
lda <- topicmodels::LDA(x = t(count_mat),
                        k = n_cluster,
                        method = method,
                        control = list(seed = seed))
t1 <- Sys.time() - t0
cat(paste0("LDA took ", round(t1, 2), " ", units(t1), " to complete \n"))

# Save output
cat("Saving file... \n")