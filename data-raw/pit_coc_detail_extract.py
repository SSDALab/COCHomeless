#!/usr/bin/env python3
"""Tidy long PIT detail by CoC, year, shelter type and subpopulation, from the
HUD PIT-by-CoC workbook. Each count column ("<shelter> Homeless <subpop>") is
melted into rows: coc_num, year, shelter, subpopulation, count.
Usage: pit_coc_detail_extract.py <input.xlsb> <output.csv>   (pandas + pyxlsb)
"""
import re, sys
import pandas as pd

infile, outfile = sys.argv[1], sys.argv[2]
xl = pd.ExcelFile(infile, engine="pyxlsb")

# shelter prefixes, longest first so "Sheltered Total" matches before "Sheltered"
SHELTERS = ["Sheltered Total", "Sheltered ES", "Sheltered TH", "Sheltered SH",
            "Unsheltered", "Overall"]

def parse(col):
    for sh in SHELTERS:
        if col.startswith(sh + " "):
            rest = col[len(sh) + 1:]
            rest = re.sub(r"^Homeless\s*", "", rest)       # drop the "Homeless" token
            rest = re.sub(r"^-\s*", "", rest)              # clean the "- " demographic prefix
            return sh, (rest.strip() or "All")
    return None

rows = []
for s in [s for s in xl.sheet_names if re.fullmatch(r"\d{4}", str(s))]:
    df = pd.read_excel(xl, sheet_name=s)
    coc = next(c for c in df.columns if "CoC Number" in str(c))
    valid = df[df[coc].astype(str).str.match(r"^[A-Z]{2}-[0-9A-Za-z]{3}$")].copy()
    valid["coc_num"] = valid[coc].astype(str).str.strip()
    for col in df.columns:
        p = parse(str(col).strip())
        if p is None:
            continue
        sh, sub = p
        v = pd.to_numeric(valid[col], errors="coerce")
        keep = pd.DataFrame({"coc_num": valid["coc_num"], "count": v})
        keep = keep.dropna(subset=["count"])
        keep["year"] = int(s); keep["shelter"] = sh; keep["subpopulation"] = sub
        rows.append(keep)

out = pd.concat(rows, ignore_index=True)
out["count"] = out["count"].astype(int)
out = out[["coc_num", "year", "shelter", "subpopulation", "count"]]
out = out.sort_values(["coc_num", "year", "subpopulation", "shelter"])
out.to_csv(outfile, index=False)
print(f"wrote {len(out)} rows | {out.coc_num.nunique()} CoCs | "
      f"shelters {sorted(out.shelter.unique())} | "
      f"{out.subpopulation.nunique()} subpops -> {outfile}")
