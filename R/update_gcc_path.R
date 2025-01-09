# Get the current PATH
current_path <- Sys.getenv("PATH")

# Define the new path you want to add
new_path <- "/usr/bin"

# Combine the new path with the current PATH
new_combined_path <- paste(new_path, current_path, sep=":")

# Set the new PATH
Sys.setenv(PATH = new_combined_path)

# clean up 
rm(current_path, new_path, new_combined_path)
