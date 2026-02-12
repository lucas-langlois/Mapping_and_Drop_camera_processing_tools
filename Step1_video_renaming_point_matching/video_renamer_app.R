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
      
      actionButton("run_rename", "Rename Videos (Auto-Match)", 
                   class = "btn-danger btn-block",
                   style = "margin-bottom: 10px;"),
      
      actionButton("run_rename_edited", "Rename Videos (Edited Matches)", 
                   class = "btn-warning btn-block",
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
                   tags$li("Review the results in the 'Results' tab - check for duration warnings and unmatched OBJECTIDs"),
                   tags$li("(Optional) Go to 'Edit Matches' tab to manually adjust matches - double-click OBJECTID cells to edit"),
                   tags$li("Click 'Rename Videos (Auto-Match)' for automatic matches or 'Rename Videos (Edited Matches)' if you made manual edits"),
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
                 h4("Duration Warnings"),
                 p("The app will check video durations and warn you if any videos are shorter than 30 seconds."),
                 p("This requires the 'av' package. Install with: install.packages('av')"),
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
                 
                 h4("Matched Videos"),
                 DTOutput("results_table"),
                 
                 hr(),
                 
                 h4("Unmatched OBJECTIDs from CSV"),
                 p("These OBJECTIDs from your CSV file were not matched to any video:"),
                 DTOutput("unmatched_objectids_table")
        ),
        
        tabPanel("Edit Matches",
                 h3("Manually Edit Video Matches"),
                 
                 p("Manually edit the matches below. You can change the matched OBJECTID for each video, or set it to blank to unmatch."),
                 
                 actionButton("load_matches", "Load Current Matches", class = "btn-info"),
                 actionButton("reset_matches", "Reset to Auto-Matches", class = "btn-warning"),
                 
                 hr(),
                 
                 uiOutput("edit_summary_box"),
                 
                 hr(),
                 
                 p(strong("Instructions:")),
                 tags$ul(
                   tags$li("Double-click on any cell in the 'matched_objectid' column (yellow) to edit it"),
                   tags$li("Enter a valid OBJECTID from your CSV file"),
                   tags$li("The 'new_filename' (blue) will automatically update to show what the file will be renamed to"),
                   tags$li("Leave blank to unmatch a video"),
                   tags$li("After editing, use 'Rename Videos (Edited Matches)' button in the sidebar")
                 ),
                 
                 hr(),
                 
                 DTOutput("editable_matches_table")
        ),
        
        tabPanel("Revert Renaming",
                 h3("Revert Video Renaming"),
                 
                 p("Use this tab to restore original DJI filenames from a previous renaming operation."),
                 
                 div(style = "margin-bottom: 10px;",
                   textInput("revert_csv_path", 
                             "Output CSV File Path:", 
                             value = "",
                             width = "100%"),
                   shinyFilesButton("revert_csv_browse", 
                                    "Browse...", 
                                    "Select output CSV file",
                                    multiple = FALSE,
                                    class = "btn-sm btn-default",
                                    style = "width: 100%; margin-top: 5px;")
                 ),
                 
                 actionButton("load_revert_csv", "Load Renamed Videos", class = "btn-info"),
                 
                 hr(),
                 
                 uiOutput("revert_summary_box"),
                 
                 hr(),
                 
                 actionButton("revert_rename", "Revert to Original Filenames", 
                              class = "btn-warning",
                              style = "margin-bottom: 10px;"),
                 
                 hr(),
                 
                 p(strong("Instructions:")),
                 tags$ul(
                   tags$li("Select the output CSV file created during the previous renaming operation"),
                   tags$li("The CSV must contain 'original_filename' and 'matched_video_filename' columns"),
                   tags$li("Click 'Load Renamed Videos' to see what will be reverted"),
                   tags$li("Click 'Revert to Original Filenames' to restore the original DJI names")
                 ),
                 
                 hr(),
                 
                 DTOutput("revert_table")
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
  unmatched_objectids <- reactiveVal(NULL)
  edited_matches <- reactiveVal(NULL)
  available_objectids <- reactiveVal(NULL)
  revert_data <- reactiveVal(NULL)
  
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
  
  # File browser for revert CSV file
  shinyFileChoose(input, "revert_csv_browse", 
                  roots = volumes, 
                  session = session,
                  filetypes = c("csv", "CSV"))
  
  # Update revert_csv_path when file is selected
  observeEvent(input$revert_csv_browse, {
    file_path <- parseFilePaths(volumes, input$revert_csv_browse)
    if (nrow(file_path) > 0) {
      updateTextInput(session, "revert_csv_path", value = as.character(file_path$datapath))
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
        
        # Extract unmatched OBJECTIDs if available
        unmatched <- attr(res, "unmatched_objectids")
        if (!is.null(unmatched)) {
          unmatched_objectids(unmatched)
        }
        
        # Switch to results tab
        updateTabsetPanel(session, "tabs", selected = "Results")
        
        # Check for warnings
        warnings_msg <- ""
        if ("duration_warning" %in% names(res)) {
          short_videos <- sum(res$duration_warning != "", na.rm = TRUE)
          if (short_videos > 0) {
            warnings_msg <- paste("\nWarning:", short_videos, "video(s) are shorter than 30 seconds.")
          }
        }
        
        if ("unmatched_objectids" %in% names(attributes(res))) {
          unmatched_count <- nrow(attr(res, "unmatched_objectids"))
          if (unmatched_count > 0) {
            warnings_msg <- paste0(warnings_msg, "\n", unmatched_count, " OBJECTID(s) from CSV were not matched to any video.")
          }
        }
        
        showNotification(paste0("Preview completed!", warnings_msg), type = "message", duration = 5)
        
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
        
        # Extract unmatched OBJECTIDs if available
        unmatched <- attr(res, "unmatched_objectids")
        if (!is.null(unmatched)) {
          unmatched_objectids(unmatched)
        }
        
        # Switch to results tab
        updateTabsetPanel(session, "tabs", selected = "Results")
        
        renamed_count <- sum(res$status == "Renamed", na.rm = TRUE)
        
        # Check for warnings
        warnings_msg <- ""
        if ("duration_warning" %in% names(res)) {
          short_videos <- sum(res$duration_warning != "", na.rm = TRUE)
          if (short_videos > 0) {
            warnings_msg <- paste("\nWarning:", short_videos, "video(s) are shorter than 30 seconds.")
          }
        }
        
        showNotification(paste0("Successfully renamed ", renamed_count, " videos! Output CSV saved to video directory.", warnings_msg), 
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
      
      # Store available OBJECTIDs for editing
      if (input$objectid_col %in% names(df)) {
        available_objectids(unique(df[[input$objectid_col]]))
      }
      
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
    
    # Count duration warnings
    short_videos <- 0
    if ("duration_warning" %in% names(res)) {
      short_videos <- sum(res$duration_warning != "", na.rm = TRUE)
    }
    
    # Count unmatched OBJECTIDs
    unmatched_count <- 0
    unmatched <- unmatched_objectids()
    if (!is.null(unmatched)) {
      unmatched_count <- nrow(unmatched)
    }
    
    status_class <- if (renamed > 0) "alert-success" else "alert-info"
    
    div(class = paste("alert", status_class),
        h4("Summary"),
        tags$ul(
          tags$li(strong("Total videos:"), total),
          tags$li(strong("Successfully matched:"), matched),
          if (renamed > 0) tags$li(strong("Successfully renamed:"), renamed),
          tags$li(strong("Failed to match:"), failed),
          if (short_videos > 0) tags$li(strong("Videos < 30 sec:"), short_videos, 
                                        tags$span(style="color: orange;", " (Warning)")),
          if (unmatched_count > 0) tags$li(strong("Unmatched OBJECTIDs:"), unmatched_count,
                                          tags$span(style="color: orange;", " (See table below)"))
        )
    )
  })
  
  # Display results table
  output$results_table <- renderDT({
    res <- results()
    if (is.null(res)) return(NULL)
    
    dt <- datatable(
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
    
    # Highlight duration warnings if column exists
    if ("duration_warning" %in% names(res)) {
      dt <- dt %>%
        formatStyle(
          'duration_warning',
          backgroundColor = styleEqual(
            c('WARNING: Video < 30 sec', ''),
            c('#fff3cd', 'transparent')
          ),
          fontWeight = styleEqual(
            c('WARNING: Video < 30 sec', ''),
            c('bold', 'normal')
          )
        )
    }
    
    return(dt)
  })
  
  # Display unmatched OBJECTIDs table
  output$unmatched_objectids_table <- renderDT({
    unmatched <- unmatched_objectids()
    if (is.null(unmatched) || nrow(unmatched) == 0) {
      return(data.frame(Message = "All OBJECTIDs were successfully matched to videos!"))
    }
    
    datatable(
      unmatched,
      options = list(
        pageLength = 10,
        scrollX = TRUE,
        dom = 'Bfrtip',
        buttons = c('copy', 'csv', 'excel')
      ),
      rownames = FALSE
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
  
  # Load matches for editing
  observeEvent(input$load_matches, {
    res <- results()
    if (is.null(res)) {
      showNotification("No matches available. Run 'Preview Matches' first!", type = "warning")
      return()
    }
    
    # Load CSV to get available OBJECTIDs
    if (!file.exists(input$csv_path)) {
      showNotification("CSV file does not exist!", type = "error")
      return()
    }
    
    tryCatch({
      df <- read.csv(input$csv_path, stringsAsFactors = FALSE)
      if (input$objectid_col %in% names(df)) {
        available_objectids(unique(df[[input$objectid_col]]))
      }
      
      # Create editable version
      edit_df <- res
      edited_matches(edit_df)
      
      # Switch to edit tab
      updateTabsetPanel(session, "tabs", selected = "Edit Matches")
      
      showNotification("Matches loaded for editing!", type = "message", duration = 3)
      
    }, error = function(e) {
      showNotification(paste("Error loading matches:", e$message), type = "error", duration = 10)
    })
  })
  
  # Reset to auto-matches
  observeEvent(input$reset_matches, {
    res <- results()
    if (is.null(res)) {
      showNotification("No matches available. Run 'Preview Matches' first!", type = "warning")
      return()
    }
    
    edited_matches(res)
    showNotification("Matches reset to automatic matches!", type = "message", duration = 3)
  })
  
  # Handle editable table changes
  observeEvent(input$editable_matches_table_cell_edit, {
    info <- input$editable_matches_table_cell_edit
    em <- edited_matches()
    
    if (!is.null(em)) {
      row <- info$row
      col <- info$col + 1  # DT uses 0-based indexing
      value <- info$value
      
      # Find the matched_objectid column
      objectid_col_idx <- which(names(em) == "matched_objectid")
      
      # Only allow editing of matched_objectid column
      if (col == objectid_col_idx) {
        # Validate the new OBJECTID
        if (value == "" || is.na(value)) {
          # Allow blank to unmatch
          em[row, col] <- NA
          em$status[row] <- "Manually unmatched"
          em$matched_datetime[row] <- NA
          em$time_difference_sec[row] <- NA
          em$new_filename[row] <- NA
        } else {
          # Check if OBJECTID exists in CSV
          if (!file.exists(input$csv_path)) {
            showNotification("CSV file not found!", type = "error")
            return()
          }
          
          df <- read.csv(input$csv_path, stringsAsFactors = FALSE)
          
          # Parse the CSV datetime column
          df$datetime_parsed <- as.POSIXct(df[[input$date_time_col]], 
                                          format = input$time_format, tz = "UTC")
          df$datetime_parsed <- force_tz(df$datetime_parsed, tzone = input$csv_timezone)
          df$datetime_camera <- with_tz(df$datetime_parsed, tzone = input$camera_timezone)
          
          # Check if the OBJECTID exists
          if (!(value %in% df[[input$objectid_col]])) {
            showNotification(paste("OBJECTID", value, "not found in CSV!"), 
                           type = "warning", duration = 5)
            return()
          }
          
          # Update the match
          em[row, col] <- value
          
          # Get the datetime for this OBJECTID
          matched_row <- df[df[[input$objectid_col]] == value, ][1, ]
          em$matched_datetime[row] <- as.character(matched_row$datetime_camera)
          
          # Calculate time difference
          video_ts <- as.POSIXct(em$video_timestamp[row], tz = input$camera_timezone)
          matched_ts <- matched_row$datetime_camera
          time_diff <- abs(as.numeric(difftime(matched_ts, video_ts, units = "secs")))
          em$time_difference_sec[row] <- time_diff
          em$status[row] <- "Manually matched"
          
          # Generate new filename with updated OBJECTID
          date_str <- format(video_ts, "%Y%m%d")
          time_str <- format(video_ts, "%H%M%S")
          format_string <- paste0("%s%0", input$id_digits, "d")
          objectid_formatted <- sprintf(format_string, input$id_prefix, as.integer(value))
          file_ext <- sub(".*\\.", "", em$original_filename[row])
          new_filename <- paste0(input$location, "_", date_str, "_", time_str, "_", 
                                objectid_formatted, ".", file_ext)
          em$new_filename[row] <- new_filename
          
          showNotification(paste("Updated match for", em$original_filename[row], "-> New filename:", new_filename), 
                         type = "message", duration = 3)
        }
        
        edited_matches(em)
      }
    }
  })
  
  # Display editable matches table
  output$editable_matches_table <- renderDT({
    em <- edited_matches()
    if (is.null(em)) return(NULL)
    
    # Find which columns to disable (all except matched_objectid)
    objectid_col_idx <- which(names(em) == "matched_objectid") - 1  # DT uses 0-based
    all_cols <- 0:(ncol(em) - 1)
    disabled_cols <- all_cols[all_cols != objectid_col_idx]
    
    datatable(
      em,
      editable = list(target = 'cell', disable = list(columns = disabled_cols)),
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
          c('Matched', 'Renamed', 'Manually matched', 'Manually unmatched', 
            'Failed to parse timestamp', 'No match within time threshold'),
          c('#d4edda', '#c3e6cb', '#b8daff', '#f8f9fa', '#f8d7da', '#fff3cd')
        )
      ) %>%
      formatStyle(
        'matched_objectid',
        backgroundColor = '#ffffcc',
        fontWeight = 'bold'
      ) %>%
      formatStyle(
        'new_filename',
        backgroundColor = '#e6f3ff',
        fontStyle = 'italic'
      )
  })
  
  # Display edit summary box
  output$edit_summary_box <- renderUI({
    em <- edited_matches()
    if (is.null(em)) {
      return(div(class = "alert alert-info", "No matches loaded. Click 'Load Current Matches' to start editing."))
    }
    
    total <- nrow(em)
    auto_matched <- sum(em$status %in% c("Matched", "Renamed"), na.rm = TRUE)
    manual_matched <- sum(em$status == "Manually matched", na.rm = TRUE)
    manual_unmatched <- sum(em$status == "Manually unmatched", na.rm = TRUE)
    unmatched <- sum(!em$status %in% c("Matched", "Renamed", "Manually matched"), na.rm = TRUE)
    
    div(class = "alert alert-info",
        h4("Edit Summary"),
        tags$ul(
          tags$li(strong("Total videos:"), total),
          tags$li(strong("Auto-matched:"), auto_matched),
          tags$li(strong("Manually matched:"), manual_matched),
          tags$li(strong("Manually unmatched:"), manual_unmatched),
          tags$li(strong("Unmatched:"), unmatched)
        )
    )
  })
  
  # Rename with edited matches
  observeEvent(input$run_rename_edited, {
    em <- edited_matches()
    
    if (is.null(em)) {
      showNotification("No edited matches available. Go to 'Edit Matches' tab first!", 
                      type = "warning", duration = 5)
      return()
    }
    
    # Confirm action
    showModal(modalDialog(
      title = "Confirm Rename with Edited Matches",
      "Are you sure you want to rename the videos using the edited matches? This action cannot be undone!",
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_rename_edited", "Yes, Rename", class = "btn-danger")
      )
    ))
  })
  
  # Confirmed rename with edited matches
  observeEvent(input$confirm_rename_edited, {
    removeModal()
    
    em <- edited_matches()
    
    if (is.null(em)) {
      showNotification("No edited matches available!", type = "error")
      return()
    }
    
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
    withProgress(message = 'Renaming videos with edited matches...', value = 0, {
      
      tryCatch({
        # Load CSV
        df <- read.csv(input$csv_path, stringsAsFactors = FALSE)
        
        # Parse datetime
        df$datetime_parsed <- as.POSIXct(df[[input$date_time_col]], 
                                        format = input$time_format, tz = "UTC")
        df$datetime_parsed <- force_tz(df$datetime_parsed, tzone = input$csv_timezone)
        df$datetime_camera <- with_tz(df$datetime_parsed, tzone = input$camera_timezone)
        
        # Process each matched video
        rename_count <- 0
        error_count <- 0
        
        for (i in 1:nrow(em)) {
          video_file <- em$original_filename[i]
          matched_oid <- em$matched_objectid[i]
          
          # Skip if no match or already renamed
          if (is.na(matched_oid) || matched_oid == "" || em$status[i] == "Renamed") {
            next
          }
          
          # Get video timestamp
          video_timestamp <- as.POSIXct(em$video_timestamp[i], tz = input$camera_timezone)
          
          # Extract date and time
          date_str <- format(video_timestamp, "%Y%m%d")
          time_str <- format(video_timestamp, "%H%M%S")
          
          # Format OBJECTID
          format_string <- paste0("%s%0", input$id_digits, "d")
          objectid_formatted <- sprintf(format_string, input$id_prefix, as.integer(matched_oid))
          
          # Get file extension
          file_ext <- sub(".*\\.", "", video_file)
          
          # Create new filename
          new_filename <- paste0(input$location, "_", date_str, "_", time_str, "_", 
                               objectid_formatted, ".", file_ext)
          
          # Rename file
          old_path <- file.path(input$video_dir, video_file)
          new_path <- file.path(input$video_dir, new_filename)
          
          if (!file.exists(old_path)) {
            cat("ERROR: Original file not found:", old_path, "\n")
            em$status[i] <- "Error: Original file not found"
            error_count <- error_count + 1
            next
          }
          
          if (file.exists(new_path)) {
            cat("ERROR: New filename already exists:", new_path, "\n")
            em$status[i] <- "Error: New filename exists"
            error_count <- error_count + 1
            next
          }
          
          success <- file.rename(old_path, new_path)
          if (success) {
            cat("Successfully renamed:", video_file, "->", new_filename, "\n")
            em$status[i] <- "Renamed"
            em$new_filename[i] <- new_filename
            rename_count <- rename_count + 1
          } else {
            cat("ERROR: Failed to rename:", video_file, "\n")
            em$status[i] <- "Error: Rename failed"
            error_count <- error_count + 1
          }
        }
        
        # Update edited matches with rename status
        edited_matches(em)
        results(em)
        
        # Create output CSV
        output_data <- data.frame()
        for (i in 1:nrow(em)) {
          if (em$status[i] == "Renamed" && !is.na(em$matched_objectid[i])) {
            matched_oid <- em$matched_objectid[i]
            csv_row <- df[df[[input$objectid_col]] == matched_oid, ][1, ]
            
            if (!is.na(csv_row[[input$objectid_col]])) {
              csv_row$original_filename <- em$original_filename[i]
              csv_row$matched_video_filename <- em$new_filename[i]
              csv_row$video_datetime <- em$video_timestamp[i]
              csv_row$time_difference_sec <- em$time_difference_sec[i]
              csv_row$datetime_parsed <- NULL
              csv_row$datetime_camera <- NULL
              output_data <- rbind(output_data, csv_row)
            }
          }
        }
        
        # Write output CSV
        if (nrow(output_data) > 0) {
          output_csv_path <- file.path(input$video_dir, paste0("video_matching_output_edited_", 
                                                               format(Sys.time(), "%Y%m%d_%H%M%S"), 
                                                               ".csv"))
          write.csv(output_data, output_csv_path, row.names = FALSE)
          cat("Output CSV saved to:", output_csv_path, "\n")
        }
        
        msg <- paste("Successfully renamed", rename_count, "videos using edited matches!")
        if (error_count > 0) {
          msg <- paste0(msg, " (", error_count, " errors)")
        }
        showNotification(msg, type = "message", duration = 7)
        
        # Switch to results tab
        updateTabsetPanel(session, "tabs", selected = "Results")
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # Load revert CSV
  observeEvent(input$load_revert_csv, {
    if (!file.exists(input$revert_csv_path)) {
      showNotification("CSV file does not exist!", type = "error")
      return()
    }
    
    tryCatch({
      df <- read.csv(input$revert_csv_path, stringsAsFactors = FALSE)
      
      # Check for required columns
      if (!("matched_video_filename" %in% names(df))) {
        showNotification("CSV must contain 'matched_video_filename' column!", type = "error")
        return()
      }
      
      # Try to find original filename column
      original_col <- NULL
      if ("original_filename" %in% names(df)) {
        original_col <- "original_filename"
      } else {
        showNotification("CSV must contain 'original_filename' column!", type = "error")
        return()
      }
      
      # Get video directory
      video_dir <- input$video_dir
      if (!dir.exists(video_dir)) {
        showNotification("Video directory does not exist! Please set it in the sidebar.", type = "error")
        return()
      }
      
      # Create revert dataframe
      revert_df <- data.frame(
        original_filename = df[[original_col]],
        current_filename = df$matched_video_filename,
        file_exists = FALSE,
        status = "",
        stringsAsFactors = FALSE
      )
      
      # Check which files exist
      for (i in seq_len(nrow(revert_df))) {
        current_path <- file.path(video_dir, revert_df$current_filename[i])
        if (file.exists(current_path)) {
          revert_df$file_exists[i] <- TRUE
          revert_df$status[i] <- "Ready to revert"
        } else {
          revert_df$status[i] <- "File not found"
        }
      }
      
      revert_data(revert_df)
      
      # Switch to revert tab
      updateTabsetPanel(session, "tabs", selected = "Revert Renaming")
      
      showNotification(paste("Loaded", sum(revert_df$file_exists), "files ready to revert!"), 
                      type = "message", duration = 3)
      
    }, error = function(e) {
      showNotification(paste("Error loading CSV:", e$message), type = "error", duration = 10)
    })
  })
  
  # Revert renaming
  observeEvent(input$revert_rename, {
    rd <- revert_data()
    
    if (is.null(rd)) {
      showNotification("No revert data loaded. Load a CSV file first!", type = "warning")
      return()
    }
    
    files_to_revert <- sum(rd$file_exists)
    if (files_to_revert == 0) {
      showNotification("No files found to revert!", type = "warning")
      return()
    }
    
    # Confirm action
    showModal(modalDialog(
      title = "Confirm Revert",
      paste("Are you sure you want to revert", files_to_revert, "files to their original DJI names? This action cannot be undone!"),
      footer = tagList(
        modalButton("Cancel"),
        actionButton("confirm_revert", "Yes, Revert", class = "btn-warning")
      )
    ))
  })
  
  # Confirmed revert
  observeEvent(input$confirm_revert, {
    removeModal()
    
    rd <- revert_data()
    if (is.null(rd)) {
      showNotification("No revert data available!", type = "error")
      return()
    }
    
    video_dir <- input$video_dir
    if (!dir.exists(video_dir)) {
      showNotification("Video directory does not exist!", type = "error")
      return()
    }
    
    withProgress(message = 'Reverting filenames...', value = 0, {
      tryCatch({
        revert_count <- 0
        error_count <- 0
        
        for (i in seq_len(nrow(rd))) {
          if (!rd$file_exists[i]) {
            next
          }
          
          current_path <- file.path(video_dir, rd$current_filename[i])
          original_path <- file.path(video_dir, rd$original_filename[i])
          
          # Check if original filename already exists
          if (file.exists(original_path)) {
            cat("ERROR: Original filename already exists:", original_path, "\n")
            rd$status[i] <- "Error: Original filename exists"
            error_count <- error_count + 1
            next
          }
          
          success <- file.rename(current_path, original_path)
          if (success) {
            cat("Successfully reverted:", rd$current_filename[i], "->", rd$original_filename[i], "\n")
            rd$status[i] <- "Reverted"
            rd$file_exists[i] <- FALSE
            revert_count <- revert_count + 1
          } else {
            cat("ERROR: Failed to revert:", rd$current_filename[i], "\n")
            rd$status[i] <- "Error: Revert failed"
            error_count <- error_count + 1
          }
        }
        
        revert_data(rd)
        
        msg <- paste("Successfully reverted", revert_count, "files to original names!")
        if (error_count > 0) {
          msg <- paste0(msg, " (", error_count, " errors)")
        }
        showNotification(msg, type = "message", duration = 7)
        
      }, error = function(e) {
        showNotification(paste("Error:", e$message), type = "error", duration = 10)
      })
    })
  })
  
  # Display revert summary
  output$revert_summary_box <- renderUI({
    rd <- revert_data()
    if (is.null(rd)) {
      return(div(class = "alert alert-info", "No data loaded. Select an output CSV file and click 'Load Renamed Videos'."))
    }
    
    total <- nrow(rd)
    ready <- sum(rd$status == "Ready to revert", na.rm = TRUE)
    reverted <- sum(rd$status == "Reverted", na.rm = TRUE)
    not_found <- sum(rd$status == "File not found", na.rm = TRUE)
    errors <- sum(grepl("Error", rd$status), na.rm = TRUE)
    
    status_class <- if (reverted > 0) "alert-success" else if (ready > 0) "alert-warning" else "alert-info"
    
    div(class = paste("alert", status_class),
        h4("Revert Summary"),
        tags$ul(
          tags$li(strong("Total entries:"), total),
          if (ready > 0) tags$li(strong("Ready to revert:"), ready),
          if (reverted > 0) tags$li(strong("Successfully reverted:"), reverted),
          if (not_found > 0) tags$li(strong("Files not found:"), not_found),
          if (errors > 0) tags$li(strong("Errors:"), errors)
        )
    )
  })
  
  # Display revert table
  output$revert_table <- renderDT({
    rd <- revert_data()
    if (is.null(rd)) return(NULL)
    
    datatable(
      rd,
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
          c('Ready to revert', 'Reverted', 'File not found', 'Error: Original filename exists', 'Error: Revert failed'),
          c('#fff3cd', '#c3e6cb', '#f8d7da', '#f8d7da', '#f8d7da')
        )
      ) %>%
      formatStyle(
        'file_exists',
        backgroundColor = styleEqual(
          c(TRUE, FALSE),
          c('#d4edda', '#f8d7da')
        )
      )
  })
}

# Run the application 
shinyApp(ui = ui, server = server)

