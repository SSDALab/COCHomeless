#!/usr/bin/env python3
"""Extract HUD PIT 'Overall Homeless' totals by CoC and year from the HUD
'PIT Counts by CoC' .xlsb workbook into a tidy long CSV.

R cannot read .xlsb directly, so 02_hud_pit.R shells out to this helper.
Requires: pandas + pyxlsb.

Usage: pit_xlsb_extract.py <input.xlsb> <output.csv>
"""
import re
import sys
import pandas as pd

def main(infile, outfile):
    xl = pd.ExcelFile(infile, engine="pyxlsb")
    year_sheets = [s for s in xl.sheet_names if re.fullmatch(r"\d{4}", str(s))]
    rows = []
    for s in year_sheets:
        df = pd.read_excel(xl, sheet_name=s)
        coc_col = next(c for c in df.columns if "CoC Number" in str(c))
        # the total column is exactly 'Overall Homeless' (optionally year-suffixed),
        # never a ' - subcategory'
        total_col = next(
            c for c in df.columns
            if re.fullmatch(r"Overall Homeless(,?\s*\d{4})?", str(c).strip())
        )
        sub = df[[coc_col, total_col]].copy()
        sub.columns = ["coc_num", "count"]
        sub["coc_num"] = sub["coc_num"].astype(str).str.strip()
        # keep only real CoC rows (drop footers / totals / blanks)
        sub = sub[sub["coc_num"].str.match(r"^[A-Z]{2}-[0-9A-Za-z]{3}$")]
        sub["count"] = pd.to_numeric(sub["count"], errors="coerce")
        sub = sub.dropna(subset=["count"])
        sub["count"] = sub["count"].round().astype(int)
        sub["year"] = int(s)
        rows.append(sub[["year", "coc_num", "count"]])
    out = pd.concat(rows, ignore_index=True).sort_values(["year", "coc_num"])
    out.to_csv(outfile, index=False)
    print(f"wrote {len(out)} rows, years {out.year.min()}-{out.year.max()}, "
          f"{out.coc_num.nunique()} unique CoCs -> {outfile}")

if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
