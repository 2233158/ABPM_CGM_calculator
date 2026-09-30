# -*- coding: utf-8 -*-
"""Golden-file generator: replicate the R preprocessing algorithm on the two
raw Mobil-O-Graph 24h PWA xls exports, and write expected converted CSVs.

Algorithm (must match the R implementation `xls_to_abpm_long()` exactly):
  1. Read the first sheet without header.
  2. Header row = first row containing 'Number' (and 'Systole').
  3. Rows above header = metadata key/value pairs (col 0 -> col 1).
  4. Data rows below header; map Systole->SBP, Diastole->DBP, Hr->HR,
     pPP->PP, MAP->MAP (device-measured values are kept).
  5. Drop rows where SBP<=0 or DBP<=0 or HR<=0 or any of them is NaN
     (failed readings: artefacts, device off, etc.).
  6. Time = HHMM (zero-padded, 24h) + '+XD', X = day offset of the reading's
     calendar date relative to the first VALID reading's calendar date.
  7. MASKID = metadata ID; rows sorted by datetime.
  8. Output columns: MASKID,Time,SBP,DBP,HR,PP,MAP.
"""
import sys, os, io
import pandas as pd

ROOT = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(ROOT)
TEST = os.path.join(PROJ, "test_data")
OUT = os.path.join(PROJ, "converted_samples")

FILES = [
    ("2017-10-23_12-47_JL_50010_24hPWA.xls", "50010"),
    ("2017-10-10_13-30_GL_50001_24hPWA.xls", "50001"),
]

HEADER_MARKERS = ["Number", "Systole"]
MAP_COLS = {"Systole": "SBP", "Diastole": "DBP", "Hr": "HR", "pPP": "PP", "MAP": "MAP"}


def find_header_row(raw):
    for i, row in raw.iterrows():
        vals = [str(v).strip() if pd.notna(v) else "" for v in row.tolist()]
        if all(m in vals for m in HEADER_MARKERS):
            return i
    raise ValueError("header row (Number/Systole) not found")


def parse_datetime(v):
    if pd.isna(v):
        return pd.NaT
    if isinstance(v, pd.Timestamp):
        return v
    if isinstance(v, str):
        v = v.strip()
        for fmt in ("%Y-%m-%d %H:%M:%S.%f", "%Y-%m-%d %H:%M:%S",
                    "%d.%m.%Y %H:%M:%S", "%d.%m.%Y %H:%M", "%Y-%m-%d"):
            try:
                return pd.to_datetime(v, format=fmt)
            except ValueError:
                continue
        return pd.to_datetime(v, errors="coerce")
    return pd.to_datetime(v, errors="coerce")


def convert(path, expected_id=None):
    xls = pd.ExcelFile(path)
    sheet = xls.sheet_names[0]
    raw = xls.parse(sheet_name=sheet, header=None)
    hdr = find_header_row(raw)
    # metadata: key/value pairs above the header row
    meta = {}
    for _, row in raw.iloc[:hdr].iterrows():
        k, v = row.iloc[0], row.iloc[1]
        if pd.notna(k) and str(k).strip():
            meta[str(k).strip()] = None if pd.isna(v) else str(v).strip()
    # data block
    cols = [str(c).strip() if pd.notna(c) else "" for c in raw.iloc[hdr].tolist()]
    data = raw.iloc[hdr + 1:].copy()
    data.columns = cols
    data = data.reset_index(drop=True)

    need = ["Date", "Systole", "Diastole", "Hr"]
    missing = [c for c in need if c not in data.columns]
    if missing:
        raise ValueError("missing columns: %s" % missing)

    data["_dt"] = data["Date"].apply(parse_datetime)
    data["SBP"] = pd.to_numeric(data["Systole"], errors="coerce")
    data["DBP"] = pd.to_numeric(data["Diastole"], errors="coerce")
    data["HR"] = pd.to_numeric(data["Hr"], errors="coerce")
    data["PP"] = pd.to_numeric(data["pPP"], errors="coerce") if "pPP" in data.columns else pd.Series([pd.NA] * len(data))
    data["MAP"] = pd.to_numeric(data["MAP"], errors="coerce") if "MAP" in data.columns else pd.Series([pd.NA] * len(data))

    n_total = len(data)
    bad_time = data["_dt"].isna()
    valid_mask = (
        ~bad_time
        & (data["SBP"] > 0) & (data["DBP"] > 0) & (data["HR"] > 0)
    )
    n_bad_time = int(bad_time.sum())
    n_zero = int((~bad_time & ~valid_mask).sum())

    valid = data[valid_mask].sort_values("_dt").reset_index(drop=True)
    first_date = valid["_dt"].iloc[0].date() if len(valid) else None

    def fmt(dt):
        off = (dt.date() - first_date).days
        return "%02d%02d+%dD" % (dt.hour, dt.minute, off)

    out = pd.DataFrame({
        "MASKID": [meta.get("ID") or expected_id or ""] * len(valid),
        "Time": valid["_dt"].apply(fmt),
        "SBP": valid["SBP"],
        "DBP": valid["DBP"],
        "HR": valid["HR"],
        "PP": valid["PP"],
        "MAP": valid["MAP"],
    })
    # trim integer floats to clean representation (like R write.csv)
    for c in ["SBP", "DBP", "HR", "PP", "MAP"]:
        out[c] = out[c].apply(lambda x: int(x) if pd.notna(x) and float(x).is_integer() else x)

    report = {
        "file": os.path.basename(path),
        "sheet": sheet,
        "header_row_0based": hdr,
        "meta_id": meta.get("ID"),
        "meta_name": "%s, %s" % (meta.get("First name", ""), meta.get("Last name", "")),
        "n_total": n_total,
        "n_valid": len(valid),
        "n_dropped_zero": n_zero,
        "n_dropped_bad_time": n_bad_time,
        "first_valid": str(valid["_dt"].iloc[0]) if len(valid) else None,
        "last_valid": str(valid["_dt"].iloc[-1]) if len(valid) else None,
        "day_offsets": sorted(set(
            (d.date() - first_date).days for d in valid["_dt"])) if len(valid) else [],
    }
    return out, report


def main():
    os.makedirs(OUT, exist_ok=True)
    for fname, exp_id in FILES:
        path = os.path.join(TEST, fname)
        out, rep = convert(path, exp_id)
        out_name = "%s_24hPWA_converted.csv" % rep["meta_id"]
        out_path = os.path.join(OUT, out_name)
        out.to_csv(out_path, index=False, encoding="utf-8")
        print("== %s ==" % rep["file"])
        for k, v in rep.items():
            print("  %-20s %s" % (k, v))
        print("  sample rows:")
        print(out.head(3).to_string(index=False))
        print("  ...")
        print(out.tail(2).to_string(index=False))
        # device MAP vs computed MAP check
        if len(out):
            cmp = out["DBP"] + (out["SBP"] - out["DBP"]) / 3
            diff = (out["MAP"] - cmp).abs()
            print("  MAP device-vs-computed: n_diff=%.0f max|diff|=%.2f mean|diff|=%.3f"
                  % ((diff > 0.5).sum(), diff.max(), diff.mean()))
        print("  written -> %s" % out_path)
        print()


if __name__ == "__main__":
    main()
