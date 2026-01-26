--
-- PostgreSQL database dump
--

\restrict Q2fMr4gLw7AYilcRGv1ihO7ZzhBavVKhzxLgGQIR4Y0ia3owcoTTByRnaW8qlG4

-- Dumped from database version 18.0 (Debian 18.0-1.pgdg13+3)
-- Dumped by pg_dump version 18.0 (Debian 18.0-1.pgdg13+3)

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

--
-- Name: action; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.action AS ENUM (
    'sign-in',
    'sign-out',
    'sign-in-failed'
);


ALTER TYPE public.action OWNER TO cs_pg_user;

--
-- Name: course_visibility; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.course_visibility AS ENUM (
    'public',
    'private'
);


ALTER TYPE public.course_visibility OWNER TO cs_pg_user;

--
-- Name: material_type; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.material_type AS ENUM (
    'document',
    'code',
    'type'
);


ALTER TYPE public.material_type OWNER TO cs_pg_user;

--
-- Name: role; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.role AS ENUM (
    'student',
    'instructor',
    'admin'
);


ALTER TYPE public.role OWNER TO cs_pg_user;

--
-- Name: semester_type; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.semester_type AS ENUM (
    'first',
    'second',
    'summer'
);


ALTER TYPE public.semester_type OWNER TO cs_pg_user;

--
-- Name: user_type; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.user_type AS ENUM (
    'oauth',
    'credential'
);


ALTER TYPE public.user_type OWNER TO cs_pg_user;

--
-- Name: visibility; Type: TYPE; Schema: public; Owner: cs_pg_user
--

CREATE TYPE public.visibility AS ENUM (
    'public',
    'private'
);


ALTER TYPE public.visibility OWNER TO cs_pg_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth_logs; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.auth_logs (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    action public.action NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.auth_logs OWNER TO cs_pg_user;

--
-- Name: code_materials; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.code_materials (
    material_id uuid NOT NULL,
    description text,
    task_id uuid NOT NULL
);


ALTER TABLE public.code_materials OWNER TO cs_pg_user;

--
-- Name: course_creators; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.course_creators (
    course_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    "order" integer NOT NULL
);


ALTER TABLE public.course_creators OWNER TO cs_pg_user;

--
-- Name: courses; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.courses (
    id uuid NOT NULL,
    name text NOT NULL,
    visibility public.course_visibility NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_archived boolean DEFAULT false NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.courses OWNER TO cs_pg_user;

--
-- Name: default_labs; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.default_labs (
    id uuid NOT NULL,
    course_id uuid NOT NULL,
    lab_id uuid NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    lab_name text NOT NULL
);


ALTER TABLE public.default_labs OWNER TO cs_pg_user;

--
-- Name: lab_materials; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.lab_materials (
    id uuid NOT NULL,
    lab_id uuid NOT NULL,
    material_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.lab_materials OWNER TO cs_pg_user;

--
-- Name: lab_sections; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.lab_sections (
    id uuid NOT NULL,
    lab_id uuid NOT NULL,
    section_id uuid NOT NULL,
    "position" integer NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.lab_sections OWNER TO cs_pg_user;

--
-- Name: labs; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.labs (
    id uuid NOT NULL,
    display_name text NOT NULL,
    course_id uuid NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone,
    is_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.labs OWNER TO cs_pg_user;

--
-- Name: material_tags; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.material_tags (
    material_id uuid NOT NULL,
    tag_id uuid NOT NULL
);


ALTER TABLE public.material_tags OWNER TO cs_pg_user;

--
-- Name: materials; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.materials (
    id uuid NOT NULL,
    name text NOT NULL,
    type public.material_type NOT NULL,
    visibility public.visibility NOT NULL,
    created_by uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.materials OWNER TO cs_pg_user;

--
-- Name: section_instructors; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.section_instructors (
    section_id uuid NOT NULL,
    instructor_id uuid NOT NULL
);


ALTER TABLE public.section_instructors OWNER TO cs_pg_user;

--
-- Name: section_logs; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.section_logs (
    id uuid NOT NULL,
    user_id uuid,
    section_id uuid NOT NULL,
    action text NOT NULL,
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP CONSTRAINT section_logs_created_at_not_null NOT NULL,
    ip_address inet NOT NULL
);


ALTER TABLE public.section_logs OWNER TO cs_pg_user;

--
-- Name: section_students; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.section_students (
    section_id uuid NOT NULL,
    student_id uuid NOT NULL
);


ALTER TABLE public.section_students OWNER TO cs_pg_user;

--
-- Name: section_tas; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.section_tas (
    section_id uuid NOT NULL,
    ta_id uuid NOT NULL
);


ALTER TABLE public.section_tas OWNER TO cs_pg_user;

--
-- Name: sections; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.sections (
    id uuid NOT NULL,
    name text NOT NULL,
    banner text,
    course_id uuid NOT NULL,
    semester_id uuid NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.sections OWNER TO cs_pg_user;

--
-- Name: semesters; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.semesters (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    type public.semester_type NOT NULL,
    started_date date NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.semesters OWNER TO cs_pg_user;

--
-- Name: tags; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.tags (
    id uuid NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.tags OWNER TO cs_pg_user;

--
-- Name: user_groups; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.user_groups (
    id uuid NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.user_groups OWNER TO cs_pg_user;

--
-- Name: user_passwords; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.user_passwords (
    user_id uuid NOT NULL,
    password character varying(80) NOT NULL
);


ALTER TABLE public.user_passwords OWNER TO cs_pg_user;

--
-- Name: user_refresh_tokens; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.user_refresh_tokens (
    user_id uuid NOT NULL,
    token text NOT NULL
);


ALTER TABLE public.user_refresh_tokens OWNER TO cs_pg_user;

--
-- Name: users; Type: TABLE; Schema: public; Owner: cs_pg_user
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email text,
    type public.user_type NOT NULL,
    username character varying(255) NOT NULL,
    display_name text NOT NULL,
    profile_image text,
    roles public.role[] NOT NULL,
    group_id uuid,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    deleted_at timestamp without time zone
);


ALTER TABLE public.users OWNER TO cs_pg_user;

--
-- Data for Name: auth_logs; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.auth_logs (id, user_id, action, created_at) FROM stdin;
\.


--
-- Data for Name: code_materials; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.code_materials (material_id, description, task_id) FROM stdin;
\.


--
-- Data for Name: course_creators; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.course_creators (course_id, creator_id, "order") FROM stdin;
019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	0
019b43f4-17f2-70e0-ac4a-a0c9756548fc	019b401a-994b-7421-b42b-5eaf5adbfc85	0
\.


--
-- Data for Name: courses; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.courses (id, name, visibility, created_at, updated_at, is_archived, is_deleted, deleted_at) FROM stdin;
019b401d-f6b0-7d49-869a-407773b197e2	Golang	public	2025-12-21 08:54:24.176952	2025-12-21 09:18:43.311305	f	f	\N
019b43f4-17f2-70e0-ac4a-a0c9756548fc	Test	public	2025-12-22 02:47:09.042108	2025-12-22 02:47:09.042108	f	f	\N
\.


--
-- Data for Name: default_labs; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.default_labs (id, course_id, lab_id, "position", created_at, updated_at, is_deleted, deleted_at, lab_name) FROM stdin;
019b585f-9e23-7bee-845a-5a518c10022f	019b401d-f6b0-7d49-869a-407773b197e2	019b585f-92b9-7d97-8e6e-3aaf71ac36d2	2	2025-12-26 01:57:00.067838	2025-12-26 01:57:13.665674	t	2026-01-03 04:41:50.754409	Lab02
019b585f-6951-7ad0-8042-0f8176421b96	019b401d-f6b0-7d49-869a-407773b197e2	019b585e-d087-722b-87bb-157dbb0f040e	1	2025-12-26 01:56:46.546162	2026-01-03 04:48:44.597756	f	\N	Lab01
019b822d-fa94-719c-88dc-5f79c5238ac7	019b401d-f6b0-7d49-869a-407773b197e2	019b822d-f614-7ed3-a2e2-4aa7dadfb194	3	2026-01-03 04:46:50.004299	2026-01-03 04:46:50.004299	f	\N	Lab3
019b822d-fbda-7670-a2d1-7933aef195b5	019b401d-f6b0-7d49-869a-407773b197e2	019b822d-e185-7a9c-97de-cb309f609121	2	2026-01-03 04:46:50.330532	2026-01-03 04:48:46.721091	f	\N	Lab02
019bb036-3765-7c4b-89c8-21a109654ea0	019b401d-f6b0-7d49-869a-407773b197e2	019bb036-07ec-7dfd-a2b9-31837868df03	4	2026-01-12 03:18:21.798095	2026-01-12 03:18:21.798095	f	\N	New lab
\.


--
-- Data for Name: lab_materials; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.lab_materials (id, lab_id, material_id, created_at, updated_at, is_deleted, deleted_at) FROM stdin;
\.


--
-- Data for Name: lab_sections; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.lab_sections (id, lab_id, section_id, "position", created_at, updated_at, is_deleted, deleted_at) FROM stdin;
019b6585-801e-70b2-b251-cc55683c6e5e	019b585e-d087-722b-87bb-157dbb0f040e	019b6585-8017-75fc-b4ff-99be90ca6214	1	2025-12-28 15:13:26.557734	2025-12-28 15:13:26.557734	f	\N
019b6585-8021-7575-84d7-2a8904ee5eea	019b585f-92b9-7d97-8e6e-3aaf71ac36d2	019b6585-8017-75fc-b4ff-99be90ca6214	2	2025-12-28 15:13:26.557734	2025-12-28 15:13:26.557734	t	2026-01-03 04:41:50.754409
019b9777-b07d-72f7-90f2-cde4c3f26b9d	019b822d-e185-7a9c-97de-cb309f609121	019b6585-8017-75fc-b4ff-99be90ca6214	2	2026-01-07 07:59:22.237243	2026-01-07 07:59:22.237243	f	\N
019b97ae-d44a-7245-8bf8-300327dbcc91	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019b6585-8017-75fc-b4ff-99be90ca6214	3	2026-01-07 08:59:35.882265	2026-01-07 08:59:35.882265	f	\N
019b97b0-de4c-7cd1-abec-193e0d7bbbce	019b97af-598e-7627-871a-ad537fab1595	019b6585-8017-75fc-b4ff-99be90ca6214	4	2026-01-07 09:01:49.516943	2026-01-07 09:01:49.516943	f	\N
019b97b0-de50-7dd0-8e9c-cda34258e38b	019b97af-7289-7baf-810c-7007acab2879	019b6585-8017-75fc-b4ff-99be90ca6214	5	2026-01-07 09:01:49.521013	2026-01-07 09:01:49.521013	f	\N
019b97b1-1eac-7d92-ae13-675a82d9a6e9	019b822d-e185-7a9c-97de-cb309f609121	019b4034-76b1-7b8c-9685-2472c18ee7e1	1	2026-01-07 09:02:05.996945	2026-01-07 09:02:05.996945	f	\N
019b97b1-1eaf-7964-a1a7-88cf7b341d15	019b97af-598e-7627-871a-ad537fab1595	019b4034-76b1-7b8c-9685-2472c18ee7e1	2	2026-01-07 09:02:05.999685	2026-01-07 09:02:05.999685	f	\N
019b97b1-31f9-7cd0-aa3e-7d0c0d1942e9	019b585e-d087-722b-87bb-157dbb0f040e	019b4034-76b1-7b8c-9685-2472c18ee7e1	3	2026-01-07 09:02:10.938809	2026-01-07 09:02:10.938809	f	\N
019b97b1-3200-790f-96ba-9c05b443918f	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019b4034-76b1-7b8c-9685-2472c18ee7e1	4	2026-01-07 09:02:10.945015	2026-01-07 09:02:10.945015	f	\N
019b97b1-3202-7a3b-b3f4-b1bac098867b	019b97af-7289-7baf-810c-7007acab2879	019b4034-76b1-7b8c-9685-2472c18ee7e1	5	2026-01-07 09:02:10.94682	2026-01-07 09:02:10.94682	f	\N
019b97b4-d143-71ac-8d3a-710205900352	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019b97b4-d13e-7d11-b81f-82f92a124c6c	3	2026-01-07 09:06:08.322294	2026-01-07 09:06:08.322294	t	2026-01-08 06:00:32.537021
019b97b5-52fc-7849-a873-f162425ab0ba	019b97af-598e-7627-871a-ad537fab1595	019b97b4-d13e-7d11-b81f-82f92a124c6c	4	2026-01-07 09:06:41.533326	2026-01-07 09:06:41.533326	t	2026-01-08 06:02:22.744908
019b97b4-d142-7ca5-bdd0-b58bf5f4b982	019b585e-d087-722b-87bb-157dbb0f040e	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-07 09:06:08.322294	2026-01-07 09:06:08.322294	t	2026-01-08 06:05:21.169189
019b97b4-d143-7002-8e1a-c6c1103a14b7	019b822d-e185-7a9c-97de-cb309f609121	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-07 09:06:08.322294	2026-01-07 09:06:08.322294	t	2026-01-08 06:05:25.830969
019b97b5-457b-7c35-91af-24da8cbadc7d	019b97af-7289-7baf-810c-7007acab2879	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-07 09:06:38.075997	2026-01-07 09:06:38.075997	t	2026-01-08 06:05:30.465655
019b9c35-e682-7445-ad56-f2c50b3a39a5	019b585e-d087-722b-87bb-157dbb0f040e	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-08 06:05:36.770724	2026-01-08 06:05:36.770724	t	2026-01-08 06:05:47.338936
019b9c35-e687-7807-b016-18eda02f5288	019b822d-e185-7a9c-97de-cb309f609121	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-08 06:05:36.775626	2026-01-08 06:05:36.775626	t	2026-01-08 06:05:51.555513
019b9c35-e688-7ddb-8770-74ef5a952296	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-08 06:05:36.776993	2026-01-08 06:05:36.776993	t	2026-01-08 06:05:55.626835
019b9c35-e68a-761c-9727-cfa6aef5ea89	019b97af-598e-7627-871a-ad537fab1595	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-08 06:05:36.778495	2026-01-08 06:05:36.778495	t	2026-01-08 06:05:59.551506
019b9c36-635f-7177-913b-d0834d19883e	019b585e-d087-722b-87bb-157dbb0f040e	019b97b4-d13e-7d11-b81f-82f92a124c6c	1	2026-01-08 06:06:08.735157	2026-01-08 06:12:22.849068	f	\N
019b9c36-635e-724e-8af2-91b14f8e01ae	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019b97b4-d13e-7d11-b81f-82f92a124c6c	3	2026-01-08 06:06:08.734194	2026-01-08 06:12:18.819933	f	\N
019b9c36-6360-770b-a3be-f747a8cc9a16	019b97af-598e-7627-871a-ad537fab1595	019b97b4-d13e-7d11-b81f-82f92a124c6c	7	2026-01-08 06:06:08.736526	2026-01-08 06:06:08.736526	f	\N
019b9c36-635c-70a0-96cf-ef01727d4bba	019b822d-e185-7a9c-97de-cb309f609121	019b97b4-d13e-7d11-b81f-82f92a124c6c	2	2026-01-08 06:06:08.732105	2026-01-08 06:12:24.618092	f	\N
019bb036-8b49-7d00-9fdd-87b54f98911b	019b585e-d087-722b-87bb-157dbb0f040e	019bb036-8b46-7386-8afc-0d9629f81a79	1	2026-01-12 03:18:43.273684	2026-01-12 03:18:43.273684	f	\N
019bb036-8b4a-71dd-b191-5527e9cdc08f	019b822d-e185-7a9c-97de-cb309f609121	019bb036-8b46-7386-8afc-0d9629f81a79	2	2026-01-12 03:18:43.273684	2026-01-12 03:18:43.273684	f	\N
019bb036-8b4a-73f9-b681-09199441d16f	019b822d-f614-7ed3-a2e2-4aa7dadfb194	019bb036-8b46-7386-8afc-0d9629f81a79	3	2026-01-12 03:18:43.273684	2026-01-12 03:18:43.273684	f	\N
019bb036-8b4a-75ec-a9d1-46cf7514e7b8	019bb036-07ec-7dfd-a2b9-31837868df03	019bb036-8b46-7386-8afc-0d9629f81a79	4	2026-01-12 03:18:43.273684	2026-01-12 03:18:43.273684	f	\N
\.


--
-- Data for Name: labs; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.labs (id, display_name, course_id, created_by, created_at, updated_at, is_deleted, deleted_at, is_default) FROM stdin;
019b585e-d087-722b-87bb-157dbb0f040e	Lab01	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2025-12-26 01:56:07.431058	2025-12-26 01:56:46.547659	f	\N	t
019b585f-92b9-7d97-8e6e-3aaf71ac36d2	Lab02	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2025-12-26 01:56:57.145792	2025-12-26 01:57:00.074403	t	2026-01-03 04:41:50.754409	t
019b822d-f614-7ed3-a2e2-4aa7dadfb194	Lab3	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2026-01-03 04:46:48.852916	2026-01-03 04:46:50.005235	f	\N	t
019b822d-e185-7a9c-97de-cb309f609121	Lab02	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2026-01-03 04:46:43.589639	2026-01-03 04:46:50.332297	f	\N	t
019b97af-598e-7627-871a-ad537fab1595	Lab04	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2026-01-07 09:00:09.99836	2026-01-07 09:00:09.99836	f	\N	f
019b97af-7289-7baf-810c-7007acab2879	Lab05	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2026-01-07 09:00:16.393675	2026-01-07 09:00:16.393675	f	\N	f
019bb036-07ec-7dfd-a2b9-31837868df03	New lab	019b401d-f6b0-7d49-869a-407773b197e2	019b401a-994b-7421-b42b-5eaf5adbfc85	2026-01-12 03:18:09.644887	2026-01-12 03:18:21.799217	f	\N	t
\.


--
-- Data for Name: material_tags; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.material_tags (material_id, tag_id) FROM stdin;
\.


--
-- Data for Name: materials; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.materials (id, name, type, visibility, created_by, created_at, updated_at, is_deleted, deleted_at) FROM stdin;
\.


--
-- Data for Name: section_instructors; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.section_instructors (section_id, instructor_id) FROM stdin;
019b43f5-ace6-7767-85f5-7af78c8810f4	019b3f96-847c-7b10-a398-1a433ef1198b
019b50c8-5c60-7b63-a3bf-aee4699b0309	019b401a-994b-7421-b42b-5eaf5adbfc85
019b4034-76b1-7b8c-9685-2472c18ee7e1	019b401a-994b-7421-b42b-5eaf5adbfc85
019b6585-8017-75fc-b4ff-99be90ca6214	019b401a-994b-7421-b42b-5eaf5adbfc85
019b97b4-d13e-7d11-b81f-82f92a124c6c	019b401a-994b-7421-b42b-5eaf5adbfc85
019bb036-8b46-7386-8afc-0d9629f81a79	019b401a-994b-7421-b42b-5eaf5adbfc85
\.


--
-- Data for Name: section_logs; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.section_logs (id, user_id, section_id, action, "timestamp", ip_address) FROM stdin;
019b442e-9ec9-7d6b-8e58-5a6876032499	019b3f96-847c-7b10-a398-1a433ef1198b	019b4034-76b1-7b8c-9685-2472c18ee7e1	Test log entry	2025-12-22 03:51:04.650962	172.22.0.1
019b4432-50ce-71d8-a544-3610f704d377	019b3f96-847c-7b10-a398-1a433ef1198b	019b4034-76b1-7b8c-9685-2472c18ee7e1	Test log entry	2025-12-22 03:55:06.831044	172.22.0.1
019b4432-52f6-730a-8b5b-3bdd64cd9d11	019b3f96-847c-7b10-a398-1a433ef1198b	019b4034-76b1-7b8c-9685-2472c18ee7e1	Test log entry	2025-12-22 03:55:07.382707	172.22.0.1
019b4432-55ff-7ddb-8b8f-df40c6554b47	019b3f96-847c-7b10-a398-1a433ef1198b	019b4034-76b1-7b8c-9685-2472c18ee7e1	Test log entry	2025-12-22 03:55:08.160821	172.22.0.1
019b4c0b-9b99-743f-8763-5317566fe226	019b3f96-847c-7b10-a398-1a433ef1198b	019b4034-76b1-7b8c-9685-2472c18ee7e1	Update this section	2025-12-23 16:29:47.801872	172.22.0.1
019b50c1-5b69-7f3c-89b7-071db49ff7af	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Updated default labs for section	2025-12-24 14:26:47.790846	172.22.0.1
019b50c2-5157-7661-90cd-4a027caa01d7	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Updated section	2025-12-24 14:27:50.749189	172.22.0.1
019b50c5-487c-7e77-8982-4e1fd72fe8f1	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:31:05.090296	172.22.0.1
019b50c5-8e0f-7a9d-857f-ac4233069cba	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:31:22.89613	172.22.0.1
019b50c8-5c64-7393-8fcd-2716f6c8ce3a	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Updated default labs for section	2025-12-24 14:34:26.784853	172.22.0.1
019b50c8-5c68-7323-aeec-30d66694b403	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Updated default labs for section	2025-12-24 14:34:26.799245	172.22.0.1
019b50c8-f480-735c-aa00-3bfec54bba09	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Updated section	2025-12-24 14:35:05.734165	172.22.0.1
019b50c9-1c51-76a3-8297-05559a015bc4	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Deleted section	2025-12-24 14:35:15.921579	172.22.0.1
019b50ca-25ec-79f7-b91d-155b9ce6f961	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Updated section	2025-12-24 14:36:23.917403	172.22.0.1
019b50ca-4fff-7aba-93ae-aacb50ae438d	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Added students to section	2025-12-24 14:36:34.687788	172.22.0.1
019b50ce-a7ab-729f-977b-cb4577ff7c66	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:41:19.275973	172.22.0.1
019b50ce-ae5f-7f23-9875-43800014cc7d	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:41:20.992227	172.22.0.1
019b50ce-f2c4-7c7c-95b5-82dc92587dac	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:41:38.501459	172.22.0.1
019b50cf-0386-7910-a247-1650f4e1db12	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:41:42.790788	172.22.0.1
019b50cf-0a90-7cc9-bc52-403dfc8f2c51	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:41:44.593316	172.22.0.1
019b50cf-11f6-7015-99f4-21ed3678851c	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:41:46.486285	172.22.0.1
019b50cf-439b-7a8d-b7ef-9c8764a020b7	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:41:59.196182	172.22.0.1
019b50cf-74bb-72a8-afb2-fbc8f29e7eea	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:42:11.771638	172.22.0.1
019b50cf-88f3-7ee9-adea-00581931c206	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:42:16.948829	172.22.0.1
019b50cf-998e-7f09-8c47-88d30971d0f2	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Removed students from section	2025-12-24 14:42:21.199107	172.22.0.1
019b50cf-d9bc-7018-ba6a-aaf195faf36f	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:42:37.628096	172.22.0.1
019b50d0-08e3-70b4-bf26-5c8fbf4b901b	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:42:49.699536	172.22.0.1
019b50d1-8b92-7802-8abc-dd27d45c4421	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Added students to section	2025-12-24 14:44:28.690691	172.22.0.1
019b50d4-81c5-7ba9-a675-8851e7c644f8	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Updated section	2025-12-24 14:47:42.790181	172.22.0.1
019b50d4-9ba1-7b8e-a987-c25ceca847bc	019b401a-994b-7421-b42b-5eaf5adbfc85	019b4034-76b1-7b8c-9685-2472c18ee7e1	Updated section	2025-12-24 14:47:49.409848	172.22.0.1
019b6585-8019-79b1-89b4-fa34befd0670	019b401a-994b-7421-b42b-5eaf5adbfc85	019b6585-8017-75fc-b4ff-99be90ca6214	Created section	2025-12-28 15:13:26.551767	172.22.0.1
019b6585-8022-7237-b6a9-8f57c8c8bfe9	019b401a-994b-7421-b42b-5eaf5adbfc85	019b6585-8017-75fc-b4ff-99be90ca6214	Updated default labs for section	2025-12-28 15:13:26.562542	172.22.0.1
019b96f1-c201-7384-8998-c84e2d96b3e0	019b401a-994b-7421-b42b-5eaf5adbfc85	019b50c8-5c60-7b63-a3bf-aee4699b0309	Deleted section	2026-01-07 05:33:04.897359	172.22.0.1
019b97b4-d13f-7e1a-b2b3-2645522a9d45	019b401a-994b-7421-b42b-5eaf5adbfc85	019b97b4-d13e-7d11-b81f-82f92a124c6c	Created section	2026-01-07 09:06:08.31894	172.22.0.1
019b97b4-d143-7304-8e88-5ed28ecfd2a0	019b401a-994b-7421-b42b-5eaf5adbfc85	019b97b4-d13e-7d11-b81f-82f92a124c6c	Updated default labs for section	2026-01-07 09:06:08.32338	172.22.0.1
019bb036-8b47-7cad-be7e-3bb81b717dda	019b401a-994b-7421-b42b-5eaf5adbfc85	019bb036-8b46-7386-8afc-0d9629f81a79	Created section	2026-01-12 03:18:43.270555	172.22.0.1
019bb036-8b4a-77cb-bd95-e591c6a1971c	019b401a-994b-7421-b42b-5eaf5adbfc85	019bb036-8b46-7386-8afc-0d9629f81a79	Updated default labs for section	2026-01-12 03:18:43.27492	172.22.0.1
\.


--
-- Data for Name: section_students; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.section_students (section_id, student_id) FROM stdin;
019b50c8-5c60-7b63-a3bf-aee4699b0309	019b3f96-847c-7b10-a398-1a433ef1198b
019b4034-76b1-7b8c-9685-2472c18ee7e1	019b3f96-847c-7b10-a398-1a433ef1198b
019b4034-76b1-7b8c-9685-2472c18ee7e1	019b401a-994b-7421-b42b-5eaf5adbfc85
019b4034-76b1-7b8c-9685-2472c18ee7e1	019b43f1-237d-7d52-9bdc-b46fe3100586
\.


--
-- Data for Name: section_tas; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.section_tas (section_id, ta_id) FROM stdin;
\.


--
-- Data for Name: sections; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.sections (id, name, banner, course_id, semester_id, created_at, updated_at, is_deleted, deleted_at) FROM stdin;
019b43f5-ace6-7767-85f5-7af78c8810f4	Sec01	section/banners/019b43f5-ace7-79bf-b5cd-ba06c779788b.gif	019b43f4-17f2-70e0-ac4a-a0c9756548fc	019b402c-f057-71ba-867b-f12e135d0730	2025-12-22 02:48:52.71056	2025-12-22 02:48:52.71056	f	\N
019b4034-76b1-7b8c-9685-2472c18ee7e1	Sec1	section/banners/019b4036-813f-7cf4-94e2-592855864b4f.gif	019b401d-f6b0-7d49-869a-407773b197e2	019b402c-f057-71ba-867b-f12e135d0730	2025-12-21 09:18:58.737835	2025-12-24 14:47:49.409022	f	\N
019b6585-8017-75fc-b4ff-99be90ca6214	Test lab	\N	019b401d-f6b0-7d49-869a-407773b197e2	019b402c-f057-71ba-867b-f12e135d0730	2025-12-28 15:13:26.551767	2025-12-28 15:13:26.551767	f	\N
019b50c8-5c60-7b63-a3bf-aee4699b0309	test updated	section/banners/019b50c8-f468-785c-ba8c-c6c60a12c079.gif	019b401d-f6b0-7d49-869a-407773b197e2	019b402c-f057-71ba-867b-f12e135d0730	2025-12-24 14:34:26.784853	2025-12-24 14:36:23.912838	t	2026-01-07 05:33:04.89553
019b97b4-d13e-7d11-b81f-82f92a124c6c	Sec 03	\N	019b401d-f6b0-7d49-869a-407773b197e2	019b402c-f057-71ba-867b-f12e135d0730	2026-01-07 09:06:08.31894	2026-01-07 09:06:08.31894	f	\N
019bb036-8b46-7386-8afc-0d9629f81a79	New section	\N	019b401d-f6b0-7d49-869a-407773b197e2	019b402c-f057-71ba-867b-f12e135d0730	2026-01-12 03:18:43.270555	2026-01-12 03:18:43.270555	f	\N
\.


--
-- Data for Name: semesters; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.semesters (id, name, type, started_date, created_at, updated_at, is_deleted, deleted_at) FROM stdin;
019b402c-f057-71ba-867b-f12e135d0730	2025	second	2025-12-11	2025-12-21 09:10:45.591452	2025-12-21 09:10:45.591452	f	\N
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.tags (id, name) FROM stdin;
019b41a9-f769-7355-8e01-d2ccf420c917	python
\.


--
-- Data for Name: user_groups; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.user_groups (id, name) FROM stdin;
019b3f96-8449-795a-8fe2-8b4df9d79728	Postman Users
019b43e5-f488-7438-b5a0-b3a7fed810b2	Nisit2025
\.


--
-- Data for Name: user_passwords; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.user_passwords (user_id, password) FROM stdin;
019b3f96-847c-7b10-a398-1a433ef1198b	$2a$10$a4UOJIDF7pkKIBKL09l2Fesqeqd3R35mWilKniXT1CYohhGPgQgHS
019b43f1-237d-7d52-9bdc-b46fe3100586	$2a$10$iDcHMxLyAe5lC7P7I/gc..EFbl24MP2ewsu94Q7LW3GbQoYdBmXqa
\.


--
-- Data for Name: user_refresh_tokens; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.user_refresh_tokens (user_id, token) FROM stdin;
019b3f96-847c-7b10-a398-1a433ef1198b	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjgyOTc4NDUsImlzcyI6ImNzLWxhYi1iYWNrZW5kIiwic3ViIjoiMDE5YjNmOTYtODQ3Yy03YjEwLWEzOTgtMWE0MzNlZjExOThiIn0.4cKMgV4D9ZLS7wSmXohdppbYn6myBHo0cCHn5O6UXRA
019b401a-994b-7421-b42b-5eaf5adbfc85	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3Njk4NTY2MTgsImlzcyI6ImNzLWxhYi1iYWNrZW5kIiwic3ViIjoiMDE5YjQwMWEtOTk0Yi03NDIxLWI0MmItNWVhZjVhZGJmYzg1In0.281fbQXQNYrFUB2Zs0Vw9JT0N3BcgvRhLSj9uUXft2k
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: cs_pg_user
--

COPY public.users (id, email, type, username, display_name, profile_image, roles, group_id, created_at, updated_at, is_deleted, deleted_at) FROM stdin;
019b3f96-847c-7b10-a398-1a433ef1198b	\N	credential	postman_admin	Postman Admin	\N	{admin}	019b3f96-8449-795a-8fe2-8b4df9d79728	2025-12-21 06:26:27.58107	2025-12-21 06:26:27.58107	f	\N
019b401a-994b-7421-b42b-5eaf5adbfc85	sornchaithedev@gmail.com	oauth	SornchaiTheDev	Sornchai Somsakul	https://lh3.googleusercontent.com/a/ACg8ocLpi4nmFXSgas3OCJJatBRtaHLY7iBa4-te8PjzhqFkHtegkeaW=s96-c	{admin}	\N	2025-12-21 08:50:43.659338	2025-12-21 08:50:48.713888	f	\N
019b43f1-237d-7d52-9bdc-b46fe3100586	\N	credential	nisit_0021	Nisit 1	\N	{student}	019b43e5-f488-7438-b5a0-b3a7fed810b2	2025-12-22 02:43:55.390221	2025-12-22 02:43:55.390221	f	\N
\.


--
-- Name: auth_logs auth_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.auth_logs
    ADD CONSTRAINT auth_logs_pkey PRIMARY KEY (id);


--
-- Name: code_materials code_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.code_materials
    ADD CONSTRAINT code_materials_pkey PRIMARY KEY (material_id);


--
-- Name: course_creators course_creators_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.course_creators
    ADD CONSTRAINT course_creators_pkey PRIMARY KEY (course_id, creator_id, "order");


--
-- Name: courses courses_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.courses
    ADD CONSTRAINT courses_pkey PRIMARY KEY (id);


--
-- Name: default_labs default_labs_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.default_labs
    ADD CONSTRAINT default_labs_pkey PRIMARY KEY (id);


--
-- Name: lab_materials lab_materials_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_materials
    ADD CONSTRAINT lab_materials_pkey PRIMARY KEY (id);


--
-- Name: lab_sections lab_sections_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_sections
    ADD CONSTRAINT lab_sections_pkey PRIMARY KEY (id);


--
-- Name: labs labs_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.labs
    ADD CONSTRAINT labs_pkey PRIMARY KEY (id);


--
-- Name: material_tags material_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.material_tags
    ADD CONSTRAINT material_tags_pkey PRIMARY KEY (material_id, tag_id);


--
-- Name: materials materials_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT materials_pkey PRIMARY KEY (id);


--
-- Name: user_groups name; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT name UNIQUE (name);


--
-- Name: section_instructors section_instructors_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_instructors
    ADD CONSTRAINT section_instructors_pkey PRIMARY KEY (section_id, instructor_id);


--
-- Name: section_logs section_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_logs
    ADD CONSTRAINT section_logs_pkey PRIMARY KEY (id);


--
-- Name: section_students section_students_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_students
    ADD CONSTRAINT section_students_pkey PRIMARY KEY (section_id, student_id);


--
-- Name: section_tas section_tas_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_tas
    ADD CONSTRAINT section_tas_pkey PRIMARY KEY (section_id, ta_id);


--
-- Name: sections sections_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT sections_pkey PRIMARY KEY (id);


--
-- Name: semesters semesters_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.semesters
    ADD CONSTRAINT semesters_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: tags unique_tag_name; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT unique_tag_name UNIQUE (name);


--
-- Name: user_groups user_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_groups
    ADD CONSTRAINT user_groups_pkey PRIMARY KEY (id);


--
-- Name: user_passwords user_passwords_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_passwords
    ADD CONSTRAINT user_passwords_pkey PRIMARY KEY (user_id);


--
-- Name: user_refresh_tokens user_refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_refresh_tokens
    ADD CONSTRAINT user_refresh_tokens_pkey PRIMARY KEY (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: unique_active_course; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_active_course ON public.courses USING btree (name) WHERE ((is_deleted = false) AND (is_archived = false));


--
-- Name: unique_active_email; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_active_email ON public.users USING btree (email) WHERE ((is_deleted = false) AND (email IS NOT NULL));


--
-- Name: unique_active_section; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_active_section ON public.sections USING btree (name, course_id, semester_id) WHERE (is_deleted = false);


--
-- Name: unique_active_semester; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_active_semester ON public.semesters USING btree (name, type) WHERE (is_deleted = false);


--
-- Name: unique_active_username; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_active_username ON public.users USING btree (username) WHERE (is_deleted = false);


--
-- Name: unique_default_lab; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_default_lab ON public.default_labs USING btree (lab_id, course_id) WHERE (is_deleted = false);


--
-- Name: unique_display_name; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_display_name ON public.labs USING btree (display_name) WHERE (is_deleted = false);


--
-- Name: unique_lab_material; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_lab_material ON public.lab_materials USING btree (lab_id, material_id) WHERE (is_deleted = false);


--
-- Name: unique_lab_section; Type: INDEX; Schema: public; Owner: cs_pg_user
--

CREATE UNIQUE INDEX unique_lab_section ON public.lab_sections USING btree (lab_id, section_id) WHERE (is_deleted = false);


--
-- Name: course_creators fk_course_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.course_creators
    ADD CONSTRAINT fk_course_id FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: labs fk_course_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.labs
    ADD CONSTRAINT fk_course_id FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: default_labs fk_course_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.default_labs
    ADD CONSTRAINT fk_course_id FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: sections fk_course_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_course_id FOREIGN KEY (course_id) REFERENCES public.courses(id) ON DELETE CASCADE;


--
-- Name: materials fk_created_by; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.materials
    ADD CONSTRAINT fk_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: labs fk_created_by; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.labs
    ADD CONSTRAINT fk_created_by FOREIGN KEY (created_by) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: course_creators fk_creator_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.course_creators
    ADD CONSTRAINT fk_creator_id FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: users fk_group_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_group_id FOREIGN KEY (group_id) REFERENCES public.user_groups(id) ON DELETE SET NULL;


--
-- Name: section_instructors fk_instructor_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_instructors
    ADD CONSTRAINT fk_instructor_id FOREIGN KEY (instructor_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: default_labs fk_lab_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.default_labs
    ADD CONSTRAINT fk_lab_id FOREIGN KEY (lab_id) REFERENCES public.labs(id) ON DELETE CASCADE;


--
-- Name: lab_materials fk_lab_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_materials
    ADD CONSTRAINT fk_lab_id FOREIGN KEY (lab_id) REFERENCES public.labs(id) ON DELETE CASCADE;


--
-- Name: lab_sections fk_lab_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_sections
    ADD CONSTRAINT fk_lab_id FOREIGN KEY (lab_id) REFERENCES public.labs(id) ON DELETE CASCADE;


--
-- Name: code_materials fk_material_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.code_materials
    ADD CONSTRAINT fk_material_id FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: lab_materials fk_material_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_materials
    ADD CONSTRAINT fk_material_id FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: material_tags fk_material_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.material_tags
    ADD CONSTRAINT fk_material_id FOREIGN KEY (material_id) REFERENCES public.materials(id) ON DELETE CASCADE;


--
-- Name: lab_sections fk_section_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.lab_sections
    ADD CONSTRAINT fk_section_id FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: section_instructors fk_section_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_instructors
    ADD CONSTRAINT fk_section_id FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: section_students fk_section_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_students
    ADD CONSTRAINT fk_section_id FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: section_tas fk_section_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_tas
    ADD CONSTRAINT fk_section_id FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: section_logs fk_section_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_logs
    ADD CONSTRAINT fk_section_id FOREIGN KEY (section_id) REFERENCES public.sections(id) ON DELETE CASCADE;


--
-- Name: sections fk_semester_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.sections
    ADD CONSTRAINT fk_semester_id FOREIGN KEY (semester_id) REFERENCES public.semesters(id) ON DELETE CASCADE;


--
-- Name: section_students fk_student_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_students
    ADD CONSTRAINT fk_student_id FOREIGN KEY (student_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: section_tas fk_ta_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_tas
    ADD CONSTRAINT fk_ta_id FOREIGN KEY (ta_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: material_tags fk_tag_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.material_tags
    ADD CONSTRAINT fk_tag_id FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: auth_logs fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.auth_logs
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: user_passwords fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_passwords
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_refresh_tokens fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.user_refresh_tokens
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: section_logs fk_user_id; Type: FK CONSTRAINT; Schema: public; Owner: cs_pg_user
--

ALTER TABLE ONLY public.section_logs
    ADD CONSTRAINT fk_user_id FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict Q2fMr4gLw7AYilcRGv1ihO7ZzhBavVKhzxLgGQIR4Y0ia3owcoTTByRnaW8qlG4

