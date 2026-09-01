#!/usr/bin/env python3
"""Shared CoC-code handling for the HUD PIT workbook extractors.

HUD marks some CoC codes with a trailing footnote letter in the workbook. The
one that occurs in practice is `MO-604a` (Kansas City -- the CoC spans Missouri
and Kansas, and the footnote explains that the row is the combined territory).
A naive `^[A-Z]{2}-[0-9A-Za-z]{3}$` filter rejects it, which silently dropped
Kansas City from every year of the series.

`select_coc_rows` normalizes the code column, then keeps only well-formed codes
*and raises* if anything that looks like a CoC code was still rejected -- the
extractors must never drop a CoC row quietly again.
"""
import re

CODE_RE = re.compile(r"^[A-Z]{2}-[0-9A-Za-z]{3}$")
FOOTNOTE_RE = re.compile(r"^([A-Z]{2}-[0-9A-Za-z]{3})[a-z]$")
# anything starting like a CoC code; used to spot rows we should not be losing
COC_SHAPED_RE = re.compile(r"^[A-Z]{2}-[0-9]")


def normalize(series):
    """Strip whitespace and any trailing footnote letter from CoC codes."""
    s = series.astype(str).str.strip()
    return s.str.replace(FOOTNOTE_RE, r"\1", regex=True)


def select_coc_rows(df, coc_col, context=""):
    """Return (subset of `df` that are real CoC rows, normalized code Series).

    Raises ValueError if a CoC-shaped code would be dropped by the filter.
    """
    codes = normalize(df[coc_col])
    good = codes.str.match(CODE_RE)
    lost = sorted(set(codes[codes.str.match(COC_SHAPED_RE) & ~good]))
    if lost:
        raise ValueError(
            f"{context}: CoC-shaped codes rejected by the filter: {lost}. "
            "Extend data-raw/coc_codes.py rather than dropping them silently."
        )
    return df[good].copy(), codes[good]
