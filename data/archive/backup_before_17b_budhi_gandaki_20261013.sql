--
-- PostgreSQL database dump
--

\restrict g9uuDReddSjddX9Iwgwpkb1Pgdy7wRSVaeIZdZcjuOixEMUQMZbMOddRtA2fNh6

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
-- Name: events; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.events (
    event_id character varying(20) NOT NULL,
    event_date date NOT NULL,
    description text NOT NULL,
    location character varying(200),
    notes text
);


ALTER TABLE public.events OWNER TO postgres;

--
-- Name: project_status_log; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.project_status_log OWNER TO postgres;

--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.project_status_log_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.project_status_log_log_id_seq OWNER TO postgres;

--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.project_status_log_log_id_seq OWNED BY public.project_status_log.log_id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.projects OWNER TO postgres;

--
-- Name: sources; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.sources OWNER TO postgres;

--
-- Name: project_status_log log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_status_log ALTER COLUMN log_id SET DEFAULT nextval('public.project_status_log_log_id_seq'::regclass);


--
-- Data for Name: events; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.events (event_id, event_date, description, location, notes) FROM stdin;
EVT-002	2026-08-26	Bhotekoshi/Trishuli flash flood from Tibet: hydropower, solar and transmission damage	Rasuwa and Nuwakot districts	Date per SRC-004 (Bhadra 10 = 26 Aug 2026).
EVT-003	2026-09-28	Kaligandaki corridor transmission disruption (landslides)	Kaligandaki corridor	NOT VERIFIED: reported by Kathmandu Post on 28 Sep; article not opened. Separate event from EVT-002: never add MW across events.
EVT-001	2025-07-08	Lende River flood from Tibet merged with the Bhotekoshi (previous-year event)	Rasuwa	Damaged Rasuwagadhi area infrastructure. Possible baseline contamination: Rasuwagadhi had only recently resumed full operation before EVT-002 (SRC-001). Evidence (SRC-006, NEA FY2025/26 report PDF pp.130-131): Rasuwagadhi COD 2024-12-31 (BS 2081.09.16); this flood (24 Asar 2082) halted generation. Unit 1 partial generation resumed 2025-12-06 (20 Mangsir 2082), unit 2 on 2025-12-25 (10 Poush 2082), unit 3 on 2026-05-14 (31 Baisakh 2083). The report states full restoration and rehabilitation is planned within FY2083/84, so the plant was not fully restored before EVT-002 (2026-08-26). Design energy 613.875 GWh a year (dry months 84.318, wet months 529.557).
\.


--
-- Data for Name: project_status_log; Type: TABLE DATA; Schema: public; Owner: postgres
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
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
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
\.


--
-- Data for Name: sources; Type: TABLE DATA; Schema: public; Owner: postgres
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
\.


--
-- Name: project_status_log_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.project_status_log_log_id_seq', 20, true);


--
-- Name: events events_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.events
    ADD CONSTRAINT events_pkey PRIMARY KEY (event_id);


--
-- Name: project_status_log project_status_log_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_pkey PRIMARY KEY (log_id);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (project_id);


--
-- Name: sources sources_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sources
    ADD CONSTRAINT sources_pkey PRIMARY KEY (source_id);


--
-- Name: project_status_log project_status_log_event_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(event_id);


--
-- Name: project_status_log project_status_log_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- Name: project_status_log project_status_log_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_status_log
    ADD CONSTRAINT project_status_log_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id);


--
-- PostgreSQL database dump complete
--

\unrestrict g9uuDReddSjddX9Iwgwpkb1Pgdy7wRSVaeIZdZcjuOixEMUQMZbMOddRtA2fNh6

