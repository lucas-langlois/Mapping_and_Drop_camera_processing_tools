# Launch Script for DJI Video Renamer Shiny App

cat("========================================\n")
cat("DJI Video Renamer - Launcher\n")
cat("========================================\n\n")

# Required packages
required_packages <- c("shiny", "DT", "lubridate", "shinyFiles", "fs")

cat("Checking for required packages...\n")

# Check which packages are missing
missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

# If packages are missing, offer to install them
if (length(missing_packages) > 0) {
  cat("\n⚠ Missing packages detected:", paste(missing_packages, collapse = ", "), "\n\n")
  cat("Would you like to install them now? (This may take a few minutes)\n")
  
  # Auto-install in non-interactive mode or prompt in interactive mode
  if (interactive()) {
    response <- readline(prompt = "Install now? (yes/no): ")
    should_install <- tolower(trimws(response)) %in% c("yes", "y", "")
  } else {
    # In non-interactive mode, auto-install
    should_install <- TRUE
  }
  
  if (should_install) {
    cat("\nInstalling packages...\n")
    for (pkg in missing_packages) {
      cat("  - Installing", pkg, "...")
      tryCatch({
        install.packages(pkg, dependencies = TRUE, quiet = TRUE)
        cat(" ✓\n")
      }, error = function(e) {
        cat(" ✗ FAILED\n")
        cat("    Error:", conditionMessage(e), "\n")
      })
    }
    cat("\n")
  } else {
    cat("\nPackage installation cancelled.\n")
    cat('Please install packages manually or run: source("install_packages.R")\n\n')
    stop("Required packages not installed.", call. = FALSE)
  }
}

# Load packages
cat("Loading packages...\n")
all_loaded <- TRUE
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  ✗ Failed to load:", pkg, "\n")
    all_loaded <- FALSE
  }
}

if (!all_loaded) {
  cat("\n⚠ Some packages failed to load.\n")
  cat('Try running: source("install_packages.R")\n\n')
  stop("Failed to load required packages.", call. = FALSE)
}

cat("✓ All packages loaded successfully!\n\n")

# Launch the Shiny app
cat("========================================\n")
cat("Launching DJI Video Renamer App...\n")
cat("========================================\n\n")
cat("The app will open in your web browser.\n")
cat("To stop the app, press Ctrl+C or ESC in RStudio.\n\n")

shiny::runApp("video_renamer_app.R", launch.browser = TRUE)

