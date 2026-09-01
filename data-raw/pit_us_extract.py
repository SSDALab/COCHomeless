#!/usr/bin/env python3
"""National yearly PIT totals (overall / sheltered / unsheltered) from the HUD
PIT-by-CoC workbook. Sums each year sheet over valid CoC rows.
Usage: pit_us_extract.py <input.xlsb> <output.csv>   (needs pandas + pyxlsb)
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
    valid, _ = select_coc_rows(df, coc, context=f"sheet {s}")
    def col(name):
        c = next((c for c in df.columns if str(c).strip() == name), None)
        return pd.to_numeric(valid[c], errors="coerce").sum() if c else None
    rows.append(dict(year=int(s),
                     total=col("Overall Homeless"),
                     sheltered=col("Sheltered Total Homeless"),
                     unsheltered=col("Unsheltered Homeless")))
out = pd.DataFrame(rows).sort_values("year")
out.to_csv(outfile, index=False)
print(f"wrote {len(out)} years -> {outfile}")
