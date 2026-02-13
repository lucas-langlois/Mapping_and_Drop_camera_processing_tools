# Match and Rename DJI Videos Based on CSV Timestamps
# This script matches DJI camera videos to the closest timestamp in a CSV file
# and renames them with a standardized format: Location_YYYYMMDD_HHMMSS_ID###.MP4

#Match and Rename DJI Videos
#'
#This function matches DJI video files to the closest timestamp in a CSV dataframe
#and renames them using a standardized format: Location_YYYYMMDD_HHMMSS_ID###.MP4.
#The time component ensures uniqueness when multiple videos match the same mapping point ID.
#'
#@param video_dir Character. Directory containing the DJI video files
#@param csv_path Character. Path to the CSV file with timestamp and mapping point ID data
#@param location Character. Location name to use in the new filename (e.g., "ReefSiteA")
#@param date_time_col Character. Name of the date/time column in the CSV (default: "date_time")
#@param mappingid_col Character. Name of the mapping point ID column in the CSV (default: "OBJECTID")
#@param time_format Character. Format of the date_time column in CSV (default: "%Y-%m-%d %H:%M:%S")
#@param csv_timezone Character. Timezone of the date_time column in CSV (default: "UTC")
#@param camera_timezone Character. Timezone used by the DJI camera for recording (default: "Asia/Kolkata"). 
#  The CSV timestamps will be converted from csv_timezone to camera_timezone for matching.
#  Use OlsonNames() to see available timezone names.
#@param max_time_diff Numeric. Maximum time difference in seconds to allow a match (default: 300 = 5 minutes). 
#  Should be set to accommodate videos recorded in succession (typically 2-3 minutes apart)
#@param id_prefix Character. Prefix for the formatted mapping point ID (default: "ID")
#@param id_digits Integer. Number of digits for the formatted mapping point ID with zero padding (default: 3 for ID001, ID002, etc.)
#@param dry_run Logical. If TRUE, shows what would be renamed without actually renaming (default: TRUE)
#'
#@return A dataframe showing the matching results and new filenames
#@export
#'
#@examples
#match_and_rename_videos(
#  video_dir = "path/to/videos",
#  csv_path = "path/to/data.csv",
#  location = "SiteA",
#  csv_timezone = "UTC",
#  camera_timezone = "Asia/Kolkata",
#  dry_run = TRUE
#)
match_and_rename_videos <- function(video_dir,
                                    csv_path,
                                    location,
                                    date_time_col = "date_time",
                                    mappingid_col = "OBJECTID",
                                    time_format = "%Y-%m-%d %H:%M:%S",
                                    csv_timezone = "UTC",
                                    camera_timezone = "Asia/Kolkata",
                                    max_time_diff = 300,
                                    id_prefix = "ID",
                                    id_digits = 3,
                                    dry_run = TRUE) {
  
  # Load required libraries
  if (!require("lubridate")) {
    stop("Package 'lubridate' is required. Install it with: install.packages('lubridate')")
  }
  
  # Check for av package for video duration (optional)
  has_av <- requireNamespace("av", quietly = TRUE)
  if (!has_av) {
    cat("Note: 'av' package not installed. Video duration warnings will be skipped.\n")
    cat("To enable duration checks, install with: install.packages('av')\n\n")
  }
  
  # Validate inputs
  if (!dir.exists(video_dir)) {
    stop("Video directory does not exist: ", video_dir)
  }
  
  if (!file.exists(csv_path)) {
    stop("CSV file does not exist: ", csv_path)
  }
  
  # Read the CSV file
  cat("Reading CSV file:", csv_path, "\n")
  df <- read.csv(csv_path, stringsAsFactors = FALSE)
  
  # Check if required columns exist
  if (!date_time_col %in% names(df)) {
    stop("Column '", date_time_col, "' not found in CSV. Available columns: ", 
         paste(names(df), collapse = ", "))
  }
  
  if (!mappingid_col %in% names(df)) {
    stop("Column '", mappingid_col, "' not found in CSV. Available columns: ", 
         paste(names(df), collapse = ", "))
  }
  
  # Detect latitude and longitude columns (all caps)
  lat_col <- NULL
  lon_col <- NULL
  for (col_name in names(df)) {
    if (toupper(col_name) == "LATITUDE") {
      lat_col <- col_name
    }
    if (toupper(col_name) == "LONGITUDE") {
      lon_col <- col_name
    }
  }
  
  if (!is.null(lat_col) && !is.null(lon_col)) {
    cat("Found coordinate columns:", lat_col, "and", lon_col, "\n")
  } else {
    cat("Note: No LATITUDE/LONGITUDE columns found in CSV\n")
  }
  
  # Parse the date_time column with flexible format handling
  cat("Parsing date/time column...\n")
  df$datetime_parsed <- as.POSIXct(df[[date_time_col]], format = time_format, tz = "UTC")
  
  # If some entries failed, try alternative formats (e.g., without seconds)
  if (any(is.na(df$datetime_parsed))) {
    na_count_before <- sum(is.na(df$datetime_parsed))
    cat("  Warning:", na_count_before, "entries failed to parse with format:", time_format, "\n")
    
    # Try format without seconds if original has seconds
    if (grepl("%S", time_format)) {
      format_no_sec <- sub(":%S", "", time_format)
      cat("  Attempting alternative format without seconds:", format_no_sec, "\n")
      
      na_indices <- which(is.na(df$datetime_parsed))
      df$datetime_parsed[na_indices] <- as.POSIXct(df[[date_time_col]][na_indices], 
                                                    format = format_no_sec, tz = "UTC")
      
      na_count_after <- sum(is.na(df$datetime_parsed))
      parsed_count <- na_count_before - na_count_after
      if (parsed_count > 0) {
        cat("  Successfully parsed", parsed_count, "additional entries\n")
      }
    }
  }
  
  if (all(is.na(df$datetime_parsed))) {
    stop("Failed to parse date_time column. Check the time_format parameter.")
  }
  
  # Report any remaining unparsed entries
  remaining_na <- sum(is.na(df$datetime_parsed))
  if (remaining_na > 0) {
    cat("  Warning: Still have", remaining_na, "unparsed entries\n")
  }
  
  # Convert from CSV timezone to camera timezone
  cat("Converting from", csv_timezone, "to", camera_timezone, "...\n")
  df$datetime_parsed <- force_tz(df$datetime_parsed, tzone = csv_timezone)
  df$datetime_camera <- with_tz(df$datetime_parsed, tzone = camera_timezone)
  
  cat("Sample conversions:\n")
  cat("  CSV time (", csv_timezone, "): ", as.character(df$datetime_parsed[1]), "\n", sep = "")
  cat("  Camera time (", camera_timezone, "): ", as.character(df$datetime_camera[1]), "\n", sep = "")
  
  # Get list of DJI video files
  video_files <- list.files(video_dir, pattern = "^DJI_.*\\.MP4$", 
                            ignore.case = TRUE, full.names = FALSE)
  
  if (length(video_files) == 0) {
    stop("No DJI video files found in directory: ", video_dir)
  }
  
  cat("Found", length(video_files), "DJI video files\n\n")
  
  # Function to extract timestamp from DJI filename
  extract_timestamp <- function(filename) {
    # DJI format: DJI_YYYYMMDDHHMMSS_####_D.MP4
    pattern <- "DJI_(\\d{14})_.*\\.MP4$"
    match <- regexpr(pattern, filename, ignore.case = TRUE)
    
    if (match == -1) {
      return(NA)
    }
    
    timestamp_str <- sub("DJI_(\\d{14})_.*\\.MP4$", "\\1", filename, ignore.case = TRUE)
    
    # Parse timestamp: YYYYMMDDHHMMSS
    # DJI camera records in local time (camera_timezone), so parse it as such
    timestamp <- as.POSIXct(timestamp_str, format = "%Y%m%d%H%M%S", tz = camera_timezone)
    
    return(timestamp)
  }
  
  # Function to get video duration
  get_video_duration <- function(filepath) {
    if (!has_av) return(NA)
    
    tryCatch({
      info <- av::av_media_info(filepath)
      return(info$duration)
    }, error = function(e) {
      return(NA)
    })
  }
  
  # Create results dataframe
  results <- data.frame(
    original_filename = character(),
    video_timestamp = character(),
    video_duration_sec = numeric(),
    duration_warning = character(),
    matched_mappingid = character(),
    matched_datetime = character(),
    matched_latitude = character(),
    matched_longitude = character(),
    time_difference_sec = numeric(),
    new_filename = character(),
    status = character(),
    stringsAsFactors = FALSE
  )
  
  # Track matched mapping IDs
  matched_mappingids <- c()
  
  # Process each video file
  # Note: Multiple videos may match to the same mapping point ID (e.g., successive recordings at same location)
  # The time component (HHMMSS) in the new filename ensures uniqueness
  for (video_file in video_files) {
    cat("Processing:", video_file, "\n")
    
    # Get video duration
    video_path <- file.path(video_dir, video_file)
    duration_sec <- get_video_duration(video_path)
    duration_warning <- ""
    
    if (!is.na(duration_sec)) {
      cat("  Duration:", round(duration_sec, 1), "seconds\n")
      if (duration_sec < 30) {
        duration_warning <- "WARNING: Video < 30 sec"
        cat("  ", duration_warning, "\n")
      }
    }
    
    # Extract timestamp from filename
    video_timestamp <- extract_timestamp(video_file)
    
    if (is.na(video_timestamp)) {
      cat("  WARNING: Could not parse timestamp from filename\n")
      results <- rbind(results, data.frame(
        original_filename = video_file,
        video_timestamp = NA,
        video_duration_sec = duration_sec,
        duration_warning = duration_warning,
        matched_mappingid = NA,
        matched_datetime = NA,
        matched_latitude = NA,
        matched_longitude = NA,
        time_difference_sec = NA,
        new_filename = NA,
        status = "Failed to parse timestamp",
        stringsAsFactors = FALSE
      ))
      next
    }
    
    # Find closest timestamp in dataframe (using camera timezone)
    time_diffs <- abs(as.numeric(difftime(df$datetime_camera, video_timestamp, units = "secs")))
    min_diff_idx <- which.min(time_diffs)
    min_diff <- time_diffs[min_diff_idx]
    
    # Check if within acceptable time difference
    if (min_diff > max_time_diff) {
      cat("  WARNING: No match within", max_time_diff, "seconds. Closest match is", 
          round(min_diff, 1), "seconds away\n")
      results <- rbind(results, data.frame(
        original_filename = video_file,
        video_timestamp = as.character(video_timestamp),
        video_duration_sec = duration_sec,
        duration_warning = duration_warning,
        matched_mappingid = NA,
        matched_datetime = NA,
        matched_latitude = NA,
        matched_longitude = NA,
        time_difference_sec = min_diff,
        new_filename = NA,
        status = "No match within time threshold",
        stringsAsFactors = FALSE
      ))
      next
    }
    
    # Get matched row
    matched_row <- df[min_diff_idx, ]
    matched_mappingid <- matched_row[[mappingid_col]]
    matched_datetime <- matched_row$datetime_camera
    
    # Extract latitude and longitude if available
    matched_lat <- if (!is.null(lat_col)) as.character(matched_row[[lat_col]]) else NA
    matched_lon <- if (!is.null(lon_col)) as.character(matched_row[[lon_col]]) else NA
    
    # Extract date for new filename (YYYYMMDD)
    date_str <- format(video_timestamp, "%Y%m%d")
    
    # Extract time for uniqueness (HHMMSS)
    time_str <- format(video_timestamp, "%H%M%S")
    
    # Format mapping ID as ID### (e.g., ID001, ID002, etc.)
    # Mapping ID is an integer from the dataframe
    # Format with custom prefix and zero padding (e.g., ID001, ID002, etc.)
    format_string <- paste0("%s%0", id_digits, "d")
    mappingid_formatted <- sprintf(format_string, id_prefix, as.integer(matched_mappingid))
    
    # Get file extension
    file_ext <- sub(".*\\.", "", video_file)
    
    # Create new filename: Location_YYYYMMDD_HHMMSS_ID###.MP4
    # Time component ensures uniqueness when multiple videos match the same mapping ID
    new_filename <- paste0(location, "_", date_str, "_", time_str, "_", mappingid_formatted, ".", file_ext)
    
    cat("  Match found! Time diff:", round(min_diff, 1), "seconds\n")
    cat("  Mapping ID:", matched_mappingid, "\n")
    cat("  New filename:", new_filename, "\n")
    
    # Track matched mapping ID
    matched_mappingids <- c(matched_mappingids, as.character(matched_mappingid))
    
    # Add to results
    results <- rbind(results, data.frame(
      original_filename = video_file,
      video_timestamp = as.character(video_timestamp),
      video_duration_sec = duration_sec,
      duration_warning = duration_warning,
      matched_mappingid = as.character(matched_mappingid),
      matched_datetime = as.character(matched_datetime),
      matched_latitude = matched_lat,
      matched_longitude = matched_lon,
      time_difference_sec = min_diff,
      new_filename = new_filename,
      status = "Matched",
      stringsAsFactors = FALSE
    ))
    
    # Rename file if not dry run
    if (!dry_run) {
      old_path <- file.path(video_dir, video_file)
      new_path <- file.path(video_dir, new_filename)
      
      # Check if new filename already exists
      if (file.exists(new_path)) {
        cat("  ERROR: New filename already exists. Skipping rename.\n")
        results$status[nrow(results)] <- "Error: New filename exists"
      } else {
        success <- file.rename(old_path, new_path)
        if (success) {
          cat("  Successfully renamed!\n")
          results$status[nrow(results)] <- "Renamed"
        } else {
          cat("  ERROR: Failed to rename file\n")
          results$status[nrow(results)] <- "Error: Rename failed"
        }
      }
    }
    
    cat("\n")
  }
  
  # Find unmatched mapping IDs
  all_mappingids <- unique(df[[mappingid_col]])
  unmatched_mappingids <- setdiff(as.character(all_mappingids), matched_mappingids)
  
  # Create unmatched mapping IDs dataframe
  if (length(unmatched_mappingids) > 0) {
    unmatched_df <- df[df[[mappingid_col]] %in% unmatched_mappingids, ]
    # Select key columns
    key_cols <- c(mappingid_col, date_time_col)
    if (!is.null(lat_col)) key_cols <- c(key_cols, lat_col)
    if (!is.null(lon_col)) key_cols <- c(key_cols, lon_col)
    unmatched_df <- unmatched_df[, key_cols[key_cols %in% names(unmatched_df)], drop = FALSE]
  } else {
    unmatched_df <- data.frame()
  }
  
  # Print summary
  cat("\n========== SUMMARY ==========\n")
  cat("Total videos processed:", nrow(results), "\n")
  cat("Successfully matched:", sum(results$status == "Matched" | results$status == "Renamed"), "\n")
  if (!dry_run) {
    cat("Successfully renamed:", sum(results$status == "Renamed"), "\n")
  }
  cat("Failed to match:", sum(results$status != "Matched" & results$status != "Renamed"), "\n")
  
  # Duration warnings
  if (has_av) {
    short_videos <- sum(results$duration_warning != "", na.rm = TRUE)
    if (short_videos > 0) {
      cat("\n** WARNING: ", short_videos, " video(s) are shorter than 30 seconds **\n", sep="")
    }
  }
  
  # Unmatched mapping IDs
  cat("\nTotal mapping IDs in CSV:", length(all_mappingids), "\n")
  cat("Mapping IDs matched to videos:", length(unique(matched_mappingids)), "\n")
  cat("Mapping IDs NOT matched:", length(unmatched_mappingids), "\n")
  
  if (length(unmatched_mappingids) > 0) {
    cat("\n** UNMATCHED Mapping IDs (no video found): **\n")
    cat(paste(unmatched_mappingids, collapse = ", "), "\n")
  }
  
  if (dry_run) {
    cat("\n** DRY RUN MODE - No files were actually renamed **\n")
    cat("Set dry_run = FALSE to perform the actual renaming\n")
  }
  
  # Create output CSV with full data (when not dry run)
  if (!dry_run) {
    # Create a merged dataframe with all CSV columns + video info
    # Only include successfully matched/renamed videos
    matched_results <- results[results$status %in% c("Matched", "Renamed"), ]
    
    if (nrow(matched_results) > 0) {
      # Create output dataframe by matching mapping ID
      output_df <- data.frame()
      
      for (i in 1:nrow(matched_results)) {
        matched_oid <- matched_results$matched_mappingid[i]
        
        # Find the corresponding CSV row
        csv_row <- df[df[[mappingid_col]] == matched_oid, ]
        
        # If multiple CSV rows match, take the first one (should be unique based on closest match)
        if (nrow(csv_row) > 0) {
          # Get first matching row and add video info
          csv_row <- csv_row[1, ]
          csv_row$original_filename <- matched_results$original_filename[i]
          csv_row$matched_video_filename <- matched_results$new_filename[i]
          csv_row$video_datetime <- matched_results$video_timestamp[i]
          csv_row$time_difference_sec <- matched_results$time_difference_sec[i]
          
          # Remove helper columns used for matching
          csv_row$datetime_parsed <- NULL
          csv_row$datetime_camera <- NULL
          
          output_data <- rbind(output_data, csv_row)
        }
      }
      
      # Write output CSV
      output_csv_path <- file.path(video_dir, paste0("video_matching_output_", 
                                                      format(Sys.time(), "%Y%m%d_%H%M%S"), 
                                                      ".csv"))
      write.csv(output_data, output_csv_path, row.names = FALSE)
      cat("\n** Output CSV saved to:", output_csv_path, "**\n")
    }
  }
  
  # Attach unmatched mapping IDs as an attribute
  attr(results, "unmatched_mappingids") <- unmatched_df
  
  # Return results dataframe
  return(results)
}


#Example usage:
#
## Dry run to see what would be renamed
#results <- match_and_rename_videos(
#  video_dir = "E:/Videos/DJI",
#  csv_path = "E:/Data/survey_data.csv",
#  location = "ReefSiteA",
#  date_time_col = "date_time",
#  mappingid_col = "OBJECTID",
#  time_format = "%Y-%m-%d %H:%M:%S",
#  csv_timezone = "UTC",           # CSV data is in UTC
#  camera_timezone = "Asia/Kolkata",  # DJI camera records in IST
#  max_time_diff = 300,  # 5 minutes max difference
#  id_prefix = "ID",     # Prefix for mapping ID (default: "ID")
#  id_digits = 3,        # Zero-pad to 3 digits (default: 3) -> ID001, ID002, etc.
#  dry_run = TRUE
#)
#
## View results
#View(results)
#
## If happy with the results, run for real
#results <- match_and_rename_videos(
#  video_dir = "E:/Videos/DJI",
#  csv_path = "E:/Data/survey_data.csv",
#  location = "ReefSiteA",
#  csv_timezone = "UTC",
#  camera_timezone = "Asia/Kolkata",
#  dry_run = FALSE
#)
#'
## Export results to CSV
#write.csv(results, "video_rename_log.csv", row.names = FALSE)
#
## Example output for successive videos at same location:
## Original: DJI_20250901121607_0024_D.MP4 -> ReefSiteA_20250901_121607_ID001.MP4
## Original: DJI_20250901121809_0025_D.MP4 -> ReefSiteA_20250901_121809_ID001.MP4
## Original: DJI_20250901122103_0026_D.MP4 -> ReefSiteA_20250901_122103_ID001.MP4

