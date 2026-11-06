"""Inspect raw NEA PDFs and (re)create page-tagged text dumps.

Reads data/raw (never modifies it). Existing text dumps are NOT overwritten
unless you pass --force, so the extracted layer stays stable.
"""
import sys
import pdfplumber
from config import RAW_DIR, EXTRACTED_DIR

FORCE = "--force" in sys.argv
EXTRACTED_DIR.mkdir(parents=True, exist_ok=True)

pdf_files = sorted(RAW_DIR.glob("*.pdf"))

if not pdf_files:
    print("No PDF files found in:", RAW_DIR)
else:
    print(f"Found {len(pdf_files)} PDF files:\n")

for pdf_path in pdf_files:
    print(f"\n{'='*60}")
    print(f"FILE: {pdf_path.name}")
    print(f"{'='*60}")

    with pdfplumber.open(pdf_path) as pdf:
        total_pages = len(pdf.pages)
        print(f"   Total Pages : {total_pages}")
        print(f"\n   Scanning first 10 pages for tables...")

        for i, page in enumerate(pdf.pages[:10]):
            tables = page.extract_tables()
            text = (page.extract_text() or "")[:100]
            print(f"\n   Page {i+1}:")
            print(f"     Tables found : {len(tables)}")
            print(f"     Text preview : {text.strip()}")

            if tables:
                for j, tbl in enumerate(tables):
                    rows = len(tbl)
                    cols = len(tbl[0]) if tbl else 0
                    print(f"     Table {j+1} shape: {rows} rows x {cols} cols")
                    print(f"     Header row   : {tbl[0]}")

    txt_out = EXTRACTED_DIR / (pdf_path.stem + "_text_dump.txt")
    if txt_out.exists() and not FORCE:
        print(f"\n   Text dump exists, skipped (use --force) -> {txt_out.name}")
        continue
    with pdfplumber.open(pdf_path) as pdf:
        with open(txt_out, "w", encoding="utf-8") as f:
            for i, page in enumerate(pdf.pages):
                f.write(f"\n\n{'='*40} PAGE {i+1} {'='*40}\n\n")
                f.write(page.extract_text() or "[NO TEXT]")

    print(f"\n   Text dump saved -> {txt_out.name}")

print("\nDone! Check data/extracted/ for text dumps.")
