# -*- coding: utf-8 -*-
"""Static self-check for the assembled integrated R Shiny app (v2).

Comment- and string-aware scans, so no R runtime is needed.
"""
import re
from pathlib import Path

APP = Path(r"ABPM_calculator_integrated.R").read_text(encoding="utf-8")
failures = []

def check(cond, msg):
    if cond:
        print("  OK  -", msg)
    else:
        failures.append(msg)
        print("  FAIL -", msg)

# ------------------------------------------------------------- tokenizer-lite
def strip_noncode(text):
    """Remove R comments and string literals so delimiters can be counted."""
    out = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if c in "\"'`":  # includes backtick-quoted function names like `[[`
            quote = c
            i += 1
            while i < n:
                if text[i] == "\\":
                    i += 2
                    continue
                if text[i] == quote:
                    i += 1
                    break
                i += 1
            out.append("S")
            continue
        out.append(c)
        i += 1
    return "".join(out)

print("== 1. Translation dictionary keys ==")
en_block = APP.split("en = list(", 1)[1].split("\nzh = list(", 1)[0]
defined = set()
for m in re.finditer(r"^\s{2}([A-Za-z0-9_]+)\s*=", en_block, flags=re.M):
    defined.add(m.group(1))
# keys sharing a line with a previous key (multi-key lines)
for line in en_block.split("\n"):
    if re.match(r"^\s{2}[A-Za-z0-9_]+\s*=", line):
        for m in re.finditer(r",\s*([A-Za-z0-9_]+)\s*=\s*[\"c]", line):
            defined.add(m.group(1))

used = set(re.findall(r'chart_tr\("([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r"chart_tr\('([A-Za-z0-9_]+)'\)", APP))
used |= set(re.findall(r'tr\("([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r'tr\(lang\(\)?,?\s*"([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r'tr\(APP_LANG,\s*"([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r'tr\(lang,\s*"([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r'tr2\("([A-Za-z0-9_]+)"\)', APP))
used |= set(re.findall(r'tr\("en", "([A-Za-z0-9_]+)"\)', APP))
used |= {"followup_urgent", "followup_elective", "followup_routine",
         "src_builtin", "src_csv", "src_raw", "src_none"}

missing = sorted(used - defined)
unused = sorted(defined - used)
check(not missing, "no tr() keys missing from dict" + ("" if not missing else " -> " + ", ".join(missing)))
print("        defined: %d, used: %d, unused: %d" % (len(defined), len(used), len(unused)))
print("        unused (informational): " + ", ".join(unused[:15]) + (" ..." if len(unused) > 15 else ""))

print("== 2. Balance of delimiters (string/comment-aware) ==")
stripped = strip_noncode(APP)
for open_ch, close_ch, name in [("{", "}", "braces"), ("(", ")", "parens"), ("[", "]", "brackets")]:
    n_open = stripped.count(open_ch)
    n_close = stripped.count(close_ch)
    ok = n_open == n_close
    check(ok, "%s balanced (%d vs %d)" % (name, n_open, n_close))
    if not ok:
        depth = 0
        for ln, line in enumerate(APP.split("\n"), 1):
            line_stripped = strip_noncode(line)
            for ch in line_stripped:
                if ch == open_ch:
                    depth += 1
                elif ch == close_ch:
                    depth -= 1
                    if depth < 0:
                        print("        first negative depth at line %d: %s" % (ln, line.strip()[:90]))
                        break
            if depth < 0:
                break
        print("        final depth: %+d" % (n_open - n_close))

print("== 3. Required definitions present ==")
for anchor in [
    "build_ui <- function(lang, settings)",
    "xls_to_abpm_long <- function",
    "read_abpm_pwa_xls <- function",
    "alias_lookup <- function",
    "load_and_prepare_data <- function(df, lang = \"en\")",
    "create_individual_patient_series <- function",
    "add_vim_from_observed_results <- function(results_df, vim_mode = \"cohort\"",
    "build_personalized_assessment <- function(metric_results, patient_id, lang = \"en\")",
    "output$download_sel_csv <- downloadHandler",
    "output$download_sel_xlsx <- downloadHandler",
    "output$download_converted_csv <- downloadHandler",
    "rintrojs::introjs(session",
    "output$page <- renderUI",
    "withMathJax",
    "footer_copyright",
    "FIELD_DEFS <- data.frame",
    "METRIC_DEFS <- data.frame",
]:
    check(anchor in APP, "present: " + anchor[:60])

print("== 4. No leftover removed references ==")
for bad in ["input$file1", "values$data_source_msg", "download_all_csv",
            "download_all_xlsx", "shinydashboard"]:
    check(bad not in APP, "no leftover: " + bad)

print("== 5. input$ ids referenced by server exist somewhere ==")
# ids declared literally by input widgets anywhere in the file
ui_ids = set(re.findall(
    r'(?:numericInput|textInput|selectInput|radioButtons|checkboxInput|'
    r'checkboxGroupInput|fileInput|actionButton|downloadButton)\(\s*"([A-Za-z0-9_]+)"', APP))
ui_ids |= {"lang_radio", "tour_btn"}
# ids created inside server-rendered panels (mapping panel / raw panel)
ui_ids |= {"map_id", "map_time", "map_sbp", "map_dbp", "map_hr", "map_pp",
           "map_map", "map_glu", "apply_mapping_btn", "convert_raw_btn", "load_converted_btn"}
# ids generated with variables (time rows, target grid, per-file maskids)
generated = {p + "_" + s for p in ("day1_start", "day1_night_start", "day2_start", "day2_night_start") for s in ("h", "m")}
for m in ("sbp", "dbp", "hr", "pp", "map"):
    for p in ("day", "night", "24h"):
        generated |= {"%s_%s_%s" % (m, p, s) for s in ("lower", "upper")}
input_refs = set(re.findall(r'input\$([A-Za-z0-9_]+)', APP))
input_refs |= set(re.findall(r'input\[\["([A-Za-z0-9_]+)"\]\]', APP))
missing_ids = sorted(i for i in input_refs
                      if i not in ui_ids and i not in generated
                      and not i.startswith("raw_maskid_"))
check(not missing_ids, "server input refs all exist" + ("" if not missing_ids else " -> " + ", ".join(missing_ids)))

print("== 6. duplicated output$ assignments ==")
outs = re.findall(r'output\$([A-Za-z0-9_`]+)\s*<-', APP)
dups = sorted({o for o in outs if outs.count(o) > 1})
check(not dups, "no duplicated output$ assignments" + ("" if not dups else " -> " + ", ".join(dups)))

print("== 7. Chinese text still present in UI-facing strings ==")
# count remaining CJK characters (engine console warnings may remain)
n_cjk = len(re.findall(r'[\u4e00-\u9fff]', APP))
print("        (informational) CJK chars remaining: %d (expected in zh dict + engine warnings)" % n_cjk)

print()
if failures:
    print("RESULT: %d FAILURE(S)" % len(failures))
    raise SystemExit(1)
print("RESULT: ALL CHECKS PASSED")
