# ========================================
# GRAB PHOTO LINKER - START HERE
# ========================================
#
# This tool links grab photos to rows in a seagrass (or similar) CSV file.
# Matching is done by the leading POINT_ID number in each photo filename.
# A GRAB_FILENAME column is added to the CSV with all matched photo filenames.
#
# Expected photo filename format:
#   {POINT_ID}_{YYYYMMDD}_{HHMMSS}_Photo {N}.jpg
#   e.g.  42_20251119_062201_Photo 3.jpg
#
# ========================================
# FIRST TIME USERS
# ========================================
#
# Step 1: Install required packages (only needed once)
#   Run this command:
#
#     source("install_packages.R")
#
# Step 2: Launch the app
#   Run this command:
#
#     source("launch_app.R")
#
# ========================================
# QUICK START (if packages already installed)
# ========================================
#
#   source("launch_app.R")
#
# ========================================

cat("\n")
cat("========================================\n")
cat("  GRAB PHOTO LINKER - WELCOME!\n")
cat("========================================\n\n")

cat("This tool helps you:\n")
cat("  * Link grab photos to CSV rows by POINT_ID\n")
cat("  * Preview matches before saving\n")
cat("  * Export an updated CSV with a GRAB_FILENAME column\n\n")

cat("========================================\n")
cat("  QUICK START GUIDE\n")
cat("========================================\n\n")

required_packages <- c("shiny", "DT", "shinyFiles", "fs")
missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  cat("It looks like this is your first time!\n\n")
  cat("Missing packages:", paste(missing_packages, collapse = ", "), "\n\n")
  cat("STEP 1: Install Required Packages\n")
  cat("  Run this command in the R console:\n\n")
  cat('    source("install_packages.R")\n\n')
  cat("STEP 2: Launch the App\n")
  cat("  After packages are installed, run:\n\n")
  cat('    source("launch_app.R")\n\n')

  if (interactive()) {
    cat("========================================\n\n")
    response <- readline(prompt = "Would you like to install packages now? (yes/no): ")
    if (tolower(trimws(response)) %in% c("yes", "y", "")) {
      cat("\n")
      source("install_packages.R")
      cat("\n========================================\n")
      response2 <- readline(prompt = "Packages installed! Launch the app now? (yes/no): ")
      if (tolower(trimws(response2)) %in% c("yes", "y", "")) {
        cat("\n")
        source("launch_app.R")
      } else {
        cat("\nYou can launch the app later by running:\n")
        cat('  source("launch_app.R")\n\n')
      }
    }
  }

} else {
  cat("All packages are installed!\n\n")
  cat("To launch the app, run:\n\n")
  cat('  source("launch_app.R")\n\n')

  if (interactive()) {
    cat("========================================\n\n")
    response <- readline(prompt = "Launch the app now? (yes/no): ")
    if (tolower(trimws(response)) %in% c("yes", "y", "")) {
      cat("\n")
      source("launch_app.R")
    }
  }
}

cat("========================================\n")
cat("  NEED HELP?\n")
cat("========================================\n\n")
cat("Check the 'Instructions' tab inside the app.\n\n")
