--
-- PostgreSQL database dump
--

\restrict J6ks4rWCYTsmRt8HDPkhVNMY8YmrRq4nj1g0rQP1jtQ4zrR35gLkCFSV2yXBnh9

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.events (
    event_id character varying(20) NOT NULL,
    event_date date NOT NULL,
    description text NOT NULL,
    location character varying(200),
    notes text
);


--
-- Name: nea_annual_data; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nea_annual_data (
    id integer NOT NULL,
    fiscal_year integer NOT NULL,
    fiscal_year_label character varying(10) NOT NULL,
    nea_generation_gwh numeric(10,2),
    ipp_purchase_gwh numeric(10,2),
    total_production_gwh numeric(10,2),
    import_gwh numeric(10,2),
    export_gwh numeric(10,2),
    net_export_gwh numeric(10,2),
    total_available_gwh numeric(10,2),
    domestic_consumption_gwh numeric(10,2),
    peak_demand_mw numeric(10,2),
    peak_supply_mw numeric(10,2),
    ppa_signed_capacity_mw numeric(10,2),
    nea_revenue_npr_million numeric(12,2),
    nea_cost_npr_million numeric(12,2),
    nea_profit_npr_million numeric(12,2),
    nea_profit_margin_pct numeric(6,2),
    system_loss_pct numeric(6,2),
    consumers_million numeric(6,2),
    source_report character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: nea_annual_data_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nea_annual_data_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nea_annual_data_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nea_annual_data_id_seq OWNED BY public.nea_annual_data.id;


--
-- Name: nea_country_trade; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nea_country_trade (
    id integer NOT NULL,
    fiscal_year integer NOT NULL,
    country character varying(50) NOT NULL,
    trade_status character varying(20),
    trade_partner character varying(100),
    trade_mechanism character varying(100),
    export_gwh numeric(10,2),
    import_gwh numeric(10,2),
    export_revenue_npr_million numeric(12,2),
    import_cost_npr_million numeric(12,2),
    export_capacity_mw numeric(10,2),
    import_capacity_mw numeric(10,2),
    season_active character varying(50),
    volume_scope character varying(60),
    notes text,
    data_source character varying(100)
);


--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nea_country_trade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nea_country_trade_id_seq OWNED BY public.nea_country_trade.id;


--
-- Name: project_baseline; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_baseline (
    project_id character varying(20) NOT NULL,
    fiscal_year integer NOT NULL,
    generation_gwh numeric(10,2),
    source_id character varying(20),
    notes text
);


--
-- Name: project_evacuation; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_evacuation (
    project_id character varying(20) NOT NULL,
    asset_id character varying(20) NOT NULL,
    source_id character varying(20),
    notes text
);


--
-- Name: project_status_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.project_status_log (
    log_id integer NOT NULL,
    project_id character varying(20) NOT NULL,
    event_id character varying(20) NOT NULL,
    status_date date NOT NULL,
    physical_condition character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    generation_status character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    evacuation_status character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    restoration_status character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    affected_mw numeric(10,2),
    available_mw numeric(10,2),
    mw_definition text,
    source_id character varying(20),
    verified character varying(20) DEFAULT 'No'::character varying NOT NULL,
    snapshot_date date,
    notes text,
    CONSTRAINT project_status_log_evacuation_status_check CHECK (((evacuation_status)::text = ANY ((ARRAY['delivering'::character varying, 'constrained'::character varying, 'blocked'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT project_status_log_generation_status_check CHECK (((generation_status)::text = ANY ((ARRAY['operating'::character varying, 'partial'::character varying, 'offline'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT project_status_log_physical_condition_check CHECK (((physical_condition)::text = ANY ((ARRAY['undamaged'::character varying, 'damaged'::character varying, 'destroyed'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT project_status_log_restoration_status_check CHECK (((restoration_status)::text = ANY ((ARRAY['not_started'::character varying, 'under_restoration'::character varying, 'restored'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT project_status_log_verified_check CHECK (((verified)::text = ANY ((ARRAY['Yes'::character varying, 'No'::character varying, 'Partially verified'::character varying])::text[])))
);


--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.project_status_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.project_status_log_log_id_seq OWNED BY public.project_status_log.log_id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.projects (
    project_id character varying(20) NOT NULL,
    project_name character varying(150) NOT NULL,
    asset_type character varying(20) NOT NULL,
    capacity_mw numeric(10,2),
    basin character varying(100),
    district character varying(100),
    commissioned_date date,
    pre_flood_phase character varying(20) DEFAULT 'unknown'::character varying NOT NULL,
    owner_type character varying(20),
    notes text,
    CONSTRAINT projects_asset_type_check CHECK (((asset_type)::text = ANY ((ARRAY['hydro'::character varying, 'solar'::character varying, 'other'::character varying])::text[]))),
    CONSTRAINT projects_owner_type_check CHECK (((owner_type)::text = ANY ((ARRAY['NEA'::character varying, 'NEA_subsidiary'::character varying, 'IPP'::character varying, 'unknown'::character varying])::text[]))),
    CONSTRAINT projects_pre_flood_phase_check CHECK (((pre_flood_phase)::text = ANY ((ARRAY['operating'::character varying, 'under_construction'::character varying, 'unknown'::character varying])::text[])))
);


--
-- Name: sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sources (
    source_id character varying(20) NOT NULL,
    title text NOT NULL,
    publisher character varying(100),
    url text,
    source_type character varying(10) NOT NULL,
    source_date date,
    snapshot_date date,
    CONSTRAINT sources_source_type_check CHECK (((source_type)::text = ANY ((ARRAY['Primary'::character varying, 'Secondary'::character varying, 'Tertiary'::character varying])::text[])))
);


--
-- Name: transmission_assets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.transmission_assets (
    asset_id character varying(20) NOT NULL,
    asset_name character varying(150) NOT NULL,
    asset_type character varying(20) NOT NULL,
    voltage_kv numeric(6,1),
    capacity_mw numeric(10,2),
    notes text,
    CONSTRAINT transmission_assets_asset_type_check CHECK (((asset_type)::text = ANY ((ARRAY['line'::character varying, 'substation'::character varying, 'other'::character varying])::text[])))
);


--
-- Name: nea_annual_data id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_annual_data ALTER COLUMN id SET DEFAULT nextval('public.nea_annual_data_id_seq'::regclass);


--
-- Name: nea_country_trade id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_country_trade ALTER COLUMN id SET DEFAULT nextval('public.nea_country_trade_id_seq'::regclass);


--
-- Name: project_status_log log_id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_status_log ALTER COLUMN log_id SET DEFAULT nextval('public.project_status_log_log_id_seq'::regclass);


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.events (event_id, event_date, description, location, notes) FROM stdin;
EVT-002	2026-08-26	Bhotekoshi/Trishuli flash flood from Tibet: hydropower, solar and transmission damage	Rasuwa and Nuwakot districts	Date per SRC-004 (Bhadra 10 = 26 Aug 2026).
EVT-003	2026-09-28	Kaligandaki corridor transmission disruption (landslides)	Kaligandaki corridor	NOT VERIFIED: reported by Kathmandu Post on 28 Sep; article not opened. Separate event from EVT-002: never add MW across events.
EVT-001	2025-07-08	Lende River flood from Tibet merged with the Bhotekoshi (previous-year event)	Rasuwa	Damaged Rasuwagadhi area infrastructure. Possible baseline contamination: Rasuwagadhi had only recently resumed full operation before EVT-002 (SRC-001). Evidence (SRC-006, NEA FY2025/26 report PDF pp.130-131): Rasuwagadhi COD 2024-12-31 (BS 2081.09.16); this flood (24 Asar 2082) halted generation. Unit 1 partial generation resumed 2025-12-06 (20 Mangsir 2082), unit 2 on 2025-12-25 (10 Poush 2082), unit 3 on 2026-05-14 (31 Baisakh 2083). The report states full restoration and rehabilitation is planned within FY2083/84, so the plant was not fully restored before EVT-002 (2026-08-26). Design energy 613.875 GWh a year (dry months 84.318, wet months 529.557).
EVT-004	2026-10-11	Budhi Gandaki River flash flood: damage reported at four under-construction hydropower projects	Gorkha district (Budhi Gandaki)	[UNVERIFIED] Preliminary press reports published 11-12 Oct 2026 (SRC-016, SRC-017, SRC-018); exact time not recorded. Cause not established: reports describe a suspected landslide dam and their locations differ. Separate event from EVT-002 (Bhotekoshi/Trishuli, 26 Aug 2026) and EVT-003 (Kaligandaki corridor, 28 Sep 2026): never add their damage together. All four projects named were under construction, so no operating generation is recorded as lost by this event; no operating plant is named in the reports read (inference: operating plants were not assessed). Other projects carry the Budhigandaki name (DoED licences 414, 425 and 426, and the proposed 1,200 MW storage project); they are different projects. [UNVERIFIED][source review 2026-10-27] The four-project damage reports are repeated in My Republica (SRC-019, citing a preliminary IPPAN assessment), Khabarhub (SRC-020), SANDRP (SRC-021) and, as a tertiary pointer only, Wikipedia (SRC-022). All describe damage to camps, equipment, Bailey bridges and access roads at under-construction projects, and say the assessment is still preliminary. A total of 412.94 MW and a five-project list appear in earlier research notes but their origin is untraced - verification pending; not used in any calculation. Stored total stays 412.09 MW; the press total 412.41 MW is in C-019.
\.


--
-- Data for Name: nea_annual_data; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.nea_annual_data (id, fiscal_year, fiscal_year_label, nea_generation_gwh, ipp_purchase_gwh, total_production_gwh, import_gwh, export_gwh, net_export_gwh, total_available_gwh, domestic_consumption_gwh, peak_demand_mw, peak_supply_mw, ppa_signed_capacity_mw, nea_revenue_npr_million, nea_cost_npr_million, nea_profit_npr_million, nea_profit_margin_pct, system_loss_pct, consumers_million, source_report, created_at) FROM stdin;
1	2020	2019/20	3021.06	2991.00	6012.06	1729.00	107.00	-1622.00	7741.06	6422.00	1407.94	\N	5978.13	73760.00	62704.00	11056.00	14.99	15.27	4.22	Annual_book_2077.pdf	2026-09-30 14:42:25.482269
4	2023	2022/23	2930.00	7606.00	10536.00	1833.00	1346.00	-487.00	12369.00	9358.00	1870.46	2171.15	7758.00	100032.00	87639.00	12393.00	12.39	13.46	5.13	NEA_Annual_Report_2023.pdf	2026-09-30 14:42:25.482269
5	2024	2023/24	2911.00	9161.00	12072.00	1895.00	1946.00	51.00	13967.00	10243.00	2211.62	2467.00	10301.00	115798.00	102491.00	13307.00	11.49	12.73	5.46	2023-2024.pdf	2026-09-30 14:42:25.482269
6	2025	2024/25	2953.00	11006.00	13959.00	1681.00	2380.00	699.00	15640.00	11343.00	2409.00	2901.00	\N	125277.00	116210.00	9067.00	7.24	12.26	5.71	2024-2025.pdf	2026-09-30 14:42:25.482269
2	2021	2020/21	2810.74	3241.00	6051.74	2826.21	44.00	-2782.21	8877.95	7275.00	1482.00	1481.85	\N	76726.00	70718.00	6008.00	7.83	17.18	4.53	2020-21.pdf	2026-09-30 14:42:25.482269
3	2022	2021/22	3259.00	6262.00	9521.00	1543.00	493.00	-1050.00	11064.00	8870.00	1747.53	1963.98	\N	87120.00	70955.00	16165.00	18.55	15.38	4.77	Annual_Report_2021-22.pdf	2026-09-30 14:42:25.482269
7	2026	2025/26	\N	\N	\N	1171.00	3965.00	2794.00	18624.00	12376.00	2479.00	3226.00	\N	\N	\N	\N	\N	12.16	5.93	A Year In Review Annual Report 2025_2026_compressed.pdf (provisional, subject to audit)	2026-10-08 11:43:26.204825
\.


--
-- Data for Name: nea_country_trade; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.nea_country_trade (id, fiscal_year, country, trade_status, trade_partner, trade_mechanism, export_gwh, import_gwh, export_revenue_npr_million, import_cost_npr_million, export_capacity_mw, import_capacity_mw, season_active, volume_scope, notes, data_source) FROM stdin;
1	2020	India	Active	NVVN / PGCIL	Power Exchange / Bilateral	107.00	1729.00	\N	\N	\N	\N	Year Round	national_total_all_destinations_split_unverified	Import via Dhalkebar-Muzaffarpur 400kV line. Nepal net importer.	NEA Annual Report 2019/20
2	2021	India	Active	NVVN / PGCIL	Power Exchange / Bilateral	44.00	2826.21	\N	\N	\N	\N	Year Round	national_total_all_destinations_split_unverified	High import due to delay in Upper Tamakoshi commissioning. COVID impact on export.	NEA Annual Report 2020/21
3	2022	India	Active	NVVN / PGCIL / IEX	Power Exchange / Day-Ahead Market	493.00	1543.00	\N	\N	452.00	\N	Year Round	national_total_all_destinations_split_unverified	First country in South Asia to join Indian Energy Exchange (IEX). Export 452 MW from 10 hydro projects.	NEA Annual Report 2021/22
4	2023	India	Active	NVVN / PGCIL / IEX / PTC India	PEC / Day-Ahead / Medium Term Bilateral	1346.00	1833.00	\N	\N	\N	\N	Year Round	national_total_all_destinations_split_unverified	Medium term agreement: 200 MW to Haryana (May 2023). PTC India agreement 300 MW (June 2023). PEC tariff escalation 5.5%.	NEA Annual Report 2022/23
5	2024	India	Active	NVVN / PGCIL / IEX / PTC India	PEC / Day-Ahead / Medium Term Bilateral	1946.00	1895.00	\N	\N	\N	\N	Year Round	national_total_all_destinations_split_unverified	Nepal became NET EXPORTER for first time. Export exceeded import by 51 GWh. Butwal-Gorakhpur 400kV line under implementation.	NEA Annual Report 2023/24
6	2025	India	Active	NVVN / PGCIL / IEX / NTPC Vidhyut	PEC / Day-Ahead / Medium Term Bilateral	2380.00	1681.00	17471.00	\N	\N	\N	Year Round	national_total_all_destinations_split_unverified	Export revenue NRs 17,471 million (17.47 billion). Export up 22% from previous year. Nepal confirmed net exporter.	NEA Annual Report 2024/25
7	2020	Bangladesh	No Trade	\N	\N	\N	\N	\N	\N	\N	\N	\N	no_volume_reported	No electricity trade. Discussions at study stage only.	NEA Annual Report 2019/20
8	2021	Bangladesh	No Trade	\N	\N	\N	\N	\N	\N	\N	\N	\N	no_volume_reported	No electricity trade. COVID impacted cross-border discussions.	NEA Annual Report 2020/21
9	2022	Bangladesh	No Trade	BPDB (planned)	Tripartite (planned)	\N	\N	\N	\N	40.00	\N	\N	no_volume_reported	40 MW export planned via Indian grid. Baharampur-Bheramara 400kV HVDC link discussed.	NEA Annual Report 2021/22
10	2023	Bangladesh	Planned	BPDB / NVVN	Tripartite Agreement (finalizing)	\N	\N	\N	\N	40.00	\N	Monsoon (planned)	no_volume_reported	Tripartite agreement NEA+NVVN+BPDB in final stage. 40 MW via Baharampur-Bheramara HVDC. Wet season export planned.	NEA Annual Report 2022/23
11	2024	Bangladesh	Planned	BPDB / NVVN	Tripartite Agreement (signing soon)	\N	\N	\N	\N	40.00	\N	Monsoon (planned)	no_volume_reported	Agreement to be signed soon. 4th JSC meeting Nepal-Bangladesh agreed to form JV for Sunkoshi III (683 MW).	NEA Annual Report 2023/24
12	2025	Bangladesh	Active	BPDB / NVVN / India	Tripartite Agreement	\N	\N	\N	\N	40.00	\N	Monsoon only (June 15 - Oct 2025)	no_volume_reported	FIRST EVER export to Bangladesh. 40 MW started June 15 2025 via India transmission line. 5 month monsoon season. Tripartite signed October 2024.	NEA Annual Report 2024/25
13	2026	India	Active	\N	PEC / Day-Ahead / Medium Term Bilateral	\N	\N	\N	\N	1160.01	\N	Year Round	volume_not_loaded_conflicting_figures	Approved export quantum in MW (not flows): 1,160.01 MW = power exchange (DAM/RTM) 486.57 MW over 11 approvals via Dhalkebar-Muzaffarpur 400 kV + 70.00 MW over 2 approvals via Tanakpur-Mahendranagar 132 kV + medium-term bilateral 603.44 MW over 22 approvals (SRC-006 PDF p.109). Report total with Bangladesh: 1,200.01 MW, 37 approvals. Interim line limits from the 13th JWG/JSC, 14-15 Jul 2026 (PDF p.109), NOT additive to the quantum: Butwal-Gorakhpur run at 220 kV, import 130 MW and export 200 MW; Dhalkebar-Muzaffarpur plus Dhalkebar-Sitamarhi combined, export 1,650 MW and import 1,400 MW. The report calls both new lines on the verge of completion. Energy: PDF p.55 says about 3,962 GWh sold to India; PDF p.54 total exported 3,938 GWh; nea_annual_data holds 3,965 (conflict open, see known_conflicts). export_gwh left NULL. Agreements described on PDF pp.15 and 108: 2 x 200 MW to Haryana Discoms for 5 years; up to 200 MW to Bihar State Power Holding Co. for 3 years (extendable to 5). All figures provisional, subject to audit.	NEA Annual Report 2025/26 (provisional)
14	2026	Bangladesh	Active	\N	Medium Term Bilateral Agreement (Nepal-Bangladesh)	\N	\N	\N	\N	40.00	\N	Round-the-clock from June (year inferred)	no_volume_reported	Approved quantum 40.00 MW over 2 approvals via Dhalkebar-Muzaffarpur 400 kV (SRC-006 PDF p.109). PDF p.55: a round-the-clock quantum of 40 MW is exported to Bangladesh starting June. The year is not printed; my reading is June 2026, after the monsoon-only start on 15 Jun 2025 recorded for FY2024/25. Earlier years labelled the arrangement tripartite; the FY2025/26 table calls it a medium-term bilateral agreement. No Bangladesh volume stated. Provisional, subject to audit.	NEA Annual Report 2025/26 (provisional)
\.


--
-- Data for Name: project_baseline; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.project_baseline (project_id, fiscal_year, generation_gwh, source_id, notes) FROM stdin;
PRJ-009	2022	432.83	SRC-007	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv. Unusually low months (under half the median, GWh): Shrawan 13.5. Cause not established.
PRJ-010	2022	137.11	SRC-007	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-011	2022	98.39	SRC-007	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-009	2024	427.06	SRC-008	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-010	2024	117.04	SRC-008	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-011	2024	86.83	SRC-008	Dump page 201, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-009	2025	355.97	SRC-009	Dump page 155, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv. Unusually low months (under half the median, GWh): Aswin 6.0, Bhadra 4.2. Cause not established.
PRJ-010	2025	97.70	SRC-009	Dump page 155, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-011	2025	76.36	SRC-009	Dump page 155, appendix generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv. Unusually low months (under half the median, GWh): Aswin 3.5, Bhadra 3.4. Cause not established.
PRJ-011	2020	92.05	SRC-010	PDF p.44, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-010	2020	128.97	SRC-010	PDF p.44, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-009	2020	407.55	SRC-010	PDF p.44, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv. Unusually low months (under half the median, GWh): Shrawan 10.4. The FY2020/21 report says the plant was commissioned in July 2019, which fits a start-up first month.
PRJ-011	2021	85.43	SRC-011	PDF p.45, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-010	2021	121.21	SRC-011	PDF p.45, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv.
PRJ-009	2021	314.77	SRC-011	PDF p.45, monthly generation table. Annual total equals the sum of the 12 monthly values (check passed). Monthly values in data/cleaned/plant_generation_monthly.csv. In this table the name and abbreviation columns disagree for three rows; this row is taken by abbreviation UT3A (printed beside the name 'Kulekhani II'). Confirmed by the report text (314.767 GWh) and by the FY2021/22 report (432.832 GWh was 37.51% more than the previous year). Name-matching would give 195.16 GWh, which is Kulekhani I.
PRJ-011	2023	88.91	SRC-008	Annual total only (no monthly table for FY2022/23). Taken from the FY2023/24 report comparison table, PDF p.200 (SRC-008), as the previous-year column. Cross-checks: the table's printed change of -2.34% reproduces from FY2023/24; the FY2022/23 report text gives the same figure to lower precision.
PRJ-010	2023	123.15	SRC-008	Annual total only (no monthly table for FY2022/23). Taken from the FY2023/24 report comparison table, PDF p.200 (SRC-008), as the previous-year column. Cross-checks: the table's printed change of -4.96% reproduces from FY2023/24; the FY2022/23 report text gives the same figure to lower precision.
PRJ-009	2023	437.12	SRC-008	Annual total only (no monthly table for FY2022/23). Taken from the FY2023/24 report comparison table, PDF p.200 (SRC-008), as the previous-year column. Cross-checks: the table's printed change of -2.3% reproduces from FY2023/24; the FY2022/23 report text gives the same figure to lower precision.
PRJ-009	2026	391.90	SRC-006	p.16: design 489.76 GWh; 80.02% of design; up 10.09% on previous year; 106.38% of target. Report mentions restoring gates after an earlier flash flood (undated; possibly EVT-001). Monthly table: PDF p.186 (printed p.176); 12 months add to the total and the 21 plant rows add to the report's hydro total. Report marks FY2025/26 figures provisional (subject to audit). Months under half the median (GWh): Shrawan 0.0. Cause not established by the report. The report describes the 8 July 2025 GLOF flash flood for Rasuwagadhi (PDF p.130-131); for this plant it says only that radial-gate hydraulics were restored 'after the flash flood' (PDF p.26, undated).
PRJ-010	2026	80.35	SRC-006	p.18: design 163 GWh; 49.29% of design; down 17.76% on previous year; 72.61% of target. Report lists repairs to a landslide-damaged bypass canal and flood deposit clearance: this year may already be affected by earlier events. Monthly table: PDF p.186 (printed p.176); 12 months add to the total and the 21 plant rows add to the report's hydro total. Report marks FY2025/26 figures provisional (subject to audit). Months under half the median (GWh): Shrawan 2.7. Cause not established by the report.
PRJ-011	2026	59.53	SRC-006	p.19: design 114 GWh; 52.22% of design; down 22.04% on previous year; 98.75% of target. Monthly table: PDF p.186 (printed p.176); 12 months add to the total and the 21 plant rows add to the report's hydro total. Report marks FY2025/26 figures provisional (subject to audit). Months under half the median (GWh): Shrawan 1.7. Cause not established by the report.
\.


--
-- Data for Name: project_evacuation; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.project_evacuation (project_id, asset_id, source_id, notes) FROM stdin;
PRJ-001	TA-001	SRC-006	Stated: PDF p.130, line up to Chilime Hub.
PRJ-009	TA-006	SRC-006	Stated: plant summary PDF p.187 (printed p.177), power transmitted to Trishuli 3B Hub - 2 Ckt.
PRJ-010	TA-002	SRC-006	Plant summary p.187 says Chilime-1 Ckt; mapping to this line by name and circuit count is an inference.
PRJ-010	TA-003	SRC-006	Plant summary p.187 says Devighat-1 Ckt; mapping by name and circuit count is an inference.
PRJ-010	TA-004	SRC-006	Plant summary p.187 says Balaju-2 Ckt; mapping by name and circuit count is an inference.
PRJ-011	TA-003	SRC-006	Plant summary p.187 says Trishuli-1 Ckt; mapping by name and circuit count is an inference.
PRJ-011	TA-005	SRC-006	Plant summary p.187 says Chapali-2 Ckt; grid table lists Devighat-Okhaltar and Okhaltar-Chapali, so the link is an inference.
PRJ-007	TA-002	SRC-006	Inference: line is named Chilime P/S - Trishuli P/S in the grid table; the report does not state it as this plant evacuation line.
PRJ-003	TA-008	SRC-006	Stated: PDF p.119, the Chilime Hub then connects to the national grid through the Chilime-Trishuli 220 kV line. Mapping that line to TA-008 is by name (inference).
PRJ-004	TA-009	SRC-006	Stated: PDF p.119, the SJCL line ends at the Chilime Hub substation.
PRJ-003	TA-012	SRC-006	Stated: PDF p.119, power from both Sanjen plants goes through the SJCL 132 kV line to the Chilime Hub substation.
PRJ-004	TA-012	SRC-006	Stated: PDF p.119, power from both Sanjen plants goes through the SJCL 132 kV line to the Chilime Hub substation.
PRJ-003	TA-009	SRC-006	Stated: PDF p.119, the SJCL line ends at the Chilime Hub substation.
PRJ-004	TA-008	SRC-006	Stated: PDF p.119, the Chilime Hub then connects to the national grid through the Chilime-Trishuli 220 kV line. Mapping that line to TA-008 is by name (inference).
\.


--
-- Data for Name: project_status_log; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.project_status_log (log_id, project_id, event_id, status_date, physical_condition, generation_status, evacuation_status, restoration_status, affected_mw, available_mw, mw_definition, source_id, verified, snapshot_date, notes) FROM stdin;
1	PRJ-001	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	111.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
2	PRJ-002	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	78.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
3	PRJ-003	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	14.80	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
4	PRJ-004	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	42.50	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
5	PRJ-005	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	5.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
6	PRJ-006	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	20.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
7	PRJ-007	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	22.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
8	PRJ-008	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	14.80	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
9	PRJ-009	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	60.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
10	PRJ-010	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	24.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
11	PRJ-011	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	14.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
12	PRJ-012	EVT-002	2026-08-27	unknown	unknown	unknown	unknown	25.00	\N	Ministry list: operational project affected. Installed MW, NOT unavailable MW	SRC-001	No	2026-09-30	List does not say what state each project is in, so all four status columns are unknown.
13	PRJ-001	EVT-002	2026-09-07	destroyed	unknown	unknown	unknown	\N	\N	\N	SRC-002	No	2026-09-30	Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.
14	PRJ-006	EVT-002	2026-09-07	destroyed	unknown	unknown	unknown	\N	\N	\N	SRC-002	No	2026-09-30	Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.
15	PRJ-007	EVT-002	2026-09-07	destroyed	unknown	unknown	unknown	\N	\N	\N	SRC-002	No	2026-09-30	Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.
16	PRJ-009	EVT-002	2026-09-07	destroyed	unknown	unknown	unknown	\N	\N	\N	SRC-002	No	2026-09-30	Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.
17	PRJ-010	EVT-002	2026-09-07	destroyed	unknown	unknown	unknown	\N	\N	\N	SRC-002	No	2026-09-30	Single secondary source describes this project as completely destroyed; SRC-004 (1 Sep) uses the word damaged for the same group.
18	PRJ-002	EVT-002	2026-09-02	unknown	unknown	blocked	unknown	\N	\N	\N	SRC-003	No	2026-09-30	Kept in isolated mode because transmission lines were damaged (SRC-003). blocked = not delivering to the national grid. SRC-004 (1 Sep) says isolated operation was still being prepared. Generation status not stated.
19	PRJ-003	EVT-002	2026-09-02	unknown	unknown	blocked	unknown	\N	\N	\N	SRC-003	No	2026-09-30	Kept in isolated mode because transmission lines were damaged (SRC-003). blocked = not delivering to the national grid. SRC-004 (1 Sep) says isolated operation was still being prepared. Generation status not stated.
20	PRJ-004	EVT-002	2026-09-02	unknown	unknown	blocked	unknown	\N	\N	\N	SRC-003	No	2026-09-30	Kept in isolated mode because transmission lines were damaged (SRC-003). blocked = not delivering to the national grid. SRC-004 (1 Sep) says isolated operation was still being prepared. Generation status not stated.
21	PRJ-019	EVT-004	2026-10-11	damaged	unknown	unknown	unknown	341.00	\N	Licensed capacity (DoED) of an under-construction project named as damaged in preliminary press reports. Not generation lost, not available capacity.	SRC-017	No	2026-10-13	Press: main camp and machinery swept away. Condition of the dam and other main works not stated. Under construction: no pre-event generation.
22	PRJ-020	EVT-004	2026-10-11	damaged	unknown	unknown	unknown	24.50	\N	Licensed capacity (DoED) of an under-construction project named as damaged in preliminary press reports. Not generation lost, not available capacity.	SRC-017	No	2026-10-13	Press: camp buildings and a Bailey bridge damaged. Condition of main works not stated. Under construction: no pre-event generation.
23	PRJ-021	EVT-004	2026-10-11	damaged	unknown	unknown	unknown	30.59	\N	Licensed capacity (DoED) of an under-construction project named as damaged in preliminary press reports. Not generation lost, not available capacity.	SRC-017	No	2026-10-13	Press: Bailey bridge and materials damaged. Capacity conflict recorded on the project. Under construction: no pre-event generation. [UNVERIFIED][2026-10-27] Yaru Khola capacity in the sources read: 30.59 (SRC-019, SRC-021 text, SRC-022), 30.91 (SRC-020), 30.49 (SRC-021 table, probable typo). Stored 30.59 unchanged; see C-018.
24	PRJ-022	EVT-004	2026-10-11	damaged	unknown	unknown	unknown	16.00	\N	Licensed capacity (DoED) of an under-construction project named as damaged in preliminary press reports. Not generation lost, not available capacity.	SRC-017	No	2026-10-13	Press: access road and bridge damaged. Condition of main works not stated. Under construction: no pre-event generation. [UNVERIFIED][2026-10-27] My Republica (SRC-019) lists a Bailey bridge, the access road and a bridge to the site; Khabarhub (SRC-020) lists the access road and the bridge to the site only.
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.projects (project_id, project_name, asset_type, capacity_mw, basin, district, commissioned_date, pre_flood_phase, owner_type, notes) FROM stdin;
PRJ-009	Upper Trishuli 3A	hydro	60.00	\N	Nuwakot	\N	operating	NEA	Ministry list (SRC-001) says Nuwakot; Wikipedia list (SRC-005) says Rasuwa. District unresolved. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 60 MW, year 2019, design generation 489.8 GWh; 2 units of 30 MW (PDF p.26). FY2020/21 report: commissioned July 2019. District not stated there. [DoED review 2026-10-13] DoED operating list (SRC-012, licence 43): Upper Trishuli 3A 60.000 MW, NEA, locality printed as Dandagoun, Laharepouwa, Thulogoun, Ramche (Rasuwa), COD BS 2076-05-13. Stored district Nuwakot kept (press); conflict logged. commissioned_date left NULL.
PRJ-001	Rasuwagadhi	hydro	111.00	\N	Rasuwa	2024-12-31	operating	NEA_subsidiary	Ministry list (SRC-001). Wikipedia list (SRC-005): commissioned 2024. Recently back at full operation after EVT-001. Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, Rasuwa, COD BS 2081.09.16. NEA FY2025/26 report PDF p.130: design energy 613.875 GWh a year (dry 84.318, wet 529.557); line 10.0 km 132 kV double circuit to Chilime Hub. NEA list check (SRC-006 appendix PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, PPA BS 2068.07.28, COD BS 2081.09.16 = 2024-12-31. Matches stored capacity and date.
PRJ-002	Salasungi Sanjen	hydro	78.00	\N	Rasuwa	2025-02-11	operating	IPP	Ministry list (SRC-001). NEA FY2025/26 report appendix (PDF p.191): listed as Sanjen Khola, Salasungi Power Limited, 78,000 kW, Rasuwa, IPP table, COD BS 2081.10.29. Matched to this row by developer name and capacity. NEA list check (SRC-006 appendix PDF p.191): project name in list is Sanjen Khola, developer Salasungi Power Limited, 78,000 kW, COD BS 2081.10.29 = 2025-02-11. Matches stored capacity and date.
PRJ-003	Upper Sanjen	hydro	14.80	\N	Rasuwa	2023-10-08	operating	NEA_subsidiary	Ministry list (SRC-001). Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Co. Limited, 14,800 kW, Rasuwa, COD BS 2080.06.21. NEA list check (SRC-006 appendix PDF p.188): Upper Sanjen, 14,800 kW, COD BS 2080.06.21 = 2023-10-08. Matches. Status log affected_mw 14.80 for PRJ-008 is NOT this plant.
PRJ-004	Sanjen	hydro	42.50	\N	Rasuwa	2024-12-16	operating	NEA_subsidiary	Ministry list (SRC-001). Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Company Limited, 42,500 kW, Rasuwa, COD BS 2081.09.01. NEA list check (SRC-006 appendix PDF p.188): Sanjen, 42,500 kW, COD BS 2081.09.01 = 2024-12-16. Matches stored capacity and date.
PRJ-011	Devighat	hydro	15.00	\N	Nuwakot	\N	operating	NEA	Ministry list 14 MW; SRC-004 gives 14.1 MW. Installed 15 MW (3 x 5 MW) per SRC-006 p.19; ministry list said 14 MW, SRC-004 and Wikipedia 14.1 MW. The status log keeps the ministry figure in affected_mw. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 15.1 MW (seed 15.00), year 1984, design generation 113.0 GWh. District not stated there. [DoED review 2026-10-13] DoED operating list (SRC-012, licence 1_gtd): Devighat 14.100 MW, NEA, Nuwakot, COD BS 2041-08-16. Stored 15.00 and NEA report p.177 (15.1) kept; status log holds 14.00 (press). Proposed correction to 14.10 NOT applied.
PRJ-012	Saurya solar (name unconfirmed)	solar	25.00	\N	Nuwakot	\N	operating	unknown	Ministry list gives only a 25 MW solar project in Nuwakot (SRC-001). SRC-004 names Saurya (25 MW): identification inferred, unverified. UNMATCHED in NEA FY2025/26 report appendix: no operating solar project in Nuwakot and no single 25 MW solar plant. The list has Dharamnagar Solar Farm 10 MW and Dharamnagar Solar Farm-I 15 MW (Pashupati Renewables, Kapilvastu). Name and district unverified; check RDNA. [DoED review 2026-10-13] POSSIBLE identity, NOT confirmed: DoED solar list (SRC-013) shows five NEA solar farms in Nuwakot: Block 1 5.1 MW, Block 2 8.3 MW, Block 4 1.37 MW, Grid Tied Solar Farm 3.09 MW, Block 5 6.5 MW (Charghare/Bidur), COD BS 2079-10-01. Total 24.36 MW = RDNA Table 34 solar (SRC-015: 5 plants, 24.36 MW). This record (25 MW, owner unknown) may be those five combined (press: 25 MW Nuwakot Solar Power Project, SRC-004). Record kept as is; not split or replaced. The NEA PPA appendix CSV lists no Nuwakot solar, consistent with NEA ownership (my inference).
PRJ-010	Trishuli	hydro	24.00	\N	Nuwakot	\N	operating	NEA	Ministry list (SRC-001). Wikipedia list: commissioned 1967. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 24 MW, year 1967, design generation 163.8 GWh. District not stated there.
PRJ-005	Mailung Khola	hydro	5.00	\N	Rasuwa	2014-07-03	operating	IPP	Ministry list (SRC-001). NEA FY2025/26 report appendix (PDF p.189): Mailung Khola Hydro Power Company, 5,000 kW, Rasuwa, IPP table, COD BS 2071.03.19. NEA list check (SRC-006 appendix PDF p.189): Mailung Khola, 5,000 kW, COD BS 2071.03.19 = 2014-07-03. Matches stored capacity and date.
PRJ-008	Upper Mailung	hydro	14.30	\N	Rasuwa	2024-02-11	operating	IPP	CONFLICT: the ministry list (SRC-001) shows it among the 12 operational projects (14.8 MW) AND among the 15 under-construction projects. Wikipedia list (SRC-005) gives 14.3 MW, commissioned 2024. Phase left unknown. NEA FY2025/26 report appendix (PDF p.191): Mathillo Mailung Khola Jalbidhyut Ltd., Upper Mailung, 14,300 kW, Rasuwa, operating, COD BS 2080.10.28. Previous seed values: capacity 14.80 (equals Upper Sanjen), district blank, phase unknown. A different project, Upper Mailung A, 6,420 kW, Energy Engineering Pvt. Ltd., is under construction (PDF p.194). Verify in RDNA. NEA list check (SRC-006 appendix PDF p.191): printed as Upper Mailun, 14,300 kW, COD BS 2080.10.28 = 2024-02-11. Matches stored capacity and date. Status log 14.80 MW is not from the NEA list.
PRJ-013	Upper Trishuli-1	hydro	216.00	\N	Rasuwa	\N	under_construction	IPP	[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 209, issued BS 2074-07-23, Nepal Water & Energy Development Co. P. Ltd, Dhunche/Haku (Rasuwa), 216.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only; the RDNA names no projects. No damage state, status date, restoration date or unavailable MW recorded.
PRJ-014	Rasuwa Bhotekoshi	hydro	120.00	\N	Rasuwa	\N	under_construction	IPP	[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 223, issued BS 2074-11-03, Langtang Bhotekosi Hydropower Company Pvt. Ltd, Thuman/Briddhim/Goljung (Rasuwa), 120.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.
PRJ-015	Super Trishuli	hydro	100.00	\N	\N	\N	under_construction	IPP	[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 218, issued BS 2074-10-02, Blue Energy Ltd., 100.000 MW. DoED prints no district, so district is NULL. Not named in SRC-001 to SRC-004; listed as under construction in a myRepublica article whose text says July 11 (date unclear; article not in sources table). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. Affected status NOT established.
PRJ-016	Upper Trishuli 3B	hydro	37.00	\N	Nuwakot	\N	under_construction	NEA	[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 104, issued BS 2070-04-27, promoter Nepal Electricity Authority, Manakamana (Nuwakot), 37.000 MW. Named as affected in press (SRC-004). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.
PRJ-017	Middle Trishuli Ganga	hydro	15.63	\N	Nuwakot	\N	under_construction	IPP	[UNVERIFIED][DoED review 2026-10-13] Proposed from DoED construction-licence list (SRC-014): licence 379, issued BS 2079-05-17, Perfect Energy Development Pvt. Ltd, Gerkhu/Manakamana/Tupche (Nuwakot). Exact capacity 15.625 MW (DoED; NEA list SRC-006 PDF p.197); stored as 15.63 because capacity_mw is numeric(10,2). Named as affected in press (SRC-004, which prints 15.5). Candidate member of the RDNA Table 34 under-construction set (SRC-015) by arithmetic match only. No damage state or restoration data recorded.
PRJ-018	Upper Tadi	hydro	11.00	\N	Nuwakot	2025-07-28	operating	IPP	[UNVERIFIED][DoED review 2026-10-13] Operating per DoED operating list (SRC-012): licence 144, Surya Kund Hydro Electric Pvt. Ltd, Rautbesi (Nuwakot), 11.000 MW, COD BS 2082-04-12. NEA list (SRC-006 PDF p.192) shows the same capacity and COD BS 2082.04.12; AD date 2025-07-28 is an approximate conversion by script 09. Not named in any press list reviewed and not in either arithmetic set. NOT classified as damaged or as excluded from the RDNA; membership unknown.
PRJ-006	Langtang Khola	hydro	20.00	\N	Rasuwa	\N	under_construction	IPP	Ministry list (SRC-001). Described as private in SRC-002. CONFLICT: NEA FY2025/26 report appendix (PDF p.198) lists Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, Rasuwa, in the UNDER CONSTRUCTION table as of FY 2082/83 (PPA BS 2072.09.29, no COD). Seed says operating. Check RDNA Table 34. CONFLICT, NEA list check (SRC-006 appendix PDF p.198): Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, PPA BS 2072.09.29, listed under CONSTRUCTION with no COD. pre_flood_phase left as operating until RDNA Table 34 is checked. [DoED review 2026-10-13] PHASE CHANGE operating -> under_construction (supersedes the earlier line saying operating was left unchanged). Old value came from the 27 Aug energy-ministry list (SRC-001), which did not state phase. New basis: DoED construction-licence list (SRC-014): licence 142, Langtang Khola Small Hydropower Project, Multi Energy Development Pvt. Ltd, 20.000 MW, Syafru (Rasuwa); not on DoED operating list (SRC-012); NEA list (SRC-006 PDF p.198) also under construction, no COD. Press (SRC-004) says testing phase: UNVERIFIED, kept as a separate claim, not evidence of operation. RDNA Table 34 sums are consistent with this but do not name the project.
PRJ-007	Chilime	hydro	22.10	\N	Rasuwa	2003-08-25	operating	NEA_subsidiary	Ministry list 22 MW. Kathmandu Post 2 Sep gives 22.1 MW (SRC-003). SRC-006 p.5 gives 22.1 MW and names Chilime Hydropower Company as NEA's first subsidiary; ministry list gave 22 MW. NEA FY2025/26 report appendix (PDF p.188): Chilime Hydro Power Company Ltd., 22,100 kW, Rasuwa, COD BS 2060.05.08. NEA list check (SRC-006 appendix PDF p.188): Chilime, 22,100 kW, COD BS 2060.05.08 = 2003-08-25. Matches stored capacity and date. Status log has 22.00 MW. [DoED review 2026-10-13] DoED operating list (SRC-012, licence 6): Chilime 22.000 MW, COD BS 2065-05-07. NEA list (SRC-006 PDF p.188): 22,100 kW, COD BS 2060.05.08. Stored 22.10 and 2003-08-25 kept; conflict logged. Proposed capacity correction to 22.00 NOT applied.
PRJ-019	Budhi Gandaki HEP (Times Energy)	hydro	341.00	\N	Gorkha	\N	under_construction	IPP	[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 420, issued BS 2080-09-05, Times Energy Ltd., Kerauja, Sirdibas, Uiya (Gorkha), 341.000 MW, river Budhi Gandaki. Press (SRC-017): main camp and machinery swept away. Not found in the NEA appendix by name search for budhi (only different projects: Naulo Nepal Ka and Kha, and Super Machha Khola 4.6 MW). NOT the 1,200 MW storage project, NOT Naulo Nepal Ka (DoED licence 426, 130 MW) or Kha (licence 425, 260 MW), NOT Super Machha Khola (licence 414). owner_type IPP is inferred from the promoter name.
PRJ-020	Dobhan Khola HEP	hydro	24.50	\N	Gorkha	\N	under_construction	IPP	[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 429, issued BS 2080-12-05, Dobhan Khola Hydropower Ltd, Kerauja (Gorkha), 24.500 MW. NEA appendix (SRC-006 PDF p.198) lists Dovan khola, developer Upper Syange Hydropower Limited, 24,500 kW, PPA BS 2080.03.07, under construction: developer name differs, same capacity and district (likely the same project, my inference). Press (SRC-017): camp buildings and a Bailey bridge damaged. Different from Junbeshi 5.2 MW (Dobhan Hydropower, Solukhumbu).
PRJ-021	Yaru Khola HEP	hydro	30.59	\N	Gorkha	\N	under_construction	IPP	[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 435, issued BS 2080-12-25, Yaru Hydropower Pvt. Ltd, Kerauja, Sirdibas, Uiya (Gorkha), 30.590 MW (stored value). CAPACITY CONFLICT: NEA appendix (SRC-006 PDF p.198) 30,542 kW, PPA BS 2079.12.17; Peoples Review (SRC-016) 30.91 MW. Press (SRC-017): Bailey bridge and materials damaged.
PRJ-022	Machhe Khola HEP	hydro	16.00	\N	Gorkha	\N	under_construction	IPP	[UNVERIFIED][Budhi Gandaki review 2026-10-13] DoED construction-licence list (SRC-014): licence 428, issued BS 2080-11-04, Water Energy Development Pvt. Ltd., Lapu, Gumda, Uiya (Gorkha), 16.000 MW. NEA appendix (SRC-006 PDF p.198) lists Machha Khola, 16,000 kW, PPA BS 2080.03.04, under construction. Press (SRC-017): access road and bridge damaged. Different from Upper Machha Khola Small 4.55 MW (operating) and Super Machha Khola 4.6 MW.
\.


--
-- Data for Name: sources; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.sources (source_id, title, publisher, url, source_type, source_date, snapshot_date) FROM stdin;
SRC-001	Massive flood in Bhotekoshi and Trishuli puts 900 MW of power projects at risk	myRepublica	https://myrepublica.nagariknetwork.com/news/floods-in-the-bhotekoshi-and-trishuli-put-900-mw-of-power-projects-in-risk-17-10.html	Secondary	2026-08-27	2026-09-30
SRC-002	BHOTEKOSHI FLOOD: Blow To Hydropower Sector	Spotlight Nepal	https://www.spotlightnepal.com/2026/09/07/bhotekoshi-flood-blow-hydropower-sector/	Secondary	2026-09-07	2026-09-30
SRC-003	Bhotekoshi floods halt Nepal's electricity exports to Bangladesh	The Kathmandu Post	https://kathmandupost.com/money/2026/09/02/bhotekoshi-floods-halt-nepal-s-electricity-exports-to-bangladesh	Secondary	2026-09-02	2026-09-30
SRC-004	Floods in Bhotekoshi Damage 12 Hydropower Projects	Spotlight Nepal	https://www.spotlightnepal.com/2026/09/01/floods-bhotekoshi-damage-12-hydropower-projects/	Secondary	2026-09-01	2026-09-30
SRC-005	List of power stations in Nepal	Wikipedia	https://en.wikipedia.org/wiki/List_of_power_stations_in_Nepal	Tertiary	\N	2026-09-30
SRC-006	NEA Annual Report 2025/26 (A Year in Review)	Nepal Electricity Authority	https://nea.org.np/uploads/shares/td_tender/A%20Year%20In%20Review%20Annual%20Report%202025_2026_compressed.pdf	Primary	2026-08-18	2026-09-30
SRC-007	NEA Annual Report FY2021/22	Nepal Electricity Authority	data/raw/Annual_Report_2021-22.pdf	Primary	\N	2026-10-01
SRC-008	NEA Annual Report FY2023/24	Nepal Electricity Authority	data/raw/2023-2024.pdf	Primary	\N	2026-10-01
SRC-009	NEA Annual Report FY2024/25	Nepal Electricity Authority	data/raw/2024-2025.pdf	Primary	\N	2026-10-01
SRC-010	NEA Annual Report FY2019/20 (A Year in Review)	Nepal Electricity Authority	data/raw/Annual_book_2077.pdf	Primary	\N	2026-10-01
SRC-011	NEA Annual Report FY2020/21	Nepal Electricity Authority	data/raw/2020-21.pdf	Primary	\N	2026-10-01
SRC-012	DoED Power Plants: Hydro (More than 1MW), operating list, page updated 2 Oct 2026 - read via web fetch, unverified	Department of Electricity Development (DoED)	https://doed.gov.np/pages/powerplantsmorethan1/	Primary	2026-10-02	2026-10-13
SRC-013	DoED Power Plants: Solar, operating list, page updated 2 Oct 2026 - read via web fetch, unverified	Department of Electricity Development (DoED)	https://doed.gov.np/pages/powerplantssolar/	Primary	2026-10-02	2026-10-13
SRC-014	DoED Construction Licence: Hydro (More than 1MW), page updated 2 Oct 2026 - read via web fetch to row 201 only, unverified	Department of Electricity Development (DoED)	https://doed.gov.np/pages/clhydromorethan1/	Primary	2026-10-02	2026-10-13
SRC-015	Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026, cut-off 3 Sep 2026	NDRRMA and National Planning Commission (Nepal)	\N	Primary	\N	2026-10-13
SRC-016	Budhigandaki flood damages four hydropower projects totalling 412.41 MW (Peoples Review, 11 Oct 2026) - read as search excerpt only, unverified	Peoples Review	https://peoplesreview.com.np/2026/10/11/budhigandaki-flood-damages-four-hydropower-projects-totalling-412-41-mw/	Secondary	2026-10-11	2026-10-13
SRC-017	Budhigandaki floods wreak havoc on 4 under-construction hydropower projects totalling 413 MW (Clickmandu, October 2026) - page fetched, unverified	Clickmandu	https://english.clickmandu.com/2026/10/12009/	Secondary	\N	2026-10-13
SRC-018	What we know so far about the damage caused by Budhi Gandaki floods (Kathmandu Post, 11 Oct 2026) - read as search excerpt only, unverified	The Kathmandu Post	https://kathmandupost.com/gandaki-province/2026/10/11/what-we-know-so-far-about-the-damage-caused-by-budhi-gandaki-floods	Secondary	2026-10-11	2026-10-13
SRC-019	Budhigandaki flood damages four hydropower projects, sweeps away camp and equipment (myRepublica, 11 Oct 2026) - page read in full, cites a preliminary IPPAN assessment, unverified	myRepublica (Nagarik Network)	https://myrepublica.nagariknetwork.com/news/budhigandaki-flood-damages-four-hydropower-projects-sweeps-away-camp-and-eq-80-70.html	Secondary	2026-10-11	2026-10-27
SRC-020	Budhigandaki flood damages four hydropower projects (Khabarhub, 11 Oct 2026, 12:07 PM) - page read in full, gives Yaru Khola 30.91 MW, unverified	Khabarhub	https://english.khabarhub.com/2026/11/571563/	Secondary	2026-10-11	2026-10-27
SRC-021	Oct. 2026: Budhi Gandaki Flashflood Affects Four Hydro Projects in Nepal (SANDRP, 13 Oct 2026, updated 15 Oct) - page read in full; text says 412.09 MW, its table says Yaru Khola 30.49 MW (probable typo), unverified	SANDRP	https://sandrp.in/2026/10/13/oct-2026-budhi-gandaki-flashflood-affects-four-hydro-projects-in-nepal/	Secondary	2026-10-13	2026-10-27
SRC-022	2026 Budhi Gandaki flood (Wikipedia) - accessed 2026-10-27, revision ID not captured; pointer only, no figure taken from it, unverified	Wikipedia	https://en.wikipedia.org/wiki/2026_Budhi_Gandaki_flood	Tertiary	\N	2026-10-27
SRC-023	Rapid Damage and Needs Assessment (RDNA), Rasuwa-Bhotekoshi Flood 2026 (NDRRMA, September 2026; sector cut-off 3 Sep 2026; estimates not independently verified)	National Disaster Risk Reduction and Management Authority (NDRRMA)	https://ndrrma.gov.np/mediafiles/rasuwa/Rapid_Damage_and_Needs_Assessment_RDNA_Rasuwa-Bhotekoshi_Flood_2026.pdf	Primary	\N	2026-11-05
\.


--
-- Data for Name: transmission_assets; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.transmission_assets (asset_id, asset_name, asset_type, voltage_kv, capacity_mw, notes) FROM stdin;
TA-001	Rasuwagadhi - Chilime Hub 132 kV line	line	132.0	\N	NEA FY2025/26 report PDF p.130 (SRC-006): 10.0 km, 132 kV, double circuit up to Chilime Hub (project key features). Not listed in the NEA grid line tables.
TA-002	Chilime P/S - Trishuli P/S 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 1: single circuit, 39.00 circuit-km, conductor WOLF 150 sq.mm.
TA-003	Trisuli P/S - Devighat P/S 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 3: single circuit, 4.56 circuit-km, WOLF 150.
TA-004	Trisuli P/S - Balaju 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 2: double circuit, 58.00 circuit-km, DOG 100.
TA-005	Devighat P/S - Okhaltar 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 4: double circuit, 53.00 circuit-km, DOG 100. Okhaltar-Chapali (row 5, double, 5.60 circuit-km, cable) not loaded.
TA-006	Trishuli 3A - Trishuli 3B Hub 132 kV line	line	132.0	\N	PDF p.208, section A (132 kV), row 43: double circuit, 6.00 circuit-km, BISON 350.
TA-007	Trishuli 3B Hub - Matatirtha 220 kV line	line	220.0	\N	PDF p.208, section B (220 kV), row 2: double circuit, 98.00 circuit-km, BISON 350.
TA-009	Chilime Hub substation	substation	220.0	\N	PDF p.215, row 17: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.
TA-010	Trishuli 3B Hub substation	substation	220.0	\N	PDF p.215, row 16: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.
TA-011	Matatirtha substation	substation	220.0	\N	PDF p.215, row 13: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA); also 132/33 kV 30 MVA, 132/11 kV 22.5 and 45 MVA. Rating is in MVA, so capacity_mw is left empty.
TA-012	SJCL 132 kV line (Sanjen and Upper Sanjen) to Chilime Hub	line	132.0	\N	NEA FY2025/26 report PDF p.119 (printed 109), Sanjen Jalavidhyut Company section (SRC-006): power from Sanjen (Upper) 14.8 MW and Sanjen 42.5 MW is evacuated through the SJCL 132 kV transmission line to the Chilime Hub substation. The report prints kVA; read as kV (my inference). Length, conductor and circuit count are not stated, and the line is not in the line tables on PDF pp.207-209.
TA-008	Chilime - Trishuli 220 kV line	line	220.0	\N	PDF p.209, section B (220 kV), row 11: double circuit, 72 circuit-km, BISON 350. Endpoints as printed (Chilime-Trishuli); reading them as Chilime Hub and Trishuli 3B Hub is an inference. [p.119 check 2026-10-13] PDF p.119 says the Chilime Hub substation connects to the grid through the Chilime-Trishuli 220 kV line. This supports reading Chilime Hub as an endpoint but does not prove it.
\.


--
-- Name: nea_annual_data_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.nea_annual_data_id_seq', 7, true);


--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.nea_country_trade_id_seq', 14, true);


--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.project_status_log_log_id_seq', 24, true);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: nea_annual_data nea_annual_data_fiscal_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_annual_data
    ADD CONSTRAINT nea_annual_data_fiscal_year_key UNIQUE (fiscal_year);


--
-- Name: nea_annual_data nea_annual_data_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_annual_data
    ADD CONSTRAINT nea_annual_data_pkey PRIMARY KEY (id);


--
-- Name: nea_country_trade nea_country_trade_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_country_trade
    ADD CONSTRAINT nea_country_trade_pkey PRIMARY KEY (id);


--
-- Name: project_baseline project_baseline_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_baseline
    ADD CONSTRAINT project_baseline_pkey PRIMARY KEY (project_id, fiscal_year);


--
-- Name: project_evacuation project_evacuation_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_pkey PRIMARY KEY (project_id, asset_id);


--
-- Name: project_status_log project_status_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_pkey PRIMARY KEY (log_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (source_id);


--
-- Name: transmission_assets transmission_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.transmission_assets
    ADD CONSTRAINT transmission_assets_pkey PRIMARY KEY (asset_id);


--
-- Name: nea_country_trade nea_country_trade_fiscal_year_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nea_country_trade
    ADD CONSTRAINT nea_country_trade_fiscal_year_fkey FOREIGN KEY (fiscal_year) REFERENCES public.nea_annual_data(fiscal_year);


--
-- Name: project_baseline project_baseline_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_baseline
    ADD CONSTRAINT project_baseline_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- Name: project_baseline project_baseline_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_baseline
    ADD CONSTRAINT project_baseline_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id);


--
-- Name: project_evacuation project_evacuation_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.transmission_assets(asset_id);


--
-- Name: project_evacuation project_evacuation_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- Name: project_evacuation project_evacuation_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id);


--
-- Name: project_status_log project_status_log_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id);


--
-- Name: project_status_log project_status_log_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- Name: project_status_log project_status_log_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id);


--
-- PostgreSQL database dump complete
--

\unrestrict J6ks4rWCYTsmRt8HDPkhVNMY8YmrRq4nj1g0rQP1jtQ4zrR35gLkCFSV2yXBnh9

