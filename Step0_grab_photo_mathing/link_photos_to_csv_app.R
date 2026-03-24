# ══════════════════════════════════════════════════════════════════════════════
# Grab Photo → CSV Linker  (Shiny App)
#
# Workflow:
#   1. Load your CSV and select the photos folder
#   2. Click "Check for EXIF Data" to see if photos have GPS metadata
#   3a. EXIF detected  → match by distance + time, review on interactive map
#   3b. No EXIF        → match by filename (POINT_ID prefix)
#   4. Preview, review on map, then export
# ══════════════════════════════════════════════════════════════════════════════

# ── Auto-install required packages ────────────────────────────────────────────
required_packages <- c(
  "shiny", "shinydashboard", "DT", "shinyFiles", "fs",
  "leaflet", "shinyjs", "lubridate", "dplyr"
)

install_if_missing <- function(pkgs) {
  missing <- pkgs[!sapply(pkgs, requireNamespace, quietly = TRUE)]
  if (length(missing) > 0) {
    cat("Installing missing packages:", paste(missing, collapse = ", "), "\n")
    install.packages(missing, repos = "https://cloud.r-project.org/", quiet = TRUE)
  }
}

install_if_missing(required_packages)

library(shiny)
library(shinydashboard)
library(DT)
library(shinyFiles)
library(fs)
library(leaflet)
library(shinyjs)
library(lubridate)
library(dplyr)

# ── Helper functions ──────────────────────────────────────────────────────────

# Haversine distance (vectorised), returns metres
haversine_m <- function(lat1, lon1, lat2, lon2) {
  R    <- 6371000
  phi1 <- lat1 * pi / 180
  phi2 <- lat2 * pi / 180
  dphi    <- (lat2 - lat1) * pi / 180
  dlambda <- (lon2 - lon1) * pi / 180
  a <- sin(dphi / 2)^2 + cos(phi1) * cos(phi2) * sin(dlambda / 2)^2
  2 * R * asin(pmin(1, sqrt(a)))
}

# Apply S/W sign to absolute GPS decimal degrees
signed_coord <- function(val, ref) {
  ifelse(!is.na(ref) & toupper(trimws(ref)) %in% c("S", "W"), -abs(val), abs(val))
}

# Pure-R JPEG EXIF GPS patcher ─────────────────────────────────────────────
# Overwrites GPS lat/lon directly in the JPEG binary (no ExifTool, no Python).
# Works even when ExifTool fails due to corrupted IFD0 thumbnail data (common
# in DJI grab photos). Returns TRUE on success, FALSE if GPS IFD not found.
patch_jpeg_gps_r <- function(filepath, lat, lon) {
  sz  <- file.info(filepath)$size
  raw <- readBin(filepath, "raw", sz)

  # ── byte-level read helpers (1-indexed positions) ──────────────────────
  r16 <- function(p, be) {
    b <- as.integer(raw[p:(p + 1L)])
    if (be) b[1L] * 256L + b[2L] else b[1L] + b[2L] * 256L
  }
  r32 <- function(p, be) {
    b <- as.integer(raw[p:(p + 3L)])
    if (be) b[1L]*16777216L + b[2L]*65536L + b[3L]*256L + b[4L]
    else     b[1L] + b[2L]*256L + b[3L]*65536L + b[4L]*16777216L
  }

  # ── pack decimal degrees → 24-byte GPS RATIONAL[3] ────────────────────
  pack_rat3 <- function(deg, be) {
    deg <- abs(deg)
    d   <- floor(deg)
    m   <- floor((deg - d) * 60)
    s   <- round(((deg - d) * 60 - m) * 60 * 1e6)
    vals <- as.integer(c(d, 1, m, 1, s, 1000000))
    do.call(c, lapply(vals, function(v) {
      b <- bitwAnd(bitwShiftR(v, c(0L, 8L, 16L, 24L)), 255L)
      as.raw(if (be) rev(b) else b)
    }))
  }

  # ── locate APP1 / EXIF ────────────────────────────────────────────────
  exif_sig  <- as.raw(c(0x45, 0x78, 0x69, 0x66, 0x00, 0x00))  # "Exif\0\0"
  tiff_base <- NA_integer_
  p <- 3L  # byte 1-2 = SOI (FF D8)
  repeat {
    if (p + 10L > sz) break
    if (raw[p] != as.raw(0xff)) break
    marker  <- as.integer(raw[p + 1L])
    seg_len <- r16(p + 2L, be = TRUE)  # JPEG lengths are always big-endian
    if (marker == 0xe1 && seg_len >= 14L &&
        all(raw[(p + 4L):(p + 9L)] == exif_sig)) {
      tiff_base <- p + 10L
      break
    }
    p <- p + 2L + seg_len
  }
  if (is.na(tiff_base)) return(FALSE)

  # ── byte order ────────────────────────────────────────────────────────
  be <- rawToChar(raw[tiff_base:(tiff_base + 1L)]) == "MM"

  # ── IFD0 → find GPS IFD pointer (tag 0x8825) ─────────────────────────
  ifd0_p  <- tiff_base + r32(tiff_base + 4L, be)
  n0      <- r16(ifd0_p, be)
  gps_p   <- NA_integer_
  for (i in 0L:(n0 - 1L)) {
    ep <- ifd0_p + 2L + i * 12L
    if (r16(ep, be) == 0x8825L) {
      gps_p <- tiff_base + r32(ep + 8L, be)
      break
    }
  }
  if (is.na(gps_p)) return(FALSE)

  # ── patch GPS IFD entries ─────────────────────────────────────────────
  lat_ref <- if (lat >= 0) as.raw(c(0x4e,0x00,0x00,0x00)) else as.raw(c(0x53,0x00,0x00,0x00))
  lon_ref <- if (lon >= 0) as.raw(c(0x45,0x00,0x00,0x00)) else as.raw(c(0x57,0x00,0x00,0x00))
  lat_b   <- pack_rat3(lat, be)
  lon_b   <- pack_rat3(lon, be)

  ng      <- r16(gps_p, be)
  patched <- 0L
  for (i in 0L:(ng - 1L)) {
    ep  <- gps_p + 2L + i * 12L
    tag <- r16(ep, be)
    if (tag == 0x0001L) {  # GPSLatitudeRef  (ASCII[2], inline)
      raw[(ep + 8L):(ep + 11L)] <- lat_ref;  patched <- patched + 1L
    } else if (tag == 0x0003L) {  # GPSLongitudeRef (ASCII[2], inline)
      raw[(ep + 8L):(ep + 11L)] <- lon_ref;  patched <- patched + 1L
    } else if (tag == 0x0002L) {  # GPSLatitude  (RATIONAL[3], offset)
      off <- tiff_base + r32(ep + 8L, be)
      raw[off:(off + 23L)] <- lat_b;         patched <- patched + 1L
    } else if (tag == 0x0004L) {  # GPSLongitude (RATIONAL[3], offset)
      off <- tiff_base + r32(ep + 8L, be)
      raw[off:(off + 23L)] <- lon_b;         patched <- patched + 1L
    }
  }

  if (patched < 4L) return(FALSE)
  writeBin(raw, filepath)
  return(TRUE)
}

# Pure-R JPEG EXIF reader ─────────────────────────────────────────────────────
# Reads GPS + DateTimeOriginal from a single JPEG without ExifTool or exifr.
read_jpeg_exif_r <- function(filepath) {
  result <- list(
    FileName         = basename(filepath),
    GPSLatitude      = NA_real_,  GPSLatitudeRef  = NA_character_,
    GPSLongitude     = NA_real_,  GPSLongitudeRef = NA_character_,
    DateTimeOriginal = NA_character_
  )
  sz <- tryCatch(file.info(filepath)$size, error = function(e) NA_integer_)
  if (is.na(sz) || sz < 12L) return(result)
  raw <- readBin(filepath, "raw", sz)

  # byte helpers — use numeric arithmetic to avoid signed int32 overflow
  r16 <- function(p, be) {
    b <- as.numeric(as.integer(raw[p:(p + 1L)]))
    if (be) b[1]*256 + b[2] else b[1] + b[2]*256
  }
  r32 <- function(p, be) {
    b <- as.numeric(as.integer(raw[p:(p + 3L)]))
    if (be) b[1]*16777216 + b[2]*65536 + b[3]*256 + b[4]
    else     b[1] + b[2]*256 + b[3]*65536 + b[4]*16777216
  }
  read_rat3 <- function(off, be) {
    dn <- r32(off,      be); dd <- r32(off + 4L,  be)
    mn <- r32(off + 8L, be); md <- r32(off + 12L, be)
    sn <- r32(off + 16L,be); sd <- r32(off + 20L, be)
    if (dd == 0) return(NA_real_)
    d <- dn / dd
    m <- if (md == 0) 0 else mn / md
    s <- if (sd == 0) 0 else sn / sd
    d + m/60 + s/3600
  }
  read_ascii <- function(off, count) {
    if (off < 1L || off + count - 1L > sz) return("")
    bytes <- raw[off:(off + count - 1L)]
    trimws(rawToChar(bytes[bytes != as.raw(0x00)]))
  }

  # locate APP1 / Exif header
  exif_sig  <- as.raw(c(0x45, 0x78, 0x69, 0x66, 0x00, 0x00))
  tiff_base <- NA_integer_
  p <- 3L
  repeat {
    if (p + 10L > sz) break
    if (raw[p] != as.raw(0xff)) break
    seg_len <- r16(p + 2L, be = TRUE)
    marker  <- as.integer(raw[p + 1L])
    if (marker == 0xe1 && seg_len >= 14L &&
        all(raw[(p + 4L):(p + 9L)] == exif_sig)) {
      tiff_base <- p + 10L; break
    }
    p <- p + 2L + seg_len
  }
  if (is.na(tiff_base)) return(result)

  be     <- rawToChar(raw[tiff_base:(tiff_base + 1L)]) == "MM"
  ifd0_p <- tiff_base + r32(tiff_base + 4L, be)
  n0     <- r16(ifd0_p, be)

  gps_p  <- NA_integer_
  exif_p <- NA_integer_
  for (i in 0L:(n0 - 1L)) {
    ep  <- ifd0_p + 2L + i * 12L
    tag <- r16(ep, be)
    if (tag == 0x8825L) gps_p  <- tiff_base + r32(ep + 8L, be)
    if (tag == 0x8769L) exif_p <- tiff_base + r32(ep + 8L, be)
  }

  # GPS sub-IFD
  if (!is.na(gps_p) && gps_p + 2L <= sz) {
    ng <- r16(gps_p, be)
    for (i in 0L:(ng - 1L)) {
      ep  <- gps_p + 2L + i * 12L
      tag <- r16(ep, be)
      cnt <- r32(ep + 4L, be)
      if (tag == 0x0001L) {  # GPSLatitudeRef  (inline ASCII)
        result$GPSLatitudeRef  <- substr(read_ascii(ep + 8L, cnt), 1L, 1L)
      } else if (tag == 0x0003L) {  # GPSLongitudeRef (inline ASCII)
        result$GPSLongitudeRef <- substr(read_ascii(ep + 8L, cnt), 1L, 1L)
      } else if (tag == 0x0002L) {  # GPSLatitude  RATIONAL[3]
        off <- tiff_base + r32(ep + 8L, be)
        result$GPSLatitude  <- tryCatch(read_rat3(off, be), error = function(e) NA_real_)
      } else if (tag == 0x0004L) {  # GPSLongitude RATIONAL[3]
        off <- tiff_base + r32(ep + 8L, be)
        result$GPSLongitude <- tryCatch(read_rat3(off, be), error = function(e) NA_real_)
      }
    }
  }

  # Exif sub-IFD → DateTimeOriginal (tag 0x9003)
  if (!is.na(exif_p) && exif_p + 2L <= sz) {
    ne <- r16(exif_p, be)
    for (i in 0L:(ne - 1L)) {
      ep  <- exif_p + 2L + i * 12L
      tag <- r16(ep, be)
      if (tag == 0x9003L) {
        cnt <- r32(ep + 4L, be)
        off <- if (cnt <= 4L) ep + 8L else tiff_base + r32(ep + 8L, be)
        result$DateTimeOriginal <- read_ascii(off, cnt)
        break
      }
    }
  }
  result
}

# Wrapper: reads many files, returns a data.frame matching exifr column names
read_exif_r <- function(filepaths) {
  blank <- list(FileName = NA_character_, GPSLatitude = NA_real_,
                GPSLatitudeRef = NA_character_, GPSLongitude = NA_real_,
                GPSLongitudeRef = NA_character_, DateTimeOriginal = NA_character_)
  rows <- lapply(filepaths, function(fp) {
    tryCatch(read_jpeg_exif_r(fp), error = function(e) { blank$FileName <- basename(fp); blank })
  })
  do.call(rbind, lapply(rows, as.data.frame, stringsAsFactors = FALSE))
}

# ══════════════════════════════════════════════════════════════════════════════
# UI
# ══════════════════════════════════════════════════════════════════════════════

ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(title = "Grab Photo Linker"),

  dashboardSidebar(
    sidebarMenu(
      id = "sidebar",
      menuItem("1. Load Data",       tabName = "load",    icon = icon("upload")),
      menuItem("2. Check EXIF",      tabName = "exif",    icon = icon("camera")),
      menuItem("3. Match Photos",    tabName = "match",   icon = icon("link")),
      menuItem("4. Review Map",      tabName = "map",     icon = icon("map")),
      menuItem("5. Rename Photos",   tabName = "rename",  icon = icon("file-signature")),
      menuItem("6. Results & Export", tabName = "results", icon = icon("table"))
    )
  ),

  dashboardBody(
    useShinyjs(),
    tags$head(tags$style(HTML("
      .content-wrapper { background-color: #ecf0f5; }
      .box { border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
      .info-box { border-radius: 8px; }
      .step-instructions { background: #eaf4fe; border-left: 4px solid #3c8dbc;
        padding: 12px 16px; margin-bottom: 15px; border-radius: 4px; }
      .step-instructions p { margin: 4px 0; }
      .warning-box { background: #fff8e1; border-left: 4px solid #ffc107;
        padding: 12px 16px; margin-bottom: 15px; border-radius: 4px; }
      .success-box { background: #e8f5e9; border-left: 4px solid #4caf50;
        padding: 12px 16px; margin-bottom: 15px; border-radius: 4px; }
      .error-box { background: #ffebee; border-left: 4px solid #f44336;
        padding: 12px 16px; margin-bottom: 15px; border-radius: 4px; }
    "))),

    tabItems(

      # ════════════════════════════════════════════════════════════════════════
      # TAB 1 — Load Data
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "load",
        fluidRow(
          box(
            title = "Step 1: Load Your Data", status = "primary",
            solidHeader = TRUE, width = 12,
            div(class = "step-instructions",
              tags$h4(icon("info-circle"), " What to do"),
              tags$p("This tool links your grab-sample photos to rows in a CSV file so each
                      row knows which photo(s) belong to it."),
              tags$ol(
                tags$li(tags$b("Select your CSV file"), " — this is the data sheet that lists
                         your sampling points (it must have columns for coordinates or a
                         POINT_ID)."),
                tags$li(tags$b("Select your photos folder"), " — the directory that contains
                         the .jpg photos you want to link."),
                tags$li("Once both are loaded, move on to ", tags$b("Step 2: Check EXIF"), ".")
              )
            )
          )
        ),

        fluidRow(
          # CSV loader
          box(
            title = "CSV File", status = "info", solidHeader = TRUE, width = 6,
            div(style = "margin-bottom: 10px;",
              textInput("csv_path", "CSV File Path:", value = "", width = "100%"),
              shinyFilesButton("csv_file_browse", "Browse for CSV...",
                               "Select CSV file", multiple = FALSE,
                               class = "btn-sm btn-info",
                               style = "width: 100%; margin-top: 5px;")
            ),
            actionButton("load_csv_btn", "Load CSV",
                         class = "btn-primary", icon = icon("file-csv"),
                         style = "width: 100%; margin-top: 5px;"),
            hr(),
            uiOutput("csv_status_ui"),
            DTOutput("csv_preview_table")
          ),

          # Photos loader
          box(
            title = "Photos Folder", status = "info", solidHeader = TRUE, width = 6,
            div(style = "margin-bottom: 10px;",
              textInput("photos_dir", "Photos Directory:",
                        value = file.path(getwd(), "Grab_photos"), width = "100%"),
              shinyDirButton("photos_dir_browse", "Browse for Folder...",
                             "Select photos directory",
                             class = "btn-sm btn-info",
                             style = "width: 100%; margin-top: 5px;")
            ),
            actionButton("scan_photos_btn", "Scan Photos",
                         class = "btn-primary", icon = icon("image"),
                         style = "width: 100%; margin-top: 5px;"),
            hr(),
            uiOutput("photo_status_ui"),
            DTOutput("photo_list_table")
          )
        )
      ),

      # ════════════════════════════════════════════════════════════════════════
      # TAB 2 — Check EXIF
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "exif",
        fluidRow(
          box(
            title = "Step 2: Check for EXIF Data", status = "primary",
            solidHeader = TRUE, width = 12,
            div(class = "step-instructions",
              tags$h4(icon("info-circle"), " What is EXIF data?"),
              tags$p("EXIF data is hidden metadata inside a photo file. Many cameras and
                      phones record the GPS location and timestamp when a photo is taken."),
              tags$p("Click the button below to scan your photos. The app will tell you
                      whether your photos contain GPS coordinates."),
              tags$ul(
                tags$li(tags$b("If GPS is found:"), " the app can match photos to CSV rows
                         using distance and/or time — this is the most accurate method.
                         You will see both points on a map to verify."),
                tags$li(tags$b("If NO GPS is found:"), " the app will fall back to matching
                         by filename. Your photo filenames must start with the POINT_ID
                         number (e.g. ", tags$code("42_20251119_062201_Photo 3.jpg"), ").")
              ),
              tags$p(tags$b("Note:"), " EXIF reading is built in — no extra software needed.",
                     " If photos have no GPS, filename matching is used automatically.")
            )
          )
        ),

        fluidRow(
          box(
            title = "EXIF Check", status = "warning", solidHeader = TRUE, width = 12,
            actionButton("check_exif_btn", "Check for EXIF Data",
                         class = "btn-warning btn-lg",
                         icon = icon("camera"),
                         style = "width: 300px; margin-bottom: 15px;"),
            hr(),
            uiOutput("exif_result_ui"),
            hr(),
            h4("EXIF Data Table"),
            p("This table shows the GPS and timestamp metadata extracted from each photo.
               Rows highlighted in yellow are missing GPS coordinates."),
            DTOutput("exif_detail_table")
          )
        )
      ),

      # ════════════════════════════════════════════════════════════════════════
      # TAB 3 — Match Photos
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "match",
        fluidRow(
          box(
            title = "Step 3: Match Photos to CSV Rows", status = "primary",
            solidHeader = TRUE, width = 12,
            uiOutput("match_instructions_ui")
          )
        ),

        fluidRow(
          # Matching settings
          box(
            title = "Matching Settings", status = "info", solidHeader = TRUE, width = 4,
            uiOutput("match_settings_ui")
          ),

          # Run matching
          box(
            title = "Run Matching", status = "success", solidHeader = TRUE, width = 8,
            uiOutput("match_ready_ui"),
            hr(),
            actionButton("run_match_btn", "Run Matching",
                         class = "btn-success btn-lg",
                         icon = icon("play"),
                         style = "width: 300px;"),
            hr(),
            uiOutput("match_summary_ui")
          )
        ),

        fluidRow(
          column(12, uiOutput("match_diag_box_ui"))
        )
      ),

      # ════════════════════════════════════════════════════════════════════════
      # TAB 4 — Review Map
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "map",
        fluidRow(
          box(
            title = "Step 4: Review Matches on Map", status = "primary",
            solidHeader = TRUE, width = 12,
            div(class = "step-instructions",
              tags$h4(icon("info-circle"), " How to use the map"),
              tags$p("This map shows two layers so you can visually verify the matching:"),
              tags$ul(
                tags$li(tags$span(style = "color: #2196F3; font-weight: bold;",
                                  "Blue circles"), " = CSV sampling points (from your data file)"),
                tags$li(tags$span(style = "color: #FF5722; font-weight: bold;",
                                  "Red circles"), " = Photo locations (from EXIF GPS)"),
                tags$li(tags$span(style = "color: #4CAF50; font-weight: bold;",
                                  "Green lines"), " = Connections between matched CSV rows and their photos")
              ),
              tags$p("Click any marker to see details. If photo markers are far from their
                      matched CSV point, you may need to increase the distance threshold
                      and re-run matching."),
              tags$p(tags$em("Note: If you used filename matching (no EXIF), only CSV points
                              will appear on the map (photo GPS is not available)."))
            )
          )
        ),

        fluidRow(
          box(
            title = "Interactive Map", status = "info", solidHeader = TRUE, width = 12,
            leafletOutput("review_map", height = "600px")
          )
        )
      ),

      # ════════════════════════════════════════════════════════════════════════
      # TAB 5 — Rename Photos
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "rename",
        fluidRow(
          box(
            title = "Step 5: Rename Matched Photos", status = "primary",
            solidHeader = TRUE, width = 12,
            div(class = "step-instructions",
              tags$h4(icon("info-circle"), " Rename your grab photos"),
              tags$p("Before exporting, you can rename the photo files to follow a
                      standardised convention. This makes it easy to identify photos
                      later, and the renamed filenames will appear in the exported CSV."),
              tags$p("New filename format:"),
              tags$code("{Location}_{PointID}_{YYYYMMDD}_GRAB_{#}.jpg"),
              tags$br(), tags$br(),
              tags$p("Example: ", tags$code("Chilika_42_20251119_GRAB_1.jpg")),
              tags$ul(
                tags$li(tags$b("Location"), " — a name you choose (e.g. your study site)."),
                tags$li(tags$b("PointID"), " — taken from the POINT_ID column in your CSV."),
                tags$li(tags$b("YYYYMMDD"), " — the date extracted from the original filename
                         or EXIF data."),
                tags$li(tags$b("#"), " — a sequence number when multiple photos match
                         the same point (1, 2, 3 ...).")
              ),
              tags$p(tags$b("Important:"), " Renamed copies are saved into a new subfolder
                     called ", tags$code("Grab_photos_renamed"),
                     " next to your photos folder. The originals are ",
                     tags$b("not modified"), ". The GRAB_FILENAME column will be updated
                     to the new names and the original filenames are kept in
                     GRAB_FILENAME_ORIGINAL for traceability."),
              tags$p("This step is ", tags$b("optional"), ". If you skip it the export
                      in Step 6 will use the original filenames.")
            )
          )
        ),

        fluidRow(
          box(
            title = "Rename Settings", status = "info", solidHeader = TRUE, width = 6,
            textInput("location_id", "Location / Site Name:",
                      value = "", width = "100%",
                      placeholder = "e.g. Chilika, SiteA, Reef3"),
            helpText("This text will be the first part of every renamed file. Use letters,
                      numbers, and underscores only — spaces will be replaced with
                      underscores."),
            hr(),
            uiOutput("rename_pointid_col_ui"),
            hr(),
            uiOutput("rename_ready_ui"),
            hr(),
            checkboxInput("fix_bad_gps_exif",
                          "Overwrite GPS in renamed photos that were matched by time only (bad GPS)",
                          value = FALSE),
            helpText("For photos where the EXIF GPS was unreliable and matching used the",
                     " timestamp instead, the renamed copy's GPS coordinates will be replaced",
                     " with the lat/lon of the matched CSV point.")
          ),
          box(
            title = "Run Rename", status = "success", solidHeader = TRUE, width = 6,
            actionButton("rename_btn", "Rename Photos",
                         class = "btn-success btn-lg",
                         icon = icon("file-signature"),
                         style = "width: 300px; margin-bottom: 15px;"),
            hr(),
            uiOutput("rename_summary_ui"),
            hr(),
            h4("Rename Log"),
            DTOutput("rename_log_table")
          )
        )
      ),

      # ════════════════════════════════════════════════════════════════════════
      # TAB 6 — Results & Export
      # ════════════════════════════════════════════════════════════════════════
      tabItem(tabName = "results",
        fluidRow(
          box(
            title = "Step 6: Review Results & Export", status = "primary",
            solidHeader = TRUE, width = 12,
            div(class = "step-instructions",
              tags$h4(icon("info-circle"), " Almost done!"),
              tags$p("Review the table below. Rows highlighted in ", tags$b("yellow"),
                     " did not get any photo matched. If too many rows are unmatched,
                      go back and adjust your settings."),
              tags$p("If you renamed photos in Step 5, the ", tags$b("GRAB_FILENAME"),
                     " column shows the new names and ", tags$b("GRAB_FILENAME_ORIGINAL"),
                     " preserves the originals for traceability."),
              tags$p("When you are satisfied, click ", tags$b("Save Output CSV"),
                     " to write a new CSV file with the photo filename columns added.")
            )
          )
        ),

        fluidRow(
          box(
            title = "Summary", status = "info", solidHeader = TRUE, width = 12,
            uiOutput("results_summary_ui")
          )
        ),

        fluidRow(
          box(
            title = "Matched Data", status = "success", solidHeader = TRUE, width = 12,
            DTOutput("results_table"),
            hr(),
            h4("Output Settings"),
            textInput("separator", "Multi-filename separator character:",
                      value = ";", width = "200px"),
            helpText("When multiple photos match one row, this character separates
                      the filenames in the GRAB_FILENAME column."),
            hr(),
            fluidRow(
              column(4,
                actionButton("save_csv_btn", "Save Output CSV",
                             class = "btn-success btn-lg",
                             icon = icon("save"),
                             style = "width: 100%;")
              )
            )
          )
        ),

        fluidRow(
          box(
            title = "Unmatched Photos", status = "warning",
            solidHeader = TRUE, width = 6, collapsible = TRUE, collapsed = TRUE,
            p("These photos were not matched to any CSV row:"),
            DTOutput("unmatched_photos_table")
          ),
          box(
            title = "Skipped Photos", status = "danger",
            solidHeader = TRUE, width = 6, collapsible = TRUE, collapsed = TRUE,
            p("These photos were skipped (unrecognised filename or missing GPS):"),
            DTOutput("skipped_photos_table")
          )
        )
      )
    ) # end tabItems
  ) # end dashboardBody
)

# ══════════════════════════════════════════════════════════════════════════════
# SERVER
# ══════════════════════════════════════════════════════════════════════════════

server <- function(input, output, session) {

  # ── Reactive values ──────────────────────────────────────────────────────
  rv <- reactiveValues(
    csv_data         = NULL,    # loaded CSV data.frame
    csv_columns      = NULL,    # column names
    photo_files      = NULL,    # data.frame of scanned photos
    exif_data        = NULL,    # full EXIF data.frame
    exif_has_gps     = NULL,    # logical: TRUE if GPS found in photos
    match_method     = NULL,    # "exif" or "filename"
    results          = NULL,    # matched data.frame
    unmatched_photos      = NULL,
    skipped_photos        = NULL,
    last_method           = NULL,
    unmatched_diagnostic  = NULL,  # nearest CSV point for each unmatched photo
    rename_log            = NULL   # data.frame of old → new filenames
  )

  # ── File browser setup ──────────────────────────────────────────────────
  volumes <- c(Project = getwd(), Home = fs::path_home(), getVolumes()())

  shinyDirChoose(input, "photos_dir_browse", roots = volumes, session = session)
  observeEvent(input$photos_dir_browse, {
    p <- parseDirPath(volumes, input$photos_dir_browse)
    if (length(p) > 0) updateTextInput(session, "photos_dir", value = p)
  })

  shinyFileChoose(input, "csv_file_browse", roots = volumes, session = session,
                  filetypes = c("csv", "CSV"))
  observeEvent(input$csv_file_browse, {
    fp <- parseFilePaths(volumes, input$csv_file_browse)
    if (nrow(fp) > 0) updateTextInput(session, "csv_path", value = as.character(fp$datapath))
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 1 — Load Data (handlers)
  # ════════════════════════════════════════════════════════════════════════

  # Load CSV
  observeEvent(input$load_csv_btn, {
    req(input$csv_path)
    if (!file.exists(input$csv_path)) {
      showNotification("CSV file not found! Check the path.", type = "error")
      return()
    }
    tryCatch({
      df <- read.csv(input$csv_path, stringsAsFactors = FALSE, check.names = FALSE)
      rv$csv_data    <- df
      rv$csv_columns <- names(df)
      showNotification(paste0("CSV loaded: ", nrow(df), " rows, ", ncol(df), " columns."),
                       type = "message", duration = 5)
    }, error = function(e) {
      showNotification(paste("Error reading CSV:", e$message), type = "error")
    })
  })

  output$csv_status_ui <- renderUI({
    df <- rv$csv_data
    if (is.null(df)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"), " No CSV loaded yet. Browse for your file and click 'Load CSV'.")
      ))
    }
    div(class = "success-box",
      p(icon("check-circle"), tags$b(" CSV loaded successfully!")),
      p("Rows: ", tags$b(nrow(df)), " | Columns: ", tags$b(ncol(df))),
      p("Column names: ", tags$code(paste(names(df), collapse = ", ")))
    )
  })

  output$csv_preview_table <- renderDT({
    df <- rv$csv_data
    if (is.null(df)) return(NULL)
    datatable(head(df, 100),
              options = list(pageLength = 10, scrollX = TRUE, dom = "tip"),
              rownames = FALSE,
              caption = "First 100 rows of your CSV")
  })

  # Scan Photos
  observeEvent(input$scan_photos_btn, {
    req(input$photos_dir)
    if (!dir.exists(input$photos_dir)) {
      showNotification("Photos directory not found! Check the path.", type = "error")
      return()
    }
    files <- list.files(input$photos_dir, pattern = "\\.jpg$",
                        ignore.case = TRUE, recursive = FALSE)
    if (length(files) == 0) {
      showNotification("No .jpg files found in that folder!", type = "warning")
      rv$photo_files <- NULL
      return()
    }
    rv$photo_files <- data.frame(
      filename = files,
      size_KB  = round(file.size(file.path(input$photos_dir, files)) / 1024, 1),
      stringsAsFactors = FALSE
    )
    showNotification(paste("Found", length(files), "photos."), type = "message", duration = 5)
  })

  output$photo_status_ui <- renderUI({
    pf <- rv$photo_files
    if (is.null(pf)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"), " No photos scanned yet. Set the folder path and click 'Scan Photos'.")
      ))
    }
    div(class = "success-box",
      p(icon("check-circle"), tags$b(" Photos found!")),
      p("Total .jpg files: ", tags$b(nrow(pf))),
      p("Total size: ", tags$b(round(sum(pf$size_KB, na.rm = TRUE) / 1024, 1), " MB"))
    )
  })

  output$photo_list_table <- renderDT({
    pf <- rv$photo_files
    if (is.null(pf)) return(NULL)
    datatable(pf,
              options = list(pageLength = 10, scrollX = TRUE, dom = "tip"),
              rownames = FALSE)
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 2 — Check EXIF (handlers)
  # ════════════════════════════════════════════════════════════════════════

  observeEvent(input$check_exif_btn, {
    if (is.null(rv$photo_files) || nrow(rv$photo_files) == 0) {
      showNotification("Please load your photos first (Step 1).", type = "warning")
      return()
    }

    jpg_full <- file.path(input$photos_dir, rv$photo_files$filename)

    withProgress(message = "Reading EXIF data from photos...", value = 0.1, {
      tryCatch({
        exif_df <- read_exif_r(jpg_full)

        # Ensure columns exist
        for (col in c("GPSLatitude", "GPSLatitudeRef", "GPSLongitude",
                       "GPSLongitudeRef", "DateTimeOriginal")) {
          if (!(col %in% names(exif_df))) exif_df[[col]] <- NA
        }

        exif_df$lat_signed <- signed_coord(exif_df$GPSLatitude,  exif_df$GPSLatitudeRef)
        exif_df$lon_signed <- signed_coord(exif_df$GPSLongitude, exif_df$GPSLongitudeRef)

        # NOTE: EXIF DateTimeOriginal has NO timezone embedded — it is always
        # camera-local time.  Timestamps will be re-parsed with the user-chosen
        # photo timezone when matching runs (Step 3), so we just store the raw
        # data here.
        rv$exif_data <- exif_df
        n_gps <- sum(!is.na(exif_df$lat_signed) & !is.na(exif_df$lon_signed))

        if (n_gps > 0) {
          rv$exif_has_gps <- TRUE
          rv$match_method <- "exif"
          showNotification(
            paste0("EXIF GPS found in ", n_gps, " of ", nrow(exif_df), " photos! ",
                   "Using distance + time matching."),
            type = "message", duration = 8)
        } else {
          rv$exif_has_gps <- FALSE
          rv$match_method <- "filename"
          showNotification(
            "No GPS data found in EXIF. Using filename-based matching.",
            type = "warning", duration = 8)
        }

      }, error = function(e) {
        rv$exif_has_gps <- FALSE
        rv$match_method <- "filename"
        showNotification(
          paste("EXIF read failed:", e$message,
                "\nFalling back to filename matching."),
          type = "warning", duration = 10)
      })
    })
  })

  output$exif_result_ui <- renderUI({
    if (is.null(rv$exif_has_gps)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"),
          " Not checked yet. Click the button above to scan your photos for EXIF data.")
      ))
    }

    exif_df <- rv$exif_data
    if (isTRUE(rv$exif_has_gps)) {
      n_gps <- sum(!is.na(exif_df$lat_signed) & !is.na(exif_df$lon_signed))
      n_ts  <- sum(!is.na(exif_df$timestamp))
      div(class = "success-box",
        h4(icon("check-circle"), " GPS Data Detected!"),
        p(tags$b(n_gps), " out of ", tags$b(nrow(exif_df)),
          " photos have GPS coordinates."),
        p(tags$b(n_ts), " photos have timestamps."),
        p("The app will use ", tags$b("distance + time matching"),
          " for the best accuracy."),
        p("Proceed to ", tags$b("Step 3: Match Photos"), " to configure thresholds
           and run matching.")
      )
    } else {
      div(class = "warning-box",
        h4(icon("exclamation-triangle"), " No GPS Data Found"),
        p("Your photos do not contain GPS metadata in their EXIF."),
        p("The app will use ", tags$b("filename-based matching"), " instead."),
        p("Your photo filenames must follow this pattern:"),
        tags$code("{POINT_ID}_{YYYYMMDD}_{HHMMSS}_Photo {N}.jpg"),
        tags$br(), tags$br(),
        p("Example: ", tags$code("42_20251119_062201_Photo 3.jpg"),
          " — the leading number (42) is matched against the POINT_ID column."),
        p("Proceed to ", tags$b("Step 3: Match Photos"), " to select the POINT_ID
           column and run matching.")
      )
    }
  })

  output$exif_detail_table <- renderDT({
    exif_df <- rv$exif_data
    if (is.null(exif_df)) return(NULL)

    display <- exif_df[, intersect(
      c("FileName", "DateTimeOriginal", "lat_signed", "lon_signed"),
      names(exif_df)), drop = FALSE]

    dt <- datatable(display,
              options = list(pageLength = 20, scrollX = TRUE, dom = "frtip"),
              rownames = FALSE)
    if ("lat_signed" %in% names(display)) {
      dt <- dt %>%
        formatRound(c("lat_signed", "lon_signed"), digits = 6) %>%
        formatStyle("lat_signed",
                    backgroundColor = styleEqual(NA, "#fff3cd"))
    }
    dt
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 3 — Match Photos (handlers)
  # ════════════════════════════════════════════════════════════════════════

  # Dynamic instructions
  output$match_instructions_ui <- renderUI({
    method <- rv$match_method
    if (is.null(method)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"),
          " Please complete Steps 1 and 2 first. Load your data and check for EXIF.")
      ))
    }

    if (method == "exif") {
      div(class = "step-instructions",
        tags$h4(icon("info-circle"), " EXIF Distance + Time Matching"),
        tags$p("Your photos have GPS data! The app will match each CSV row to the
                nearest photo(s) based on:"),
        tags$ul(
          tags$li(tags$b("Distance threshold"), " — how close (in metres) a photo's GPS
                   must be to a CSV point to be considered a match."),
          tags$li(tags$b("Time threshold"), " — how close in time (in seconds) the photo
                   timestamp must be to the CSV datetime. Set to 0 to ignore time.")
        ),
        tags$p("For each CSV row, all photos within ", tags$em("both"),
               " thresholds will be linked. Results are sorted nearest-first."),
        tags$p("After matching, check the ", tags$b("Review Map"), " tab to visually verify
                that CSV points and photo locations line up correctly.")
      )
    } else {
      div(class = "step-instructions",
        tags$h4(icon("info-circle"), " Filename-Based Matching"),
        tags$p("Photos have no GPS. Matching will use the leading number in the
                filename as a POINT_ID."),
        tags$p("Expected filename format: ",
               tags$code("{POINT_ID}_{YYYYMMDD}_{HHMMSS}_Photo {N}.jpg")),
        tags$p("Select which column in your CSV contains the POINT_ID, then click
                'Run Matching'.")
      )
    }
  })

  # Pick a default column from column names
  pick_col <- function(cols, patterns, fallback = 1) {
    for (p in patterns) {
      m <- grep(p, cols, ignore.case = TRUE, value = TRUE)
      if (length(m) > 0) return(m[1])
    }
    cols[min(fallback, length(cols))]
  }

  # Dynamic settings panel
  output$match_settings_ui <- renderUI({
    method <- rv$match_method
    cols   <- rv$csv_columns

    if (is.null(method)) {
      return(p("Complete previous steps first."))
    }

    if (method == "exif") {
      tagList(
        h4("Distance + Time Thresholds"),
        numericInput("dist_threshold", "Distance threshold (metres):",
                     value = 50, min = 1, max = 50000, step = 1),
        helpText("Photos within this radius of a CSV point are eligible for matching."),
        hr(),
        numericInput("time_threshold", "Time threshold (seconds):",
                     value = 180, min = 0, max = 86400, step = 10),
        helpText("Photos within this many seconds of the CSV timestamp are eligible.
                  Set to 0 to match by distance only (ignore time)."),
        hr(),
        h4(icon("clock"), " Timezone Settings"),
        p(tags$em("EXIF ", tags$code("DateTimeOriginal"), " stores camera-local time
          with no timezone info. You must set both timezones manually so the
          time difference is calculated correctly.")),
        selectInput("photo_tz", "Photo / camera timezone:",
                    choices = c("UTC", "Asia/Kolkata", "US/Eastern", "US/Central",
                                "US/Pacific", "Europe/London", "Europe/Paris",
                                "Australia/Sydney", "Pacific/Auckland",
                                OlsonNames()),
                    selected = "UTC"),
        helpText("The timezone the camera clock was set to when the photos were taken."),
        uiOutput("photo_tz_sample_ui"),
        selectInput("csv_tz", "CSV datetime timezone:",
                    choices = c("UTC", "Asia/Kolkata", "US/Eastern", "US/Central",
                                "US/Pacific", "Europe/London", "Europe/Paris",
                                "Australia/Sydney", "Pacific/Auckland",
                                OlsonNames()),
                    selected = "UTC"),
        helpText("The timezone used by the date/time column in your CSV file."),
        uiOutput("csv_tz_sample_ui"),
        hr(),
        h4("CSV Column Mapping"),
        if (!is.null(cols)) {
          tagList(
            selectInput("lat_col", "Latitude column:", choices = cols,
                        selected = pick_col(cols, c("^lat(itude)?$", "^y$"))),
            selectInput("lon_col", "Longitude column:", choices = cols,
                        selected = pick_col(cols, c("^lon(gitude)?$", "^lng$", "^x$"))),
            selectInput("datetime_col", "Date/time column (for time matching):",
                        choices = c("(none - ignore time)" = "", cols),
                        selected = pick_col(cols, c("^DATETIME$", "date.*time", "^time")))
          )
        } else {
          p(tags$em("Load CSV first to see column names."))
        },
        hr(),
        h4("Fallback Matching"),
        checkboxInput("use_time_fallback_bad_gps",
                      "Time-only fallback for photos with bad/missing GPS",
                      value = FALSE),
        helpText("If a photo's GPS puts it more than the distance below from every CSV point,",
                 " its GPS is treated as unreliable and it is matched by timestamp alone.",
                 " Requires a datetime column and time threshold to be set above."),
        numericInput("bad_gps_km",
                     "Treat GPS as bad if nearest point is further than (km):",
                     value = 100, min = 1, max = 50000, step = 10),
        hr(),
        checkboxInput("use_filename_fallback",
                      "Filename POINT_ID fallback (last resort)",
                      value = FALSE),
        helpText("Only tick this if filenames start with the POINT_ID number ",
                 "(e.g. ", tags$code("42_20251119_062201_Photo 1.jpg"), "). ",
                 "Photos that still have no match after GPS and time fallback will be ",
                 "matched by that leading number.")
      )
    } else {
      tagList(
        h4("Filename Settings"),
        if (!is.null(cols)) {
          selectInput("point_id_col", "POINT_ID column:", choices = cols,
                      selected = pick_col(cols, c("^POINT_ID$", "point.*id", "pid")))
        } else {
          textInput("point_id_col", "POINT_ID column:", value = "POINT_ID")
        },
        hr(),
        div(class = "warning-box",
          tags$b(icon("clock"), " Timezone note"),
          tags$p("Filename matching uses only the leading POINT_ID number — the
            timestamp embedded in the filename (e.g. ",
            tags$code("062201"), " in ",
            tags$code("42_20251119_062201_Photo 3.jpg"),
            ") is NOT used for matching, so no timezone setting is needed."),
          tags$p("If time-based matching from filenames is added in the future,
            the camera timezone would need to be set manually here, as filename
            timestamps are always camera-local time with no timezone embedded.")
        )
      )
    }
  })

  # ── Timezone sample previews ─────────────────────────────────────────────

  # Show a raw EXIF DateTimeOriginal sample so the user can see what the
  # camera recorded and verify they are picking the right photo timezone.
  output$photo_tz_sample_ui <- renderUI({
    exif_df <- rv$exif_data
    if (is.null(exif_df)) return(NULL)
    samples <- exif_df$DateTimeOriginal[!is.na(exif_df$DateTimeOriginal) &
                                         nchar(as.character(exif_df$DateTimeOriginal)) > 0]
    if (length(samples) == 0) return(NULL)
    div(style = "background:#f0f4f8; border:1px solid #cdd8e3; border-radius:4px;
                 padding:8px 12px; margin:4px 0 10px 0; font-size:0.9em;",
      tags$b(icon("camera"), " Sample from your photos:"),
      tags$br(),
      tags$code(samples[1]),
      tags$br(),
      tags$span(style = "color:#555;",
        "EXIF format is ", tags$code("YYYY:MM:DD HH:MM:SS"), " — always camera-local
         time with no timezone. Choose the timezone the camera clock was set to.")
    )
  })

  # Show sample values from the selected CSV datetime column so the user can
  # see the actual values they need to assign a timezone to.
  output$csv_tz_sample_ui <- renderUI({
    df  <- rv$csv_data
    col <- input$datetime_col
    if (is.null(df) || is.null(col) || nchar(trimws(col)) == 0 ||
        !(col %in% names(df))) return(NULL)
    vals    <- as.character(df[[col]])
    samples <- vals[!is.na(vals) & nchar(vals) > 0]
    if (length(samples) == 0) return(NULL)
    show <- head(unique(samples), 3)
    div(style = "background:#f0f4f8; border:1px solid #cdd8e3; border-radius:4px;
                 padding:8px 12px; margin:4px 0 10px 0; font-size:0.9em;",
      tags$b(icon("file-csv"), " Sample values from \'" , col, "\' column:"),
      tags$br(),
      tags$code(paste(show, collapse = "  |  ")),
      tags$br(),
      tags$span(style = "color:#555;",
        "These are the values that will be parsed. Choose the timezone they
         were recorded in.")
    )
  })

  # Readiness check
  output$match_ready_ui <- renderUI({
    issues <- character(0)
    if (is.null(rv$csv_data))     issues <- c(issues, "CSV not loaded.")
    if (is.null(rv$photo_files))  issues <- c(issues, "Photos not scanned.")
    if (is.null(rv$match_method)) issues <- c(issues, "EXIF check not done.")

    if (length(issues) > 0) {
      div(class = "error-box",
        h4(icon("times-circle"), " Not ready to match:"),
        tags$ul(lapply(issues, tags$li))
      )
    } else {
      div(class = "success-box",
        p(icon("check-circle"), " Everything is loaded. Ready to match!"),
        p("Method: ", tags$b(
          if (rv$match_method == "exif") "EXIF Distance + Time" else "Filename (POINT_ID)"))
      )
    }
  })

  # ── Run Matching ─────────────────────────────────────────────────────────
  observeEvent(input$run_match_btn, {
    req(rv$csv_data, rv$photo_files, rv$match_method)

    separator <- if (is.null(input$separator) || nchar(trimws(input$separator)) == 0) ";" else input$separator
    df        <- rv$csv_data
    jpg_files <- rv$photo_files$filename

    withProgress(message = "Matching photos...", value = 0.1, {
      tryCatch({
        if (rv$match_method == "exif") {
          result <- match_by_exif_fn(df, jpg_files, separator)
        } else {
          result <- match_by_filename_fn(df, jpg_files, separator)
        }

        if (!is.null(result)) {
          rv$results              <- result$df
          rv$last_method          <- rv$match_method
          rv$unmatched_photos     <- result$unmatched
          rv$skipped_photos       <- result$skipped
          rv$unmatched_diagnostic <- result$diag

          matched_count <- sum(result$df$GRAB_FILENAME != "", na.rm = TRUE)
          showNotification(
            paste0("Matching complete! ", matched_count, " of ", nrow(df),
                   " rows matched."),
            type = "message", duration = 5)
        }
      }, error = function(e) {
        showNotification(paste("Error during matching:", e$message),
                         type = "error", duration = 12)
      })
    })
  })

  # ── Filename matching function ──────────────────────────────────────────
  match_by_filename_fn <- function(df, jpg_files, separator) {
    req(input$point_id_col)

    if (!(input$point_id_col %in% names(df))) {
      showNotification(paste("Column", input$point_id_col, "not found in CSV!"),
                       type = "error")
      return(NULL)
    }

    photo_pattern <- "^(\\d+)_\\d{8}_\\d{6}_Photo \\d+\\.jpg$"
    lookup  <- list()
    skipped <- character(0)

    for (fname in jpg_files) {
      if (grepl(photo_pattern, fname, ignore.case = TRUE, perl = TRUE)) {
        pid <- sub("^(\\d+)_.*$", "\\1", fname, perl = TRUE)
        lookup[[pid]] <- sort(c(lookup[[pid]], fname))
      } else {
        skipped <- c(skipped, fname)
      }
    }

    matched_pids     <- character(0)
    df$GRAB_FILENAME <- ""

    for (i in seq_len(nrow(df))) {
      pid_norm <- as.character(suppressWarnings(as.integer(
        as.character(df[[input$point_id_col]][i]))))
      photos <- lookup[[pid_norm]]
      if (!is.null(photos) && length(photos) > 0) {
        df$GRAB_FILENAME[i] <- paste(photos, collapse = separator)
        matched_pids <- c(matched_pids, pid_norm)
      }
    }

    unmatched_pids <- setdiff(names(lookup), matched_pids)
    unmatched <- if (length(unmatched_pids) > 0) {
      do.call(rbind, lapply(unmatched_pids, function(pid) {
        data.frame(POINT_ID = pid,
                   filenames = paste(lookup[[pid]], collapse = separator),
                   stringsAsFactors = FALSE)
      }))
    } else NULL

    skipped_df <- if (length(skipped) > 0) {
      data.frame(filename = skipped, reason = "Filename pattern not recognised",
                 stringsAsFactors = FALSE)
    } else NULL

    list(df = df, unmatched = unmatched, skipped = skipped_df)
  }

  # ── EXIF matching function ──────────────────────────────────────────────
  match_by_exif_fn <- function(df, jpg_files, separator) {
    req(input$lat_col, input$lon_col)
    exif_df <- rv$exif_data
    if (is.null(exif_df)) {
      showNotification("No EXIF data - run EXIF check first.", type = "error")
      return(NULL)
    }

    if (!(input$lat_col %in% names(df))) {
      showNotification(paste("Latitude column", input$lat_col, "not found!"), type = "error")
      return(NULL)
    }
    if (!(input$lon_col %in% names(df))) {
      showNotification(paste("Longitude column", input$lon_col, "not found!"), type = "error")
      return(NULL)
    }

    dist_threshold <- input$dist_threshold
    time_threshold <- input$time_threshold

    has_gps      <- !is.na(exif_df$lat_signed) & !is.na(exif_df$lon_signed)
    photos_gps   <- exif_df[has_gps, ]
    photos_nogps <- exif_df[!has_gps, ]

    csv_lat <- suppressWarnings(as.numeric(df[[input$lat_col]]))
    csv_lon <- suppressWarnings(as.numeric(df[[input$lon_col]]))

    # Parse CSV timestamps if time matching enabled
    csv_time <- NULL
    use_time <- !is.null(input$datetime_col) && nchar(input$datetime_col) > 0 &&
                time_threshold > 0
    photo_tz_val <- if (!is.null(input$photo_tz) && nchar(input$photo_tz) > 0)
      input$photo_tz else "UTC"
    csv_tz_val   <- if (!is.null(input$csv_tz)   && nchar(input$csv_tz)   > 0)
      input$csv_tz   else "UTC"

    # Re-parse EXIF timestamps now that we know the correct camera timezone.
    # EXIF DateTimeOriginal has no timezone embedded, so this must be done here
    # rather than at EXIF-check time (when the user may not have set photo_tz yet).
    photos_gps$timestamp <- as.POSIXct(photos_gps$DateTimeOriginal,
                                        format = "%Y:%m:%d %H:%M:%S",
                                        tz = photo_tz_val)

    if (use_time && input$datetime_col %in% names(df)) {
      csv_time <- tryCatch(
        lubridate::parse_date_time(df[[input$datetime_col]],
                                   orders = c("dmy HM", "dmy HMS", "ymd HMS",
                                              "ymd HM", "dmY HM", "dmY HMS"),
                                   tz = csv_tz_val),
        error = function(e) NULL
      )
    }

    df$GRAB_FILENAME     <- ""
    df$GRAB_DISTANCE_M   <- ""
    df$GRAB_MATCH_METHOD <- ""
    if (use_time) df$GRAB_TIME_DIFF_S <- ""

    matched_photo_idx <- integer(0)

    withProgress(message = "Matching by distance + time...", value = 0.3, {
      for (i in seq_len(nrow(df))) {
        if (is.na(csv_lat[i]) || is.na(csv_lon[i])) next
        if (nrow(photos_gps) == 0) next

        dists <- haversine_m(csv_lat[i], csv_lon[i],
                             photos_gps$lat_signed, photos_gps$lon_signed)
        within_dist <- dists <= dist_threshold

        # Time filter (if enabled)
        if (use_time && !is.null(csv_time) && !is.na(csv_time[i])) {
          photo_times <- photos_gps$timestamp
          time_diffs  <- abs(as.numeric(difftime(csv_time[i], photo_times, units = "secs")))
          within_time <- time_diffs <= time_threshold
          within <- which(within_dist & within_time)
        } else {
          within <- which(within_dist)
          time_diffs <- rep(NA, nrow(photos_gps))
        }

        if (length(within) > 0) {
          ord <- within[order(dists[within])]
          df$GRAB_FILENAME[i]     <- paste(photos_gps$FileName[ord], collapse = separator)
          df$GRAB_DISTANCE_M[i]   <- paste(round(dists[ord], 1),     collapse = separator)
          df$GRAB_MATCH_METHOD[i] <- "GPS"
          if (use_time) {
            df$GRAB_TIME_DIFF_S[i] <- paste(round(time_diffs[ord], 0), collapse = separator)
          }
          matched_photo_idx <- union(matched_photo_idx, ord)
        }
      }
    })

    # Unmatched: GPS photos outside threshold of every CSV row
    unmatched_idx <- setdiff(seq_len(nrow(photos_gps)), matched_photo_idx)

    # ── Time-only fallback for photos with suspicious GPS ──────────────────
    # If a photo's nearest CSV point is beyond bad_gps_km, its GPS coordinates
    # are treated as unreliable. We then try to match it by timestamp alone
    # using the existing time threshold.
    bad_gps_m      <- (if (!is.null(input$bad_gps_km)) input$bad_gps_km else 100) * 1000
    use_time_fallback <- isTRUE(input$use_time_fallback_bad_gps) &&
                         use_time && !is.null(csv_time)
    valid_csv <- !is.na(csv_lat) & !is.na(csv_lon)

    time_fallback_count <- 0L
    after_time_unmatched_idx <- integer(0)

    for (j in unmatched_idx) {
      # Check if this photo's GPS is suspect: min distance to any CSV row > bad_gps_m
      p_lat <- photos_gps$lat_signed[j]
      p_lon <- photos_gps$lon_signed[j]
      min_dist <- if (any(valid_csv)) {
        min(haversine_m(p_lat, p_lon, csv_lat[valid_csv], csv_lon[valid_csv]))
      } else Inf

      if (!use_time_fallback || min_dist <= bad_gps_m) {
        after_time_unmatched_idx <- c(after_time_unmatched_idx, j)
        next
      }

      # GPS is bad — try time-only match
      photo_ts <- photos_gps$timestamp[j]
      if (is.na(photo_ts)) {
        after_time_unmatched_idx <- c(after_time_unmatched_idx, j)
        next
      }

      td <- abs(as.numeric(difftime(photo_ts, csv_time, units = "secs")))
      td[is.na(td)] <- Inf
      within_time_only <- which(td <= time_threshold)

      if (length(within_time_only) > 0) {
        ord <- within_time_only[order(td[within_time_only])]
        for (row_i in ord) {
          existing <- df$GRAB_FILENAME[row_i]
          if (nchar(existing) == 0) {
            df$GRAB_FILENAME[row_i]     <- photos_gps$FileName[j]
            df$GRAB_DISTANCE_M[row_i]   <- round(haversine_m(
              csv_lat[row_i], csv_lon[row_i], p_lat, p_lon), 1)
            df$GRAB_TIME_DIFF_S[row_i]  <- round(td[row_i], 0)
            df$GRAB_MATCH_METHOD[row_i] <- "time_only (bad GPS)"
          } else {
            df$GRAB_FILENAME[row_i]     <- paste(existing, photos_gps$FileName[j],
                                                  sep = separator)
            df$GRAB_DISTANCE_M[row_i]   <- paste(df$GRAB_DISTANCE_M[row_i],
              round(haversine_m(csv_lat[row_i], csv_lon[row_i], p_lat, p_lon), 1),
              sep = separator)
            df$GRAB_TIME_DIFF_S[row_i]  <- paste(df$GRAB_TIME_DIFF_S[row_i],
                                                   round(td[row_i], 0), sep = separator)
            df$GRAB_MATCH_METHOD[row_i] <- paste0(df$GRAB_MATCH_METHOD[row_i],
                                                   "+time_only")
          }
        }
        matched_photo_idx     <- union(matched_photo_idx, j)
        time_fallback_count   <- time_fallback_count + 1L
      } else {
        after_time_unmatched_idx <- c(after_time_unmatched_idx, j)
      }
    }

    if (time_fallback_count > 0) {
      showNotification(
        paste0(time_fallback_count, " photo(s) matched by time only ",
               "(GPS was > ", input$bad_gps_km, " km from any CSV point)."),
        type = "warning", duration = 10)
    }

    # ── Filename POINT_ID fallback (opt-in, last resort) ──────────────────
    pid_col <- if (!is.null(input$point_id_col) && input$point_id_col %in% names(df)) {
      input$point_id_col
    } else if ("POINT_ID" %in% names(df)) {
      "POINT_ID"
    } else NULL

    fn_pattern <- "^(\\d+)_\\d{8}_\\d{6}_Photo \\d+\\.jpg$"
    still_unmatched_idx <- integer(0)
    fallback_count <- 0L

    use_fallback <- isTRUE(input$use_filename_fallback)

    if (use_fallback && !is.null(pid_col)) {
      # Build POINT_ID → CSV row index lookup
      pid_to_row <- setNames(
        seq_len(nrow(df)),
        as.character(suppressWarnings(as.integer(as.character(df[[pid_col]]))))
      )

      for (j in after_time_unmatched_idx) {
        fname <- photos_gps$FileName[j]
        if (!grepl(fn_pattern, fname, ignore.case = TRUE, perl = TRUE)) {
          still_unmatched_idx <- c(still_unmatched_idx, j)
          next
        }
        pid_str <- sub("^(\\d+)_.*$", "\\1", fname, perl = TRUE)
        row_i   <- pid_to_row[pid_str]
        if (is.na(row_i)) {
          still_unmatched_idx <- c(still_unmatched_idx, j)
          next
        }
        # Append to any GPS matches already on this row (rare but possible)
        existing <- df$GRAB_FILENAME[row_i]
        if (nchar(existing) == 0) {
          df$GRAB_FILENAME[row_i]     <- fname
          df$GRAB_MATCH_METHOD[row_i] <- "filename_fallback"
        } else {
          df$GRAB_FILENAME[row_i]     <- paste(existing, fname, sep = separator)
          df$GRAB_MATCH_METHOD[row_i] <- paste0(df$GRAB_MATCH_METHOD[row_i],
                                                "+filename_fallback")
        }
        matched_photo_idx <- union(matched_photo_idx, j)
        fallback_count    <- fallback_count + 1L
      }
    } else {
      # Fallback disabled or no POINT_ID column — all remaining photos stay unmatched
      still_unmatched_idx <- after_time_unmatched_idx
    }

    if (fallback_count > 0) {
      showNotification(
        paste0(fallback_count, " photo(s) matched via filename POINT_ID fallback ",
               "(EXIF GPS was too far from any CSV point)."),
        type = "warning", duration = 10)
    }

    # Rebuild unmatched using only photos that failed BOTH methods
    final_unmatched_idx <- setdiff(seq_len(nrow(photos_gps)), matched_photo_idx)
    unmatched <- if (length(final_unmatched_idx) > 0) {
      data.frame(
        filename = photos_gps$FileName[final_unmatched_idx],
        GPS_lat  = round(photos_gps$lat_signed[final_unmatched_idx], 6),
        GPS_lon  = round(photos_gps$lon_signed[final_unmatched_idx], 6),
        stringsAsFactors = FALSE
      )
    } else NULL

    # Diagnostic: for each GPS-unmatched photo (before fallback) find nearest
    # CSV point so user knows by how much thresholds were exceeded, and flag
    # photos where GPS looks completely wrong (> 100 km from everything).

    diag_rows <- lapply(final_unmatched_idx, function(j) {
      p_lat <- photos_gps$lat_signed[j]
      p_lon <- photos_gps$lon_signed[j]

      if (!any(valid_csv)) {
        return(data.frame(
          Photo = photos_gps$FileName[j],
          Photo_Time = as.character(photos_gps$DateTimeOriginal[j]),
          Nearest_Point = NA_character_,
          Nearest_Dist_m = NA_real_,
          Nearest_TimeDiff_s = NA_real_,
          Why_unmatched = "No valid CSV coordinates",
          stringsAsFactors = FALSE
        ))
      }

      d <- haversine_m(p_lat, p_lon, csv_lat, csv_lon)
      d[!valid_csv] <- Inf
      ni      <- which.min(d)
      nd      <- round(d[ni], 1)
      pt_lbl  <- if (!is.null(pid_col)) as.character(df[[pid_col]][ni]) else as.character(ni)

      # Nearest time diff (independently of nearest distance)
      nt   <- NA_real_
      nt_lbl <- NA_character_
      if (use_time && !is.null(csv_time) && !is.na(photos_gps$timestamp[j])) {
        td <- abs(as.numeric(difftime(photos_gps$timestamp[j], csv_time, units = "secs")))
        td[is.na(td)] <- Inf
        ti   <- which.min(td)
        nt   <- round(td[ti], 0)
        nt_lbl <- if (!is.null(pid_col)) as.character(df[[pid_col]][ti]) else as.character(ti)
      }

      dist_ok <- nd <= dist_threshold
      time_ok <- if (use_time && !is.na(nt)) nt <= time_threshold else TRUE

      # Flag photos where GPS is clearly wrong (> 100 km away from everything)
      gps_suspect <- nd > 100000

      why <- dplyr::case_when(
        gps_suspect              ~ paste0("GPS likely wrong (", round(nd/1000, 0),
                                          " km from nearest point) — matched by filename instead"),
        !dist_ok & !time_ok      ~ paste0("Dist ", nd, "m > ", dist_threshold,
                                           "m  &  Time ", nt, "s > ", time_threshold, "s"),
        !dist_ok                 ~ paste0("Dist ", nd, "m > ", dist_threshold, "m threshold"),
        !time_ok                 ~ paste0("Time ", nt, "s > ", time_threshold, "s threshold"),
        TRUE                     ~ "Unknown"
      )

      data.frame(
        Photo              = photos_gps$FileName[j],
        Photo_Time         = as.character(photos_gps$DateTimeOriginal[j]),
        Nearest_Point      = pt_lbl,
        Nearest_Dist_m     = nd,
        Nearest_TimeDiff_s = nt,
        GPS_suspect        = nd > 100000,
        Why_unmatched      = why,
        stringsAsFactors   = FALSE
      )
    })
    diag_df <- if (length(diag_rows) > 0) do.call(rbind, diag_rows) else NULL

    skipped <- if (nrow(photos_nogps) > 0) {
      data.frame(filename = photos_nogps$FileName,
                 reason = "No GPS in EXIF",
                 stringsAsFactors = FALSE)
    } else NULL

    # Remove empty helper column if time was not used
    if (!use_time && "GRAB_TIME_DIFF_S" %in% names(df)) {
      df$GRAB_TIME_DIFF_S <- NULL
    }

    list(df = df, unmatched = unmatched, skipped = skipped, diag = diag_df)
  }

  # Match summary
  output$match_summary_ui <- renderUI({
    df <- rv$results
    if (is.null(df)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"),
          " No results yet. Configure your settings and click 'Run Matching'.")
      ))
    }
    matched <- sum(df$GRAB_FILENAME != "", na.rm = TRUE)
    total   <- nrow(df)
    up_n    <- if (!is.null(rv$unmatched_photos)) nrow(rv$unmatched_photos) else 0
    sp_n    <- if (!is.null(rv$skipped_photos))   nrow(rv$skipped_photos) else 0

    all_photos_matched <- up_n == 0 && sp_n == 0

    cls <- if (matched > 0) "success-box" else "error-box"
    div(class = cls,
      h4(icon("check-circle"), " Matching Complete"),
      tags$ul(
        tags$li("Method: ", tags$b(
          if (rv$last_method == "exif") "EXIF Distance + Time" else "Filename (POINT_ID)")),
        tags$li("CSV rows: ", tags$b(total)),
        tags$li("Rows matched: ", tags$b(matched)),
        tags$li("Rows without match: ", tags$b(total - matched)),
        if (all_photos_matched)
          tags$li(style = "color: #2e7d32; font-weight: bold;",
                  icon("check-circle"), " All photos were matched to a CSV row!")
        else {
          tagList(
            if (up_n > 0) tags$li("Photos not matched to any row: ", tags$b(up_n),
                                  " — see diagnostics below"),
            if (sp_n > 0) tags$li("Photos skipped (no GPS): ", tags$b(sp_n))
          )
        }
      ),
      p("Check the ", tags$b("Review Map"), " tab to visualise the matches, then go to ",
        tags$b("Results & Export"), " to save.")
    )
  })

  # ── Unmatched diagnostic table ───────────────────────────────────────────
  output$match_diag_box_ui <- renderUI({
    diag <- rv$unmatched_diagnostic

    # Not run yet
    if (is.null(diag)) {
      return(box(
        title = "Unmatched Photos — Diagnostics", status = "primary",
        solidHeader = TRUE, width = 12, collapsible = TRUE, collapsed = TRUE,
        p(tags$em("Run matching first to see diagnostics."))
      ))
    }

    # All photos matched
    if (nrow(diag) == 0) {
      return(box(
        title = tagList(icon("check-circle"), " All Photos Matched!"),
        status = "success", solidHeader = TRUE, width = 12,
        collapsible = TRUE, collapsed = FALSE,
        div(class = "success-box",
          p(icon("check-circle"), tags$b(" Every photo was successfully matched to a CSV row."))
        )
      ))
    }

    # Some unmatched
    dist_thr <- if (!is.null(input$dist_threshold)) input$dist_threshold else NA
    box(
      title = tagList(icon("exclamation-triangle"),
                      paste0(" ", nrow(diag), " Photo(s) Not Matched — Nearest CSV Point")),
      status = "warning", solidHeader = TRUE, width = 12,
      collapsible = TRUE, collapsed = FALSE,
      div(class = "warning-box",
        p("The table shows the closest CSV point for each unmatched photo.",
          " Use these distances/times to decide whether to increase your thresholds."),
        if (!is.na(dist_thr))
          p(tags$b("Current distance threshold: "), tags$code(paste0(dist_thr, " m")),
            " — orange rows are within 3× this value, purple rows have suspect GPS.")
      ),
      DTOutput("match_diag_table")
    )
  })

  output$match_diag_header_ui <- renderUI({
    diag <- rv$unmatched_diagnostic
    if (is.null(diag)) {
      return(p(tags$em("Run matching first to see diagnostics.")))
    }
    if (nrow(diag) == 0) {
      return(div(class = "success-box",
        p(icon("check-circle"), " All photos were matched — nothing unmatched!")))
    }
    dist_thr <- if (!is.null(input$dist_threshold)) input$dist_threshold else NA
    time_thr <- if (!is.null(input$time_threshold)) input$time_threshold else NA
    div(class = "warning-box",
      p(icon("exclamation-triangle"),
        tags$b(nrow(diag)), " photo(s) could not be matched."),
      p("The table shows the closest CSV point for each unmatched photo.",
        " Use these distances/times to decide whether to increase your thresholds."),
      if (!is.na(dist_thr))
        p(tags$b("Current distance threshold: "), tags$code(paste0(dist_thr, " m")),
          " — orange rows are within 3× this value.")
    )
  })

  output$match_diag_table <- renderDT({
    diag <- rv$unmatched_diagnostic
    if (is.null(diag) || nrow(diag) == 0) return(NULL)

    dist_thr <- if (!is.null(input$dist_threshold)) input$dist_threshold else Inf

    # Drop time column if not used
    if (all(is.na(diag$Nearest_TimeDiff_s))) {
      diag$Nearest_TimeDiff_s <- NULL
    }
    # Drop internal GPS_suspect flag column from display
    gps_suspect_vec <- if ("GPS_suspect" %in% names(diag)) diag$GPS_suspect else rep(FALSE, nrow(diag))
    diag$GPS_suspect <- NULL

    dt <- datatable(
      diag,
      rownames  = FALSE,
      colnames  = c("Photo", "EXIF Time", "Nearest CSV Point",
                    "Distance (m)",
                    if ("Nearest_TimeDiff_s" %in% names(diag)) "Time Diff (s)" else NULL,
                    "Why not matched"),
      options   = list(
        pageLength = 25, scrollX = TRUE, dom = "frtip",
        order = list(list(3, "asc"))   # sort by distance ascending
      )
    )

    # Colour rows: purple = GPS looks wrong (> 100 km), red = close miss,
    # orange = within 3x threshold
    row_colours <- dplyr::case_when(
      gps_suspect_vec                        ~ "#ede7f6",   # purple tint
      diag$Nearest_Dist_m <= dist_thr * 3   ~ "#fff3e0",   # orange tint
      TRUE                                   ~ "white"
    )

    dt <- dt %>%
      formatRound("Nearest_Dist_m", digits = 1) %>%
      formatStyle(0, target = "row",
                  backgroundColor = styleEqual(seq_len(nrow(diag)), row_colours))
    dt
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 4 — Review Map
  # ════════════════════════════════════════════════════════════════════════

  output$review_map <- renderLeaflet({
    df <- rv$results
    if (is.null(df) || is.null(rv$last_method)) {
      return(
        leaflet() %>%
          addProviderTiles(providers$Esri.WorldImagery) %>%
          setView(lng = 0, lat = 0, zoom = 2) %>%
          addControl(
            html = "<div style='background:white; padding:10px; border-radius:5px;'>
                     Run matching first (Step 3) to see data on the map.</div>",
            position = "topright")
      )
    }

    # CSV points (if lat/lon columns are available)
    csv_lat <- csv_lon <- NULL
    if (!is.null(input$lat_col) && input$lat_col %in% names(df)) {
      csv_lat <- suppressWarnings(as.numeric(df[[input$lat_col]]))
    }
    if (!is.null(input$lon_col) && input$lon_col %in% names(df)) {
      csv_lon <- suppressWarnings(as.numeric(df[[input$lon_col]]))
    }

    # For filename method, try LATITUDE / LONGITUDE anyway
    if (is.null(csv_lat) || is.null(csv_lon)) {
      lat_guess <- grep("^lat(itude)?$", names(df), ignore.case = TRUE, value = TRUE)
      lon_guess <- grep("^lon(gitude)?$|^lng$", names(df), ignore.case = TRUE, value = TRUE)
      if (length(lat_guess) > 0 && length(lon_guess) > 0) {
        csv_lat <- suppressWarnings(as.numeric(df[[lat_guess[1]]]))
        csv_lon <- suppressWarnings(as.numeric(df[[lon_guess[1]]]))
      }
    }

    has_csv_coords <- !is.null(csv_lat) && !is.null(csv_lon) &&
                      any(!is.na(csv_lat) & !is.na(csv_lon))

    # Photo EXIF points
    exif_df  <- rv$exif_data
    has_exif <- !is.null(exif_df) && any(!is.na(exif_df$lat_signed))

    # Build map
    m <- leaflet(options = leafletOptions(maxZoom = 22)) %>%
      addProviderTiles(providers$Esri.WorldImagery,
                       options = providerTileOptions(maxZoom = 22)) %>%
      addProviderTiles(providers$CartoDB.PositronOnlyLabels,
                       options = providerTileOptions(maxZoom = 22)) %>%
      addScaleBar(position = "bottomleft")

    # Add CSV points (blue)
    if (has_csv_coords) {
      valid_csv <- !is.na(csv_lat) & !is.na(csv_lon)
      csv_labels <- if ("POINT_ID" %in% names(df)) {
        paste0("CSV #", df$POINT_ID[valid_csv])
      } else {
        paste0("CSV Row ", which(valid_csv))
      }
      matched_flag <- df$GRAB_FILENAME[valid_csv] != ""
      csv_popups <- paste0(
        "<b>", csv_labels, "</b><br>",
        "Lat: ", round(csv_lat[valid_csv], 6), "<br>",
        "Lon: ", round(csv_lon[valid_csv], 6), "<br>",
        "Matched: ", ifelse(matched_flag, "Yes", "<span style='color:red'>No</span>"), "<br>",
        ifelse(matched_flag, paste0("Photos: ", df$GRAB_FILENAME[valid_csv]), "")
      )

      m <- m %>%
        addCircleMarkers(
          lng = csv_lon[valid_csv], lat = csv_lat[valid_csv],
          radius = 7, color = "#2196F3", fillColor = "#2196F3",
          fillOpacity = 0.8, stroke = TRUE, weight = 2,
          popup = csv_popups,
          label = csv_labels,
          group = "CSV Points"
        )

      center_lat <- mean(csv_lat[valid_csv], na.rm = TRUE)
      center_lon <- mean(csv_lon[valid_csv], na.rm = TRUE)
      m <- m %>% setView(lng = center_lon, lat = center_lat, zoom = 14)
    }

    # Add photo EXIF points (red)
    if (has_exif) {
      valid_exif <- !is.na(exif_df$lat_signed) & !is.na(exif_df$lon_signed)
      if (any(valid_exif)) {
        photo_popups <- paste0(
          "<b>Photo: ", exif_df$FileName[valid_exif], "</b><br>",
          "Lat: ", round(exif_df$lat_signed[valid_exif], 6), "<br>",
          "Lon: ", round(exif_df$lon_signed[valid_exif], 6), "<br>",
          ifelse(!is.na(exif_df$DateTimeOriginal[valid_exif]),
                 paste0("Time: ", exif_df$DateTimeOriginal[valid_exif]),
                 "")
        )

        m <- m %>%
          addCircleMarkers(
            lng = exif_df$lon_signed[valid_exif],
            lat = exif_df$lat_signed[valid_exif],
            radius = 5, color = "#FF5722", fillColor = "#FF5722",
            fillOpacity = 0.7, stroke = TRUE, weight = 1,
            popup = photo_popups,
            label = exif_df$FileName[valid_exif],
            group = "Photo Locations (EXIF)"
          )

        # Draw match lines (green) between CSV rows and their matched photos
        if (has_csv_coords && rv$last_method == "exif") {
          separator <- if (is.null(input$separator) || nchar(trimws(input$separator)) == 0)
            ";" else input$separator

          for (i in which(valid_csv & df$GRAB_FILENAME != "")) {
            photo_names <- trimws(unlist(strsplit(df$GRAB_FILENAME[i], separator, fixed = TRUE)))
            for (pname in photo_names) {
              pidx <- which(exif_df$FileName == pname)
              if (length(pidx) == 1 && valid_exif[pidx]) {
                m <- m %>%
                  addPolylines(
                    lng = c(csv_lon[i], exif_df$lon_signed[pidx]),
                    lat = c(csv_lat[i], exif_df$lat_signed[pidx]),
                    color = "#4CAF50", weight = 2, opacity = 0.6,
                    group = "Match Lines"
                  )
              }
            }
          }
        }
      }
    }

    # Layer controls
    groups <- "CSV Points"
    if (has_exif) groups <- c(groups, "Photo Locations (EXIF)", "Match Lines")
    m <- m %>%
      addLayersControl(
        overlayGroups = groups,
        options = layersControlOptions(collapsed = FALSE)
      )

    m
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 6 — Results & Export
  # ════════════════════════════════════════════════════════════════════════

  output$results_summary_ui <- renderUI({
    df <- rv$results
    if (is.null(df)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"),
          " No results yet. Complete Steps 1-4 first.")
      ))
    }
    matched <- sum(df$GRAB_FILENAME != "", na.rm = TRUE)
    total   <- nrow(df)
    up_n    <- if (!is.null(rv$unmatched_photos)) nrow(rv$unmatched_photos) else 0
    sp_n    <- if (!is.null(rv$skipped_photos))   nrow(rv$skipped_photos)   else 0

    div(class = if (matched > 0) "success-box" else "error-box",
      h4("Matching Summary"),
      tags$ul(
        tags$li("Method: ", tags$b(
          if (rv$last_method == "exif") "EXIF Distance + Time" else "Filename")),
        tags$li("CSV rows: ", tags$b(total)),
        tags$li("Rows with photos: ", tags$b(matched)),
        tags$li("Rows without photos: ", tags$b(total - matched)),
        if (up_n > 0) tags$li("Unmatched photos: ", tags$b(up_n),
          " (expand 'Unmatched Photos' box below)"),
        if (sp_n > 0) tags$li("Skipped photos: ", tags$b(sp_n),
          " (expand 'Skipped Photos' box below)")
      )
    )
  })

  output$results_table <- renderDT({
    df <- rv$results
    if (is.null(df)) return(NULL)
    dt <- datatable(df,
              options = list(pageLength = 25, scrollX = TRUE, dom = "frtip"),
              rownames = FALSE)
    dt <- dt %>% formatStyle(
      "GRAB_FILENAME", target = "row",
      backgroundColor = styleEqual("", "#fff3cd")
    )
    if ("GRAB_DISTANCE_M" %in% names(df)) {
      dt <- dt %>% formatStyle("GRAB_DISTANCE_M", color = "#555", fontStyle = "italic")
    }
    dt
  })

  output$unmatched_photos_table <- renderDT({
    up <- rv$unmatched_photos
    if (is.null(up) || nrow(up) == 0)
      return(datatable(data.frame(Message = "All photos matched!")))
    datatable(up, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })

  output$skipped_photos_table <- renderDT({
    sp <- rv$skipped_photos
    if (is.null(sp) || nrow(sp) == 0)
      return(datatable(data.frame(Message = "No photos skipped.")))
    datatable(sp, options = list(pageLength = 10, scrollX = TRUE), rownames = FALSE)
  })

  # Save CSV
  observeEvent(input$save_csv_btn, {
    df <- rv$results
    if (is.null(df)) {
      showNotification("No results to save. Run matching first!", type = "warning")
      return()
    }
    tryCatch({
      base <- tools::file_path_sans_ext(basename(input$csv_path))
      out  <- file.path(dirname(input$csv_path), paste0(base, "_photos.csv"))
      write.csv(df, out, row.names = FALSE)
      showNotification(paste("Saved:", out), type = "message", duration = 8)
    }, error = function(e) {
      showNotification(paste("Error saving:", e$message), type = "error")
    })
  })

  # ════════════════════════════════════════════════════════════════════════
  # TAB 5 — Rename Photos
  # ════════════════════════════════════════════════════════════════════════

  # POINT_ID column selector (reuse csv_columns)
  output$rename_pointid_col_ui <- renderUI({
    cols <- rv$csv_columns
    if (!is.null(cols)) {
      selectInput("rename_pid_col", "POINT_ID column (for the new filename):",
                  choices = cols,
                  selected = pick_col(cols, c("^POINT_ID$", "point.*id", "pid")))
    } else {
      textInput("rename_pid_col", "POINT_ID column:", value = "POINT_ID")
    }
  })

  # Readiness check
  output$rename_ready_ui <- renderUI({
    issues <- character(0)
    if (is.null(rv$results))       issues <- c(issues, "No matching results yet (complete Steps 1-4 first).")
    if (is.null(input$location_id) || nchar(trimws(input$location_id)) == 0)
      issues <- c(issues, "Enter a Location / Site Name above.")

    if (length(issues) > 0) {
      div(class = "warning-box",
        h4(icon("exclamation-triangle"), " Not ready:"),
        tags$ul(lapply(issues, tags$li))
      )
    } else {
      div(class = "success-box",
        p(icon("check-circle"), " Ready to rename. Click the button on the right.")
      )
    }
  })

  # Rename handler
  observeEvent(input$rename_btn, {
    df <- rv$results
    if (is.null(df)) {
      showNotification("Run matching first (Steps 1-4).", type = "warning")
      return()
    }

    location_raw <- trimws(input$location_id)
    if (nchar(location_raw) == 0) {
      showNotification("Please enter a Location / Site Name.", type = "warning")
      return()
    }

    # Sanitise location: replace spaces/special chars with underscores
    location <- gsub("[^A-Za-z0-9_-]", "_", location_raw)

    pid_col <- input$rename_pid_col
    if (is.null(pid_col) || !(pid_col %in% names(df))) {
      showNotification(paste("POINT_ID column", pid_col, "not found in results."), type = "error")
      return()
    }

    separator <- if (is.null(input$separator) || nchar(trimws(input$separator)) == 0)
      ";" else input$separator

    # Create output directory next to photos folder
    out_dir <- file.path(dirname(input$photos_dir), "Grab_photos_renamed")
    dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

    log_rows <- list()
    n_copied <- 0
    n_failed <- 0

    withProgress(message = "Renaming photos...", value = 0, {
      for (i in seq_len(nrow(df))) {
        fnames_str <- df$GRAB_FILENAME[i]
        if (is.na(fnames_str) || nchar(fnames_str) == 0) next

        point_id <- as.character(df[[pid_col]][i])
        fnames   <- trimws(unlist(strsplit(fnames_str, separator, fixed = TRUE)))

        # Determine if this row was time-only matched and GPS fix is requested
        row_method  <- if ("GRAB_MATCH_METHOD" %in% names(df)) df$GRAB_MATCH_METHOD[i] else ""
        do_fix_gps  <- isTRUE(input$fix_bad_gps_exif) &&
                       grepl("time_only", row_method, fixed = TRUE)
        # Resolve lat/lon columns once per row
        lat_col_n <- if (!is.null(input$lat_col) && input$lat_col %in% names(df))
          input$lat_col else
          grep("^lat(itude)?$", names(df), ignore.case = TRUE, value = TRUE)[1]
        lon_col_n <- if (!is.null(input$lon_col) && input$lon_col %in% names(df))
          input$lon_col else
          grep("^lon(gitude)?$|^lng$", names(df), ignore.case = TRUE, value = TRUE)[1]
        csv_lat_val <- suppressWarnings(as.numeric(df[[lat_col_n]][i]))
        csv_lon_val <- suppressWarnings(as.numeric(df[[lon_col_n]][i]))

        for (j in seq_along(fnames)) {
          old_name <- fnames[j]
          old_path <- file.path(input$photos_dir, old_name)

          if (!file.exists(old_path)) {
            log_rows[[length(log_rows) + 1]] <- data.frame(
              original = old_name, renamed = NA_character_,
              status = "File not found", stringsAsFactors = FALSE)
            n_failed <- n_failed + 1
            next
          }

          # Extract date: try EXIF timestamp first, then filename pattern
          date_str <- NA_character_
          if (!is.null(rv$exif_data)) {
            exif_row <- rv$exif_data[rv$exif_data$FileName == old_name, , drop = FALSE]
            if (nrow(exif_row) == 1 &&
                "timestamp" %in% names(exif_row) &&
                length(exif_row$timestamp) == 1 &&
                !is.na(exif_row$timestamp[1])) {
              date_str <- format(exif_row$timestamp[1], "%Y%m%d")
            }
          }
          if (is.na(date_str)) {
            # Try from filename like 42_20251119_062201_Photo 3.jpg
            m <- regmatches(old_name, regexpr("\\d{8}", old_name))
            if (length(m) == 1) date_str <- m
          }
          if (is.na(date_str)) date_str <- "00000000"

          ext      <- tolower(tools::file_ext(old_name))
          new_name <- paste0(location, "_", point_id, "_", date_str,
                             "_GRAB_", j, ".", ext)
          new_path <- file.path(out_dir, new_name)

          tryCatch({
            file.copy(old_path, new_path, overwrite = TRUE)

            # Optionally overwrite GPS in the copied file for time-only matches
            gps_note <- ""
            if (do_fix_gps && !is.na(csv_lat_val) && !is.na(csv_lon_val)) {
              ok <- tryCatch(
                patch_jpeg_gps_r(new_path, csv_lat_val, csv_lon_val),
                error = function(e) FALSE
              )
              gps_note <- if (isTRUE(ok)) " | GPS overwritten" else " | GPS fix FAILED"
            }

            log_rows[[length(log_rows) + 1]] <- data.frame(
              original = old_name, renamed = new_name,
              status = paste0("OK", gps_note), stringsAsFactors = FALSE)
            n_copied <- n_copied + 1
          }, error = function(e) {
            log_rows[[length(log_rows) + 1]] <<- data.frame(
              original = old_name, renamed = new_name,
              status = paste("Error:", e$message), stringsAsFactors = FALSE)
            n_failed <<- n_failed + 1
          })
        }

        incProgress(1 / nrow(df))
      }
    })

    rv$rename_log <- if (length(log_rows) > 0) do.call(rbind, log_rows) else NULL

    # --- Update rv$results: store originals then replace with new names ---
    if (n_copied > 0 && !is.null(rv$rename_log)) {
      df <- rv$results
      # Keep original filenames for traceability (only add once)
      if (!("GRAB_FILENAME_ORIGINAL" %in% names(df))) {
        df$GRAB_FILENAME_ORIGINAL <- df$GRAB_FILENAME
      }
      ok_log <- rv$rename_log[startsWith(rv$rename_log$status, "OK"), , drop = FALSE]
      name_map <- setNames(ok_log$renamed, ok_log$original)

      for (i in seq_len(nrow(df))) {
        fnames_str <- df$GRAB_FILENAME_ORIGINAL[i]
        if (is.na(fnames_str) || nchar(fnames_str) == 0) next
        fnames <- trimws(unlist(strsplit(fnames_str, separator, fixed = TRUE)))
        new_fnames <- vapply(fnames, function(fn) {
          if (fn %in% names(name_map)) name_map[[fn]] else fn
        }, character(1), USE.NAMES = FALSE)
        df$GRAB_FILENAME[i] <- paste(new_fnames, collapse = separator)
      }
      rv$results <- df
    }

    showNotification(
      paste0("Rename complete: ", n_copied, " copied, ", n_failed, " failed. ",
             "Output folder: ", out_dir),
      type = if (n_failed == 0) "message" else "warning", duration = 10)
  })

  # Rename summary
  output$rename_summary_ui <- renderUI({
    log <- rv$rename_log
    if (is.null(log)) {
      return(div(class = "warning-box",
        p(icon("exclamation-triangle"), " No rename performed yet.")))
    }
    n_ok   <- sum(startsWith(log$status, "OK"))
    n_fail <- sum(!startsWith(log$status, "OK"))
    out_dir <- file.path(dirname(input$photos_dir), "Grab_photos_renamed")
    cls <- if (n_fail == 0) "success-box" else "warning-box"
    div(class = cls,
      h4(icon("check-circle"), " Rename Summary"),
      tags$ul(
        tags$li("Photos renamed: ", tags$b(n_ok)),
        tags$li("Failures: ", tags$b(n_fail)),
        tags$li("Output folder: ", tags$code(out_dir))
      ),
      if (n_fail > 0) p("Check the log table below for details on failures.")
    )
  })

  # Rename log table
  output$rename_log_table <- renderDT({
    log <- rv$rename_log
    if (is.null(log)) return(NULL)
    dt <- datatable(log,
              options = list(pageLength = 25, scrollX = TRUE, dom = "frtip"),
              rownames = FALSE)
    dt %>% formatStyle("status",
      backgroundColor = styleEqual("OK", "#e8f5e9"),
      color = styleEqual("OK", "#2e7d32"))
  })
}

# ── Launch ────────────────────────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
