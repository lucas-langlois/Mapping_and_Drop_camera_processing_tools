# Shiny App for Matching and Renaming DJI Videos
# Based on CSV Timestamp Matching

library(shiny)
library(DT)
library(lubridate)
library(shinyFiles)

# Source the matching function
source("match_and_rename_videos_fun.R")

# Define UI
ui <- fluidPage(
  titlePanel("DJI Video Matcher & Renamer"),
  
  sidebarLayout(
    sidebarPanel(
      width = 3,
      
      h4("File Selection"),
      
      div(style = "margin-bottom: 10px;",
        textInput("video_dir", 
                  "Video Directory:", 
                  value = file.path(getwd(), "Videos"),
                  width = "100%"),
        shinyDirButton("video_dir_browse", 
                       "Browse...", 
                       "Select video directory",
                       class = "btn-sm btn-default",
                       style = "width: 100%; margin-top: 5px;")
      ),
      
      div(style = "margin-bottom: 10px;",
        textInput("csv_path", 
                  "CSV File Path:", 
                  value = file.path(getwd(), "data"),
                  width = "100%"),
        shinyFilesButton("csv_file_browse", 
                         "Browse...", 
                         "Select CSV file",
                         multiple = FALSE,
                         class = "btn-sm btn-default",
                         style = "width: 100%; margin-top: 5px;")
      ),
      
      hr(),
      
      h4("Location & Naming"),
      textInput("location", "Location Name:", value = "Location_name"),
      
      textInput("id_prefix", "ID Prefix:", value = "ID"),
      
      numericInput("id_digits", "ID Digits (zero-pad):", value = 3, min = 1, max = 6),
      
      hr(),
      
      h4("CSV Settings"),
      textInput("date_time_col", "Date/Time Column:", value = "Date.Time"),
      
      textInput("objectid_col", "Object ID Column:", value = "OBJECTID"),
      
      textInput("time_format", "Time Format:", value = "%d/%m/%Y %H:%M:%S"),
      
      selectInput("csv_timezone", 
                  "CSV Timezone:",
                  choices = c(
                    "UTC" = "UTC",
                    "--- Asia ---" = "",
                    "India (IST)" = "Asia/Kolkata",
                    "--- Australia ---" = "",
                    "Sydney/Melbourne (AEDT/AEST)" = "Australia/Sydney",
                    "Brisbane (AEST)" = "Australia/Brisbane",
                    "Perth (AWST)" = "Australia/Perth",
                    "Adelaide (ACDT/ACST)" = "Australia/Adelaide",
                    "Darwin (ACST)" = "Australia/Darwin",
                    "Hobart (AEDT/AEST)" = "Australia/Hobart",
                    "--- Americas ---" = "",
                    "New York (EST/EDT)" = "America/New_York",
                    "--- Europe ---" = "",
                    "London (GMT/BST)" = "Europe/London"
                  ),
                  selected = "UTC"),
      
      selectInput("camera_timezone", 
                  "Camera Timezone:",
                  choices = c(
                    "--- Asia ---" = "",
                    "India (IST)" = "Asia/Kolkata",
                    "--- Australia ---" = "",
                    "Sydney/Melbourne (AEDT/AEST)" = "Australia/Sydney",
                    "Brisbane (AEST)" = "Australia/Brisbane",
                    "Perth (AWST)" = "Australia/Perth",
                    "Adelaide (ACDT/ACST)" = "Australia/Adelaide",
                    "Darwin (ACST)" = "Australia/Darwin",
                    "Hobart (AEDT/AEST)" = "Australia/Hobart",
                    "--- Other ---" = "",
                    "UTC" = "UTC",
                    "New York (EST/EDT)" = "America/New_York",
                    "London (GMT/BST)" = "Europe/London"
                  ),
                  selected = "Australia/Brisbane"),
      
      hr(),
      
      h4("Matching Settings"),
      numericInput("max_time_diff", 
                   "Max Time Diff (seconds):", 
                   value = 300, 
                   min = 10, 
                   max = 86400),
      
      helpText("Maximum time difference to allow a match (e.g., 180 = 3 minutes)"),
      
      hr(),
      
      actionButton("run_preview", "Preview Matches", 
                   class = "btn-primary btn-block",
                   style = "margin-bottom: 10px;"),
      
      actionButton("run_rename", "Rename Videos", 
                   class = "btn-danger btn-block",
                   style = "margin-bottom: 10px;"),
      
      hr(),
      
      downloadButton("download_log", "Download Log", 
                     class = "btn-secondary btn-block")
    ),
    
    mainPanel(
      width = 9,
      
      tabsetPanel(
        id = "tabs",
        
        tabPanel("Instructions",
                 h3("How to Use This App"),
                 tags$ol(
                   tags$li("Set the video directory and CSV file path (you can type or click 'Browse...' to select)"),
                   tags$li("Configure the location name and naming format"),
                   tags$li("Adjust CSV column names and time format if needed"),
                   tags$li("Set the correct timezones for your data"),
                   tags$li("Click 'Preview Matches' to see what will be renamed"),
                   tags$li("Review the results in the 'Results' tab"),
                   tags$li("If everything looks good, click 'Rename Videos' to apply changes"),
                   tags$li("An output CSV will be saved in the video directory with all CSV data + matched video info")
                 ),
                 hr(),
                 h4("File Browser"),
                 p("Use the 'Browse...' buttons next to the path fields to visually navigate and select:"),
                 tags$ul(
                   tags$li(tags$strong("Video Directory:"), " Select the folder containing your DJI videos"),
                   tags$li(tags$strong("CSV File:"), " Select your CSV file with timestamps and object IDs")
                 ),
                 hr(),
                 h4("Time Format Examples"),
                 tags$ul(
                   tags$li(tags$code("%m/%d/%Y %H:%M:%S"), " - 11/18/2025 14:30:45"),
                   tags$li(tags$code("%Y-%m-%d %H:%M:%S"), " - 2025-11-18 14:30:45"),
                   tags$li(tags$code("%d/%m/%Y %H:%M:%S"), " - 18/11/2025 14:30:45")
                 ),
                 hr(),
                 h4("Timezone Information"),
                 p("CSV Timezone: The timezone that your CSV timestamps are recorded in"),
                 p("Camera Timezone: The timezone that your DJI camera uses for recording"),
                 p("The app will automatically convert between timezones for matching."),
                 hr(),
                 h5("Common Timezones:"),
                 tags$ul(
                   tags$li(tags$strong("India:"), " Asia/Kolkata (IST, UTC+5:30)"),
                   tags$li(tags$strong("Australia East:"), " Australia/Sydney (AEDT/AEST, UTC+10/+11)"),
                   tags$li(tags$strong("Australia East (no DST):"), " Australia/Brisbane (AEST, UTC+10)"),
                   tags$li(tags$strong("Australia Central:"), " Australia/Adelaide (ACDT/ACST, UTC+9:30/+10:30)"),
                   tags$li(tags$strong("Australia West:"), " Australia/Perth (AWST, UTC+8)")
                 )
        ),
        
        tabPanel("Results",
                 h3("Matching Results"),
                 
                 uiOutput("summary_box"),
                 
                 hr(),
                 
                 DTOutput("results_table")
        ),
        
        tabPanel("CSV Preview",
                 h3("CSV Data Preview"),
                 
                 actionButton("load_csv", "Load CSV", class = "btn-info"),
                 
                 hr(),
                 
                 verbatimTextOutput("csv_info"),
                 
                 hr(),
                 
                 DTOutput("csv_preview_table")
        ),
        
        tabPanel("Video Files",
                 h3("Video Files Found"),
                 
                 actionButton("scan_videos", "Scan Video Directory", class = "btn-info"),
                 
                 hr(),
                 
                 verbatimTextOutput("video_info"),
                 
                 hr(),
                 
                 tableOutput("video_list")
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  # Reactive value to store results
  results <- reactiveVal(NULL)
  csv_data <- reactiveVal(NULL)
  video_files <- reactiveVal(NULL)
  
  # Set up file browser volumes (roots for browsing)
  # This allows browsing from root on Windows or home directory on Unix
  volumes <- c(
    Project = getwd(),
    Home = fs::path_home(),
    getVolumes()()
  )
  
  # Directory browser for video directory
  shinyDirChoose(input, "video_dir_browse", roots = volumes, session = session)
  
  # Update video_dir when directory is selected
  observeEvent(input$video_dir_browse, {
    dir_path <- parseDirPath(volumes, input$video_dir_browse)
    if (length(dir_path) > 0) {
      updateTextInput(session, "video_dir", value = dir_path)
    }
  })
  
  # File browser for CSV file
  shinyFileChoose(input, "csv_file_browse", 
                  roots = volumes, 
                  session = session,
                  filetypes = c("csv", "CSV"))
  
  # Update csv_path when file is selected
  observeEvent(input$csv_file_browse, {
    file_path <- parseFilePaths(volumes, input$csv_file_browse)
    if (nrow(file_path) > 0) {
      updateTextInput(session, "csv_path", value = as.character(file_path$datapath))
    }
  })
  
  
  # Preview matches (dry run)
  observeEvent(input$run_preview, {
    
    # Validate inputs
    if (!dir.exists(input$video_dir)) {
      showNotification("Video directory does not exist!", type = "error")
      return()
    }
    
    if (!file.exists(input$csv_path)) {
      showNotification("CSV file does not exist!", type = "error")
      return()
    }
    
    # Show progress
    withProgress(message = 'Matching videos...', value = 0, {
      
      tryCatch({
        # Run matching function in dry run mode
        res <- match_and_rename_videos(
          video_dir = input$video_dir,
          csv_path = input$csv_path,
          location = input$location,
          date_time_col = input$date_time_col,
          objectid_col = input$objectid_col,
          time_format = input$time_format,
          csv_timezone = input$csv_timezone,
          camera_timezone = input$camera_timezone,
          max_time_diff = input$max_time_diff,
          id_prefix = input$id_prefix,
          id_digits = input$id_digits,
          dry_run = TRUE
        )
        
        results(res)
        
        # Switch to results tab
        updateTabsetPanel(session, "tabs", selected = "Results")
        
        showNotification("Preview completed!", type = "message", duration = 3)
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
      
    })
  })
  
  # Rename videos (actual run)
  observeEvent(input$run_rename, {
    
    # Confirm action
    showModal(modalDialog(
      title = "Confirm Rename",
      "Are you sure you want to rename the videos? This action cannot be undone!",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_rename", "Yes, Rename", class = "btn-danger")
      )
    ))
  })
  
  # Confirmed rename
  observeEvent(input$confirm_rename, {
    removeModal()
    
    # Validate inputs
    if (!dir.exists(input$video_dir)) {
      showNotification("Video directory does not exist!", type = "error")
      return()
    }
    
    if (!file.exists(input$csv_path)) {
      showNotification("CSV file does not exist!", type = "error")
      return()
    }
    
    # Show progress
    withProgress(message = 'Renaming videos...', value = 0, {
      
      tryCatch({
        # Run matching function with dry_run = FALSE
        res <- match_and_rename_videos(
          video_dir = input$video_dir,
          csv_path = input$csv_path,
          location = input$location,
          date_time_col = input$date_time_col,
          objectid_col = input$objectid_col,
          time_format = input$time_format,
          csv_timezone = input$csv_timezone,
          camera_timezone = input$camera_timezone,
          max_time_diff = input$max_time_diff,
          id_prefix = input$id_prefix,
          id_digits = input$id_digits,
          dry_run = FALSE
        )
        
        results(res)
        
        # Switch to results tab
        updateTabsetPanel(session, "tabs", selected = "Results")
        
        renamed_count <- sum(res$status == "Renamed", na.rm = TRUE)
        showNotification(paste("Successfully renamed", renamed_count, "videos! Output CSV saved to video directory."), 
                        type = "message", duration = 7)
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
      
    })
  })
  
  # Load CSV preview
  observeEvent(input$load_csv, {
    
    if (!file.exists(input$csv_path)) {
      showNotification("CSV file does not exist!", type = "error")
      return()
    }
    
    tryCatch({
      df <- read.csv(input$csv_path, stringsAsFactors = FALSE)
      csv_data(df)
      
      # Switch to CSV preview tab
      updateTabsetPanel(session, "tabs", selected = "CSV Preview")
      
      showNotification("CSV loaded successfully!", type = "message", duration = 3)
      
    }, error = function(e) {
      showNotification(paste("Error loading CSV:", e$message), type = "error", duration = 10)
    })
  })
  
  # Scan video files
  observeEvent(input$scan_videos, {
    
    if (!dir.exists(input$video_dir)) {
      showNotification("Video directory does not exist!", type = "error")
      return()
    }
    
    tryCatch({
      files <- list.files(input$video_dir, 
                         pattern = "^DJI_.*\\.MP4$", 
                         ignore.case = TRUE, 
                         full.names = FALSE)
      
      if (length(files) == 0) {
        showNotification("No DJI video files found!", type = "warning")
        video_files(NULL)
      } else {
        video_files(data.frame(
          Filename = files,
          Size_MB = round(file.size(file.path(input$video_dir, files)) / 1024 / 1024, 2)
        ))
        
        # Switch to video files tab
        updateTabsetPanel(session, "tabs", selected = "Video Files")
        
        showNotification(paste("Found", length(files), "video files!"), 
                        type = "message", duration = 3)
      }
      
    }, error = function(e) {
      showNotification(paste("Error scanning videos:", e$message), type = "error", duration = 10)
    })
  })
  
  # Display summary box
  output$summary_box <- renderUI({
    res <- results()
    if (is.null(res)) {
      return(div(class = "alert alert-info", "No results yet. Click 'Preview Matches' to start."))
    }
    
    total <- nrow(res)
    matched <- sum(res$status %in% c("Matched", "Renamed"), na.rm = TRUE)
    renamed <- sum(res$status == "Renamed", na.rm = TRUE)
    failed <- sum(!res$status %in% c("Matched", "Renamed"), na.rm = TRUE)
    
    status_class <- if (renamed > 0) "alert-success" else "alert-info"
    
    div(class = paste("alert", status_class),
        h4("Summary"),
        tags$ul(
          tags$li(strong("Total videos:"), total),
          tags$li(strong("Successfully matched:"), matched),
          if (renamed > 0) tags$li(strong("Successfully renamed:"), renamed),
          tags$li(strong("Failed to match:"), failed)
        )
    )
  })
  
  # Display results table
  output$results_table <- renderDT({
    res <- results()
    if (is.null(res)) return(NULL)
    
    datatable(
      res,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        'status',
        backgroundColor = styleEqual(
          c('Matched', 'Renamed', 'Failed to parse timestamp', 'No match within time threshold'),
          c('#d4edda', '#c3e6cb', '#f8d7da', '#fff3cd')
        )
      )
  })
  
  # CSV info
  output$csv_info <- renderText({
    df <- csv_data()
    if (is.null(df)) return("No CSV loaded. Click 'Load CSV' button.")
    
    paste0(
      "Total rows: ", nrow(df), "\n",
      "Total columns: ", ncol(df), "\n",
      "Columns: ", paste(names(df), collapse = ", ")
    )
  })
  
  # CSV preview table
  output$csv_preview_table <- renderDT({
    df <- csv_data()
    if (is.null(df)) return(NULL)
    
    datatable(
      head(df, 100),
      options = list(
        pageLength = 10,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })
  
  # Video info
  output$video_info <- renderText({
    vf <- video_files()
    if (is.null(vf)) return("No videos scanned. Click 'Scan Video Directory' button.")
    
    paste0(
      "Total DJI videos found: ", nrow(vf), "\n",
      "Total size: ", round(sum(vf$Size_MB, na.rm = TRUE), 2), " MB"
    )
  })
  
  # Video list
  output$video_list <- renderTable({
    video_files()
  })
  
  # Download log
  output$download_log <- downloadHandler(
    filename = function() {
      paste0("video_rename_log_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
    },
    content = function(file) {
      res <- results()
      if (!is.null(res)) {
        write.csv(res, file, row.names = FALSE)
      }
    }
  )
}

# Run the application 
shinyApp(ui = ui, server = server)

