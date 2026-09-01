#!/usr/bin/env python3
"""Per-CoC, per-year PIT totals split by shelter status (overall / sheltered /
unsheltered), long format, from the HUD PIT-by-CoC workbook.
Usage: pit_coc_extract.py <input.xlsb> <output.csv>   (needs pandas + pyxlsb)
"""
import os, re, sys
import pandas as pd

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from coc_codes import select_coc_rows

infile, outfile = sys.argv[1], sys.argv[2]
xl = pd.ExcelFile(infile, engine="pyxlsb")
rows = []
for s in [s for s in xl.sheet_names if re.fullmatch(r"\d{4}", str(s))]:
    df = pd.read_excel(xl, sheet_name=s)
    coc = next(c for c in df.columns if "CoC Number" in str(c))
    def pick(name):
        c = next((c for c in df.columns if str(c).strip() == name), None)
        return c
    ct, csh, cun = (pick("Overall Homeless"),
                    pick("Sheltered Total Homeless"),
                    pick("Unsheltered Homeless"))
    valid, codes = select_coc_rows(df, coc, context=f"sheet {s}")
    sub = valid[[coc, ct, csh, cun]]
    sub.columns = ["coc_num", "total", "sheltered", "unsheltered"]
    sub["coc_num"] = codes
    for c in ["total", "sheltered", "unsheltered"]:
        sub[c] = pd.to_numeric(sub[c], errors="coerce")
    sub = sub.dropna(subset=["total"])
    sub["year"] = int(s)
    rows.append(sub)
out = pd.concat(rows, ignore_index=True).sort_values(["coc_num", "year"])
out = out[["coc_num", "year", "total", "sheltered", "unsheltered"]]
out.to_csv(outfile, index=False)
print(f"wrote {len(out)} rows, {out.coc_num.nunique()} CoCs, "
      f"years {out.year.min()}-{out.year.max()} -> {outfile}")
