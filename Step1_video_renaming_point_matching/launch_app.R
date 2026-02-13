# Launch Script for DJI Video Renamer Shiny App

cat("========================================\n")
cat("DJI Video Renamer - Launcher\n")
cat("========================================\n\n")

# Required packages
required_packages <- c("shiny", "DT", "lubridate", "shinyFiles", "fs")

# Optional packages (nice to have but not required)
optional_packages <- c("av")

cat("Checking for required packages...\n")

# Check which packages are missing
missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

# Auto-install missing required packages
if (length(missing_packages) > 0) {
  cat("\n📦 Installing missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("This may take a few minutes...\n\n")
  
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
}

# Check and auto-install optional packages
missing_optional <- c()
for (pkg in optional_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_optional <- c(missing_optional, pkg)
  }
}

if (length(missing_optional) > 0) {
  cat("📦 Installing optional packages:", paste(missing_optional, collapse = ", "), "\n")
  cat("(These enable extra features like video duration warnings)\n\n")
  
  for (pkg in missing_optional) {
    cat("  - Installing", pkg, "...")
    tryCatch({
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      cat(" ✓\n")
    }, error = function(e) {
      cat(" ⚠ Skipped (optional)\n")
      cat("    Note:", conditionMessage(e), "\n")
      cat("    The app will work without this package.\n")
    })
  }
  cat("\n")
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

