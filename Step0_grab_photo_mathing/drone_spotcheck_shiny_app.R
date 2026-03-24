### Drone Spotcheck Image Processing - Shiny App
### Interactive tool for processing and analyzing drone imagery

#######################################
## AUTO-INSTALL REQUIRED PACKAGES
## This section checks and installs any missing packages
#######################################

# List of required packages (order matters - terra must be installed before tidyterra)
required_packages <- c(
  "shiny", "shinydashboard", "tidyverse", "magick", "lubridate", 
  "exifr", "leaflet", "DT", "shinyjs", "shinyWidgets", "plotly", "base64enc",
  "terra", "tidyterra"  # terra MUST be installed before tidyterra
)

# Function to check and install packages
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  
  if(length(new_packages) > 0) {
    cat("📦 Installing missing packages:", paste(new_packages, collapse=", "), "\n")
    cat("This may take a few minutes...\n")
    cat("ℹ️  Note: terra will be installed before tidyterra (required dependency)\n\n")
    
    failed_packages <- c()
    
    for(pkg in new_packages) {
      cat("Installing", pkg, "...\n")
      tryCatch({
        install.packages(pkg, 
                        repos = "https://cloud.r-project.org/",
                        dependencies = TRUE,
                        quiet = FALSE)
        cat("✅", pkg, "installed successfully\n")
      }, error = function(e) {
        cat("❌ Failed to install", pkg, "\n")
        cat("   Error:", conditionMessage(e), "\n")
        failed_packages <<- c(failed_packages, pkg)
      })
    }
    
    if(length(failed_packages) > 0) {
      cat("\n⚠️ WARNING: The following packages failed to install:\n")
      cat("   ", paste(failed_packages, collapse=", "), "\n\n")
      cat("📝 Common solutions:\n")
      cat("   • For 'terra' issues: Make sure you have Rtools installed (Windows)\n")
      cat("   • For 'tidyterra': Install 'terra' first, then try again\n")
      cat("   • Try installing manually: install.packages('", failed_packages[1], "')\n")
      cat("   • Check that your R version is up-to-date (R >= 4.0)\n\n")
      stop("Package installation incomplete. Please resolve the issues above and restart the app.")
    } else {
      cat("\n✅ All packages installed successfully!\n\n")
    }
  } else {
    cat("✅ All required packages are already installed!\n\n")
  }
}

# Run the installation check
cat("🔍 Checking for required packages...\n")
install_if_missing(required_packages)

# Load libraries
library(shiny)
library(shinydashboard)
library(tidyverse)
library(terra)
library(tidyterra)
library(magick)
library(lubridate)
library(exifr)
library(leaflet)
library(DT)
library(shinyjs)
library(shinyWidgets)
library(plotly)

# UI Definition
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Drone Spotcheck Processor"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("📁 Setup & Process", tabName = "process", icon = icon("cogs")),
      menuItem("🔍 Duplicate Review", tabName = "duplicates", icon = icon("clone")),
      menuItem("🗺️ Map View", tabName = "map", icon = icon("map")),
      menuItem("📊 Data Explorer", tabName = "data", icon = icon("table")),
      menuItem("🖼️ Image Gallery", tabName = "gallery", icon = icon("images")),
      menuItem("📈 Statistics", tabName = "stats", icon = icon("chart-bar"))
    )
  ),
  
  dashboardBody(
    useShinyjs(),
    tags$head(
      tags$style(HTML("
        .content-wrapper { background-color: #ecf0f5; }
        .box { border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .progress-bar { background-color: #3c8dbc; }
        .info-box { border-radius: 8px; cursor: pointer; transition: transform 0.2s; }
        .info-box:hover { transform: translateY(-2px); box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
        .image-comparison { display: flex; justify-content: space-around; }
        .image-container { text-align: center; padding: 10px; }
      "))
    ),
    
    tabItems(
      # Tab 1: Process
      tabItem(tabName = "process",
        fluidRow(
          box(
            title = "⚙️ Configuration", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(4,
                textInput("location", "Location Name:", value = "SR3_spotcheck",
                         placeholder = "e.g., SR3_spotcheck")
              ),
              column(4,
                selectInput("drone_model", "Drone Model:", 
                           choices = c("M3E" = "M3E", "Other" = "Other"),
                           selected = "M3E")
              ),
              column(4,
                numericInput("crop_size", "Crop Size (pixels):", 
                            value = 1800, min = 100, max = 5000, step = 100),
                helpText("📐 Pixel size for standard 50×50cm quadrat.",
                        "Estimate from calibration photo.",
                        "Default: 1800px for M3E at 1m altitude (normal camera, not zoom).")
              )
            )
          )
        ),
        
        fluidRow(
          box(
            title = "🚀 Processing Pipeline", status = "info", solidHeader = TRUE, width = 12,
            p("Click the steps below to process your drone images:"),
            br(),
            fluidRow(
              column(2,
                actionBttn("btn_detect_duplicates", "Step 0: Detect Duplicates", 
                          style = "fill", color = "royal", size = "lg", block = TRUE,
                          icon = icon("clone"))
              ),
              column(2,
                actionBttn("btn_rename", "Step 1: Rename Photos", 
                          style = "fill", color = "primary", size = "lg", block = TRUE,
                          icon = icon("file-signature"))
              ),
              column(2,
                actionBttn("btn_exif", "Step 2: Extract EXIF", 
                          style = "fill", color = "success", size = "lg", block = TRUE,
                          icon = icon("camera"))
              ),
              column(3,
                actionBttn("btn_crop", "Step 3: Crop Images", 
                          style = "fill", color = "warning", size = "lg", block = TRUE,
                          icon = icon("crop"))
              ),
              column(3,
                actionBttn("btn_export", "Step 4: Export Data", 
                          style = "fill", color = "danger", size = "lg", block = TRUE,
                          icon = icon("file-export"))
              )
            ),
            br(),
            verbatimTextOutput("process_log")
          )
        ),
        
        fluidRow(
          valueBoxOutput("box_photos", width = 3),
          valueBoxOutput("box_processed", width = 3),
          valueBoxOutput("box_altitude", width = 3),
          valueBoxOutput("box_coverage", width = 3)
        )
      ),
      
      # Tab 2: Duplicate Review
      tabItem(tabName = "duplicates",
        fluidRow(
          box(
            title = "🔍 Duplicate Detection Settings", status = "primary", solidHeader = TRUE, width = 12,
            fluidRow(
              column(3,
                numericInput("distance_threshold", "Distance Threshold (meters):",
                            value = 5, min = 1, max = 50, step = 1),
                helpText("Photos within this distance OR time threshold")
              ),
              column(3,
                numericInput("time_threshold", "Time Threshold (seconds):",
                            value = 30, min = 5, max = 120, step = 5),
                helpText("Photos within this time OR distance threshold")
              ),
              column(3,
                actionButton("btn_refresh_duplicates", "Refresh Detection",
                            class = "btn-primary btn-lg", style = "margin-top: 25px;"),
                helpText("Re-analyze with new settings")
              ),
              column(3,
                actionButton("btn_apply_selection", "Apply Selection",
                            class = "btn-success btn-lg", style = "margin-top: 25px;"),
                helpText("Save selected images and exclude duplicates")
              )
            ),
            br(),
            p(style = "color: #555; font-style: italic;", 
              "ℹ️ Photos are grouped as duplicates if they meet EITHER the distance OR time threshold (or both).")
          )
        ),
        fluidRow(
          box(
            title = "🗺️ Duplicate Locations Map", status = "warning", solidHeader = TRUE, width = 12,
            leafletOutput("duplicates_map", height = "400px"),
            br(),
            p("Click on markers to see photo details. Duplicate groups are shown in different colors.")
          )
        ),
        fluidRow(
          box(
            title = "📊 Duplicate Groups", status = "info", solidHeader = TRUE, width = 6,
            DTOutput("duplicates_table")
          ),
          box(
            title = "🖼️ Selected Group Preview", status = "success", solidHeader = TRUE, width = 6,
            uiOutput("duplicate_review_ui")
          )
        )
      ),
      
      # Tab 3: Map
      tabItem(tabName = "map",
        fluidRow(
          box(
            title = "🗺️ Photo Locations", status = "primary", solidHeader = TRUE, width = 12,
            leafletOutput("map", height = "600px"),
            br(),
            p("Click on markers to view photo details")
          )
        )
      ),
      
      # Tab 4: Data Explorer
      tabItem(tabName = "data",
        fluidRow(
          box(
            title = "📊 Metadata Table", status = "primary", solidHeader = TRUE, width = 12,
            downloadButton("download_data", "Download CSV", class = "btn-info"),
            br(), br(),
            DTOutput("data_table")
          )
        )
      ),
      
      # Tab 5: Gallery
      tabItem(tabName = "gallery",
        fluidRow(
          box(
            title = "🖼️ Image Gallery", status = "primary", solidHeader = TRUE, width = 12,
            sliderInput("gallery_select", "Select Image:", min = 1, max = 10, value = 1, 
                       step = 1, width = "100%"),
            uiOutput("image_display")
          )
        )
      ),
      
      # Tab 6: Statistics
      tabItem(tabName = "stats",
        fluidRow(
          box(
            title = "📈 Processing Statistics", status = "primary", solidHeader = TRUE, width = 6,
            plotlyOutput("altitude_plot")
          ),
          box(
            title = "⏱️ Time Distribution", status = "info", solidHeader = TRUE, width = 6,
            plotlyOutput("time_plot")
          )
        ),
        fluidRow(
          box(
            title = "📐 Image Dimensions", status = "success", solidHeader = TRUE, width = 12,
            plotlyOutput("dimension_plot")
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values to store data
  rv <- reactiveValues(
    spotcheck = NULL,
    exif_data = NULL,
    raw_exif = NULL,
    duplicate_groups = NULL,
    duplicate_selections = list(),  # Store selections separately to avoid triggering UI re-renders
    duplicate_handler_counts = list(),
    selected_photos = NULL,
    duplicates_detected = FALSE,
    photos_renamed = FALSE,
    exif_extracted = FALSE,
    images_cropped = FALSE,
    data_exported = FALSE,
    log = "Ready to process images...\n"
  )

  # Track dynamic observers for duplicate selection buttons
  duplicate_button_observers <- reactiveVal(list())

  # Ensure stored selections always match current group size
  get_group_selections <- function(group_idx, group) {
    selections <- rv$duplicate_selections[[as.character(group_idx)]]

    if(is.null(selections)) {
      selections <- group$selected
    }

    selections <- as.logical(selections)
    selections[is.na(selections)] <- FALSE

    if(length(selections) != nrow(group)) {
      fixed <- rep(FALSE, nrow(group))
      copy_len <- min(length(selections), nrow(group))
      if(copy_len > 0) {
        fixed[1:copy_len] <- selections[1:copy_len]
      }
      selections <- fixed
    }

    if(length(selections) > 0 && !any(selections)) {
      selections[1] <- TRUE
    }

    selections
  }
  
  # Helper function to detect duplicates
  detect_duplicates_func <- function(exif_raw, dist_threshold, time_threshold) {
    duplicate_groups <- list()
    group_id <- 1
    processed <- rep(FALSE, nrow(exif_raw))
    
    for(i in 1:(nrow(exif_raw)-1)) {
      if(processed[i]) next
      
      group <- c(i)
      
      for(j in (i+1):nrow(exif_raw)) {
        if(processed[j]) next
        
        # Calculate distance in meters using Haversine formula
        lat1 <- exif_raw$GPSLatitude[i] * pi/180
        lat2 <- exif_raw$GPSLatitude[j] * pi/180
        lon1 <- exif_raw$GPSLongitude[i] * pi/180
        lon2 <- exif_raw$GPSLongitude[j] * pi/180
        
        dlat <- lat2 - lat1
        dlon <- lon2 - lon1
        
        a <- sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2
        c <- 2 * atan2(sqrt(a), sqrt(1-a))
        distance <- 6371000 * c  # Earth radius in meters
        
        # Calculate time difference in seconds
        time_diff <- abs(as.numeric(difftime(exif_raw$DateTimeOriginal[i],
                                             exif_raw$DateTimeOriginal[j],
                                             units = "secs")))
        
        # Check if within thresholds (OR logic - either distance OR time)
        if(distance <= dist_threshold || time_diff <= time_threshold) {
          group <- c(group, j)
          processed[j] <- TRUE
        }
      }
      
      if(length(group) > 1) {
        duplicate_groups[[group_id]] <- exif_raw[group, ]
        duplicate_groups[[group_id]]$group_id <- group_id
        duplicate_groups[[group_id]]$selected <- FALSE
        duplicate_groups[[group_id]]$selected[1] <- TRUE  # Select first by default
        group_id <- group_id + 1
      }
      processed[i] <- TRUE
    }
    
    return(duplicate_groups)
  }
  
  # Check for existing work on startup (run once)
  observe({
    isolate({
      if(rv$log == "Ready to process images...\n") {
        log_msg <- ""
        
        # Check if photos already renamed
        if(dir.exists("raw_sorted_newname")) {
          renamed_files <- list.files("raw_sorted_newname", pattern = "\\.JPG$")
          if(length(renamed_files) > 0) {
            rv$photos_renamed <- TRUE
            log_msg <- paste0(log_msg, "✅ Found ", length(renamed_files), " renamed photos\n")
          }
        }
        
        # Check for existing CSV files to reload data
        csv_files <- list.files(pattern = "^SR3_spotcheck_[0-9]{8}\\.csv$")
        if(length(csv_files) > 0) {
          tryCatch({
            spotcheck <- read.csv(csv_files[1], stringsAsFactors = FALSE)
            if("TIMESTAMP" %in% colnames(spotcheck)) {
              spotcheck$TIMESTAMP <- as.POSIXct(spotcheck$TIMESTAMP)
            }
            rv$spotcheck <- spotcheck
            rv$exif_extracted <- TRUE
            log_msg <- paste0(log_msg, "✅ Loaded existing data from ", csv_files[1], "\n")
            updateSliderInput(session, "gallery_select", max = nrow(spotcheck))
          }, error = function(e) {
            # Silently fail if CSV can't be loaded
          })
        }
        
        # Check if images already cropped
        if(dir.exists("quads_50cm") || dir.exists("quads_square")) {
          crop_50cm <- if(dir.exists("quads_50cm")) length(list.files("quads_50cm", pattern = "\\.JPG$")) else 0
          crop_square <- if(dir.exists("quads_square")) length(list.files("quads_square", pattern = "\\.JPG$")) else 0
          
          if(crop_50cm > 0 || crop_square > 0) {
            rv$images_cropped <- TRUE
            log_msg <- paste0(log_msg, "✅ Found cropped images (50cm: ", crop_50cm, ", square: ", crop_square, ")\n")
          }
        }
        
        # Check if data files exist
        data_files <- list.files(pattern = "^SR3_spotcheck_[0-9]{8}_data\\.csv$")
        if(length(data_files) > 0) {
          rv$data_exported <- TRUE
          log_msg <- paste0(log_msg, "✅ Found exported data files\n")
        }
        
        if(log_msg != "") {
          rv$log <- paste0(rv$log, "\n🔍 Checking existing work...\n", log_msg, "\nYou can continue from any step!\n")
        }
      }
    })
  })
  
  # Trigger variable for when duplicate groups are initialized (not when selections change)
  rv$duplicates_initialized <- FALSE
  
  # Step 0: Detect Duplicates
  observeEvent(input$btn_detect_duplicates, {
    withProgress(message = 'Detecting duplicate images...', value = 0, {
      
      tryCatch({
        incProgress(0.2, detail = "Reading raw photos...")
        
        list_photo <- list.files("raw", full.names = TRUE, pattern = "\\.JPG$")
        
        if(length(list_photo) == 0) {
          rv$log <- paste0(rv$log, "❌ ERROR: No JPG files found in 'raw' folder\n")
          showNotification("No JPG files found in 'raw' folder", type = "error")
          return()
        }
        
        incProgress(0.3, detail = "Extracting EXIF data...")
        
        # Extract EXIF data for duplicate detection
        exif_raw <- exifr::read_exif(list_photo,
                                     tags = c("FileName", "DateTimeOriginal", "GPSLatitude",
                                            "GPSLongitude"),
                                     recursive = FALSE)
        
        exif_raw <- as.data.frame(exif_raw)
        exif_raw$path <- list_photo
        exif_raw$DateTimeOriginal <- as.POSIXct(exif_raw$DateTimeOriginal, format="%Y:%m:%d %H:%M:%S")
        
        incProgress(0.3, detail = "Analyzing for duplicates...")
        
        # Use helper function to detect duplicates
        duplicate_groups <- detect_duplicates_func(exif_raw, input$distance_threshold, input$time_threshold)
        
        rv$raw_exif <- exif_raw
        rv$duplicate_groups <- duplicate_groups
        rv$duplicate_selections <- list()
        rv$duplicate_handler_counts <- list()
        rv$duplicates_detected <- TRUE
        
        # Initialize selected photos (all photos by default)
        rv$selected_photos <- exif_raw$path
        
        incProgress(0.2, detail = "Done!")
        
        n_groups <- length(duplicate_groups)
        n_total_dups <- if(n_groups > 0) sum(sapply(duplicate_groups, nrow)) else 0
        
        rv$log <- paste0(rv$log, "✅ Step 0 Complete: Found ", n_groups, 
                        " duplicate groups (", n_total_dups, " photos total)\n",
                        "   Please review duplicates in the 'Duplicate Review' tab\n")
        showNotification(paste("Found", n_groups, "duplicate groups!"), type = "message")
        
        # Switch to duplicates tab
        updateTabItems(session, "sidebar", "duplicates")

        # Reset table selection so review panel starts clean after regrouping
        proxy <- dataTableProxy('duplicates_table')
        selectRows(proxy, NULL)
        
      }, error = function(e) {
        rv$log <- paste0(rv$log, "❌ ERROR: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Refresh duplicate detection with new settings
  observeEvent(input$btn_refresh_duplicates, {
    req(rv$raw_exif)
    
    withProgress(message = 'Re-analyzing duplicates...', value = 0, {
      tryCatch({
        incProgress(0.5, detail = "Detecting duplicates with new settings...")
        
        # Re-run duplicate detection with updated thresholds
        duplicate_groups <- detect_duplicates_func(rv$raw_exif, 
                                                   input$distance_threshold, 
                                                   input$time_threshold)
        
        rv$duplicate_groups <- duplicate_groups
        rv$duplicate_selections <- list()
        rv$duplicate_handler_counts <- list()
        image_cache(list())  # Clear cache when refreshing

        # Reset selected row so stale group UI does not persist after regrouping
        proxy <- dataTableProxy('duplicates_table')
        selectRows(proxy, NULL)
        
        incProgress(0.5, detail = "Done!")
        
        n_groups <- length(duplicate_groups)
        n_total_dups <- if(n_groups > 0) sum(sapply(duplicate_groups, nrow)) else 0
        
        rv$log <- paste0(rv$log, "🔄 Duplicates refreshed: Found ", n_groups, 
                        " groups (", n_total_dups, " photos) with new settings\n")
        showNotification(paste("Found", n_groups, "duplicate groups with new settings!"), 
                        type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Render duplicates table (only renders once, updates via proxy)
  output$duplicates_table <- renderDT({
    req(rv$duplicate_groups)
    
    if(length(rv$duplicate_groups) == 0) {
      return(data.frame(Message = "No duplicates found!"))
    }
    
    # Create summary table - initial render only
    summary_df <- data.frame(
      Group = sapply(rv$duplicate_groups, function(g) unique(g$group_id)),
      Count = sapply(rv$duplicate_groups, nrow),
      Selected = sapply(rv$duplicate_groups, function(g) sum(g$selected)),
      FirstPhoto = sapply(rv$duplicate_groups, function(g) basename(g$FileName[1])),
      MaxDistance = sapply(rv$duplicate_groups, function(g) {
        if(nrow(g) < 2) return("0m")
        
        # Calculate max distance between any two photos in the group
        max_dist <- 0
        for(i in 1:(nrow(g)-1)) {
          for(j in (i+1):nrow(g)) {
            lat1 <- g$GPSLatitude[i] * pi/180
            lat2 <- g$GPSLatitude[j] * pi/180
            lon1 <- g$GPSLongitude[i] * pi/180
            lon2 <- g$GPSLongitude[j] * pi/180
            
            dlat <- lat2 - lat1
            dlon <- lon2 - lon1
            
            a <- sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2
            c <- 2 * atan2(sqrt(a), sqrt(1-a))
            distance <- 6371000 * c  # Earth radius in meters
            
            max_dist <- max(max_dist, distance)
          }
        }
        paste0(round(max_dist, 1), "m")
      }),
      TimeDiff = sapply(rv$duplicate_groups, function(g) {
        paste0(round(as.numeric(difftime(max(g$DateTimeOriginal), 
                                         min(g$DateTimeOriginal), units = "secs"))), "s")
      })
    )
    
    datatable(summary_df, 
              options = list(pageLength = 10),
              rownames = FALSE,
              selection = 'single')
  })
  
  # Render duplicates map
  output$duplicates_map <- renderLeaflet({
    req(rv$duplicate_groups)
    
    if(length(rv$duplicate_groups) == 0) {
      return(
        leaflet() %>%
          addProviderTiles(providers$Esri.WorldImagery) %>%
          setView(lng = 0, lat = 0, zoom = 2) %>%
          addControl(html = "<div style='background: white; padding: 10px; border-radius: 5px;'>No duplicates detected yet.</div>",
                    position = "topright")
      )
    }
    
    # Create color palette for different groups
    colors <- c("#e41a1c", "#377eb8", "#4daf4a", "#984ea3", "#ff7f00", 
                "#ffff33", "#a65628", "#f781bf", "#999999", "#66c2a5")
    
    # Prepare data for mapping
    map_data <- do.call(rbind, lapply(1:length(rv$duplicate_groups), function(i) {
      group <- rv$duplicate_groups[[i]]
      group$color <- colors[(i %% length(colors)) + 1]
      group$group_num <- i
      return(group)
    }))
    
    # Create map with increased max zoom
    m <- leaflet(map_data, options = leafletOptions(maxZoom = 25)) %>%
      addProviderTiles(providers$Esri.WorldImagery, options = providerTileOptions(maxZoom = 25))
    
    # Add markers for each group with different colors
    for(i in 1:length(rv$duplicate_groups)) {
      group <- rv$duplicate_groups[[i]]
      group_color <- colors[(i %% length(colors)) + 1]
      
      m <- m %>%
        addCircleMarkers(
          data = group,
          lng = ~GPSLongitude,
          lat = ~GPSLatitude,
          radius = 8,
          color = group_color,
          fillColor = group_color,
          fillOpacity = 0.7,
          stroke = TRUE,
          weight = 2,
          popup = ~paste0(
            "<b>Group ", i, "</b><br>",
            "<b>Filename:</b> ", basename(FileName), "<br>",
            "<b>Time:</b> ", format(DateTimeOriginal, "%H:%M:%S"), "<br>",
            "<b>Selected:</b> ", ifelse(selected, "✓ Yes", "No")
          ),
          label = ~paste("Group", i),
          labelOptions = labelOptions(
            noHide = TRUE,
            direction = "center",
            textOnly = TRUE,
            style = list(
              "color" = "white",
              "font-weight" = "bold",
              "font-size" = "12px",
              "text-shadow" = "2px 2px 4px #000000"
            )
          ),
          group = paste("Group", i)
        )
    }
    
    # Add legend
    m <- m %>%
      addLegend(
        position = "bottomright",
        colors = colors[1:min(length(rv$duplicate_groups), length(colors))],
        labels = paste("Group", 1:min(length(rv$duplicate_groups), length(colors))),
        title = "Duplicate Groups",
        opacity = 0.7
      ) %>%
      addScaleBar(position = "bottomleft")
    
    return(m)
  })
  
  # Cache for encoded images to avoid re-encoding on selection changes
  image_cache <- reactiveVal(list())
  
  # Render duplicate review UI - completely isolated from selection changes
  output$duplicate_review_ui <- renderUI({
    # Only respond to table row selection changes, not to rv$duplicate_groups or selections
    req(input$duplicates_table_rows_selected)
    group_idx <- input$duplicates_table_rows_selected
    
    # Isolate everything to prevent any reactive updates
    req(isolate(rv$duplicate_groups))
    group <- isolate(rv$duplicate_groups[[group_idx]])
    
    if(is.null(group)) return(NULL)
    
    # Get current cache
    cache <- isolate(image_cache())
    
    # Get selections from separate storage (or use default from group)
    selections <- isolate(get_group_selections(group_idx, group))
    
    # Create UI for each image in the group with larger previews
    image_ui <- lapply(1:nrow(group), function(i) {
      img_path <- group$path[i]
      is_selected <- selections[i]  # Use separate selection storage
      
      # Calculate column width based on number of images (max 2 per row for better viewing)
      col_width <- if(nrow(group) <= 2) 6 else if(nrow(group) <= 4) 3 else 3
      
      column(col_width,
        div(id = paste0("image_border_", group_idx, "_", i),
            style = paste0("border: ", if(is_selected) "4px solid #00a65a" else "2px solid #ddd", 
                          "; padding: 15px; margin: 10px; border-radius: 8px; background-color: white;"),
          h5(style = "font-weight: bold;", basename(group$FileName[i])),
          p(style = "color: #555;", 
            icon("clock"), " ", format(group$DateTimeOriginal[i], "%H:%M:%S")),
          if(file.exists(img_path)) {
            # Use cached images if available, otherwise encode
            cache_key <- paste0("img_", group_idx, "_", i)
            
            if(!is.null(cache[[cache_key]])) {
              encoded <- cache[[cache_key]]$preview
              encoded_full <- cache[[cache_key]]$full
            } else {
              img_data <- image_read(img_path)
              # Larger preview size for better viewing
              img_resized <- image_resize(img_data, "600x600")  # Reduced from 800 for faster loading
              temp_file <- tempfile(fileext = ".jpg")
              image_write(img_resized, temp_file, format = "jpg", quality = 85)  # Reduced quality for speed
              encoded <- base64enc::base64encode(temp_file)
              unlink(temp_file)
              
              # Also create full-size version for popup
              img_full <- image_read(img_path)
              temp_full <- tempfile(fileext = ".jpg")
              image_write(img_full, temp_full, format = "jpg", quality = 95)
              encoded_full <- base64enc::base64encode(temp_full)
              unlink(temp_full)
              
              # Cache the encoded images
              cache[[cache_key]] <- list(preview = encoded, full = encoded_full)
              image_cache(cache)
            }
            
            tagList(
              tags$img(
                src = paste0("data:image/jpeg;base64,", encoded), 
                width = "100%", 
                style = "cursor: zoom-in; border-radius: 4px; box-shadow: 0 2px 4px rgba(0,0,0,0.2);",
                title = "Click to view full size",
                onclick = sprintf(
                  "var w = window.open('', '_blank', 'width=1200,height=900,resizable=yes,scrollbars=yes');
                   w.document.write('<html><head><title>%s</title><style>body{margin:0;display:flex;justify-content:center;align-items:center;min-height:100vh;background:#222;}</style></head><body><img src=\"data:image/jpeg;base64,%s\" style=\"max-width:100%%;height:auto;\"/></body></html>');
                   w.document.close();",
                  basename(group$FileName[i]),
                  encoded_full
                )
              ),
              tags$br(),
              tags$small(
                style = "color: #999;",
                icon("search-plus"), " Click image to zoom"
              )
            )
          } else {
            p("Image not found")
          },
          br(),
          actionButton(paste0("select_", group_idx, "_", i), 
                      if(is_selected) "✓ SELECTED" else "Select This Image",
                      class = "btn-default btn-lg",
                      style = paste0("width: 100%; margin-top: 10px; ",
                                    if(is_selected) "font-weight: bold; color: #00a65a;" else ""),
                      icon = if(is_selected) icon("check-circle") else icon("circle"))
        )
      )
    })
    
    # Check if all are selected (keep all mode)
    all_selected <- all(group$selected)
    
    tagList(
      h3(paste("Group", group_idx, "- Review and Select Image(s)"), 
         style = "color: #3c8dbc; border-bottom: 2px solid #3c8dbc; padding-bottom: 10px;"),
      p(style = "color: #777; font-size: 12px; margin-top: -5px;",
        icon("bug"), " Debug: group has ",
        isolate(rv$duplicate_handler_counts[[as.character(group_idx)]] %||% 0),
        " active button handlers (", nrow(group), " image select + 1 keep-all)."
      ),
      fluidRow(
        column(8,
          p(style = "color: #666; font-style: italic;", 
            icon("info-circle"), " Click on any image to view full-size version in a popup window. Then select the best image to keep, or keep all if they're actually different.")
        ),
        column(4,
          actionButton(paste0("keep_all_", group_idx), 
                      if(all_selected) "✓ KEEPING ALL" else "Keep All Images",
                      class = if(all_selected) "btn-warning btn-lg" else "btn-outline-warning btn-lg",
                      style = "width: 100%; margin-top: 5px;",
                      icon = if(all_selected) icon("check-double") else icon("layer-group"))
        )
      ),
      fluidRow(image_ui)
    )
  })
  
  # Handle image selection - rebuild observers whenever duplicate groups change
  observeEvent(rv$duplicate_groups, {
    req(rv$duplicate_groups)

    # Remove old observers before creating new ones
    old_observers <- isolate(duplicate_button_observers())
    if(length(old_observers) > 0) {
      lapply(old_observers, function(obs) {
        try(obs$destroy(), silent = TRUE)
      })
    }

    new_observers <- list()
    
    # Setup observers for all groups in the current snapshot
    groups_snapshot <- isolate(rv$duplicate_groups)
    handler_counts <- list()
    
    for(group_idx in 1:length(groups_snapshot)) {
      group <- groups_snapshot[[group_idx]]
      handler_counts[[as.character(group_idx)]] <- nrow(group) + 1
      
      # Handle "Keep All" button
      local({
        g_idx <- group_idx
        obs <- observeEvent(input[[paste0("keep_all_", g_idx)]], {
          # Update selection data in separate storage (not in duplicate_groups)
          rv$duplicate_selections[[as.character(g_idx)]] <- rep(TRUE, nrow(rv$duplicate_groups[[g_idx]]))
          
          # Update UI buttons and borders without re-rendering
          for(i in 1:nrow(rv$duplicate_groups[[g_idx]])) {
            shinyjs::html(id = paste0("select_", g_idx, "_", i), html = '<i class="fa fa-check-circle"></i> ✓ SELECTED')
            shinyjs::runjs(paste0("$('#select_", g_idx, "_", i, "').css({'font-weight': 'bold', 'color': '#00a65a'});"))
            # Update border to green
            shinyjs::runjs(paste0("$('#image_border_", g_idx, "_", i, "').css({'border': '4px solid #00a65a', 'background-color': 'white'});"))
          }
          shinyjs::removeClass(id = paste0("keep_all_", g_idx), class = "btn-outline-warning")
          shinyjs::addClass(id = paste0("keep_all_", g_idx), class = "btn-warning")
          shinyjs::html(id = paste0("keep_all_", g_idx), html = "✓ KEEPING ALL")
          
          # Update the table's Selected column using JavaScript to avoid losing selection
          selected_count <- nrow(rv$duplicate_groups[[g_idx]])
          shinyjs::runjs(paste0("$('#duplicates_table table tbody tr:eq(", g_idx - 1, ") td:eq(2)').text('", selected_count, "');"))
          
          # Old approach that caused selection loss - kept for reference but not executed
          if(FALSE) {
          proxy <- dataTableProxy('duplicates_table')
          replaceData(proxy, isolate({
            summary_df <- data.frame(
              Group = sapply(rv$duplicate_groups, function(g) unique(g$group_id)),
              Count = sapply(rv$duplicate_groups, nrow),
              Selected = sapply(1:length(rv$duplicate_groups), function(i) {
                selections <- rv$duplicate_selections[[as.character(i)]]
                if(is.null(selections)) selections <- rv$duplicate_groups[[i]]$selected
                sum(selections)
              }),
              FirstPhoto = sapply(rv$duplicate_groups, function(g) basename(g$FileName[1])),
              MaxDistance = sapply(rv$duplicate_groups, function(g) {
                if(nrow(g) < 2) return("0m")
                max_dist <- 0
                for(i in 1:(nrow(g)-1)) {
                  for(j in (i+1):nrow(g)) {
                    lat1 <- g$GPSLatitude[i] * pi/180
                    lat2 <- g$GPSLatitude[j] * pi/180
                    lon1 <- g$GPSLongitude[i] * pi/180
                    lon2 <- g$GPSLongitude[j] * pi/180
                    dlat <- lat2 - lat1
                    dlon <- lon2 - lon1
                    a <- sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2
                    c <- 2 * atan2(sqrt(a), sqrt(1-a))
                    distance <- 6371000 * c
                    max_dist <- max(max_dist, distance)
                  }
                }
                paste0(round(max_dist, 1), "m")
              }),
              TimeDiff = sapply(rv$duplicate_groups, function(g) {
                paste0(round(as.numeric(difftime(max(g$DateTimeOriginal), 
                                                 min(g$DateTimeOriginal), units = "secs"))), "s")
              })
            )
            summary_df
          }), resetPaging = FALSE, rownames = FALSE)
          }
        }, ignoreInit = TRUE)

        new_observers[[length(new_observers) + 1]] <<- obs
      })
      
      # Handle individual image selections
      for(img_idx in 1:nrow(group)) {
        local({
          i_idx <- img_idx
          g_idx <- group_idx
          
          obs <- observeEvent(input[[paste0("select_", g_idx, "_", i_idx)]], {
            # Update selection data in separate storage (only this one selected)
            selections <- rep(FALSE, nrow(rv$duplicate_groups[[g_idx]]))
            selections[i_idx] <- TRUE
            rv$duplicate_selections[[as.character(g_idx)]] <- selections
            
            # Update UI buttons and borders for all images in this group without re-rendering
            for(i in 1:nrow(rv$duplicate_groups[[g_idx]])) {
              if(i == i_idx) {
                # This button should be selected
                shinyjs::html(id = paste0("select_", g_idx, "_", i), html = '<i class="fa fa-check-circle"></i> ✓ SELECTED')
                shinyjs::runjs(paste0("$('#select_", g_idx, "_", i, "').css({'font-weight': 'bold', 'color': '#00a65a'});"))
                # Update border to green
                shinyjs::runjs(paste0("$('#image_border_", g_idx, "_", i, "').css({'border': '4px solid #00a65a', 'background-color': 'white'});"))
              } else {
                # This button should be deselected
                shinyjs::html(id = paste0("select_", g_idx, "_", i), html = '<i class="fa fa-circle"></i> Select This Image')
                shinyjs::runjs(paste0("$('#select_", g_idx, "_", i, "').css({'font-weight': 'normal', 'color': ''});"))
                # Update border to gray
                shinyjs::runjs(paste0("$('#image_border_", g_idx, "_", i, "').css({'border': '2px solid #ddd', 'background-color': 'white'});"))
              }
            }
            # Update "Keep All" button to deselected state
            shinyjs::removeClass(id = paste0("keep_all_", g_idx), class = "btn-warning")
            shinyjs::addClass(id = paste0("keep_all_", g_idx), class = "btn-outline-warning")
            shinyjs::html(id = paste0("keep_all_", g_idx), html = "Keep All Images")
            
            # Update the table's Selected column using JavaScript to avoid losing selection
            selected_count <- 1
            shinyjs::runjs(paste0("$('#duplicates_table table tbody tr:eq(", g_idx - 1, ") td:eq(2)').text('", selected_count, "');"))
            
            # Old approach that caused selection loss - kept for reference but not executed
            if(FALSE) {
            proxy <- dataTableProxy('duplicates_table')
            replaceData(proxy, isolate({
              summary_df <- data.frame(
                Group = sapply(rv$duplicate_groups, function(g) unique(g$group_id)),
                Count = sapply(rv$duplicate_groups, nrow),
                Selected = sapply(1:length(rv$duplicate_groups), function(i) {
                  selections <- rv$duplicate_selections[[as.character(i)]]
                  if(is.null(selections)) selections <- rv$duplicate_groups[[i]]$selected
                  sum(selections)
                }),
                FirstPhoto = sapply(rv$duplicate_groups, function(g) basename(g$FileName[1])),
                MaxDistance = sapply(rv$duplicate_groups, function(g) {
                  if(nrow(g) < 2) return("0m")
                  max_dist <- 0
                  for(i in 1:(nrow(g)-1)) {
                    for(j in (i+1):nrow(g)) {
                      lat1 <- g$GPSLatitude[i] * pi/180
                      lat2 <- g$GPSLatitude[j] * pi/180
                      lon1 <- g$GPSLongitude[i] * pi/180
                      lon2 <- g$GPSLongitude[j] * pi/180
                      dlat <- lat2 - lat1
                      dlon <- lon2 - lon1
                      a <- sin(dlat/2)^2 + cos(lat1) * cos(lat2) * sin(dlon/2)^2
                      c <- 2 * atan2(sqrt(a), sqrt(1-a))
                      distance <- 6371000 * c
                      max_dist <- max(max_dist, distance)
                    }
                  }
                  paste0(round(max_dist, 1), "m")
                }),
                TimeDiff = sapply(rv$duplicate_groups, function(g) {
                  paste0(round(as.numeric(difftime(max(g$DateTimeOriginal), 
                                                   min(g$DateTimeOriginal), units = "secs"))), "s")
              })
            )
            summary_df
          }), resetPaging = FALSE, rownames = FALSE)
            }
          }, ignoreInit = TRUE)

          new_observers[[length(new_observers) + 1]] <<- obs
        })
      }
    }
    
    duplicate_button_observers(new_observers)
    rv$duplicate_handler_counts <- handler_counts
  })  # Apply selection button
  observeEvent(input$btn_apply_selection, {
    req(rv$duplicate_groups)
    req(rv$raw_exif)
    
    withProgress(message = 'Applying your selections...', value = 0, {
      tryCatch({
        incProgress(0.2, detail = "Processing duplicate groups")
        
        # Get all selected photos
        selected_paths <- rv$raw_exif$path
        
        # Remove non-selected duplicates using separate selection storage
        for(group_idx in 1:length(rv$duplicate_groups)) {
          group <- rv$duplicate_groups[[group_idx]]
          # Get normalized selections from separate storage or defaults
          selections <- get_group_selections(group_idx, group)
          non_selected <- group$path[!selections]
          selected_paths <- selected_paths[!selected_paths %in% non_selected]
        }
        
        rv$selected_photos <- selected_paths
        
        incProgress(0.5, detail = "Creating filtered folder")
        
        # Create filtered folder
        dir.create("raw_filtered", showWarnings = FALSE)
        
        incProgress(0.7, detail = paste("Copying", length(selected_paths), "photos"))
        
        for(photo in selected_paths) {
          file.copy(photo, file.path("raw_filtered", basename(photo)), overwrite = TRUE)
        }
        
        incProgress(0.9, detail = "Finalizing")
        
        n_excluded <- length(rv$raw_exif$path) - length(selected_paths)
        n_groups_kept_all <- sum(sapply(1:length(rv$duplicate_groups), function(i) {
          selections <- get_group_selections(i, rv$duplicate_groups[[i]])
          all(selections)
        }))
        
        rv$log <- paste0(rv$log, "✅ Selection applied: ", length(selected_paths), 
                        " photos selected, ", n_excluded, " duplicates excluded\n",
                        "   Groups with all photos kept: ", n_groups_kept_all, "\n",
                        "   Filtered photos saved to 'raw_filtered' folder\n")
        
        incProgress(1, detail = "Complete!")
        
        showNotification(paste("✓ Selection applied successfully!", length(selected_paths), 
                              "photos ready for processing"), 
                        type = "message", duration = 5)
        
        # Switch back to process tab
        Sys.sleep(0.5)  # Brief pause to show completion
        updateTabItems(session, "sidebar", "process")
        
      }, error = function(e) {
        rv$log <- paste0(rv$log, "❌ ERROR applying selection: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error", duration = 8)
      })
    })
  })
  
  # Step 1: Rename Photos
  observeEvent(input$btn_rename, {
    withProgress(message = 'Renaming photos...', value = 0, {
      
      tryCatch({
        # Use filtered photos if duplicates were processed, otherwise use raw
        source_folder <- if(dir.exists("raw_filtered")) "raw_filtered" else "raw"
        list_photo <- list.files(source_folder, full.names = TRUE, pattern = "\\.JPG$")
        
        if(length(list_photo) == 0) {
          rv$log <- paste0(rv$log, "❌ ERROR: No JPG files found in '", source_folder, "' folder\n")
          showNotification(paste("No JPG files found in", source_folder, "folder"), type = "error")
          return()
        }
        
        dir.create("raw_sorted_newname", showWarnings = FALSE)
        
        for(i in 1:length(list_photo)) {
          incProgress(1/length(list_photo), detail = paste("Processing", i, "of", length(list_photo)))
          
          filename <- basename(list_photo[i])
          date_str <- substr(filename, 5, 12)
          new_filename <- paste0(input$location, "_", date_str, "_", sprintf("%03d", i), ".JPG")
          new_path <- file.path("raw_sorted_newname", new_filename)
          file.copy(list_photo[i], new_path, overwrite = TRUE)
        }
        
        rv$photos_renamed <- TRUE
        rv$log <- paste0(rv$log, "✅ Step 1 Complete: Renamed ", length(list_photo), " photos\n")
        showNotification(paste("Successfully renamed", length(list_photo), "photos!"), type = "message")
        
      }, error = function(e) {
        rv$log <- paste0(rv$log, "❌ ERROR: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Step 2: Extract EXIF
  observeEvent(input$btn_exif, {
    withProgress(message = 'Extracting EXIF data...', value = 0, {
      
      tryCatch({
        incProgress(0.3, detail = "Reading photos...")
        
        # Check if renamed folder exists
        if(!dir.exists("raw_sorted_newname")) {
          rv$log <- paste0(rv$log, "⚠️ Step 2 requires renamed photos. Please run Step 1 first.\n")
          showNotification("Please run Step 1 first to rename photos", type = "warning")
          return()
        }
        
        list_photo <- list.files("raw_sorted_newname", full.names = TRUE)
        
        if(length(list_photo) == 0) {
          rv$log <- paste0(rv$log, "❌ ERROR: No photos found in 'raw_sorted_newname' folder\n")
          showNotification("No photos found in 'raw_sorted_newname' folder", type = "error")
          return()
        }
        
        incProgress(0.3, detail = "Extracting metadata...")
        exif_data_df <- exifr::read_exif(list_photo, 
                                   tags = c("FileName", "DateTimeOriginal", "GPSLatitude", 
                                          "GPSLongitude", "RelativeAltitude", 
                                          "ImageWidth", "ImageHeight", "Model"),
                                   recursive = FALSE)
        
        exif_data_df <- as.data.frame(exif_data_df)
        exif_data_df <- exif_data_df %>% 
          select(FileName, DateTimeOriginal, GPSLatitude, GPSLongitude, 
                RelativeAltitude, ImageWidth, ImageHeight, Model)
        
        incProgress(0.3, detail = "Processing metadata...")
        colnames(exif_data_df) <- c("FILENAME", "TIMESTAMP", "LATITUDE", "LONGITUDE",
                                     "RELATIVEALTITUDE", "IMAGEWIDTH", "IMAGEHEIGHT", "MODEL")
        exif_data_df$TIMESTAMP <- as.POSIXct(exif_data_df$TIMESTAMP, format="%Y:%m:%d %H:%M:%S")
        exif_data_df$RELATIVEALTITUDE <- as.numeric(exif_data_df$RELATIVEALTITUDE)
        
        # Create spotcheck data
        spotcheck <- exif_data_df
        spotcheck$SITE_ID <- gsub(".JPG", "", spotcheck$FILENAME)
        spotcheck$SITE_ID <- sub(".*_([0-9]{3})$", "\\1", spotcheck$SITE_ID) %>% as.numeric()
        spotcheck <- spotcheck %>% arrange(SITE_ID)
        spotcheck$path <- paste0("raw_sorted_newname/", spotcheck$FILENAME)
        spotcheck$quad_path <- gsub("raw_sorted_newname", "quads", spotcheck$path)
        
        rv$spotcheck <- spotcheck
        rv$exif_data <- exif_data_df
        rv$exif_extracted <- TRUE
        
        incProgress(0.1, detail = "Done!")
        rv$log <- paste0(rv$log, "✅ Step 2 Complete: Extracted EXIF from ", nrow(spotcheck), " photos\n")
        showNotification("EXIF data extracted successfully!", type = "message")
        
        # Update slider range
        updateSliderInput(session, "gallery_select", max = nrow(spotcheck))
        
      }, error = function(e) {
        rv$log <- paste0(rv$log, "❌ ERROR: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Step 3: Crop Images
  observeEvent(input$btn_crop, {
    withProgress(message = 'Cropping images...', value = 0, {
      
      tryCatch({
        # Load data if not already in memory
        if(is.null(rv$spotcheck)) {
          csv_files <- list.files(pattern = paste0("^", input$location, "_[0-9]{8}\\.csv$"))
          if(length(csv_files) > 0) {
            spotcheck <- read.csv(csv_files[1], stringsAsFactors = FALSE)
            if("TIMESTAMP" %in% colnames(spotcheck)) {
              spotcheck$TIMESTAMP <- as.POSIXct(spotcheck$TIMESTAMP)
            }
            rv$spotcheck <- spotcheck
          } else {
            rv$log <- paste0(rv$log, "⚠️ Step 3 requires metadata. Please run Step 2 first.\n")
            showNotification("Please run Step 2 first to extract EXIF data", type = "warning")
            return()
          }
        }
        
        dir.create("quads_50cm", showWarnings = FALSE)
        dir.create("quads_square", showWarnings = FALSE)
        
        spotcheck <- rv$spotcheck
        
        for(i in 1:nrow(spotcheck)) {
          incProgress(1/nrow(spotcheck), detail = paste("Processing", i, "of", nrow(spotcheck)))
          
          img_width <- spotcheck$IMAGEWIDTH[i]
          img_height <- spotcheck$IMAGEHEIGHT[i]
          drone <- spotcheck$MODEL[i]
          
          img <- image_read(spotcheck$path[i])
          
          # Method 1: Fixed crop
          if(drone == "M3E" || input$drone_model == "M3E") {
            crop_size <- input$crop_size
            x_offset <- (img_width - crop_size)/2
            y_offset <- (img_height - crop_size)/2
            
            img_crop_50cm <- image_crop(img, paste0(crop_size, "x", crop_size, "+", x_offset, "+", y_offset))
            quad_path_50cm <- gsub("raw_sorted_newname", "quads_50cm", spotcheck$path[i])
            image_write(img_crop_50cm, path = quad_path_50cm, format = "jpg")
          }
          
          # Method 2: Square crop
          square_size <- min(img_width, img_height)
          x_offset <- (img_width - square_size)/2
          y_offset <- (img_height - square_size)/2
          
          img_crop_square <- image_crop(img, paste0(square_size, "x", square_size, "+", x_offset, "+", y_offset))
          quad_path_square <- gsub("raw_sorted_newname", "quads_square", spotcheck$path[i])
          image_write(img_crop_square, path = quad_path_square, format = "jpg")
        }
        
        rv$images_cropped <- TRUE
        rv$log <- paste0(rv$log, "✅ Step 3 Complete: Cropped ", nrow(spotcheck), " images\n")
        showNotification("Images cropped successfully!", type = "message")
        
      }, error = function(e) {
        rv$log <- paste0(rv$log, "❌ ERROR: ", e$message, "\n")
        showNotification(paste("Error:", e$message), type = "error")
      })
    })
  })
  
  # Step 4: Export Data
  observeEvent(input$btn_export, {
    tryCatch({
      # Load data if not already in memory
      if(is.null(rv$spotcheck)) {
        csv_files <- list.files(pattern = paste0("^", input$location, "_[0-9]{8}\\.csv$"))
        if(length(csv_files) > 0) {
          spotcheck <- read.csv(csv_files[1], stringsAsFactors = FALSE)
          if("TIMESTAMP" %in% colnames(spotcheck)) {
            spotcheck$TIMESTAMP <- as.POSIXct(spotcheck$TIMESTAMP)
          }
          rv$spotcheck <- spotcheck
        } else {
          rv$log <- paste0(rv$log, "⚠️ Step 4 requires metadata. Please run Step 2 first.\n")
          showNotification("Please run Step 2 first to extract EXIF data", type = "warning")
          return()
        }
      }
      
      spotcheck <- rv$spotcheck
      
      # Export metadata
      output_date <- unique(sub(".*_([0-9]{8})_.*", "\\1", spotcheck$FILENAME))[1]
      output_filename <- paste0(input$location, "_", output_date, ".csv")
      write.csv(spotcheck, file = output_filename)
      
      # Create data collection template
      spotcheck_data <- spotcheck %>% 
        select(SITE_ID, FILENAME, LATITUDE, LONGITUDE, TIMESTAMP)
      
      spotcheck_data$SG_PRESENCE <- ""
      spotcheck_data$SG_COVER <- ""
      spotcheck_data$SUBSTRATE <- ""
      spotcheck_data$CR <- ""
      spotcheck_data$CS <- ""
      spotcheck_data$HO <- ""
      spotcheck_data$HU <- ""
      spotcheck_data$SI <- ""
      spotcheck_data$EA <- ""
      spotcheck_data$TH <- ""
      spotcheck_data$TC <- ""
      spotcheck_data$ZC <- ""
      spotcheck_data$TOTAL <- ""
      spotcheck_data$AL_COVER <- ""
      spotcheck_data$EPI_COVER <- ""
      spotcheck_data$COMMENT <- ""
      
      output_data_filename <- paste0(input$location, "_", output_date, "_data.csv")
      write.csv(spotcheck_data, file = output_data_filename, row.names = FALSE)
      
      rv$data_exported <- TRUE
      rv$log <- paste0(rv$log, "✅ Step 4 Complete: Exported data files\n",
                      "   • ", output_filename, "\n",
                      "   • ", output_data_filename, "\n")
      showNotification("Data exported successfully!", type = "message")
      
    }, error = function(e) {
      rv$log <- paste0(rv$log, "❌ ERROR: ", e$message, "\n")
      showNotification(paste("Error:", e$message), type = "error")
    })
  })
  
  # Process log output
  output$process_log <- renderText({
    rv$log
  })
  
  # Value boxes
  output$box_photos <- renderValueBox({
    count <- if(!is.null(rv$spotcheck)) nrow(rv$spotcheck) else 0
    valueBox(count, "Photos Processed", icon = icon("camera"), color = "blue")
  })
  
  output$box_processed <- renderValueBox({
    status <- if(rv$data_exported) "Complete" else "In Progress"
    valueBox(status, "Status", icon = icon("check-circle"), 
            color = if(rv$data_exported) "green" else "yellow")
  })
  
  output$box_altitude <- renderValueBox({
    avg_alt <- if(!is.null(rv$spotcheck)) {
      round(mean(rv$spotcheck$RELATIVEALTITUDE, na.rm = TRUE), 1)
    } else 0
    valueBox(paste0(avg_alt, " m"), "Avg Altitude", icon = icon("plane"), color = "purple")
  })
  
  output$box_coverage <- renderValueBox({
    coverage <- if(!is.null(rv$spotcheck)) {
      paste0(nrow(rv$spotcheck) * 0.25, " m²")
    } else "0 m²"
    valueBox(coverage, "Coverage Area", icon = icon("map"), color = "orange")
  })
  
  # Map output
  output$map <- renderLeaflet({
    if(is.null(rv$spotcheck)) {
      # Return empty map if no data
      return(
        leaflet() %>%
          addProviderTiles(providers$Esri.WorldImagery) %>%
          setView(lng = 0, lat = 0, zoom = 2) %>%
          addControl(html = "<div style='background: white; padding: 10px; border-radius: 5px;'>No data loaded yet. Please complete Step 2 to extract EXIF data.</div>",
                    position = "topright")
      )
    }
    
    spotcheck <- rv$spotcheck
    
    leaflet(spotcheck, options = leafletOptions(maxZoom = 25)) %>%
      addProviderTiles(providers$Esri.WorldImagery, options = providerTileOptions(maxZoom = 25)) %>%
      addCircleMarkers(
        lng = ~LONGITUDE,
        lat = ~LATITUDE,
        radius = 6,
        color = "#3c8dbc",
        fillColor = "#3c8dbc",
        fillOpacity = 0.7,
        popup = ~paste0(
          "<b>Site ID:</b> ", SITE_ID, "<br>",
          "<b>Filename:</b> ", FILENAME, "<br>",
          "<b>Time:</b> ", TIMESTAMP, "<br>",
          "<b>Altitude:</b> ", round(RELATIVEALTITUDE, 1), " m<br>",
          "<b>Lat:</b> ", round(LATITUDE, 6), "<br>",
          "<b>Lon:</b> ", round(LONGITUDE, 6)
        ),
        label = ~as.character(SITE_ID)
      ) %>%
      addScaleBar(position = "bottomleft")
  })
  
  # Data table
  output$data_table <- renderDT({
    req(rv$spotcheck)
    
    rv$spotcheck %>%
      select(SITE_ID, FILENAME, TIMESTAMP, LATITUDE, LONGITUDE, RELATIVEALTITUDE, MODEL) %>%
      datatable(
        options = list(pageLength = 25, scrollX = TRUE),
        rownames = FALSE,
        filter = 'top'
      ) %>%
      formatRound(c('LATITUDE', 'LONGITUDE', 'RELATIVEALTITUDE'), 3)
  })
  
  # Download handler
  output$download_data <- downloadHandler(
    filename = function() {
      paste0(input$location, "_", format(Sys.Date(), "%Y%m%d"), "_metadata.csv")
    },
    content = function(file) {
      write.csv(rv$spotcheck, file, row.names = FALSE)
    }
  )
  
  # Image gallery
  output$image_display <- renderUI({
    if(is.null(rv$spotcheck)) {
      return(p("No data loaded yet. Please complete Step 2 to extract EXIF data."))
    }
    
    idx <- input$gallery_select
    spotcheck <- rv$spotcheck
    
    if(idx > nrow(spotcheck)) return(NULL)
    
    original_path <- spotcheck$path[idx]
    crop_50cm_path <- gsub("raw_sorted_newname", "quads_50cm", original_path)
    crop_square_path <- gsub("raw_sorted_newname", "quads_square", original_path)
    
    # Function to create base64 encoded image
    encode_image <- function(path) {
      if(file.exists(path)) {
        img_data <- image_read(path)
        img_resized <- image_resize(img_data, "800x800")
        temp_file <- tempfile(fileext = ".jpg")
        image_write(img_resized, temp_file, format = "jpg", quality = 85)
        encoded <- base64enc::base64encode(temp_file)
        unlink(temp_file)
        return(paste0("data:image/jpeg;base64,", encoded))
      }
      return(NULL)
    }
    
    tagList(
      h4(paste("Site ID:", spotcheck$SITE_ID[idx], "—", spotcheck$FILENAME[idx])),
      fluidRow(
        column(4,
          h5("Original Image"),
          if(file.exists(original_path)) {
            tags$img(src = encode_image(original_path), width = "100%", 
                    style = "border: 2px solid #ddd; border-radius: 4px;")
          } else {
            p("Image not found")
          }
        ),
        column(4,
          h5("50cm Crop (1800x1800)"),
          if(file.exists(crop_50cm_path)) {
            tags$img(src = encode_image(crop_50cm_path), width = "100%", 
                    style = "border: 2px solid #3c8dbc; border-radius: 4px;")
          } else {
            p("Image not yet cropped. Please complete Step 3.")
          }
        ),
        column(4,
          h5("Square Crop"),
          if(file.exists(crop_square_path)) {
            tags$img(src = encode_image(crop_square_path), width = "100%", 
                    style = "border: 2px solid #00a65a; border-radius: 4px;")
          } else {
            p("Image not yet cropped. Please complete Step 3.")
          }
        )
      )
    )
  })
  
  # Statistics plots
  output$altitude_plot <- renderPlotly({
    req(rv$spotcheck)
    
    p <- ggplot(rv$spotcheck, aes(x = SITE_ID, y = RELATIVEALTITUDE)) +
      geom_line(color = "#3c8dbc", size = 1) +
      geom_point(color = "#3c8dbc", size = 3) +
      labs(x = "Site ID", y = "Altitude (m)", title = "Altitude by Site") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$time_plot <- renderPlotly({
    req(rv$spotcheck)
    
    p <- ggplot(rv$spotcheck, aes(x = TIMESTAMP)) +
      geom_histogram(fill = "#00a65a", color = "white", bins = 20) +
      labs(x = "Time", y = "Count", title = "Photo Capture Timeline") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  output$dimension_plot <- renderPlotly({
    req(rv$spotcheck)
    
    plot_ly(rv$spotcheck, x = ~IMAGEWIDTH, y = ~IMAGEHEIGHT, 
            text = ~paste("Site:", SITE_ID), type = 'scatter', mode = 'markers',
            marker = list(size = 10, color = '#f39c12', 
                         line = list(color = 'white', width = 2))) %>%
      layout(title = "Image Dimensions",
             xaxis = list(title = "Width (px)"),
             yaxis = list(title = "Height (px)"))
  })
}

# Run the application
shinyApp(ui = ui, server = server)
