# -*- coding: utf-8 -*-
"""Generate anonymized built-in glucose samples from the CGM xlsx.

Raw layout sample  : the original sheet as CSV text (header row with metadata,
                     name replaced by ***), used by the raw-glucose demo path.
Processed sample    : canonical long format MASKID,Time,GLU (mmol/L).
MASKID = device serial (LT2503SGHM); personal name is NOT included.
"""
from pathlib import Path
import pandas as pd

SRC = r"C:\Users\MSI\Desktop\abpm\寿萍-2025-10-16.xlsx"
OUT_DIR = Path(__file__).resolve().parent

raw = pd.read_excel(SRC, sheet_name=0, header=None)
print("shape:", raw.shape)

# header row 0: 血糖值(mmol/L) | 采集时间 | 机构名称：... | 姓名：寿萍 | 设备名称：LT2503SGHM
hdr = [str(v) if pd.notna(v) else "" for v in raw.iloc[0].tolist()]
hdr = [h.replace("姓名：寿萍", "姓名：***") for h in hdr]
meta_dev = [h for h in hdr if h.startswith("设备名称：")][0].split("：")[1]
print("device serial:", meta_dev)

# raw-layout CSV text (anonymized)
raw_lines = [",".join(hdr)]
for _, row in raw.iloc[1:].iterrows():
    cells = ["" if pd.isna(v) else str(v) for v in row.tolist()]
    raw_lines.append(",".join(cells))
raw_text = "\n".join(raw_lines)
OUT_DIR.joinpath("builtin_glu_raw.csv").write_text(raw_text, encoding="utf-8")
print("raw text lines:", len(raw_lines))

# canonical processed form
data = raw.iloc[1:].copy()
data.columns = ["GLU", "DT", "X1", "X2", "X3"]
data["DT"] = pd.to_datetime(data["DT"], errors="coerce")
data["GLU"] = pd.to_numeric(data["GLU"], errors="coerce")
data = data.dropna(subset=["DT", "GLU"]).sort_values("DT").reset_index(drop=True)
first_date = data["DT"].iloc[0].date()
out = pd.DataFrame({
    "MASKID": [meta_dev] * len(data),
    "Time": ["%02d%02d+%dD" % (dt.hour, dt.minute, (dt.date() - first_date).days)
             for dt in data["DT"]],
    "GLU": data["GLU"],
})
out.to_csv(OUT_DIR / "builtin_glu_processed.csv", index=False, encoding="utf-8")
print("processed rows:", len(out))
print("day offsets:", sorted(set(int(t.split("+")[1][:-1]) for t in out["Time"])))
print("first:", out.iloc[0].tolist(), "last:", out.iloc[-1].tolist())
print("GLU range: %.1f - %.1f" % (out["GLU"].min(), out["GLU"].max()))
