--
-- PostgreSQL database dump
--

\restrict 1NvsBhCu7pWGfd55WuVzTa08zpNR2aUBAWYuDlcpGIdeE6PNK8lIaCZL6OsnwGh

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
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.projects (project_id, project_name, asset_type, capacity_mw, basin, district, commissioned_date, pre_flood_phase, owner_type, notes) FROM stdin;
PRJ-001	Rasuwagadhi	hydro	111.00	\N	Rasuwa	2024-12-31	operating	NEA_subsidiary	Ministry list (SRC-001). Wikipedia list (SRC-005): commissioned 2024. Recently back at full operation after EVT-001. Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, Rasuwa, COD BS 2081.09.16. NEA FY2025/26 report PDF p.130: design energy 613.875 GWh a year (dry 84.318, wet 529.557); line 10.0 km 132 kV double circuit to Chilime Hub. NEA list check (SRC-006 appendix PDF p.188): Rasuwagadhi Hydropower Company Ltd., 111,000 kW, PPA BS 2068.07.28, COD BS 2081.09.16 = 2024-12-31. Matches stored capacity and date.
PRJ-009	Upper Trishuli 3A	hydro	60.00	\N	Nuwakot	\N	operating	NEA	Ministry list (SRC-001) says Nuwakot; Wikipedia list (SRC-005) says Rasuwa. District unresolved. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 60 MW, year 2019, design generation 489.8 GWh; 2 units of 30 MW (PDF p.26). FY2020/21 report: commissioned July 2019. District not stated there.
PRJ-002	Salasungi Sanjen	hydro	78.00	\N	Rasuwa	2025-02-11	operating	IPP	Ministry list (SRC-001). NEA FY2025/26 report appendix (PDF p.191): listed as Sanjen Khola, Salasungi Power Limited, 78,000 kW, Rasuwa, IPP table, COD BS 2081.10.29. Matched to this row by developer name and capacity. NEA list check (SRC-006 appendix PDF p.191): project name in list is Sanjen Khola, developer Salasungi Power Limited, 78,000 kW, COD BS 2081.10.29 = 2025-02-11. Matches stored capacity and date.
PRJ-003	Upper Sanjen	hydro	14.80	\N	Rasuwa	2023-10-08	operating	NEA_subsidiary	Ministry list (SRC-001). Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Co. Limited, 14,800 kW, Rasuwa, COD BS 2080.06.21. NEA list check (SRC-006 appendix PDF p.188): Upper Sanjen, 14,800 kW, COD BS 2080.06.21 = 2023-10-08. Matches. Status log affected_mw 14.80 for PRJ-008 is NOT this plant.
PRJ-004	Sanjen	hydro	42.50	\N	Rasuwa	2024-12-16	operating	NEA_subsidiary	Ministry list (SRC-001). Owner: NEA subsidiary group per SRC-006 p.5, identified by an exact MW sum match (111 + 42.5 + 14.8 + 102 = 270.3), not by name. NEA FY2025/26 report appendix (PDF p.188): Sanjen Hydropower Company Limited, 42,500 kW, Rasuwa, COD BS 2081.09.01. NEA list check (SRC-006 appendix PDF p.188): Sanjen, 42,500 kW, COD BS 2081.09.01 = 2024-12-16. Matches stored capacity and date.
PRJ-010	Trishuli	hydro	24.00	\N	Nuwakot	\N	operating	NEA	Ministry list (SRC-001). Wikipedia list: commissioned 1967. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 24 MW, year 1967, design generation 163.8 GWh. District not stated there.
PRJ-011	Devighat	hydro	15.00	\N	Nuwakot	\N	operating	NEA	Ministry list 14 MW; SRC-004 gives 14.1 MW. Installed 15 MW (3 x 5 MW) per SRC-006 p.19; ministry list said 14 MW, SRC-004 and Wikipedia 14.1 MW. The status log keeps the ministry figure in affected_mw. NEA FY2025/26 report appendix (PDF p.187, printed p.177): installed 15.1 MW (seed 15.00), year 1984, design generation 113.0 GWh. District not stated there.
PRJ-012	Saurya solar (name unconfirmed)	solar	25.00	\N	Nuwakot	\N	operating	unknown	Ministry list gives only a 25 MW solar project in Nuwakot (SRC-001). SRC-004 names Saurya (25 MW): identification inferred, unverified. UNMATCHED in NEA FY2025/26 report appendix: no operating solar project in Nuwakot and no single 25 MW solar plant. The list has Dharamnagar Solar Farm 10 MW and Dharamnagar Solar Farm-I 15 MW (Pashupati Renewables, Kapilvastu). Name and district unverified; check RDNA.
PRJ-005	Mailung Khola	hydro	5.00	\N	Rasuwa	2014-07-03	operating	IPP	Ministry list (SRC-001). NEA FY2025/26 report appendix (PDF p.189): Mailung Khola Hydro Power Company, 5,000 kW, Rasuwa, IPP table, COD BS 2071.03.19. NEA list check (SRC-006 appendix PDF p.189): Mailung Khola, 5,000 kW, COD BS 2071.03.19 = 2014-07-03. Matches stored capacity and date.
PRJ-006	Langtang Khola	hydro	20.00	\N	Rasuwa	\N	operating	IPP	Ministry list (SRC-001). Described as private in SRC-002. CONFLICT: NEA FY2025/26 report appendix (PDF p.198) lists Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, Rasuwa, in the UNDER CONSTRUCTION table as of FY 2082/83 (PPA BS 2072.09.29, no COD). Seed says operating. Check RDNA Table 34. CONFLICT, NEA list check (SRC-006 appendix PDF p.198): Langtang Khola, Multi Energy Development Pvt. Ltd., 20,000 kW, PPA BS 2072.09.29, listed under CONSTRUCTION with no COD. pre_flood_phase left as operating until RDNA Table 34 is checked.
PRJ-007	Chilime	hydro	22.10	\N	Rasuwa	2003-08-25	operating	NEA_subsidiary	Ministry list 22 MW. Kathmandu Post 2 Sep gives 22.1 MW (SRC-003). SRC-006 p.5 gives 22.1 MW and names Chilime Hydropower Company as NEA's first subsidiary; ministry list gave 22 MW. NEA FY2025/26 report appendix (PDF p.188): Chilime Hydro Power Company Ltd., 22,100 kW, Rasuwa, COD BS 2060.05.08. NEA list check (SRC-006 appendix PDF p.188): Chilime, 22,100 kW, COD BS 2060.05.08 = 2003-08-25. Matches stored capacity and date. Status log has 22.00 MW.
PRJ-008	Upper Mailung	hydro	14.30	\N	Rasuwa	2024-02-11	operating	IPP	CONFLICT: the ministry list (SRC-001) shows it among the 12 operational projects (14.8 MW) AND among the 15 under-construction projects. Wikipedia list (SRC-005) gives 14.3 MW, commissioned 2024. Phase left unknown. NEA FY2025/26 report appendix (PDF p.191): Mathillo Mailung Khola Jalbidhyut Ltd., Upper Mailung, 14,300 kW, Rasuwa, operating, COD BS 2080.10.28. Previous seed values: capacity 14.80 (equals Upper Sanjen), district blank, phase unknown. A different project, Upper Mailung A, 6,420 kW, Energy Engineering Pvt. Ltd., is under construction (PDF p.194). Verify in RDNA. NEA list check (SRC-006 appendix PDF p.191): printed as Upper Mailun, 14,300 kW, COD BS 2080.10.28 = 2024-02-11. Matches stored capacity and date. Status log 14.80 MW is not from the NEA list.
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
\.


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
-- PostgreSQL database dump complete
--

\unrestrict 1NvsBhCu7pWGfd55WuVzTa08zpNR2aUBAWYuDlcpGIdeE6PNK8lIaCZL6OsnwGh

