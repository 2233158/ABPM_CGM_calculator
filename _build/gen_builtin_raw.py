# -*- coding: utf-8 -*-
"""Convert the two new raw device exports into anonymized built-in samples.

Anonymization: only the 7 analysis columns (MASKID, Time, SBP, DBP, HR, PP,
MAP) are kept - no name, date of birth, height/weight or other metadata.
MASKID = the device ID from the file metadata.
"""
import os
import pandas as pd

FILES = [
    (r"C:\Users\MSI\Desktop\abpm\透析ABPM示例\2017-10-12_12-51_GM_50002_24hPWA.xls", "50002"),
    (r"C:\Users\MSI\Desktop\abpm\透析ABPM示例\2017-10-12_12-49_DZ_50003_24hPWA.xls", "50003"),
]
OUT_DIR = os.path.dirname(os.path.abspath(__file__))


def find_header_row(raw):
    for i, row in raw.iterrows():
        vals = [str(v).strip() if pd.notna(v) else "" for v in row.tolist()]
        if all(m in vals for m in ["Number", "Systole"]):
            return i
    raise ValueError("header row not found")


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


def convert(path, fallback_id):
    xls = pd.ExcelFile(path)
    raw = xls.parse(sheet_name=0, header=None)
    hdr = find_header_row(raw)
    meta = {}
    for _, row in raw.iloc[:hdr].iterrows():
        k, v = row.iloc[0], row.iloc[1]
        if pd.notna(k) and str(k).strip():
            meta[str(k).strip()] = None if pd.isna(v) else str(v).strip()
    cols = [str(c).strip() if pd.notna(c) else "" for c in raw.iloc[hdr].tolist()]
    data = raw.iloc[hdr + 1:].copy()
    data.columns = cols
    data = data.reset_index(drop=True)
    data["_dt"] = data["Date"].apply(parse_datetime)
    data["SBP"] = pd.to_numeric(data["Systole"], errors="coerce")
    data["DBP"] = pd.to_numeric(data["Diastole"], errors="coerce")
    data["HR"] = pd.to_numeric(data["Hr"], errors="coerce")
    data["PP"] = pd.to_numeric(data["pPP"], errors="coerce")
    data["MAP"] = pd.to_numeric(data["MAP"], errors="coerce")
    valid = (~data["_dt"].isna()) & (data["SBP"] > 0) & (data["DBP"] > 0) & (data["HR"] > 0)
    v = data[valid].sort_values("_dt").reset_index(drop=True)
    first_date = v["_dt"].iloc[0].date()
    maskid = meta.get("ID") or fallback_id
    out = pd.DataFrame({
        "MASKID": [maskid] * len(v),
        "Time": ["%02d%02d+%dD" % (dt.hour, dt.minute, (dt.date() - first_date).days)
                 for dt in v["_dt"]],
        "SBP": v["SBP"], "DBP": v["DBP"], "HR": v["HR"],
        "PP": v["PP"], "MAP": v["MAP"],
    })
    for c in ["SBP", "DBP", "HR", "PP", "MAP"]:
        out[c] = out[c].apply(lambda x: int(x) if pd.notna(x) and float(x).is_integer() else x)
    return out, meta, len(data), len(v)


for path, fid in FILES:
    out, meta, n_total, n_valid = convert(path, fid)
    out_path = os.path.join(OUT_DIR, "builtin_%s.csv" % fid)
    out.to_csv(out_path, index=False, encoding="utf-8")
    print("== %s ==" % os.path.basename(path))
    print("  meta ID:", meta.get("ID"), "| name:", meta.get("First name"), meta.get("Last name"))
    print("  n_total=%d n_valid=%d  -> %s (%d rows)" % (n_total, n_valid, out_path, len(out)))
    print("  first:", out.iloc[0].tolist(), " last:", out.iloc[-1].tolist())
