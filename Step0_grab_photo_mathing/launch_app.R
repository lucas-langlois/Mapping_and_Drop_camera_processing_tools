# Launch Script for Grab Photo Linker Shiny App

cat("========================================\n")
cat("Grab Photo Linker - Launcher\n")
cat("========================================\n\n")

# Required packages
required_packages <- c("shiny", "DT", "shinyFiles", "fs")

# Optional packages (needed for EXIF GPS matching method)
optional_packages <- c("exifr")

cat("Checking for required packages...\n")

missing_packages <- c()
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  cat("\nInstalling missing required packages:", paste(missing_packages, collapse = ", "), "\n")
  cat("This may take a few minutes...\n\n")

  for (pkg in missing_packages) {
    cat("  - Installing", pkg, "...")
    tryCatch({
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      cat(" OK\n")
    }, error = function(e) {
      cat(" FAILED\n")
      cat("    Error:", conditionMessage(e), "\n")
    })
  }
  cat("\n")
}

# Check and install optional packages
missing_optional <- optional_packages[!sapply(optional_packages, requireNamespace, quietly = TRUE)]
if (length(missing_optional) > 0) {
  cat("\nInstalling optional packages:", paste(missing_optional, collapse = ", "), "\n")
  cat("(Required for the EXIF GPS matching method)\n\n")
  for (pkg in missing_optional) {
    cat("  - Installing", pkg, "...")
    tryCatch({
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      cat(" OK\n")
    }, error = function(e) {
      cat(" Skipped (optional)\n")
      cat("    Note:", conditionMessage(e), "\n")
      cat("    The filename matching method will still work without this package.\n")
    })
  }
  cat("\n")
}

cat("Loading packages...\n")
all_loaded <- TRUE
for (pkg in required_packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  Failed to load:", pkg, "\n")
    all_loaded <- FALSE
  }
}

if (!all_loaded) {
  cat("\nSome packages failed to load.\n")
  cat('Try running: source("install_packages.R")\n\n')
  stop("Failed to load required packages.", call. = FALSE)
}

cat("All packages loaded successfully!\n\n")

cat("========================================\n")
cat("Launching Grab Photo Linker App...\n")
cat("========================================\n\n")
cat("The app will open in your web browser.\n")
cat("To stop the app, press Ctrl+C or ESC in RStudio.\n\n")

shiny::runApp("link_photos_to_csv_app.R", launch.browser = TRUE)
