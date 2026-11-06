--
-- PostgreSQL database dump
--

\restrict GqkC0mFx4WVlau1iwCsjQzZb8IygVtyf5lhXYL2gUKy7WXNFZCDoQ11IbSeFIp1

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
-- Name: nea_country_trade; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.nea_country_trade OWNER TO postgres;

--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nea_country_trade_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nea_country_trade_id_seq OWNER TO postgres;

--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nea_country_trade_id_seq OWNED BY public.nea_country_trade.id;


--
-- Name: project_evacuation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.project_evacuation (
    project_id character varying(20) NOT NULL,
    asset_id character varying(20) NOT NULL,
    source_id character varying(20),
    notes text
);


ALTER TABLE public.project_evacuation OWNER TO postgres;

--
-- Name: transmission_assets; Type: TABLE; Schema: public; Owner: postgres
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


ALTER TABLE public.transmission_assets OWNER TO postgres;

--
-- Name: nea_country_trade id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nea_country_trade ALTER COLUMN id SET DEFAULT nextval('public.nea_country_trade_id_seq'::regclass);


--
-- Data for Name: nea_country_trade; Type: TABLE DATA; Schema: public; Owner: postgres
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
\.


--
-- Data for Name: project_evacuation; Type: TABLE DATA; Schema: public; Owner: postgres
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
\.


--
-- Data for Name: transmission_assets; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transmission_assets (asset_id, asset_name, asset_type, voltage_kv, capacity_mw, notes) FROM stdin;
TA-001	Rasuwagadhi - Chilime Hub 132 kV line	line	132.0	\N	NEA FY2025/26 report PDF p.130 (SRC-006): 10.0 km, 132 kV, double circuit up to Chilime Hub (project key features). Not listed in the NEA grid line tables.
TA-002	Chilime P/S - Trishuli P/S 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 1: single circuit, 39.00 circuit-km, conductor WOLF 150 sq.mm.
TA-003	Trisuli P/S - Devighat P/S 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 3: single circuit, 4.56 circuit-km, WOLF 150.
TA-004	Trisuli P/S - Balaju 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 2: double circuit, 58.00 circuit-km, DOG 100.
TA-005	Devighat P/S - Okhaltar 66 kV line	line	66.0	\N	PDF p.209, section D (66 kV), row 4: double circuit, 53.00 circuit-km, DOG 100. Okhaltar-Chapali (row 5, double, 5.60 circuit-km, cable) not loaded.
TA-006	Trishuli 3A - Trishuli 3B Hub 132 kV line	line	132.0	\N	PDF p.208, section A (132 kV), row 43: double circuit, 6.00 circuit-km, BISON 350.
TA-007	Trishuli 3B Hub - Matatirtha 220 kV line	line	220.0	\N	PDF p.208, section B (220 kV), row 2: double circuit, 98.00 circuit-km, BISON 350.
TA-008	Chilime - Trishuli 220 kV line	line	220.0	\N	PDF p.209, section B (220 kV), row 11: double circuit, 72 circuit-km, BISON 350. Endpoints as printed (Chilime-Trishuli); reading them as Chilime Hub and Trishuli 3B Hub is an inference.
TA-009	Chilime Hub substation	substation	220.0	\N	PDF p.215, row 17: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.
TA-010	Trishuli 3B Hub substation	substation	220.0	\N	PDF p.215, row 16: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA) and one 132/33 kV row of 50 MVA; no increment in FY2082/83. Rating is in MVA, so capacity_mw is left empty.
TA-011	Matatirtha substation	substation	220.0	\N	PDF p.215, row 13: six 220/132 kV rows of 53.33 MVA each (sum 319.98 MVA); also 132/33 kV 30 MVA, 132/11 kV 22.5 and 45 MVA. Rating is in MVA, so capacity_mw is left empty.
\.


--
-- Name: nea_country_trade_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.nea_country_trade_id_seq', 12, true);


--
-- Name: nea_country_trade nea_country_trade_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nea_country_trade
    ADD CONSTRAINT nea_country_trade_pkey PRIMARY KEY (id);


--
-- Name: project_evacuation project_evacuation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_pkey PRIMARY KEY (project_id, asset_id);


--
-- Name: transmission_assets transmission_assets_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transmission_assets
    ADD CONSTRAINT transmission_assets_pkey PRIMARY KEY (asset_id);


--
-- Name: nea_country_trade nea_country_trade_fiscal_year_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nea_country_trade
    ADD CONSTRAINT nea_country_trade_fiscal_year_fkey FOREIGN KEY (fiscal_year) REFERENCES public.nea_annual_data(fiscal_year);


--
-- Name: project_evacuation project_evacuation_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES public.transmission_assets(asset_id);


--
-- Name: project_evacuation project_evacuation_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(project_id);


--
-- Name: project_evacuation project_evacuation_source_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.project_evacuation
    ADD CONSTRAINT project_evacuation_source_id_fkey FOREIGN KEY (source_id) REFERENCES public.sources(source_id);


--
-- PostgreSQL database dump complete
--

\unrestrict GqkC0mFx4WVlau1iwCsjQzZb8IygVtyf5lhXYL2gUKy7WXNFZCDoQ11IbSeFIp1

