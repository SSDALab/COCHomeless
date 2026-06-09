#!/usr/bin/env python3
"""Dump a single named sheet of an .xlsb workbook to CSV.
Usage: xlsb_sheet_to_csv.py <input.xlsb> "<Sheet Name>" <output.csv>
Requires pandas + pyxlsb.
"""
import sys
import pandas as pd

infile, sheet, outfile = sys.argv[1], sys.argv[2], sys.argv[3]
df = pd.read_excel(infile, sheet_name=sheet, engine="pyxlsb")
df.to_csv(outfile, index=False)
print(f"wrote {len(df)} rows from sheet '{sheet}' -> {outfile}")
