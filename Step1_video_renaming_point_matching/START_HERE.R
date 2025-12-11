# ========================================
# DJI VIDEO RENAMER - START HERE
# ========================================
#
# Welcome! This tool helps you match and rename DJI camera videos
# based on timestamps from a CSV file.
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
# Just run:
#
#   source("launch_app.R")
#
# ========================================

cat("\n")
cat("========================================\n")
cat("  DJI VIDEO RENAMER - WELCOME!\n")
cat("========================================\n\n")

cat("This tool helps you:\n")
cat("  • Match DJI videos to CSV timestamps\n")
cat("  • Rename videos with standardized names\n")
cat("  • Handle timezone conversions\n")
cat("  • Process multiple videos at once\n\n")

cat("========================================\n")
cat("  QUICK START GUIDE\n")
cat("========================================\n\n")

# Check if this is first time use
required_packages <- c("shiny", "DT", "lubridate", "shinyFiles", "fs")
missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  # First time user
  cat("👋 It looks like this is your first time!\n\n")
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
  # Returning user
  cat("✓ All packages are installed!\n\n")
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
cat("• Read README_SHINY_APP.md for detailed instructions\n")
cat("• Check the 'Instructions' tab in the app\n\n")

