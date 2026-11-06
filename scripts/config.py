"""Shared paths. All scripts import this so nothing depends on where the repo lives."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = ROOT / "data" / "raw"              # NEVER written to by any script
EXTRACTED_DIR = ROOT / "data" / "extracted"  # text dumps of the raw PDFs
CLEANED_DIR = ROOT / "data" / "cleaned"      # hand-entered values (source of truth)
PROCESSED_DIR = ROOT / "data" / "processed"  # generated: derived columns
ARCHIVE_DIR = ROOT / "data" / "archive"
SQL_DIR = ROOT / "sql"
DOCS_DIR = ROOT / "docs"

# Fiscal_Year convention: Gregorian END year. 2025 = FY 2024/25.
def fy_label(fiscal_year: int) -> str:
    return f"{fiscal_year - 1}/{str(fiscal_year)[2:]}"

# Fiscal year -> raw report + its text dump
SOURCE_REPORTS = {
    2020: "Annual_book_2077",
    2021: "2020-21",
    2022: "Annual_Report_2021-22",
    2023: "NEA_Annual_Report_2023",
    2024: "2023-2024",
    2025: "2024-2025",
}
