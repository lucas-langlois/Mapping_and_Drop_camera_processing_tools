# Installation Script for DJI Video Renamer
# Run this script first if you're a new user

cat("========================================\n")
cat("DJI Video Renamer - Package Installer\n")
cat("========================================\n\n")

# List of required packages
required_packages <- c(
  "shiny",       # Web application framework
  "DT",          # Interactive tables
  "lubridate",   # Date/time manipulation
  "shinyFiles",  # File browser in Shiny
  "fs"           # Cross-platform file system operations
)

# Optional packages (nice to have but not required)
optional_packages <- c(
  "av"           # Video duration checking (enables warnings for short videos)
)

cat("Checking for required packages...\n\n")

# Track installation status
packages_to_install <- c()
packages_already_installed <- c()

# Check each package
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    packages_to_install <- c(packages_to_install, pkg)
    cat("  [ ] ", pkg, " - NOT INSTALLED\n", sep = "")
  } else {
    packages_already_installed <- c(packages_already_installed, pkg)
    cat("  [✓] ", pkg, " - Already installed\n", sep = "")
  }
}

cat("\n")

# Check optional packages
cat("Checking for optional packages...\n\n")
optional_to_install <- c()
optional_already_installed <- c()

for (pkg in optional_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    optional_to_install <- c(optional_to_install, pkg)
    cat("  [ ] ", pkg, " - NOT INSTALLED (optional)\n", sep = "")
  } else {
    optional_already_installed <- c(optional_already_installed, pkg)
    cat("  [✓] ", pkg, " - Already installed (optional)\n", sep = "")
  }
}

cat("\n")

# Install missing packages
if (length(packages_to_install) > 0) {
  cat("========================================\n")
  cat("Installing", length(packages_to_install), "required package(s)...\n")
  cat("========================================\n\n")
  
  for (pkg in packages_to_install) {
    cat("Installing:", pkg, "...\n")
    tryCatch({
      install.packages(pkg, dependencies = TRUE)
      cat("  ✓ Successfully installed", pkg, "\n\n")
    }, error = function(e) {
      cat("  ✗ ERROR installing", pkg, "\n")
      cat("    Error message:", conditionMessage(e), "\n\n")
    })
  }
  
  cat("========================================\n")
  cat("Installation Complete!\n")
  cat("========================================\n\n")
  
  # Verify installations
  cat("Verifying installations...\n\n")
  failed_packages <- c()
  
  for (pkg in packages_to_install) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("  [✓] ", pkg, " - Successfully verified\n", sep = "")
    } else {
      cat("  [✗] ", pkg, " - FAILED to install\n", sep = "")
      failed_packages <- c(failed_packages, pkg)
    }
  }
  
  cat("\n")
  
  if (length(failed_packages) > 0) {
    cat("========================================\n")
    cat("WARNING: Some packages failed to install\n")
    cat("========================================\n\n")
    cat("Failed packages:", paste(failed_packages, collapse = ", "), "\n\n")
    cat("Please try installing them manually:\n")
    cat('  install.packages(c("', paste(failed_packages, collapse = '", "'), '"))\n\n', sep = "")
  } else {
    cat("========================================\n")
    cat("All required packages installed successfully!\n")
    cat("========================================\n\n")
  }
  
} else {
  cat("========================================\n")
  cat("All required packages are already installed!\n")
  cat("========================================\n\n")
}

# Install optional packages
if (length(optional_to_install) > 0) {
  cat("========================================\n")
  cat("Installing", length(optional_to_install), "optional package(s)...\n")
  cat("========================================\n\n")
  cat("Note: Optional packages enable extra features.\n")
  cat("The app will work without them if installation fails.\n\n")
  
  for (pkg in optional_to_install) {
    cat("Installing:", pkg, "...\n")
    tryCatch({
      install.packages(pkg, dependencies = TRUE)
      cat("  ✓ Successfully installed", pkg, "\n\n")
    }, error = function(e) {
      cat("  ⚠ Installation failed (this is OK - optional package)\n")
      cat("    Error message:", conditionMessage(e), "\n\n")
    })
  }
  
  # Verify optional installations
  cat("Verifying optional packages...\n\n")
  
  for (pkg in optional_to_install) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("  [✓] ", pkg, " - Successfully verified\n", sep = "")
    } else {
      cat("  [⚠] ", pkg, " - Not installed (optional)\n", sep = "")
    }
  }
  
  cat("\n")
} else {
  cat("All optional packages are already installed!\n\n")
}

cat("========================================\n")
cat("Package Summary\n")
cat("========================================\n")
cat("Required packages:\n")
cat("  - Total required:", length(required_packages), "\n")
cat("  - Already installed:", length(packages_already_installed), "\n")
cat("  - Newly installed:", length(packages_to_install), "\n")
cat("\nOptional packages:\n")
cat("  - Total optional:", length(optional_packages), "\n")
cat("  - Already installed:", length(optional_already_installed), "\n")
cat("  - Newly installed:", sum(sapply(optional_to_install, function(pkg) requireNamespace(pkg, quietly = TRUE))), "\n")
cat("\n")

if (length(packages_to_install) == 0 || all(sapply(required_packages, function(pkg) requireNamespace(pkg, quietly = TRUE)))) {
  cat("✓ Setup complete! You're ready to use the DJI Video Renamer.\n")
  cat("\nYou can now run the app with:\n")
  cat('  source("launch_app.R")\n\n')
}

