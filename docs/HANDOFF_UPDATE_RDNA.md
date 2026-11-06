# HANDOFF UPDATE (compact; written in the terminal because the downloaded file was not available)
Read with the older handoff; its section 0 rules still apply (simple English, one ask at a time, PASS/FAIL/NOT VERIFIED, backup first, tiny patches with anchor checks, undo command each time).

## Done (seen in pasted output)
- C-022 added: conflicts now 22. Section 5 demand note cites 12,394 GWh (C-022).
- RDNA is a SEPARATE NDRRMA report, not the NEA annual report. Official PDF: https://ndrrma.gov.np/mediafiles/rasuwa/Rapid_Damage_and_Needs_Assessment_RDNA_Rasuwa-Bhotekoshi_Flood_2026.pdf
- Two local copies in data/raw (same text, different bytes, edition not proven). Checksums in data/RAW_CHECKSUMS.sha256 (9 lines); verify with: cd data/raw and sha256sum -c ../RAW_CHECKSUMS.sha256
- Verified in the PDF (text and page images): damage NPR 13,469.76 crore (Figure 18 printed p.92; Table 8 p.56; text p.89); losses 1,634.69 (Table 35 p.92); generation loss 2,730.48 GWh/yr (Table 35 p.92; 2,520 hydro + 210.48 solar); recovery needs 39,062.30 (Table 36 p.93; 105.00 early + 38,957.30 longer-term). Portfolio Table 34 p.91: 13 hydro projects 759.025 MW (7 operating 250.400; 6 under construction 508.625) + 5 solar 24.360 MW. PDF pp.50/51/52 = printed 88-89 / 90-91 / 92-93.
- These are ASSESSMENT ESTIMATES: not observed losses, not damaged MW. The energy chapter names no projects. Capacity factors and outage periods are not in the report text. Report cut-off 3 Sep 2026; finalised 10 Sep 2026.
- My calculations (analyst-derived, NOT stored in data): 250.4 MW x 8,760 h = 2,193.5 GWh maximum, so the 2,520 GWh hydro figure cannot be operating-only; solar 210.48 GWh = 98.6% of the 24.36 MW maximum; about NPR 5.88/kWh implied; recovery needs / damage = 2.90.
- Database: SRC-023 inserted (sources = 23). Plain dump for restore: data/archive/nea_nepal_state_for_github.sql
- data/cleaned/rdna_claims.csv (21 claims RDNA-01..21), script 15 loads it, Section 5 RDNA card built, tests 42 of 42 pass, 0 console errors. The LOOK of the card is NOT seen yet: take a screenshot.
- Fixed a stray line of x characters after </html> in dashboard/index.html.

## PROBLEM TO FIX FIRST: SRC-023 duplicates SRC-015
SRC-015 already exists (same title, Primary, publisher "NDRRMA and National Planning Commission (Nepal)", snapshot 2026-10-13, URL empty) and is cited by C-007, C-008, C-009 and C-015. I created SRC-023 without searching titles. Recommended fix: delete SRC-023; point the 21 claims at SRC-015; fill SRC-015's URL; sources back to 22 (Primary 10); script 15 sources 23 -> 22; fix test text; export JSON; rebuild. Every step: read-only preview, pg_dump backup, ONE transaction with RAISE EXCEPTION checks, undo command. Open check: is the National Planning Commission really a publisher (not seen in the pages read)?

## Also open
- Section 2 RDNA card shows "Total assessed 18 783.385" (operating plus construction added): review the wording.
- RDNA totals appear in Sections 2, 5 and 6: keep them consistent.
- Earlier "typos" were paste artefacts: grep the FILE before editing text.
- Not read: non-energy RDNA chapters. "23 energy assets affected" (PDF p.11) not added.
- EVT-002 database text says "flash flood from Tibet"; RDNA says ice-and-rock avalanche, upper Lhende Khola, about 20 km upstream of Rasuwagadhi (PDF pp.6, 11). Not yet a conflict.
- Do not change research-question statuses automatically.
- Older list still to do: Section 3, Section 4, C-018 note, carried-over conflicts, EVT-003 article, SRC-014 title, net-export chart, polish pass, README, requirements.

## Home setup
Git Bash, Python (pandas, openpyxl, pymupdf), Node 24, PostgreSQL 18 or newer, Edge. Restore: createdb -U postgres -h localhost nea_nepal, then psql -U postgres -h localhost -d nea_nepal -f data/archive/nea_nepal_state_for_github.sql. Copy the 9 PDFs into data/raw. Run node --test tests/*.js (expect 42 pass). student_visa_db must stay untouched.
END OF FILE
