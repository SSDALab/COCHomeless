#!/usr/bin/env python3
"""State-level PIT totals from HUD's "PIT Counts by State" workbook.

This is a different HUD publication from the by-CoC workbook the rest of the
package is built from, and it is the authoritative state-level series. It is used
for two things:

  * validation -- the national roll-up and per-state roll-ups are checked against
    it, so a CoC silently dropped on import cannot pass unnoticed;
  * the bi-state split -- MO-604 (Kansas City) covers territory in both Missouri
    and Kansas. The by-CoC file reports one combined row; this file reports the
    two portions separately, and the county apportionment needs that split so
    that Kansas counties do not absorb Missouri's share.

Usage: pit_state_extract.py <input.xlsb> <output.csv>   (needs pandas + pyxlsb)
"""
import re
import sys

import pandas as pd

infile, outfile = sys.argv[1], sys.argv[2]
xl = pd.ExcelFile(infile, engine="pyxlsb")

rows = []
for s in [s for s in xl.sheet_names if re.fullmatch(r"\d{4}", str(s))]:
    df = pd.read_excel(xl, sheet_name=s)
    st_col = next(c for c in df.columns if str(c).strip() == "State")
    tot_col = next(c for c in df.columns if str(c).strip() == "Overall Homeless")
    sub = df[[st_col, tot_col]].copy()
    sub.columns = ["state", "total"]
    sub["state"] = sub["state"].astype(str).str.strip()
    sub = sub[sub["state"].str.match(r"^[A-Z]{2}$")]
    sub["total"] = pd.to_numeric(sub["total"], errors="coerce")
    sub = sub.dropna(subset=["total"])
    sub["total"] = sub["total"].round().astype(int)
    sub["year"] = int(s)
    rows.append(sub[["state", "year", "total"]])

out = pd.concat(rows, ignore_index=True).sort_values(["state", "year"])
out.to_csv(outfile, index=False)
print(f"wrote {len(out)} rows, {out.state.nunique()} states, "
      f"years {out.year.min()}-{out.year.max()} -> {outfile}")
