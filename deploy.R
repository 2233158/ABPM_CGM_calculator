# =============================================================================
# deploy.R - deploy BOTH variants to Posit Connect Cloud (rsconnect)
# -----------------------------------------------------------------------------
# 1) demo version  (DEMO_MODE = TRUE):  uploads hidden, built-in samples only
# 2) full version  (DEMO_MODE = FALSE): file uploads enabled
#
# Open this file in RStudio and run it. It locates the app folder by this
# script's own path, so the RStudio working directory does not matter.
# Staged copies are written to an ASCII folder next to the project
# (abpm_deploy_stage/demo and abpm_deploy_stage/full) because rsconnect
# cannot list folders whose path contains non-ASCII characters.
#
# One-time account setup (run once in the RStudio console):
#   1) Register at https://connect.posit.cloud/
#   2) In the Posit Connect Cloud dashboard create an API token.
#   3) install.packages("rsconnect")
#      rsconnect::connectApiUser(account = "<name>", server = "connect.posit.cloud",
#                                apiKey = "<token>")
#
# After every change to ABPM_calculator_integrated.R, re-run this script to
# update both deployed apps.
#
# Notes for the full (upload-enabled) version on shinyapps.io:
#   - uploads live only in the current session's memory; nothing is stored;
#   - the Python/xlrd fallback for damaged legacy .xls is NOT available on
#     the server: clean .xls/.xlsx and CSV files work, damaged .xls files
#     show a clear read error there (they still work locally).
# =============================================================================

app_name_demo <- "abpm"          # URL slug of the demo version
app_name_full <- "abpm-upload"   # URL slug of the upload-enabled version
app_title <- "ABPM Integrated Bilingual Analysis System"

# ---- locate the app folder (robust to the RStudio working directory) ----
script_dir <- tryCatch({
  file_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(file_arg) == 0) {
    NA_character_
  } else {
    dirname(normalizePath(sub("^--file=", "", file_arg[1]), mustWork = FALSE))
  }
}, error = function(e) NA_character_)

if (is.na(script_dir) || !nzchar(script_dir) || !dir.exists(script_dir)) {
  # running via RStudio "Run" (no --file argument): use the editor's path
  editor_path <- tryCatch({
    if (requireNamespace("rstudioapi", quietly = TRUE)) {
      rstudioapi::getSourceEditorContext()$path
    } else ""
  }, error = function(e) "")
  if (nzchar(editor_path)) script_dir <- dirname(normalizePath(editor_path))
}

if (is.na(script_dir) || !nzchar(script_dir) || !dir.exists(script_dir)) {
  script_dir <- getwd()
}

app_src <- file.path(script_dir, "ABPM_calculator_integrated.R")

# last-resort fallback (known install location of this project; the folder
# name is written with \u escapes so it survives any source encoding)
KNOWN_APP <- "C:/Users/MSI/Desktop/abpm/ABPM_eng_\u4ea4\u6d41\u7248/ABPM_calculator_integrated.R"
if (!file.exists(app_src) && file.exists(KNOWN_APP)) {
  app_src <- KNOWN_APP
  script_dir <- dirname(app_src)
}

if (!file.exists(app_src)) {
  stop("Could not find ABPM_calculator_integrated.R. ",
       "Please run deploy.R from the app folder (ABPM_eng_\u4ea4\u6d41\u7248).")
}
setwd(script_dir)

library(rsconnect)

# ---- stage one variant (flip DEMO_MODE_DEFAULT) and deploy it ----
stage_and_deploy <- function(app_name, demo_default) {
  # Byte-faithful staging: flip only the ASCII DEMO_MODE_DEFAULT line at the
  # raw-byte level, so the staged app.R stays byte-identical to the source
  # under any locale (C / CP936 / UTF-8). No string parsing is involved.
  src_bytes <- readBin(app_src, what = "raw", n = file.info(app_src)$size)
  pat <- charToRaw("DEMO_MODE_DEFAULT <- ")
  pos <- grepRaw(pat, src_bytes, fixed = TRUE, all = TRUE)
  is_line_start <- function(p) {
    p == 1L || identical(src_bytes[p - 1L], as.raw(0x0a))
  }
  pos <- pos[vapply(pos, is_line_start, logical(1))]
  if (length(pos) != 1L) {
    stop("Could not locate the 'DEMO_MODE_DEFAULT <- TRUE/FALSE' flag in the app source.")
  }
  val_start <- pos[1L] + length(pat)
  old_val <- rawToChar(src_bytes[val_start:min(val_start + 4L, length(src_bytes))])
  old_len <- if (grepl("^TRUE", old_val)) 4L else if (grepl("^FALSE", old_val)) 5L else NA_integer_
  if (is.na(old_len)) {
    stop("Unexpected value after DEMO_MODE_DEFAULT <- in the app source.")
  }
  new_val <- charToRaw(if (demo_default) "TRUE" else "FALSE")
  head <- if (val_start > 1L) src_bytes[seq_len(val_start - 1L)] else raw(0)
  tail <- src_bytes[(val_start + old_len):length(src_bytes)]
  src_bytes <- c(head, new_val, tail)

  # Stage into an ASCII folder next to the project: rsconnect cannot list
  # directories whose path contains non-ASCII characters on this setup.
  stage_root <- file.path(dirname(script_dir), "abpm_deploy_stage")
  pkg_dir <- file.path(stage_root, if (demo_default) "demo" else "full")
  dir.create(pkg_dir, recursive = TRUE, showWarnings = FALSE)
  staged <- file.path(pkg_dir, "app.R")
  writeBin(src_bytes, staged)
  if (!file.exists(staged) || file.info(staged)$size < 1000) {
    stop("Failed to stage the app into ", pkg_dir,
         ". Please check folder permissions and retry.")
  }

  # Carry over the published-app record (appId) from the previous staging
  # folder so this update targets the already-published app instead of
  # creating a duplicate.
  legacy_rs <- file.path(script_dir,
                         if (demo_default) "deploy_pkg_demo" else "deploy_pkg_full",
                         "rsconnect")
  dcf_files <- tryCatch(Sys.glob(file.path(legacy_rs, "*", "*", "*.dcf")),
                        error = function(e) character(0))
  new_rs <- file.path(pkg_dir, "rsconnect")
  if (length(dcf_files) > 0 && !dir.exists(new_rs)) {
    for (f in dcf_files) {
      rel <- substring(f, nchar(legacy_rs) + 2L)
      dst <- file.path(new_rs, rel)
      dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
      if (!file.copy(f, dst, overwrite = TRUE)) {
        warning("Could not copy deployment record: ", f)
      }
    }
  }

  # Read account/server from the deployment record so the deploy always
  # targets the right account even when several accounts are registered.
  dcf_info <- if (length(dcf_files) > 0) {
    tryCatch(read.dcf(dcf_files[1]), error = function(e) NULL)
  } else NULL
  deploy_account <- if (!is.null(dcf_info) && "account" %in% colnames(dcf_info)) {
    dcf_info[1, "account"]
  } else NULL
  deploy_server <- if (!is.null(dcf_info) && "server" %in% colnames(dcf_info)) {
    dcf_info[1, "server"]
  } else NULL
  do_deploy <- function() {
    rsconnect::deployApp(
      appDir = pkg_dir,
      appName = app_name,
      appTitle = app_title,
      account = deploy_account,
      server = deploy_server,
      launch.browser = FALSE
    )
  }

  message("Deploying ", app_name, " (DEMO_MODE = ", demo_default, ") ...")
  deployed <- tryCatch({
    do_deploy()
    TRUE
  }, error = function(e) {
    msg <- conditionMessage(e)
    # If the previously published content no longer exists on the server
    # (deleted / expired free-tier content), drop the stale local record and
    # create a fresh deployment instead of failing.
    stale <- grepl("deleted|not found|failed to find existing content", msg,
                   ignore.case = TRUE)
    if (stale) {
      message("  Existing content is gone from the server; creating a fresh deployment.")
      try(rsconnect::forgetDeployment(pkg_dir, force = TRUE), silent = TRUE)
      do_deploy()
      TRUE
    } else {
      stop(e)
    }
  })
  if (!isTRUE(deployed)) stop("Deployment of ", app_name, " failed.")
  message("  -> ", app_name, " updated (Posit Connect Cloud).")
}

stage_and_deploy(app_name_demo, demo_default = TRUE)
stage_and_deploy(app_name_full, demo_default = FALSE)

message("Done. Both variants deployed to Posit Connect Cloud:")
message("  demo (no uploads):  ", app_name_demo)
message("  full (uploads on):  ", app_name_full)
