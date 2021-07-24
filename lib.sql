--
-- PostgreSQL database dump
--

-- Dumped from database version 10.13
-- Dumped by pg_dump version 10.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: DATABASE postgres; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON DATABASE postgres IS 'default administrative connection database';


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


--
-- Name: classe_libri_associati(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.classe_libri_associati(classid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (SELECT * FROM libri_classe WHERE id_classe="classid") THEN
RETURN TRUE;
ELSE
return FALSE;
END IF;
END;
$$;


ALTER FUNCTION public.classe_libri_associati(classid integer) OWNER TO postgres;

--
-- Name: filtra_ordini_all(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.filtra_ordini_all() RETURNS TABLE(id integer, nome character varying, tipo character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  
(select d.id, d.nome, 'distributore'::VARCHAR as tipo from distributore d where d.id in (
select distributore from ordini o where o.id in(select id_ordine from ordine_prenotazioni op
join prenotazioni_studente ps on ps.id=op.id_prenotazione where ps.stato='In ordine'
 )))
Union ALL
(select ce.id, ce.nome, 'casa editrice' as tipo from case_editrici ce where ce.id in (
select casa_editrice from ordini o where o.id in(select id_ordine from ordine_prenotazioni op
join prenotazioni_studente ps on ps.id=op.id_prenotazione where ps.stato='In ordine'
)));
END;
$$;


ALTER FUNCTION public.filtra_ordini_all() OWNER TO postgres;

--
-- Name: filtra_ordini_by_id_and_tipo(character varying, character varying); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.filtra_ordini_by_id_and_tipo(_id character varying, _tipo character varying) RETURNS TABLE(id bigint, id_prenotazione bigint, id_ordine bigint, libro json, distributore json, data timestamp without time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
IF _tipo = 'distributore' THEN
  RETURN QUERY
select  _op.*,json_build_object('libro', row_to_json(l.*),'ce_nome',ce.nome) as libro, row_to_json(d.*) as "distributore", _ord.data from ordine_prenotazioni _op
INNER JOIN ordini _ord ON _ord.id = _op.id_ordine
inner join distributore d ON d.id=_ord.distributore
INNER JOIN prenotazioni_studente ps ON ps.id = _op.id_prenotazione
INNER JOIN libri l ON ps.libro = l.id
INNER JOIN case_editrici ce ON ce.id=l.casa_editrice
  where _op.id_ordine in(select o.id from ordini o
WHERE o.distributore=_id::int8
 ) AND ps.stato = 'In ordine';
ELSE 
RETURN QUERY
select  _op.*,json_build_object('libro', row_to_json(l.*)) as libro, row_to_json(ce.*) as "distributore", _ord.data from ordine_prenotazioni _op
INNER JOIN ordini _ord ON _ord.id = _op.id_ordine
inner join case_editrici ce ON ce.id=_ord.casa_editrice
INNER JOIN prenotazioni_studente ps ON ps.id = _op.id_prenotazione
INNER JOIN libri l ON ps.libro = l.id
  where _op.id_ordine in(select o.id from ordini o
WHERE o.casa_editrice=_id::int8
AND o.distributore IS null
 ) AND ps.stato = 'In ordine'
;
END IF;
END;
$$;


ALTER FUNCTION public.filtra_ordini_by_id_and_tipo(_id character varying, _tipo character varying) OWNER TO postgres;

--
-- Name: get_bookings_nor_in_waiting(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_bookings_nor_in_waiting() RETURNS TABLE(prenotazione_id bigint, libro_id integer, titolo character varying, codice_isbn character varying, casa_editrice json)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
     EXECUTE 'SELECT ps."id" as prenotazione_id, l.id as libro_id, l.titolo, l.codice_isbn, row_to_json(ce.*) as casa_editrice from prenotazioni_studente ps
INNER JOIN libri l on l."id"=ps.libro
INNER JOIN case_editrici ce ON ce."id"=l.casa_editrice
WHERE ps.stato=$1'
    USING 'Attesa';
  RETURN;
END;
$_$;


ALTER FUNCTION public.get_bookings_nor_in_waiting() OWNER TO postgres;

--
-- Name: get_libri_associated_by_class_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_libri_associated_by_class_id(classid integer) RETURNS TABLE(id integer, casa_editrice character varying, titolo character varying, codice_isbn character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
     EXECUTE 'SELECT l.id, ce.nome, l.titolo, l.codice_isbn FROM libri l
INNER JOIN case_editrici ce ON ce.id = l.casa_editrice
WHERE l."id" in (select id_libro FROM libri_classe where id_classe = $1) 
ORDER BY l.id desc'
    USING classid;
  RETURN;
END;
$_$;


ALTER FUNCTION public.get_libri_associated_by_class_id(classid integer) OWNER TO postgres;

--
-- Name: get_libri_not_associated_by_class_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_libri_not_associated_by_class_id(classid integer) RETURNS TABLE(id integer, casa_editrice character varying, titolo character varying, materia character varying, codice_isbn character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
     EXECUTE 'SELECT l.id, ce.nome, l.titolo, l.materia, l.codice_isbn FROM libri l
INNER JOIN case_editrici ce ON ce.id = l.casa_editrice
WHERE l."id" NOT in (select id_libro FROM libri_classe where id_classe = $1) ORDER BY l.id DESC'
    USING classid;
  RETURN;
END;
$_$;


ALTER FUNCTION public.get_libri_not_associated_by_class_id(classid integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: case_editrici; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.case_editrici (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    iva character varying(255) DEFAULT '0'::character varying,
    indirizzo character varying(255),
    citta character varying(255),
    provincia character(2),
    mail character varying(255),
    telefono character varying(255),
    cap character(5) NOT NULL
);


ALTER TABLE public.case_editrici OWNER TO postgres;

--
-- Name: casa_editrice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.casa_editrice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.casa_editrice_id_seq OWNER TO postgres;

--
-- Name: casa_editrice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.casa_editrice_id_seq OWNED BY public.case_editrici.id;


--
-- Name: classi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classi (
    id integer NOT NULL,
    scuola integer,
    nome character varying(255)
);


ALTER TABLE public.classi OWNER TO postgres;

--
-- Name: classi_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classi_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.classi_id_seq OWNER TO postgres;

--
-- Name: classi_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classi_id_seq OWNED BY public.classi.id;


--
-- Name: distributore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.distributore (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    citta character varying(255),
    indirizzo character varying(255),
    iva character varying(255),
    mail character varying(255),
    telefono character varying(255),
    provincia character(2),
    cap character(5) NOT NULL
);


ALTER TABLE public.distributore OWNER TO postgres;

--
-- Name: distributore_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.distributore_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.distributore_id_seq OWNER TO postgres;

--
-- Name: distributore_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.distributore_id_seq OWNED BY public.distributore.id;


--
-- Name: libri; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.libri (
    id integer NOT NULL,
    casa_editrice integer,
    titolo character varying(255),
    prezzo real,
    codice_isbn character varying(255),
    tomi integer DEFAULT 1 NOT NULL,
    materia character varying(255)
);


ALTER TABLE public.libri OWNER TO postgres;

--
-- Name: libri_classe; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.libri_classe (
    id integer NOT NULL,
    id_libro integer NOT NULL,
    id_classe integer NOT NULL
);


ALTER TABLE public.libri_classe OWNER TO postgres;

--
-- Name: libri_classe_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.libri_classe_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.libri_classe_id_seq OWNER TO postgres;

--
-- Name: libri_classe_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.libri_classe_id_seq OWNED BY public.libri_classe.id;


--
-- Name: libri_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.libri_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.libri_id_seq OWNER TO postgres;

--
-- Name: libri_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.libri_id_seq OWNED BY public.libri.id;


--
-- Name: prenotazioni_studente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prenotazioni_studente (
    id bigint NOT NULL,
    studente integer NOT NULL,
    prenotazione integer NOT NULL,
    libro integer NOT NULL,
    foderatura boolean,
    cedola boolean,
    stato character varying(255)
);


ALTER TABLE public.prenotazioni_studente OWNER TO postgres;

--
-- Name: prenotazioni_studente_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prenotazioni_studente_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prenotazioni_studente_id_seq OWNER TO postgres;

--
-- Name: prenotazioni_studente_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prenotazioni_studente_id_seq OWNED BY public.prenotazioni_studente.id;


--
-- Name: ordine_prenotazioni; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ordine_prenotazioni (
    id bigint DEFAULT nextval('public.prenotazioni_studente_id_seq'::regclass) NOT NULL,
    id_prenotazione bigint NOT NULL,
    id_ordine bigint NOT NULL
);


ALTER TABLE public.ordine_prenotazioni OWNER TO postgres;

--
-- Name: ordine_prenotazioni_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ordine_prenotazioni_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ordine_prenotazioni_id_seq OWNER TO postgres;

--
-- Name: ordini; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ordini (
    id bigint NOT NULL,
    data timestamp(6) without time zone NOT NULL,
    protocollo_ext character varying(255),
    casa_editrice integer,
    distributore integer
);


ALTER TABLE public.ordini OWNER TO postgres;

--
-- Name: ordini_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ordini_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ordini_id_seq OWNER TO postgres;

--
-- Name: ordini_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ordini_id_seq OWNED BY public.ordini.id;


--
-- Name: prenotazioni; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prenotazioni (
    id integer NOT NULL,
    data timestamp(6) without time zone NOT NULL,
    caparra real,
    note text
);


ALTER TABLE public.prenotazioni OWNER TO postgres;

--
-- Name: prenotazioni_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.prenotazioni_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prenotazioni_id_seq OWNER TO postgres;

--
-- Name: prenotazioni_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.prenotazioni_id_seq OWNED BY public.prenotazioni.id;


--
-- Name: scuole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scuole (
    id integer NOT NULL,
    nome character varying(255),
    tipologia character varying(255)
);


ALTER TABLE public.scuole OWNER TO postgres;

--
-- Name: scuole_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scuole_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.scuole_id_seq OWNER TO postgres;

--
-- Name: scuole_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scuole_id_seq OWNED BY public.scuole.id;


--
-- Name: studenti; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.studenti (
    id integer NOT NULL,
    nome character varying(255) NOT NULL,
    cognome character varying(255) NOT NULL,
    classe integer NOT NULL,
    residenza character varying(255),
    mail character varying(255),
    telefono character varying(255)
);


ALTER TABLE public.studenti OWNER TO postgres;

--
-- Name: studenti_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.studenti_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.studenti_id_seq OWNER TO postgres;

--
-- Name: studenti_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.studenti_id_seq OWNED BY public.studenti.id;


--
-- Name: v_classi_ordinate; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_classi_ordinate AS
 SELECT cl.id,
    cl.scuola,
    cl.nome,
    row_to_json(sc.*) AS scuole,
    public.classe_libri_associati(cl.id) AS associata
   FROM (public.classi cl
     JOIN public.scuole sc ON ((sc.id = cl.scuola)))
  ORDER BY sc.tipologia, sc.nome, cl.nome;


ALTER TABLE public.v_classi_ordinate OWNER TO postgres;

--
-- Name: v_libri_arrivati_studente; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_libri_arrivati_studente AS
 WITH libri_studente AS (
         SELECT l.id,
            l.casa_editrice,
            l.titolo,
            l.prezzo,
            l.codice_isbn,
            l.tomi,
            l.materia,
            ps.studente,
            ps.id AS prenotazione
           FROM (public.libri l
             JOIN public.prenotazioni_studente ps ON ((ps.libro = l.id)))
          WHERE ((ps.stato)::text = 'Arrivato'::text)
        ), studente AS (
         SELECT DISTINCT s_1.id,
            s_1.nome,
            s_1.cognome,
            s_1.classe,
            s_1.residenza,
            s_1.mail,
            s_1.telefono
           FROM (public.prenotazioni_studente ps1
             JOIN public.studenti s_1 ON ((s_1.id = ps1.studente)))
        )
 SELECT row_to_json(s.*) AS studente,
    json_agg(ls.*) AS libri
   FROM (studente s
     JOIN libri_studente ls ON ((ls.studente = s.id)))
  GROUP BY s.*;


ALTER TABLE public.v_libri_arrivati_studente OWNER TO postgres;

--
-- Name: v_libri_in_attesa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_libri_in_attesa AS
SELECT
    NULL::json AS libro,
    NULL::bigint AS num,
    NULL::character varying(255) AS casa_editrice;


ALTER TABLE public.v_libri_in_attesa OWNER TO postgres;

--
-- Name: v_libri_per_ordine; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_libri_per_ordine AS
SELECT
    NULL::bigint AS id_ordine,
    NULL::timestamp(6) without time zone AS data,
    NULL::json AS libro,
    NULL::character varying(255) AS casa_editrice,
    NULL::bigint AS quantity,
    NULL::character varying(255) AS protocollo_ext;


ALTER TABLE public.v_libri_per_ordine OWNER TO postgres;

--
-- Name: v_libriclasse; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_libriclasse AS
 SELECT DISTINCT lc.id_libro,
    c.nome
   FROM ((public.libri_classe lc
     JOIN public.libri l ON ((lc.id_libro = l.id)))
     JOIN public.classi c ON ((c.id = lc.id_classe)));


ALTER TABLE public.v_libriclasse OWNER TO postgres;

--
-- Name: v_lista_libri; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_lista_libri AS
 SELECT prenotazioni_studente.id,
    prenotazioni_studente.studente,
    prenotazioni_studente.prenotazione,
    prenotazioni_studente.libro,
    prenotazioni_studente.foderatura,
    prenotazioni_studente.cedola,
    prenotazioni_studente.stato
   FROM public.prenotazioni_studente
UNION
 SELECT 0 AS id,
    st.id AS studente,
    0 AS prenotazione,
    l.id AS libro,
    false AS foderatura,
    false AS cedola,
    ''::character varying AS stato
   FROM (((public.libri_classe lc
     JOIN public.libri l ON ((l.id = lc.id_libro)))
     JOIN public.classi cl ON ((cl.id = lc.id_classe)))
     JOIN public.studenti st ON ((st.classe = cl.id)))
  WHERE (NOT (lc.id_libro IN ( SELECT ps.libro
           FROM public.prenotazioni_studente ps
          WHERE (ps.studente = st.id))));


ALTER TABLE public.v_lista_libri OWNER TO postgres;

--
-- Name: v_order_waiting; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_order_waiting AS
SELECT
    NULL::json AS ordine_prenotazioni,
    NULL::json AS prenotazioni_studente,
    NULL::json AS prenotazione,
    NULL::json AS libri;


ALTER TABLE public.v_order_waiting OWNER TO postgres;

--
-- Name: v_ordini_in_attesa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_ordini_in_attesa AS
 SELECT row_to_json(op.*) AS ordine_prenotazioni,
    row_to_json(ps.*) AS prenotazioni_studente,
    row_to_json(p.*) AS prenotazione
   FROM ((public.ordine_prenotazioni op
     JOIN public.prenotazioni_studente ps ON ((ps.id = op.id_prenotazione)))
     JOIN public.prenotazioni p ON ((p.id = ps.prenotazione)))
  WHERE ((ps.stato)::text = 'Attesa'::text);


ALTER TABLE public.v_ordini_in_attesa OWNER TO postgres;

--
-- Name: v_ordini_object; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_ordini_object AS
 SELECT o.id,
    o.data,
    o.protocollo_ext,
    o.distributore,
    row_to_json(d.*) AS object
   FROM public.ordini o,
    public.distributore d
  WHERE ((o.distributore IS NOT NULL) AND (o.distributore = d.id))
UNION ALL
 SELECT o.id,
    o.data,
    o.protocollo_ext,
    o.casa_editrice AS distributore,
    row_to_json(c_e.*) AS object
   FROM public.ordini o,
    public.case_editrici c_e
  WHERE ((o.distributore IS NULL) AND (o.casa_editrice = c_e.id));


ALTER TABLE public.v_ordini_object OWNER TO postgres;

--
-- Name: v_prenotazioni; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prenotazioni AS
 SELECT DISTINCT ps.studente,
    p.id,
    p.data,
    p.caparra,
    s.nome,
    s.cognome,
    concat(_s.nome, ' ', _cl.nome) AS scuola
   FROM ((((public.prenotazioni_studente ps
     JOIN public.studenti s ON ((s.id = ps.studente)))
     JOIN public.classi _cl ON ((_cl.id = s.classe)))
     JOIN public.scuole _s ON ((_s.id = _cl.scuola)))
     JOIN public.prenotazioni p ON ((p.id = ps.prenotazione)));


ALTER TABLE public.v_prenotazioni OWNER TO postgres;

--
-- Name: v_prenotazioni_in_attesa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_prenotazioni_in_attesa AS
 SELECT row_to_json(ps.*) AS prenotazioni_studente,
    row_to_json(p.*) AS prenotazione
   FROM (public.prenotazioni_studente ps
     JOIN public.prenotazioni p ON ((p.id = ps.prenotazione)))
  WHERE ((ps.stato)::text = 'In ordine'::text);


ALTER TABLE public.v_prenotazioni_in_attesa OWNER TO postgres;

--
-- Name: v_studenti_dettagli; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_studenti_dettagli AS
 SELECT _s.nome,
    _s.cognome,
    _cl.id AS id_classe
   FROM (public.studenti _s
     JOIN public.classi _cl ON ((_cl.id = _s.classe)));


ALTER TABLE public.v_studenti_dettagli OWNER TO postgres;

--
-- Name: case_editrici id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_editrici ALTER COLUMN id SET DEFAULT nextval('public.casa_editrice_id_seq'::regclass);


--
-- Name: classi id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classi ALTER COLUMN id SET DEFAULT nextval('public.classi_id_seq'::regclass);


--
-- Name: distributore id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distributore ALTER COLUMN id SET DEFAULT nextval('public.distributore_id_seq'::regclass);


--
-- Name: libri id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri ALTER COLUMN id SET DEFAULT nextval('public.libri_id_seq'::regclass);


--
-- Name: libri_classe id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri_classe ALTER COLUMN id SET DEFAULT nextval('public.libri_classe_id_seq'::regclass);


--
-- Name: ordini id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordini ALTER COLUMN id SET DEFAULT nextval('public.ordini_id_seq'::regclass);


--
-- Name: prenotazioni id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni ALTER COLUMN id SET DEFAULT nextval('public.prenotazioni_id_seq'::regclass);


--
-- Name: prenotazioni_studente id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni_studente ALTER COLUMN id SET DEFAULT nextval('public.prenotazioni_studente_id_seq'::regclass);


--
-- Name: scuole id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scuole ALTER COLUMN id SET DEFAULT nextval('public.scuole_id_seq'::regclass);


--
-- Name: studenti id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studenti ALTER COLUMN id SET DEFAULT nextval('public.studenti_id_seq'::regclass);


--
-- Data for Name: case_editrici; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.case_editrici (id, nome, iva, indirizzo, citta, provincia, mail, telefono, cap) FROM stdin;
1	A. MONDADORI				  			     
2	B. MONDADORI				  			     
3	PEARSON				  			     
4	IL CAPITELLO				  			     
5	PICCOLI				  			     
7	ELI				  			     
8	FABBRI SCUOLA				  			     
6	GIUNTI SCUOLA				  			     
9	OXFORD UNIVERSITY PRESS				  			     
10	LANG EDIZIONI				  			     
11	LA SPIGA				  			     
12	MINERVA ITALICA				  			     
13	CELTING PUBLISHING				  			     
14	LISCIANI SCUOLA				  			     
15	ARDEA				  			     
17	RAFFAELLO				  			     
19	ATLAS				  			     
18	CAMBRIDGE UNIVERSITY PRESS				  			     
20	ZANICHELLI				  			     
21	CETEM				  			     
22	SEI				  			     
23	CEDAM				  			     
24	LATTES				  			     
25	LOESCHER				  			     
26	ARCHIMEDE				  			     
27	PARAVIA				  			     
28	PETRINI				  			     
29	MURSIA				  			     
30	LE MONNIER				  			     
31	DEL BORGO				  			     
32	MARIETTI				  			     
33	LA NUOVA ITALIA				  			     
34	DE AGOSTINI				  			     
35	PARAMOND				  			     
16	LA SCUOLA elem				  			     
36	LA SCUOLA medie/sup				  			     
37	SANSONI				  			     
38	THEOREMA				  			     
39	HOEPLI				  			     
40	ELECTA				  			     
41	PRINCIPATO				  			     
42	LATERZA				  			     
43	TRAMONTANA				  			     
44	Poseidonia				  			     
45	GARZANTI				  			     
46	LIVIANA				  			     
48	CARLO SIGNORELLI				  			     
49	MARKES				  			     
50	SAN MARCO				  			     
51	EDINUMEN				  			     
52	SCUOLA & AZIENDA				  			     
53	JUVENILIA				  			     
54	PALUMBO				  			     
55	CIDEB				  			     
56	CLITT				  			     
57	LINX				  			     
58	SIMONE PER LA SCUOLA				  			     
59	Einaudi scuola				  			     
60	PLAN				  			     
61	D'ANNA				  			     
\.


--
-- Data for Name: classi; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.classi (id, scuola, nome) FROM stdin;
97	1	5 A
98	8	3 D
99	2	3 C
100	1	1
102	5	4
103	2	2 B
105	4	5
106	2	4 B
107	1	4 A
108	2	4 C
109	1	2 A
110	1	3 B
111	2	1
112	1	4 B
113	5	2
114	8	2 B
115	7	2 C
116	14	2 A
117	9	2 B
118	6	2 B
119	2	2 D
120	2	4 A
121	1	3 A
122	11	2 A
123	2	3 A
124	2	5 B
125	3	3 A
126	9	2 H
127	5	3
128	5	5
129	1	2 B
130	7	3 A
131	16	3 C
132	6	2 A
133	8	2 A
134	35	2 B
135	2	2 A
136	13	5 B
137	8	2 G
138	18	3
139	19	3
140	8	2 D
141	9	3 F
142	3	4 B
143	3	4 A
144	4	2 A
145	3	5 C 
146	21	4
147	3	1 D
148	14	3 B
149	18	5
150	10	2 B
151	25	3 A
152	25	1 A
153	9	2 A
154	3	2 C
155	15	2 C
157	28	3 SS
158	3	3 B
159	36	2 G
160	29	1
104	4	3 B
161	30	3 BS
156	30	2 AS
162	37	1
\.


--
-- Data for Name: distributore; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.distributore (id, nome, citta, indirizzo, iva, mail, telefono, provincia, cap) FROM stdin;
16	Moretti&Santini	Corciano	Via Veretti 3		info@morettisantini.it	075 375 40 82	PG	06073
17	Orselli	Ponte San Giovanni	Strada San Girolamo 392		libriorselli@gmail.com	075 393096	PG	06135
19	My lea			07125321211			  	     
20	Centro Libri	Brescia	Via Buozzi n. 28	02956630178	info@centrolibri.it	0303539292/3	BS	25125
21	Pearson						  	     
15	Ternana Libri	San Gemini	Via Enrico Fermi 5	IT01364530558	info@ternanalibri.com	0744 241820	TR	05029
22	GIUNTI						  	     
18	Strappaghetti	Chiugiana	Via dell'astronautica 1/B	01726960543	info@agenziastrappaghetti.com	FAX 0755179963	PG	06073
\.


--
-- Data for Name: libri; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.libri (id, casa_editrice, titolo, prezzo, codice_isbn, tomi, materia) FROM stdin;
2	5	Come il fiore nel campo plus 1-2-3	7.4000001	9788826135113	1	\N
4	7	The story garden 1	3.6400001	9788853623799	1	\N
6	8	Valigia dei sogni (LA) 1	12.04	9788891532411	1	\N
7	9	Rainbow bridge 1	3.6400001	9780194112826	1	\N
13	10	Let's be friends 4	7.26999998	9788861612013	1	\N
16	12	Cittadini del XXI° - volume unico 4°	19.3700008	9788829858170	1	\N
21	4	Libro magico 1	12.04	9788842628613	1	\N
23	13	Story lane 2	5.46999979	9788847233232	1	Inglese
24	4	Libro magico 2	16.8799992	9788842628620	1	\N
25	1	Acchiappastorie (L') 3	24.1100006	9788824768955	1	\N
27	6	Terramare matematica-4	9.68000031	9788809985971	1	\N
28	7	The story garden 4	7.26999998	9788853623928	1	\N
29	12	Cittadini del XXI°/volume antropologico 4	9.68999958	9788829858354	1	\N
30	15	Viva chi legge 4	15.5900002	9788883975776	1	\N
37	6	Lago blu 2	16.8799992	9788809985902	1	\N
39	5	Rudi 3 	24.1100006	9788826135878	1	\N
40	10	Go! + myapp 3	7.26999998	9788861616035	1	\N
42	7	Get on 4	7.26999998	9788853627193	1	\N
43	16	Esplorastorie kit 4	15.5900002	9788835050674	1	\N
72	10	Top secret premium 5	9.14000034	9788861615373	1	Inglese
44	11	@discipline.it storia-geo 4	9.68999958	9788846837592	1	\N
45	11	@discipline.it matematica-scienze 4	9.68000031	9788846837622	1	\N
48	6	Terramare unico a fascicoli-4	19.3700008	9788809983076	1	\N
51	3	Mille scintille 1	12.04	9788891911223	1	\N
52	7	Get on 1	3.6400001	9788853627162	1	\N
58	2	#Ioviaggio 2	19.2000008	9788869105630	1	Geografia
56	4	Forza ragazzi! 4 colibri mat/sci	9.68000031	9788842631828	1	\N
57	6	Terramare antropologico-4	9.68999958	9788809985964	1	\N
59	18	Go global student's 2	20.1499996	9781108610476	1	\N
64	2	Repoter 2	23.3999996	9788869103377	1	\N
65	11	Fantastici noi 1	12.04	9788846839268	1	\N
66	10	Top secret premium 1	3.6400001	9788861615335	1	\N
8	4	In volo come farfalle 1-2-3	7.44000006	9788842631712	1	Religione
67	13	Super wow 3	7.26999998	9788847228047	1	Inglese
68	3	Scintille 3	24.1100006	9788891904218	1	SUSSIDIARIO
63	20	En juego	19.2000008	9788808337351	1	\N
73	6	Che lettura! 5	18.9200001	9788809985933	1	Sussidiario dei linguaggi
74	6	Terramare monodiscipline mate 5	11.2799997	9788809983144	1	Sussidiario delle discipline scient
75	13	Super wow 4	7.26999998	9788847228054	1	Inglese
15	11	Letture di dani 4 (LE)	15.5900002	9788846839176	1	Sussidiario dei linguaggi
47	17	Officina dei linguaggi 4	15.5900002	9788847232808	1	\N
77	17	OFFICINA DELLEDISCIPLINE 4 AREASTORIA/GEOGRAFIA	9.68999958	9788847232662	1	SUSSIDIARIO DELLEDISCIPLINE - AMBITOANTROPOLOGICO(STORIA/GEOGRAFIA)
78	17	OFFICINA DELLEDISCIPLINE 4 AREAMATEMATICA/SCIENZE	9.68000031	9788847232679	1	SUSSIDIARIO DELLEDISCIPLINE - AMBITOSCIENTIFICO(MATEMATICA/SCIENZE)
79	22	Sorpresa e l'incontro (La)	19.3999996	9788805076956	1	Religione
80	23	Grammatica & co	32	9788861811409	1	Grammatica
81	24	Sostanza dei sogni (La) 1	29.7000008	9788869170645	1	Antologia
82	25	Stai per leggere...	11.1999998	9788820119683	1	Italiano
83	20	Di tempo in tempo 1	24.2000008	9788808721242	1	Storia
84	26	Terra che cambia	19.7999992	9788879527040	1	Geografia
85	18	Go global plus 1	22.2000008	9781108685641	1	Inglese
86	10	A marveille! 1	17.1000004	9788861614680	1	Francese
87	19	Noi matematici/aritmetica 1	13.3000002	9788826817514	1	Matematica
88	19	Noi matematici/geometria 1	11	9788826818511	1	Matematica
90	28	Ad arte	21.2000008	9788849421538	1	Arte
91	24	Hypertech	21.6000004	9788869175169	1	Tecnologia
76	16	IL NUOVO RACCONTOMERAVIGLIOSOCLASSE 4-5 KIT	7.44000006	9788835048763	1	Religione
49	7	Get on 2	5.46999979	9788853627179	1	Inglese
60	1	Nuovo amico libro 2	32.2000008	9788824774017	1	Italiano Antologia
26	10	Top secret premium 3	7.30999994	9788861615359	1	Inglese
17	10	Let's be friends 5	9.14000034	9788861612020	1	Inglese
18	11	Letture di dani 5 (LE)	19.0100002	9788846839183	1	Sussidiario dei linguaggi
19	12	Cittadini del XXI° - volume unico 5°	22.6800003	9788829858187	1	Sussidiario delle discipline
20	13	Story lane 1	3.6400001	9788847233225	1	Inglese
55	9	Rainbow bridge 4	7.30999994	9780194112918	1	\N
14	4	In volo come farfalle 4-5	7.44000006	9788842631729	1	\N
9	9	Rainbow bridge 2	5.46999979	9780194112857	1	Inglese
10	8	Valigia dei sogni (LA) 2	16.9599991	9788891532428	1	Sussidiario
11	9	Rainbow bridge 3	7.30999994	9780194112888	1	Inglese
12	8	Valigia dei sogni (LA) 3	24.2299995	9788891532435	1	Sussidiario
54	15	A scuola con fred 2	16.9599991	9788883975929	1	Sussidiario
3	6	Lago blu 1	12.1000004	9788809985896	1	Libro della prima classe
62	36	Insieme al giordano + DVD	12.6999998	9788835041443	1	Religione
35	15	Viva chi legge 5	19.0100002	9788883975851	1	Sussidiario dei linguaggi
53	5	Gioia nel cuore 1-2-3 (La)	7.44000006	9788826135885	1	Religione
36	11	Mondo di bene 1-2-3 (UN)	7.44000006	9788846839350	1	Religione
33	9	Rainbow bridge 5	9.14000034	9780194112949	1	\N
46	5	Gioia nel cuore 4-5 (La)	7.44000006	9788826135892	1	Religione
89	27	Life la natura intorno	37.5999985	9788839528285	1	Scienze
61	19	Tutti matematici plus	25.1000004	9788826820644	1	\N
69	17	GRANDE AMORE 1-2-3 (UN)	7.44000006	9788847233522	1	Religione
41	4	Insieme è bello 4-5	7.44000006	9788842631408	1	Religione
32	11	@discipline.it storia-geo 5	11.3400002	9788846837639	1	Sussidiario delle discipline antropologico
38	7	The story garden 2	5.46999979	9788853623843	1	Inglese
98	10	Quelle chance! Plus 2	18.7000008	9788861612778	1	Francese
100	8	A rigor di logica libro misto	19	9788891545695	1	Grammatica
101	29	Come scintille 1	26.6000004	9788893240451	1	Antologia
102	8	Altra storia (Un') 1	19.6000004	9788891542649	1	Storia
103	8	Geoprotagonisti 1	16.2999992	9788891542946	1	Geografia
104	18	Make it! plus level 1	22.75	9781316623800	1	Inglese
105	10	Mira!	28	9788861616653	1	Spagnolo
106	30	Wiki math 1	25.4500008	9788800348935	1	Matematica
107	22	Sale della terra 1	12.1000004	9788805029655	1	Religione
110	2	Storia e storie 2	23.8999996	9788869104923	1	Storia
111	27	Meravigliarti	23.2999992	9788839528957	1	Arte
112	24	Tecnomedia digit	22.8999996	9788869170898	1	Tecnologia
113	28	Musica nel cuore	17.2999992	9788849421613	1	Musica
114	31	Leggermente plus 4	15.5900002	9788833711065	1	Sussidiario dei linguaggi
115	5	Gioco tra i saperi 4 sto-geo	9.68999958	9788826136202	1	Sussidiario delle discipline antrop
116	5	Gioco tra i saperi 4 mat-sci	9.68000031	9788826136196	1	Sussidiario delle discipline scient
118	32	Pietra viva	19.75	9788839302892	1	Religione
119	2	Italiano	28.6000004	9788869105296	1	Grammatica
120	30	Fino a noi 1	27.3500004	9788800353557	1	Storia
121	18	Make it! 1	21.5499992	9781316608012	1	Inglese
123	33	Matematica	23.3999996	9788822156167	1	Matematica
125	20	Tecnologia verde	26	9788808520616	1	Tecnologia
126	28	MUSICA NEL CUORE + EBOOK / VOLUME A +  VOLUMEB + EASY EBOOK A + B (SU DVD)	34.4500008	9788849421583	1	Musica
127	32	Sportbook	8.64999962	9788839303271	1	Scienze motorie
128	34	Senza confini 2	19.6499996	9788851128210	1	Geografia
129	28	Game on 2	20.2000008	9788849421798	1	Inglese
130	24	Matematica aritmetica 2	14.1000004	9788869170928	1	Aritmetica
131	24	Matematica geometria 2	12.3000002	9788869171079	1	Geometria
132	20	Ora di storia 2	26	9788808853769	1	Storia
133	20	Libro sogna	17.2000008	9788808592095	1	Antologia
135	18	GET THINKING 2	27.9500008	9781107517110	1	Inglese
136	10	¿TU ESPAñOL? ¡YA ESTá! 2	21.7000008	9788861615588	1	Spagnolo
137	2	La storia che vive 2	21.7000008	9788869103193	1	Storia
138	20	Geografia territori 2	21.1000004	9788808454591	1	Geografia
139	28	Colori della matematica ross 2	28.6000004	9788849422252	1	Matematica
140	20	Scopriamo la chimica	15.8000002	9788808821225	1	Chimica
142	1	Esplorare la vita 3	24.2000008	9788824763462	1	Biologia
143	35	Vivere il diritto e l'economia 2	12.8999996	9788861601635	1	Diritto ed economia
144	22	Sale della terra 2	12.5	9788805029662	1	Religione
145	10	Quelle chance! Plus 1	18.7000008	9788861612747	1	Francese
109	20	Contaci-conf 2	25.8999996	9788808547477	1	Matematica
146	37	In arte	16.2999992	9788838336379	1	Arte
147	2	#Ioviaggio 1	19.2999992	9788869105623	1	Geografia
148	9	High five 1	23.5	9780194603911	1	Inglese
149	1	Nuovo amico libro 1	28.5	9788824773744	1	italiano antologia
150	8	A rigor di logica libro misto con libro digitale	25.3999996	9788891548443	1	Grammatica
151	20	Contaci! 1	27.2999992	9788808921277	1	Matematica
152	12	Sonora	35.3499985	9788829844272	1	Musica
153	36	Insieme al Giordano 1	10.3999996	9788835042990	1	Religione
154	4	Mondo scienza lab	36.7999992	9788842652373	1	Scienze
155	20	En juego 1 - seconda ediz	18.7999992	9788808321220	1	Spagnolo
156	1	Incontra la storia 1	24.7999992	9788824762786	1	Storia
157	27	Tecnocloud	23.2000008	9788839521545	1	Tecnologia
158	38	Colori della luce 4,5	7.4000001	9788825909524	1	Religione
160	20	RES  PUBLICA 4ED . - VOL. UNICO  (LDM)	24.5	9788808420299	1	Diritto ed Economia
161	24	Sostanza dei sogni (La) 2	20.1000004	9788869170713	1	Antologia
167	19	Noi matematici/geometria 2	11.3000002	9788826818528	1	Matematica/geometria
169	24	SOSTANZA DEI SOGNI (LA) / VOL. 2 CON DVD + LETTERATURATEATRO+TAVOLE+QUADERNO DELLE COMPETENZE2	31.3999996	9788869170652	1	Antologia
122	10	A marveille 	28.8999996	9788861616202	1	Francese
173	2	Forte e chiaro	25.7000008	9788869103100	1	Italiano
174	22	Promessi Sposi + DVD	19.7000008	9788805075324	1	Italiano
176	27	Verso la prova invalsi di italiano	6.9000001	9788839537676	1	Italiano
175	20	Testi e immaginazioni	19.1000004	9788808301154	1	Italiano
177	20	Performer B1 2 ed. vol 1	24.2999992	9788808420657	1	Inglese
178	28	colori della matematica- ed. verde vol 1	32.2000008	9788849421729	1	Matematica
108	3	Just right!Premium 2	22.6000004	9788883394690	1	Inglese
92	8	A rigor di logica	6.5	9788891545701	1	Grammatica
93	29	Come scintille 2	31.2999992	9788893240604	1	Antologia
94	8	Altra storia (Un') 2	22.8999996	9788891542595	1	Storia
95	8	Geoprotagonisti 2	21.2000008	9788891542991	1	Geografia
97	18	Make it! plus level 2	23.2000008	9781316623817	1	Inglese
99	30	Wiki math 2	26.7000008	9788800349031	1	Matematica
117	17	Super prezioso 2	16.9599991	9788847232136	1	Sussidiario
162	20	Di tempo in tempo 2	25.6000004	9788808979438	1	Storia
164	18	Go global plus 2	22.7000008	9781108685658	1	Inglese
166	19	Noi matematici/aritmetica 2	13.6999998	9788826817521	1	Matematica/aritmetica
165	10	A marveille! 2	17.3999996	9788861614710	1	Francese
159	10	Top secret premium 2	5.46999979	9788861615342	1	Inglese
171	18	Make it! 2	22	9781316608036	1	Inglese
170	30	Fino a noi 2	27	9788800353755	1	Storia
179	11	Impronte	16.8999996	9788846836007	1	Religione
180	20	Chimica: molecole in movimento	34.5999985	9788808269409	1	Chimica
181	20	Fisica verde - vol 1	22.2999992	9788808327895	1	Fisica
182	1	Libro della terra	22.3500004	9788824763387	1	Scienze della terra e biologia
183	4	Studenti informati	11.3999996	9788842662532	1	Scienze motorie
184	1	Storia per un apprendimento pemanente vol. 1	22.3999996	9788824760591	1	Storia
185	22	Graph - disegno 1	13.1999998	9788805076680	1	Tecnologie e tecniche
186	39	Tecnologie informatiche	20.8999996	9788820366674	1	Tecnologie informatiche
187	34	Ora geo	11.6499996	9788851128272	1	Geografia
189	20	Vita da lettori	19.8999996	9788808875099	1	Italiano
190	20	Performer B1 2 ed. vol 2	24	9788808367167	1	Inglese
191	28	colori della matematica- ed. verde vol 2	32.2000008	9788849421736	1	Matematica
192	12	Forward 2 ed.	23.75	9788829845354	1	Scienze e tecnologie applicate
193	20	Fisica verde - vol 2	22.6000004	9788808719447	1	Fisica
194	19	Corso di scienze integrate	20.6000004	9788826816319	1	Scienze della terra e biologia
195	1	Storia per un apprendimento pemanente vol. 2	22.3999996	9788824760652	1	Storia
196	22	Graph - autocad + CD Rom	8.89999962	9788805076710	1	Tecnologie e tecniche di rappresentazione grafica
197	22	Graph - disegno 2	14.1999998	9788805076697	1	Tecnologie e tecniche di rappresentazione grafica
198	19	Grafica e arte	26.6000004	9788826815367	1	Discipline grafiche e pittpriche
199	40	Manuali d'arte	25.8999996	9788863080520	1	Disegno 
200	41	Itinera	23.7999992	9788841632628	1	Geostoria
202	27	Un incontro inatteso ed. plus	23.5	9788839536211	1	Antologia
203	27	Più bello dei mari	12.3000002	9788839526298	1	Epica
204	8	Chiaramente	22.7000008	9788891513540	1	Grammatica
205	20	Matematica azzurro 2 ed. vol. 1	27.7000008	9788808237347	1	Matematica
206	22	Orizzonti	16.2999992	9788805070800	1	Religione
207	20	Scienze integrate	25.7000008	9788808820464	1	Scienze integrate
70	21	Le avventure  di Amica stella 1	12.04	9788847306592	1	Libro prima classe
209	3	Just right! Premium 1	22.2000008	9788883394676	1	Inglese
210	10	Paris decouverte	28	9788861616509	1	Francese
211	18	Go global student's 1	19.8999996	9781108610438	1	Inglese
212	19	Tutti matematici plus	24.5	9788826820637	1	Matematica
213	2	Storia e storie 1	23.8999996	9788869104909	1	Storia
215	2	Reporter 1	23.7999992	9788869103360	1	Storia
246	39	Sistemi e automazione	25.8999996	9788820378349	1	Sistemi e automazione
208	42	Arte in opera 1 9788842115489	27.8999996	9788842114161	1	Storia dell'arte
216	12	Leggere è 5 - volume unico	18.9200001	9788829854660	1	Sussidiario dei linguaggi
219	39	Nuovo sta - scienze e tecn appl meccanica	20.5	9788820366599	1	Scienze e tecnologie applicate
222	27	Le occasioni della letteratura 2 edizione nuovo esame di stato	31.3999996	9788839536549	1	Italiano Letteratura
223	42	Pospettive della storia ed. arancio vol. 2	0	9788842115175	1	Storia
224	19	Matematica per gli istituti tecnici ed economici	22.7999992	9788826818214	1	Matematica
227	19	Pro.sia informatica e processi aziendali	22.8999996	9788826820187	1	Informatica
228	43	Entriamo in azienda up libro misto con libro digitale vol. 2	46.2000008	9788823362642	1	Economia Aziendale
229	24	Matematica teoria esercizi digit - aritmetica b con dvd	14.1000004	9788869170928	1	Matematica Aritmetica
230	24	Matematica teoria esercizi digit - geometria b con dvd	12.3000002	9788869171079	1	Matematica Geometria
232	42	Arte svelata ed.plus 2017	24.8999996	9788842115526	1	Storia dell'arte
233	44	Lavoriamo con le scienze e tecnologie app.	24.5	9788848260961	1	Scienze e tecnologie app
234	24	Sostanza dei sogni con dvd 3	26.3999996	9788869170720	1	Italiano Antologia
235	2	Linee della storia plus 3	28.7000008	9788869101359	1	Storia
239	2	Matelive 3	26.5	9788869100383	1	Matematica
240	27	Nuovo dal progetto al prodotto 2	39.9000015	9788839529947	1	Disegno
241	45	Cuori intelligenti 2	32.4000015	9788869645204	1	Italiano
242	7	Verso le prove nazionali inglese	7.9000001	9788846838353	1	Inglese
243	28	Colori della matematica 4	27.5499992	9788849422986	1	Matematica
244	20	Corso di meccanica	38	9788808268976	1	Meccanica
245	39	Manuale di meccanica	71.9000015	9788820366452	1	Meccanica
247	2	Storia, concetti e connessioni	30.6000004	9788869101441	1	Storia
248	20	Libro sogna	18	9788808831460	1	Antologia
249	36	Guida allo studio della storia	22	9788835044093	1	Storia
250	23	Matematica in pratica 2	17.7000008	9788861811553	1	Matematica
251	1	Scienze integrate biologia	10.4499998	9788824775458	1	Biologia
252	43	Finestra sulla realtà 2	14	9788823344884	1	Diritto ed economia
253	46	Diritto e tecnica amm.	18.8999996	9788849471205	1	Diritto e tecniche amm
254	48	Porte della letteratura vol 3	34	9788843418978	1	Italiano
255	28	Matematica a colori	14.6999998	9788849420333	1	Matematica
256	49	Scienza e cultura dell'alimentazione	19.5	9788823105935	1	Scienza e cultura dell'alimentazione
257	36	Guida studio storia triennio 5	24	9788835047698	1	Storia
258	20	Chimica:concetti e mod	42.2999992	9788808820747	1	Chimica
259	20	Amaldi per i licei scient blu	28.5	9788808253989	1	Fisica
201	3	Engage 1	26.8999996	9788883393495	1	Inglese
238	10	Quelle chance! Plus 3	19	9788861612808	1	Francese
220	9	High five 2 - super premium	25.6000004	9780194603928	1	Inglese
237	18	Make it! Level 3	22	9781316608081	1	Inglese
221	2	Reporter 2	23.7999992	9788869103377	1	Storia
236	26	Terra che cambia 3	21.2000008	9788879526203	1	Geografia
260	34	Geostorica 1	25.9500008	9788851119461	1	Geostoria
261	28	Colori della matematica ediz blu vol 1	31.2000008	9788849421668	1	Matematica
262	22	Orizzonti	16.2999992	9788805070800	1	Religione
263	32	Educare al movimento	24.3999996	9788839303585	1	Scienze motorie
265	4	Supereroi 3	24.1100006	9788842631439	1	Sussidiario
226	42	Prospettive della storia ed. arancio vol. 2	28.8999996	9788842115175	1	Storia
266	20	Biologia e micro	41.5999985	9788808059796	1	Biologia
267	20	Biologia.La scienza della vita	19.7999992	9788808128225	1	Biologia
268	20	Principi di chimica analitica	24.1000004	9788808920645	1	Chimica
269	20	Chimica organica	33.5	9788808821317	1	Chimica organica
270	20	Conosciamo il corpo umano	34.9000015	9788808320537	1	Igiene, anatomia
271	20	Igiene e patologia	25	9788808192790	1	Igiene e anatomia
272	45	Cuori intelligenti ediz.verde vol1 	41.5999985	9788869645198	1	Lingua e letteratura italiana
273	50	Sciencewise	23.5	9788884883322	1	Inglese
274	28	Colori della matematica ed.verde vol.3	37.7000008	9788849422979	1	Matematica
275	2	Storia.Concetti e connessioni 1	30.6000004	9788869101427	1	Storia
276	25	Voy contigo! V.2	22.2000008	9788858328910	1	Spagnolo
277	17	Giorni di scuola 3	24.1100006	9788847227194	1	Sussidiario
278	9	New treetops gold 5	9.09000015	9780194004930	1	Inglese
279	12	Cittadini del XXI° 5 - scient	11.29	9788829858385	1	Sussid.discipline amb.scientifico
281	45	Cuori intelligenti 3	32.4000015	9788869645211	1	Italiano
282	3	Training for successfull invalsi	7.80000019	9788883394881	1	Inglese
283	20	Corso di meccanica	38	9788808406019	1	Meccanica
284	39	Guida al plc	18.8999996	9788820377199	1	Sistemi e automazione
285	39	Sistemi e automazione	25.8999996	9788820383268	1	Sistemi e automazione
286	2	Storia.Concetti e connessioni 3	32.2999992	9788869101465	1	Storia
287	27	Nuovo giramondo pl 3	22.2000008	9788839528933	1	Geografia
288	3	Just right! Premium 3	23.2999992	9788883394713	1	Inglese
289	1	Amico libro 3	30.4500008	9788824758802	1	Antologia
290	20	Matematica in azione 3	26.5	9788808892317	1	Matematica
294	20	En juego 3	19.2000008	9788808437358	1	Spagnolo
296	17	Grande amore 4-5	7.4000001	9788847233539	1	Religione
298	17	Spirito libero 4	15.5900002	9788847229839	1	Sussidiario dei linguaggi
299	6	Terramare antropol 4	9.68999958	9788809983113	1	Sussidiario delle discipline-antropolog
300	6	Terramare mate 4	9.68000031	9788809983120	1	Sussidiario delle discipline-scientif
301	8	Autori e lettori più 3	28.5	9788891534613	1	Antologia
302	8	Parola alla storia 3	21.2999992	9788891520180	1	Storia
303	8	Geonatura 3	21.3999996	9788891520364	1	Geografia
306	48	Mia letteratura	28.2999992	9788843418060	1	Letteratura
309	50	Tecnologie applicate	27	9788884882394	1	Tecnologie applicate
310	39	Nuovo tecnologie della modellistica	26.8999996	9788820366520	1	Laboratori tecnologici
311	2	La forza delle parole	31	9788869105210	1	Grammatica
312	20	Libro sogna	23.3999996	9788808721075	1	Antologia
313	18	Get thinking 1	27.9500008	9781107516854	1	Inglese
314	10	Tu espanol 1	21.7000008	9788861615571	1	Spagnolo
315	51	Ahora si!	19.8999996	9788498486889	1	Spagnolo
316	2	La storia che vive 1	21.7000008	9788869103179	1	Storia
317	20	Geografia territori 1	21.1000004	9788808720610	1	Geografia
318	28	Colori della matematica 1	28.6000004	9788849422245	1	Matematica
319	52	Compuware	22.2000008	9788824751469	1	Tecnologie informatiche
320	20	Studiamo la fisica	20.7000008	9788808737021	1	Fisica
321	35	Azienda passo passo 1	15.5	9788861603141	1	Economia aziendale
322	35	Vivere il diritto 1	12.8999996	9788861601611	1	Diritto
323	53	Energia pura	18.3999996	9788874856268	1	Scienze motorie
324	18	Essential grammar	29.1000004	9781316509036	1	Inglese
325	20	Performer heritage	28.1000004	9788808642820	1	Inglese
326	1	Storia futuro 2	27.2000008	9788824751650	1	Storia
327	36	Nuovo storia del pensiero	38	9788835044512	1	Filosofia
328	20	Lineamenti di matematica azzurro 4	20.7999992	9788808542779	1	Matematica
329	19	Civiltà d'arte 4	15.6000004	9788826817835	1	Storia dell'arte
330	12	Cittadini del XXI vol.scient 4	9.68000031	9788829858361	1	Sussidiario discipl scient
331	9	New treetops gold 4	7.26999998	9780194033923	1	Inglese
332	18	Cambridge igcse	34.9000015	9781107614796	1	Biologia
333	20	Osservare e capire	20	9788808536297	1	Scienze della terra
334	22	Sale della terra 3	12.5	9788805029679	1	Religione
124	6	Arteattiva ex cod. 9788809780644	19.7999992	9788809772670	1	Arte
336	54	Grammatica in laboratorio	15.3000002	9788860178343	1	Grammatica
337	9	Network concise	31.7000008	9780194214230	1	Inglese
339	56	Occhi del grafico	34.4000015	9788808720924	1	Tecniche prof.li dei servizi commerciali
340	52	Compuware 3° ed.	21.5499992	9788824751421	1	Tecnologie informatiche
341	2	#Ioviaggio 3	21.7999992	9788869105647	1	Geografia
295	2	Reporter 3	25.2999992	9788869103384	1	Storia
264	7	The story garden 3	7.30999994	9788853623881	1	Inglese
304	18	Make it! Plus level 3	23.2000008	9781316623824	1	Inglese
305	30	Wiki math 3	27.1000004	9788800349130	1	Matematica
297	10	Top secret premium 4	7.30999994	9788861615366	1	Inglese
335	20	Invito alla biologia	61	9788808346261	1	Biologia
307	36	Guida studio storia	22.2000008	9788835047674	1	Storia
308	23	Matematica in pratica	19.8500004	9788861811720	1	Matematica
338	55	Eiffel en ligne	29.7999992	9788853014962	1	Francese
342	9	Hig five 3	26.1000004	9780194603935	1	Inglese
343	1	Nuovo amico libro 3	31.1000004	9788824774284	1	Italiano Antologia
344	20	Contaci! conf 3	27.7999992	9788808567055	1	Matematica
293	36	Insieme al Giordano + dvd	12.6999998	9788835041450	1	Religione
345	4	Libro magico 3	24.2299995	9788842628637	1	Sussidiario
346	13	Story lane 3	7.30999994	9788847233249	1	Inglese
347	8	sorridoimparo cresce	12.1000004	9788891560391	1	Libro 1 classe
349	13	Story lane 4	7.30999994	9788847233300	1	inglese
350	17	Tesoro prezioso 4-5	7.44000006	9788847237926	1	Religione
351	15	Pianeta lettura 4	15.6700001	9788883976254	1	Sussidiario dei linguaggi
352	21	cambiamondo 4 mat-sci	9.73999977	9788847306660	1	Sussidiario delle discipline sci
353	21	cambiamondo sto-geo	9.72999954	9788847306707	1	sussidiario delle discipline ant
354	4	Tutti con il libro magico 2	16.9599991	9788842632078	1	Sussidiario
355	7	Get on 3	7.30999994	9788853627186	1	Inglese
356	3	Mille scintille 3	24.2299995	9788891910547	1	Sussidiario
357	7	Get on 5	9.14000034	9788853627209	1	Inglese
358	17	Officina dei linguaggi 5	19.0100002	9788847232853	1	Sussidiario dei linguaggi
359	6	Terramare unico a fascicoli-5	22.6800003	9788809983083	1	Sussidiario delle discipline
360	17	Geniale 4 area stori/geografia	9.72999954	9788847229761	1	Sussidiario delle discipline antropologico
361	1	Leggiamo il mondo volume unico 4	15.6700001	9788824790000	1	Sussidiario dei linguaggi
362	12	Password / volume scientifico 4	9.73999977	9788829860579	1	Sussidiaro delle discipline scientifico
31	14	Gioia di incontrarsi plus 4-5 (LA)	7.44000006	9788876273735	1	Religione
364	10	Top secret premium 4+Grammar	7.26999998	9788861617070	1	Inglese
365	8	Sorridoimparo sussidiario discipline 4 antrop	9.72999954	9788891565907	1	Suss discipline sto/geo
366	6	Terramare 2020 cl.4 mate	9.73999977	9788809982215	1	Sussidiaario delle discipline mat/scienze
22	14	Gioia di incontrarsi plus 1-2-3 (LA)	7.44000006	9788876273728	1	Religione
367	9	Learn with us 1 + CD 1	3.66000009	9780194464468	1	Inglese
369	1	Incontra la storia 2	28.2999992	9788824762076	1	storia
163	26	Terra che cambia 2	19.3999996	9788879526197	1	Geografia
370	5	Che bello è imparare 2	16.9599991	978886136479	1	sussidiario
371	21	Le avventure di Amica stella 2	16.9599991	9788847306608	1	Sussidiario
372	7	The story garden 5	9.14000034	9788853623966	1	Inglese
280	12	Cittadini del XXI° 5 - vol.antropologico	11.3400002	9788829858378	1	Sussid.discipline-ambito antropologico
34	6	Terramare matematica-5	11.3400002	9788809870468	1	SUSSIDIARIO DELLE DISCIPLINE (AMBITO SCIENTIFICO)
373	6	Lago blu 3	24.2299995	9788809985919	1	Sussidiario
374	15	A scuola con fred 3	24.2299995	9788883976001	1	Sussidiario
376	6	TERRAMARE ANTROPOLOGICO - 5	11.3400002	9788809870031	1	Sussidiario delle discipline
375	4	Forza ragazzi! 5 colibri mat/sci	11.3400002	9788842631842	1	Sussidiario della discipline
377	29	Come scintille 3	28.3999996	9788893240857	1	Italiano Antologia
378	8	Altra storia (Un') 3	24.2000008	9788891542601	1	Storia
379	8	Geoprotagonisti 3	22.3999996	9788891543004	1	Geografia
380	34	Senza confini 3	21.6000004	9788851128227	1	Geografia
381	28	Game on 3	20.6000004	9788849423419	1	Inglese
382	29	COME SCINTILLE - VOLUME 3 + TEMI	30.8999996	9788893241403	1	Italiano Antologia
383	24	MATEMATICA TEORIA ESERCIZI DIGIT - ALGEBRA CON DVD+MI PREP.PER INTERROG.+QUAD.COMPETENZE 3+QUAD.OPER.3	22.3999996	9788869170935	1	Matematica Algebra
384	24	MATEMATICA TEORIA ESERCIZI DIGIT - GEOMETRIA C CON DVD	9.10000038	9788869171086	1	Matematica Geometria
385	20	ORA DI STORIA (L') - CONFEZIONE VOLUME 3	27.2999992	9788808305596	1	Storia
368	20	Todos a la meta 2	19	9788808430922	1	Spagnolo
386	57	CAMPBELL BIOLOGIA CONCETTI E COLLEGAMENTI PLUS - PRIMO BIENNIO	23.7000008	9788863649437	1	Biologia
387	42	OCCHIO DELLA STORIA (L') VOL. 2 DALL'IMPERO ROMANO ALL'ETA CAROLINGIA	28.8999996	9788842115977	1	GeoStoria
388	54	POROS - LABORATORIO 2 LINGUA E CIVILTA GRECA	16.8999996	9788868893743	1	Greco Grammatica
389	18	TALENT 2 SB+WB+EBOOK INTERATTIVO+MATERIALI DIGITALI	29.7000008	9781108627719	1	Inglese
390	27	UN INCONTRO INATTESO B CON PERCORSO LE ORIGINI DELLA LETTERATURA	20.8999996	9788839529039	1	Italiano Antologia
391	44	TANTUCCI PLUS (IL) LABORATORIO 2	23.8999996	9788848260459	1	Latino
392	20	MATEMATICA.VERDE 2ED. - VOLUME 2 (LDM)	32.2000008	9788808302052	1	Matematica
393	32	STRADA CON L?ALTRO - EDIZIONE VERDE (LA) VOLUME UNICO + UDA MULTIDISCIPLINARI DI EDUCAZIONE CIVICA E IRC + EBOOK	17.5	9788839303943	1	Religione
394	13	SUPER WOW 5	9.14000034	9788847228061	1	inglese
395	11	LETTURE DI DANI 5 (LE)	19.0100002	9788846839183	1	sussidiaro dei linguaggi
396	17	OFFICINA DELLE DISCIPLINE 5 AREA STORIA/GEOGRAFIA	11.3400002	9788847232686	1	Sussidiario delle disc. antropologico Storia Geo
397	17	OFFICINA DELLE DISCIPLINE 5 AREA MATEMATICA/SCIENZE	11.3400002	9788847232693	1	sussidiario delle discipline scientifiche matematiche e scienze
398	1	INCONTRA LA STORIA - VOLUME 2 + ATLANTE 2 + LABORATORI 2 + ME BOOK	29.8999996	9788824754576	1	Storia
399	24	SOSTANZA DEI SOGNI (LA) - VOL. 3 CON DVD + PERCORSI ATTRAVERSO IL '900+QUADERNO DELLE COMPETENZE 3	30.7999992	9788869170669	1	Italiano Antologia
400	33	MATEMATICA (LA) - FIGURE SOLIDE + LEGGI MAT + ESPANSIONE WEB FIGURE SOLIDE + ESPANSIONE WEB LE	25.7999992	9788822155863	1	Matematica
401	30	Fino a noi 3	28.6000004	9788800353854	1	Storia
402	20	DI TEMPO IN TEMPO - VOLUME 3	27.2000008	9788808549709	1	Storia
403	18	GO GLOBAL PLUS STUDENT'S BOOK/WORKBOOK+EBOOK+DVDROM 3	22.7000008	9781108685665	1	Inglese
404	19	NOI MATEMATICI / ALGEBRA	17.8999996	9788826817538	1	Matematica
405	19	NOI MATEMATICI / GEOMETRIA 3	11.3000002	9788826818535	1	Matematica Geometria
406	10	Go Kids 4	7.30999994	9788861617025	1	Inglese
407	16	Esplorastorie plus 4 Kit	15.6700001	9788835053804	1	Sussidiario dei linguaggi
408	16	esploramondo plus storia e geografia 4 Kit	9.72999954	9788835053613	1	Sussidiaro delle discipline antropologico
409	16	Esploramondo plus matematica scienze 4 kit	9.73999977	9788835053620	1	Sussidiaro delle discipline scientifico
50	3	Mille scintille 2	16.9599991	9788891910523	1	Sussidiario
217	11	@discipline.it mate-scienze 5	11.3400002	9788846837660	1	Mate/scienze
410	16	Esplorastorie kit 5	19.0100002	9788835050681	1	Sussidiaro dei linguaggi
411	5	Che bello e! un ponte tra i popoli 4-5	7.44000006	9788826136424	1	Religione
412	11	Che spasso... leggere! 4	15.6700001	9788846840844	1	Sussidiario dei linguaggi
413	17	Nuova officina delle discipline 4 mat/sci	9.73999977	9788847237018	1	Sussidiario delle discipline mat/sci
414	4	Insieme è bello 1-2-3	7.44000006	9788842631392	1	Religione
415	4	Tutti con il libro magico 1	12.1000004	9788842632061	1	Libro prima classe
416	13	You and me friends 1	3.66000009	9788847238046	1	Inglese
417	17	Super prezioso 3	24.2299995	9788847232143	1	Sussidiario
418	17	Spirito libero 5	19.0100002	9788847229846	1	Sussidiario dei linguaggi
419	6	TERRAMARE MONODISCIPLINE ANTROP. - 5	11.3400002	9788809983137	1	SUSSIDIARIO DELLE DISCIPLINE - AMBITO ANTROPOLOGICO (STORIA/GEOGRAFIA)
420	6	TERRAMARE MONODISCIPLINE MATEM. - 5	11.3400002	9788809983144	1	SUSSIDIARIO DELLE DISCIPLINE - AMBITO SCIENTIFICO (MATEMATICA/SCIENZE)
421	11	Fantastici noi 2	16.9599991	9788846839275	1	Sussidiario
422	3	Tre amici 1	12.1000004	9788891907974	1	Libro della prima classe
348	10	Billy bot 1	3.66000009	9788861617094	1	Inglese
172	33	MATEMATICA (LA) / NUMERI B + FIGURE PIANE B + ESPANSIONEWEB NUMERI B + ESPANSIONE WEB FIGURE	23.2999992	9788822156150	1	Matematica
423	34	Geostorica 2	26.4500008	9788851119478	1	Geostoria
424	3	Engage 2	26.8999996	9788883393501	1	Inglese
425	2	Mirum iter lezioni 2	23.5	9788869102417	1	Latino
426	28	COLORI DELLA MATEMATICA - EDIZIONE BLU VOLUME 2 + QUADERNO 2 + EBOOK	31.7999992	9788849421675	1	Matematica
427	42	ARTE SVELATA (L') ED. PLUS VOL. B DAL TARDOANTICO AL GOTICO INTERNAZIONALE	18.8999996	9788842113171	1	Storia dell'arte
428	48	Mia nuova letteratura 1	26.3999996	9788843419753	1	Letteratura
429	56	Percorsi di metodologie operative	33	9788808851048	1	Metodologie operative
430	58	Igiene e cultura	23	9788891424846	1	Igiene e cultura
431	27	Comprensione e l'esperienza	32.4000015	9788839527318	1	Psicologia
432	56	Percorsi di diritto	21	9788808520067	1	Diritto
433	3	Il campbell	23	9788891915184	1	Biologia
434	59	Agenda del cittadino	8.39999962	9788828625506	1	Educazione civica
435	18	Preliminary	19.8999996	9781108528870	1	Inglese
436	3	Get into grammar	27.2000008	9788883394508	1	Inglese grammatica
437	27	Più bello dei mari B	21.2000008	9788839526311	1	Italiano antologia
438	42	Arte in opera plus 2	23.8999996	9788842114178	1	Storia dell'arte
439	2	Lontani vicini 2	27	9788869105470	1	Storia e geografia
440	52	Diritto ed economia	7.5	9788824783972	1	Diritto ed economia
441	41	Geonet	12.3000002	9788841634677	1	Geografia
442	3	Engage! compact	30.1000004	9788883394478	1	Inglese
443	33	Leggere come viaggiare	26.7000008	9788822196682	1	Antologia
444	1	A tutto campo	23.7999992	9788824778480	1	Grammatica
445	35	Benvenuti welcome	23.8999996	9788861603769	1	Laboratori servizi accoglienza
446	60	Tecniche di sala	21.8999996	9788899059453	1	LAB. DI SERVIZI ENOGASTR. SETT.SALA-VENDITA
447	39	Professionisti in cucina	22.8999996	9788820372798	1	LAB. DI SERVIZI ENOGASTR. SETTORE CUCINA
448	28	Colori della matematica	25.4500008	9788849422368	1	Matematica
449	22	Arcobaleni	18.3999996	9788805075492	1	Religione
450	49	Scienza degli alimenti	33.0999985	9788823106222	1	Scienza degli alimenti
451	20	Scienza in cucina	30.2999992	9788808747570	1	Scienze integrate
452	61	Tempo di sport	22.8999996	9788857792712	1	Scienze motorie
453	8	Scopri la storia	28.5	9788891553058	1	Storia
454	20	Informatica in cucina	16.2000008	9788808720474	1	TIC-TECNICHE INFORMAZIONE E COMUNICAZIONE
455	27	Con filosofare 1	35.5	9788839524522	1	Filosofia
456	20	Nuovo amaldi blu	33.9000015	9788808938060	1	Fisica
457	20	Performer shaping ideas 1	23.8999996	9788808220240	1	Inglese
458	20	Performer B2	25.2999992	9788808469960	1	Inglese
459	54	Perche la letteratura	33.5	9788868891794	1	Italiano
460	54	Perche la letteratura Umanesimo	27.7000008	9788868891800	1	Italiano
461	30	Forme e contesti della lett latina 1	30	9788800227513	1	Latino
462	20	Manuale blu	38.9000015	9788808988874	1	Matematica
463	2	L'idea della storia 1	31.7999992	9788869103575	1	Storia
464	20	Itinerario nell'arte 3	27.5	9788808276414	1	Storia dell'arte
465	6	Nuovo albero meraviglie 1-2-3	7.44000006	9788809982246	1	Religione
466	16	Girafavole kit 1	12.1000004	9788835054672	1	Libro prima classe
\.


--
-- Data for Name: libri_classe; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.libri_classe (id, id_libro, id_classe) FROM stdin;
534	19	97
535	18	97
536	17	97
537	341	98
538	342	98
539	343	98
540	293	98
541	295	98
542	344	98
543	346	99
544	345	99
545	348	100
546	347	100
547	8	100
549	352	102
548	353	102
550	351	102
551	350	102
552	349	102
553	23	103
554	354	103
555	356	104
556	355	104
557	359	105
558	358	105
559	357	105
560	360	106
561	361	106
562	31	106
563	362	106
564	364	106
565	366	107
566	365	107
567	361	107
568	14	107
569	55	107
570	360	108
571	361	108
572	362	108
573	31	108
574	364	108
575	9	109
576	10	109
577	11	110
578	12	110
579	367	111
580	3	111
581	22	111
582	55	112
583	14	112
584	365	112
585	361	112
586	366	112
587	54	113
588	9	113
589	368	114
590	58	114
591	108	114
592	60	114
593	109	114
594	62	114
595	369	114
596	92	115
597	93	115
598	94	115
599	95	115
600	144	115
601	99	115
602	97	115
603	117	116
604	49	116
605	161	117
606	163	117
607	162	117
608	164	117
609	166	117
610	167	117
611	165	117
612	370	118
613	38	118
614	23	119
615	354	119
616	360	120
617	361	120
618	31	120
619	362	120
620	364	120
621	11	121
622	12	121
623	371	122
624	159	122
625	346	123
626	345	123
627	372	124
628	280	124
629	34	124
630	35	124
631	373	125
632	264	125
633	162	126
634	161	126
635	163	126
636	164	126
637	166	126
638	167	126
639	11	127
640	374	127
641	35	128
642	375	128
643	376	128
644	33	128
645	10	129
646	9	129
647	334	130
648	304	130
649	378	130
650	377	130
651	238	130
652	379	130
653	305	130
654	385	131
655	384	131
656	382	131
657	383	131
658	381	131
659	380	131
660	370	132
661	38	132
662	58	133
663	220	133
664	62	133
665	60	133
666	109	133
667	368	133
668	369	133
669	393	134
670	389	134
671	387	134
672	386	134
673	390	134
674	392	134
675	391	134
676	388	134
677	354	135
678	23	135
679	397	136
680	396	136
681	394	136
682	395	136
683	76	136
684	58	137
685	61	137
686	108	137
687	62	137
688	398	137
689	60	137
690	368	137
691	26	138
692	373	138
693	400	139
694	401	139
695	237	139
696	399	139
697	379	139
698	58	140
699	220	140
700	109	140
701	60	140
702	62	140
703	221	140
704	236	141
705	405	141
706	403	141
707	404	141
708	402	141
709	234	141
710	41	143
711	407	143
712	409	143
713	406	143
714	408	143
715	41	142
716	406	142
717	407	142
718	408	142
719	409	142
720	49	144
721	50	144
722	357	145
723	410	145
724	32	145
725	217	145
726	413	146
727	411	146
728	297	146
729	365	146
730	412	146
731	416	147
732	415	147
733	414	147
734	417	148
735	355	148
736	72	149
737	418	149
738	419	149
739	420	149
740	159	150
741	421	150
742	417	151
743	355	151
744	22	152
745	422	152
746	348	152
747	161	153
748	162	153
749	163	153
750	164	153
751	167	153
752	166	153
753	370	154
754	38	154
755	95	155
756	172	155
757	170	155
758	171	155
759	169	155
760	335	156
761	390	156
762	426	156
763	427	156
764	425	156
765	423	156
766	424	156
767	428	157
768	429	157
769	308	157
770	432	157
771	431	157
772	430	157
773	307	157
774	264	158
775	373	158
776	433	159
777	434	159
778	438	159
779	437	159
780	435	159
781	439	159
782	391	159
783	436	159
784	426	159
785	440	160
786	441	160
787	447	160
788	442	160
789	443	160
790	444	160
791	445	160
792	448	160
793	454	160
794	446	160
795	338	160
796	453	160
797	449	160
798	452	160
799	450	160
800	451	160
801	455	161
802	464	161
803	457	161
804	456	161
805	460	161
806	461	161
807	462	161
808	458	161
809	459	161
810	463	161
811	348	162
812	465	162
813	466	162
\.


--
-- Data for Name: ordine_prenotazioni; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ordine_prenotazioni (id, id_prenotazione, id_ordine) FROM stdin;
2363	1837	114
2364	1851	114
2365	1877	114
2366	1913	114
2367	1917	114
2368	2017	114
2369	2032	114
2370	2046	114
2371	2100	114
2372	2173	114
2373	2182	114
2374	2226	114
2375	2150	114
2376	2263	114
2377	2284	114
2378	2340	114
2379	1899	114
2380	1920	114
2381	1997	114
2382	2002	114
2383	2004	114
2384	2064	114
2385	2185	114
2386	2074	114
2387	2083	114
2388	2254	114
2389	2289	114
2390	2320	114
2391	2134	114
2392	2145	114
2393	2221	114
2394	2317	114
2395	2318	114
2427	1783	115
2428	1798	115
2429	1799	115
2430	1803	115
2431	1823	115
2432	1827	115
2433	1875	115
2434	2214	115
2435	2292	115
2436	2408	115
2437	1839	115
2438	1845	115
2439	1862	115
2440	1873	115
2441	1894	115
2442	1901	115
2443	1906	115
2444	1972	115
2445	1992	115
2446	2008	115
2447	2012	115
2448	2027	115
2449	2040	115
2450	2041	115
2451	2059	115
2452	2066	115
2453	2080	115
2454	2088	115
2455	2105	115
2456	2115	115
2457	2120	115
2458	2129	115
2459	2136	115
2460	2191	115
2461	2248	115
2462	2075	115
2463	1787	115
2464	1840	115
2465	1847	115
2466	1852	115
2467	1865	115
2468	1872	115
2469	1878	115
2470	1896	115
2471	1903	115
2472	1909	115
2473	1910	115
2474	1918	115
2475	1975	115
2476	1994	115
2477	2009	115
2478	2010	115
2479	2018	115
2480	2024	115
2481	2031	115
2482	2039	115
2483	2042	115
2484	2050	115
2485	2060	115
2486	2069	115
2487	2079	115
2488	2087	115
2489	2097	115
2490	2104	115
2491	2118	115
2492	2123	115
2493	2128	115
2494	2138	115
2495	2174	115
2496	2178	115
2497	2189	115
2498	2228	115
2499	2149	115
2500	2252	115
2501	2261	115
2502	2285	115
2503	2339	115
2504	1931	115
2505	2196	115
2506	2242	115
2507	2271	115
2508	1936	115
2509	2195	115
2510	2241	115
2511	1791	115
2512	2072	115
2513	2313	115
2514	1820	115
2515	1856	115
2516	1926	115
2517	1829	115
2518	1831	115
2519	2021	115
2520	2029	115
2521	2085	115
2522	2103	115
2523	2112	115
2524	2113	115
2525	2153	115
2526	2161	115
2527	2219	115
2528	2247	115
2529	2310	115
2530	2426	115
2531	2230	115
2532	2309	115
2533	1818	115
2534	1857	115
2535	1925	115
2536	1928	115
2537	2073	115
2538	2133	115
2539	2144	115
2540	2223	115
2541	2131	115
2542	2163	115
2543	1822	115
2544	1859	115
2545	1923	115
2546	1836	115
2547	1841	115
2548	1846	115
2549	1864	115
2550	1869	115
2551	1892	115
2552	1904	115
2553	1908	115
2554	1973	115
2555	1993	115
2556	2007	115
2557	2014	115
2558	2025	115
2559	2036	115
2560	2043	115
2561	2061	115
2562	2068	115
2563	2081	115
2564	2086	115
2565	2106	115
2566	2119	115
2567	2124	115
2568	2125	115
2569	2139	115
2570	2192	115
2571	2251	115
2572	1984	115
2573	2232	115
2574	2234	115
2575	2303	115
2576	2314	115
2577	2326	115
2578	2319	115
2579	1978	115
2580	2158	115
2581	2167	115
2582	1979	115
2583	2156	115
2584	2255	115
2585	2346	115
2590	2207	115
2591	2420	115
2592	2208	115
2593	2402	115
2594	2419	115
2595	1792	116
2596	2071	116
2597	2312	116
2598	1795	116
2599	1806	116
2600	1853	116
2601	1867	116
2602	1885	116
2603	1889	116
2604	2413	116
2605	1830	116
2606	1832	116
2607	2020	116
2608	2030	116
2609	2084	116
2610	2102	116
2611	2111	116
2612	2114	116
2613	2152	116
2614	2162	116
2615	2220	116
2616	2246	116
2617	2311	116
2618	2425	116
2619	1850	116
2620	1879	116
2621	1912	116
2622	1919	116
2623	2016	116
2624	2034	116
2625	2047	116
2626	2099	116
2627	2176	116
2628	2180	116
2629	2227	116
2630	2151	116
2631	2264	116
2632	2287	116
2633	2342	116
2634	2135	116
2635	2143	116
2636	2222	116
2637	2283	116
2638	2307	116
2639	2308	116
2640	1819	116
2641	1860	116
2642	1924	116
2643	1821	116
2644	1858	116
2645	1927	116
2646	2056	116
2647	1784	116
2648	1797	116
2649	1801	116
2650	1802	116
2651	1825	116
2652	1828	116
2653	1874	116
2654	2216	116
2655	2293	116
2656	2410	116
2657	2233	116
2658	2297	116
2659	2298	116
2660	2304	116
2661	2322	116
2662	1833	116
2663	2315	116
2664	2327	116
2665	1835	116
2666	2296	116
2667	1983	116
2668	2294	116
2669	2022	116
2670	2166	116
2671	2184	116
2672	2337	116
2673	2076	116
2674	2082	116
2675	2290	116
2676	2407	116
2677	1838	116
2678	1843	116
2679	1863	116
2680	1870	116
2681	1893	116
2682	1900	116
2683	1907	116
2684	1974	116
2685	1995	116
2686	2013	116
2687	2028	116
2688	2037	116
2689	2045	116
2690	2058	116
2691	2062	116
2692	2067	116
2693	2078	116
2694	2090	116
2695	2108	116
2696	2116	116
2697	2122	116
2698	2126	116
2699	2137	116
2700	2190	116
2701	2250	116
2702	1898	116
2703	1922	116
2704	1998	116
2705	2001	116
2706	2005	116
2707	2065	116
2708	2187	116
2709	2329	116
2710	2404	116
2711	2400	116
2712	2231	116
2713	2279	116
2714	2280	116
2715	2281	116
2716	2299	116
2717	1782	117
2718	1796	117
2719	1800	117
2720	1804	117
2721	1824	117
2722	1826	117
2723	1876	117
2724	2215	117
2725	2291	117
2726	2409	117
2727	1793	117
2728	1807	117
2729	1855	117
2730	1868	117
2731	1884	117
2732	1890	117
2733	2330	117
2734	2411	117
2735	1842	117
2736	1844	117
2737	1861	117
2738	1871	117
2739	1895	117
2740	1902	117
2741	1905	117
2742	1971	117
2743	1996	117
2744	2006	117
2745	2011	117
2746	2026	117
2747	2038	117
2748	2044	117
2749	2057	117
2750	2070	117
2751	2077	117
2752	2089	117
2753	2107	117
2754	2117	117
2755	2121	117
2756	2127	117
2757	2140	117
2758	2188	117
2759	2249	117
2760	1990	117
2761	2055	117
2762	2323	117
2763	2154	117
2764	2253	117
2765	2321	117
2766	2282	117
2767	2305	117
2768	2316	117
2769	1788	117
2770	1789	117
2771	1934	117
2772	2198	117
2773	2243	117
2774	2269	117
2775	2270	117
2776	2349	117
2777	2356	117
2778	2414	117
2779	1834	117
2780	1933	117
2781	2239	117
2782	2295	117
2783	2328	117
2784	2353	117
2785	2361	117
2786	2415	117
2787	2416	117
2788	1986	117
2789	2096	117
2790	2332	117
2791	2274	117
2792	2202	117
2793	2351	117
2794	2358	117
2795	2399	117
2796	2421	117
2797	2206	117
2798	1790	118
2799	1849	118
2800	1880	118
2801	1914	118
2802	1916	118
2803	2015	118
2804	2033	118
2805	2048	118
2806	2101	118
2807	2177	118
2808	2179	118
2809	2229	118
2810	2148	118
2811	2262	118
2812	2286	118
2813	2343	118
2814	1883	118
2815	1929	118
2816	2142	118
2817	2266	118
2818	2423	118
2819	1888	118
2820	2052	118
2821	2054	118
2822	2109	118
2823	2130	118
2824	2164	118
2825	2201	118
2826	2211	118
2827	2213	118
2828	2217	118
2829	2236	118
2830	2237	118
2831	2300	118
2832	2325	118
2833	1897	118
2834	1921	118
2835	1999	118
2836	2000	118
2837	2003	118
2838	2063	118
2839	2186	118
2840	2405	118
2841	2132	118
2842	2146	118
2843	2224	118
2844	2197	118
2845	2267	118
2846	1794	118
2847	1805	118
2848	1854	118
2849	1866	118
2850	1886	118
2851	1891	118
2852	2412	118
2853	1848	118
2854	1881	118
2855	1911	118
2856	1915	118
2857	2019	118
2858	2035	118
2859	2049	118
2860	2098	118
2861	2175	118
2862	2181	118
2863	2225	118
2864	2147	118
2865	2260	118
2866	2288	118
2867	2302	118
2868	2341	118
2869	1882	118
2870	2141	118
2871	2265	118
2872	2424	118
2873	1887	118
2874	2051	118
2875	2053	118
2876	2110	118
2877	2200	118
2878	2210	118
2879	2212	118
2880	2218	118
2881	2235	118
2882	2238	118
2883	2301	118
2884	2324	118
2885	1977	118
2886	1980	118
2887	2348	118
2888	1982	118
2889	2155	118
2890	2259	118
2891	2160	118
2892	2257	118
2893	2347	118
2924	1785	119
2925	1932	119
2926	2193	119
2927	2244	119
2928	2268	119
2929	2401	119
2930	1981	119
2931	2157	119
2932	2909	119
2933	1985	119
2934	2095	119
2935	2331	119
2936	1987	119
2937	2091	119
2938	2333	119
2939	2245	119
2940	2277	119
2941	2278	119
2942	1991	119
2943	2092	119
2944	2334	119
2945	2169	119
2946	2172	119
2947	2258	119
2948	2273	119
2949	2344	119
2950	2168	119
2951	2355	119
2952	2357	119
2953	2422	119
2954	2896	119
2955	2171	119
2956	2350	119
2957	2360	119
2958	2205	119
2959	2396	119
2960	2397	119
2961	2398	119
2962	2900	119
\.


--
-- Data for Name: ordini; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ordini (id, data, protocollo_ext, casa_editrice, distributore) FROM stdin;
114	2021-06-29 15:23:08.722	\N	6	22
115	2021-07-04 09:25:30.762	\N	\N	16
116	2021-07-04 09:57:56.112	\N	\N	15
117	2021-07-04 10:29:39.141	\N	\N	21
118	2021-07-05 14:32:24.301		\N	16
119	2021-07-07 08:18:36.706	\N	\N	19
\.


--
-- Data for Name: prenotazioni; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prenotazioni (id, data, caparra, note) FROM stdin;
210	2021-06-15 20:04:32.594	0	NO foderati
212	2021-06-19 07:03:52.459	0	
214	2021-06-19 07:13:19.73	0	
6	2020-06-21 15:08:43.177	0	\N
7	2020-06-21 16:31:14.3	0	\N
216	2021-06-19 07:14:47.858	0	
218	2021-06-19 15:13:22.582	0	
220	2021-06-19 15:15:59.17	0	
222	2021-06-19 15:18:18.866	0	
13	2020-06-21 16:45:16.685	0	\N
224	2021-06-19 15:25:29.22	0	
226	2021-06-19 15:38:29.543	0	
228	2021-06-19 16:00:03.754	0	
230	2021-06-19 16:10:54.564	0	
232	2021-06-19 16:13:05.532	0	
234	2021-06-19 16:17:06.669	0	
236	2021-06-19 16:27:41.466	0	
238	2021-06-19 16:29:01.074	0	
240	2021-06-19 16:35:13.773	0	
242	2021-06-19 16:39:50.51	0	
32	2020-06-21 17:59:43.569	0	\N
244	2021-06-19 16:48:12.236	0	
246	2021-06-19 16:49:36.698	0	
248	2021-06-19 16:53:36.485	0	
40	2020-06-21 18:56:53.352	0	\N
250	2021-06-19 17:01:05.553	0	
252	2021-06-19 17:03:06.096	0	
339	2021-06-27 09:40:08.042	0	
288	2021-06-26 08:54:00.368	0	Rappresentante sez. c
290	2021-06-26 09:35:47.836	0	
51	2020-06-21 19:12:44.359	0	\N
292	2021-06-26 09:42:44.733	0	
294	2021-06-26 09:44:46.174	0	
298	2021-06-26 09:54:06.34	0	
300	2021-06-26 10:00:26.501	0	
302	2021-06-26 10:07:43.196	0	
304	2021-06-26 10:09:40.995	0	
306	2021-06-26 10:13:26.178	0	FODERATI SOLO ITALIANO E MATEMATICA
308	2021-06-26 10:16:59.804	0	
310	2021-06-26 10:20:55.576	0	
296	2021-06-26 09:49:54.139	0	
311	2021-06-27 08:27:26.851	0	
313	2021-06-27 08:31:45.084	0	
315	2021-06-27 08:40:39.587	0	Foderati solo quelli con più pagine
317	2021-06-27 08:46:32.945	0	
319	2021-06-27 08:56:10.015	0	Alessandra rappresentante
84	2020-06-23 20:42:59.541	0	\N
85	2020-06-23 21:21:53.01	0	\N
86	2020-06-23 21:23:11.59	0	\N
87	2020-06-23 21:26:55.599	0	\N
88	2020-06-23 21:31:39.816	0	\N
89	2020-06-23 21:33:29.025	0	\N
321	2021-06-27 08:58:17.973	0	
323	2021-06-27 08:59:42.483	0	
325	2021-06-27 09:01:29.716	0	
327	2021-06-27 09:03:14.752	0	Eneida
329	2021-06-27 09:08:16.003	0	No Foderati
331	2021-06-27 09:16:46.852	0	
333	2021-06-27 09:19:51.426	0	
335	2021-06-27 09:21:48.606	0	
337	2021-06-27 09:38:18.208	0	
341	2021-06-27 10:02:11.119	0	Verificare se da foderare
343	2021-06-27 10:15:03.616	0	
345	2021-06-27 10:16:24.31	0	
347	2021-06-27 10:48:50.219	0	
349	2021-06-27 13:05:45.076	0	
351	2021-06-27 13:07:03.925	0	
353	2021-06-27 13:09:39.204	0	
355	2021-06-27 13:13:22.816	0	
357	2021-06-27 13:25:06.174	0	
359	2021-06-27 13:29:51.889	0	da verificare da foderare
361	2021-06-27 13:51:13.342	0	Foderati solo Italiano e Matematica
363	2021-06-27 13:54:03.091	0	Foderati solo Italiano e Matematica
365	2021-06-27 14:10:31.792	0	
367	2021-06-27 14:12:43.12	0	
369	2021-06-27 14:34:16.062	0	
371	2021-06-27 14:55:32.654	0	
373	2021-06-27 14:59:34.849	0	
375	2021-06-27 15:22:40.704	0	
378	2021-06-28 09:27:04.081	0	NO t.p.
380	2021-06-28 09:29:48.669	0	
382	2021-06-28 09:51:55.558	0	No foderati
384	2021-06-28 10:03:00.892	0	
387	2021-06-28 14:54:15.911	0	No foderati i piccoli
389	2021-06-28 15:42:06.502	0	T.P.
391	2021-06-29 09:18:26.516	50	
393	2021-06-29 15:22:43.101	0	
395	2021-07-03 08:46:24.874	0	
397	2021-07-03 08:49:18.876	0	
136	2020-07-09 09:44:23.967	0	
399	2021-07-03 09:49:36.31	0	Più c'è da ordinare Promessi sposi ediz. libera
403	2021-07-06 15:43:07.555	0	
405	2021-07-06 16:11:50.673	50	
407	2021-07-08 15:04:01.572	0	TSSDMN15A21D653M
211	2021-06-15 20:22:31.661	0	
213	2021-06-19 07:09:46.4	0	
143	2020-07-13 14:32:56.575	0	
215	2021-06-19 07:14:07.757	0	
145	2020-07-14 18:01:36.235	0	
217	2021-06-19 07:15:26.856	0	
340	2021-06-27 10:00:26.46	0	
221	2021-06-19 15:17:35.058	0	
223	2021-06-19 15:19:20.668	0	
227	2021-06-19 15:48:41.648	0	
229	2021-06-19 16:01:08.271	0	
231	2021-06-19 16:12:03.454	0	
233	2021-06-19 16:16:03.872	0	
235	2021-06-19 16:20:01.47	0	
237	2021-06-19 16:28:20.844	0	
239	2021-06-19 16:33:44.503	0	Sezione da controllare
241	2021-06-19 16:38:49.536	0	
243	2021-06-19 16:41:34.665	0	
245	2021-06-19 16:48:53.328	0	
247	2021-06-19 16:52:54.47	0	
249	2021-06-19 16:54:56.932	0	
251	2021-06-19 17:01:51.496	0	
253	2021-06-19 17:20:02.787	0	
342	2021-06-27 10:03:07.884	0	Verificare se da foderare
289	2021-06-26 09:18:14.81	0	
291	2021-06-26 09:41:02.482	0	FRANCESE SI (lo vuole lei, non era in lista)
293	2021-06-26 09:44:09.771	0	
295	2021-06-26 09:45:21.742	0	
299	2021-06-26 09:55:42.567	0	
301	2021-06-26 10:01:31.416	0	
303	2021-06-26 10:08:52.764	0	
305	2021-06-26 10:11:48.808	0	
307	2021-06-26 10:16:25.225	0	
309	2021-06-26 10:20:18.664	0	
312	2021-06-27 08:28:28.681	0	
314	2021-06-27 08:39:18.817	0	Foderati solo quelli con più pagine
316	2021-06-27 08:45:46.724	0	
318	2021-06-27 08:47:11.852	0	
320	2021-06-27 08:57:05.077	0	
322	2021-06-27 08:58:56.167	0	Rovena
324	2021-06-27 09:00:55.016	0	
326	2021-06-27 09:02:16.635	0	
328	2021-06-27 09:03:54.891	0	
330	2021-06-27 09:15:48.368	0	No Foderati
332	2021-06-27 09:19:05.915	0	No Foderati
344	2021-06-27 10:15:48.229	0	
336	2021-06-27 09:36:53.742	0	Verificare se da foderare
338	2021-06-27 09:38:55.945	0	
346	2021-06-27 10:43:30.885	0	
348	2021-06-27 11:11:29.033	0	
350	2021-06-27 13:06:12.658	0	
352	2021-06-27 13:07:45.368	0	
358	2021-06-27 13:26:28.991	0	
334	2021-06-27 09:20:37.048	0	No foderati
360	2021-06-27 13:49:17.771	0	
362	2021-06-27 13:53:07.13	0	Foderati solo Italiano e Matematica
364	2021-06-27 13:59:07.419	0	
366	2021-06-27 14:11:21.938	0	
368	2021-06-27 14:18:48.348	0	
370	2021-06-27 14:54:26.015	0	
372	2021-06-27 14:58:47.882	0	
201	2020-09-11 19:36:01.645	0	
374	2021-06-27 15:12:12.444	0	
376	2021-06-27 15:25:46.859	0	
377	2021-06-28 09:19:42.597	0	
379	2021-06-28 09:28:50.559	0	
381	2021-06-28 09:41:36.169	0	
383	2021-06-28 09:56:31.691	0	No foderati
385	2021-06-28 10:04:00.405	0	
386	2021-06-28 14:45:38.753	0	Foderati no i piccoli
388	2021-06-28 15:28:32.476	0	Francese
390	2021-06-29 09:10:43.107	0	
392	2021-06-29 15:21:55.819	0	
394	2021-07-03 08:45:18.262	0	
396	2021-07-03 08:48:46.916	0	
398	2021-07-03 08:50:40.615	0	
400	2021-07-03 10:05:08.718	0	
401	2021-07-04 09:18:49.766	0	Foderati solo Italiano e Matematica
402	2021-07-06 15:38:06.911	0	
404	2021-07-06 15:45:41.359	0	
354	2021-06-27 13:12:52.556	0	BTTMME14D47D653Z
406	2021-07-08 09:46:56.105	0	RNCGLI12M22D653X
408	2021-07-08 15:26:23.648	0	DLSTMS15H13G478A
225	2021-06-19 15:26:02.455	0	PTRGAI14T47D653K
356	2021-06-27 13:14:38.916	0	NGLCST12C13I921F
297	2021-06-26 09:52:58.789	0	SCPRCR12D30D653V
\.


--
-- Data for Name: prenotazioni_studente; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prenotazioni_studente (id, studente, prenotazione, libro, foderatura, cedola, stato) FROM stdin;
1786	195	211	344	t	f	Attesa
1887	224	241	12	t	f	In ordine
1888	224	241	11	t	f	In ordine
1851	214	230	366	t	f	In ordine
1913	230	247	366	f	f	In ordine
1877	221	238	366	t	f	In ordine
1917	231	248	366	f	f	In ordine
1920	232	249	3	t	f	In ordine
1783	194	210	19	f	f	In ordine
1799	199	215	19	t	f	In ordine
1827	207	223	19	t	f	In ordine
1798	198	214	19	t	f	In ordine
1845	213	229	362	t	f	In ordine
1862	217	233	362	t	f	In ordine
1873	219	235	362	t	f	In ordine
1823	206	222	19	t	f	In ordine
1906	229	246	362	t	f	In ordine
1875	220	236	19	t	f	In ordine
1787	195	211	343	t	f	In ordine
1840	212	228	361	t	f	In ordine
1847	213	229	361	t	f	In ordine
1865	217	233	361	t	f	In ordine
1852	214	230	361	t	f	In ordine
1872	219	235	361	t	f	In ordine
1878	221	238	361	t	f	In ordine
1896	226	243	361	t	f	In ordine
1903	228	245	361	t	f	In ordine
1910	230	247	361	f	f	In ordine
1839	212	228	362	t	f	In ordine
1909	229	246	361	t	f	In ordine
1918	231	248	361	f	f	In ordine
1820	205	221	349	t	f	In ordine
1856	216	232	349	t	f	In ordine
1791	196	212	346	t	f	In ordine
1829	208	224	23	t	f	In ordine
1782	194	210	17	f	f	Arrivato
1926	233	250	349	t	f	In ordine
1818	205	221	351	t	f	In ordine
1857	216	232	351	t	f	In ordine
1925	233	250	351	t	f	In ordine
1822	205	221	350	t	f	In ordine
1859	216	232	350	t	f	In ordine
1923	233	250	350	t	f	In ordine
1836	211	227	358	t	f	In ordine
1841	212	228	360	t	f	In ordine
1846	213	229	360	t	f	In ordine
1892	226	243	360	t	f	In ordine
1864	217	233	360	t	f	In ordine
1904	228	245	360	t	f	In ordine
1869	219	235	360	t	f	In ordine
1908	229	246	360	t	f	In ordine
1792	196	212	345	t	f	In ordine
1806	201	217	8	t	f	In ordine
1889	225	242	8	f	f	In ordine
1867	218	234	8	t	f	In ordine
1830	208	224	354	t	f	In ordine
1795	197	213	8	t	f	In ordine
1853	215	231	8	t	f	In ordine
1885	223	240	8	t	f	In ordine
1879	221	238	14	t	f	In ordine
1919	231	248	14	f	f	In ordine
1912	230	247	14	f	f	In ordine
1824	206	222	17	t	f	Arrivato
1819	205	221	353	t	f	In ordine
1924	233	250	353	t	f	In ordine
1858	216	232	352	t	f	In ordine
1821	205	221	352	t	f	In ordine
1784	194	210	18	f	f	In ordine
1825	206	222	18	t	f	In ordine
1802	200	216	18	t	f	In ordine
1801	199	215	18	t	f	In ordine
1828	207	223	18	t	f	In ordine
1797	198	214	18	t	f	In ordine
1874	220	236	18	t	f	In ordine
1833	210	226	355	t	f	In ordine
1835	211	227	357	t	f	In ordine
1838	212	228	31	t	f	In ordine
1863	217	233	31	t	f	In ordine
1843	213	229	31	t	f	In ordine
1893	226	243	31	t	f	In ordine
1907	229	246	31	t	f	In ordine
1900	228	245	31	t	f	In ordine
1898	227	244	22	t	f	In ordine
1922	232	249	22	t	f	In ordine
1796	198	214	17	t	f	Arrivato
1800	199	215	17	t	f	Arrivato
1826	207	223	17	t	f	Arrivato
1804	200	216	17	t	f	Arrivato
1844	213	229	364	t	f	Arrivato
1807	201	217	348	t	f	In ordine
1855	215	231	348	t	f	In ordine
1868	218	234	348	t	f	In ordine
1890	225	242	348	f	f	In ordine
1876	220	236	17	t	f	Arrivato
1861	217	233	364	t	f	Arrivato
1793	197	213	348	t	f	In ordine
1789	195	211	341	t	f	Arrivato
1788	195	211	295	t	f	Arrivato
1842	212	228	364	t	f	Arrivato
1902	228	245	364	t	f	Arrivato
1905	229	246	364	t	f	Arrivato
1834	210	226	356	t	f	Arrivato
1884	223	240	348	t	f	In ordine
1895	226	243	364	t	f	Arrivato
1790	195	211	342	t	f	In ordine
1880	221	238	55	t	f	In ordine
1914	230	247	55	f	f	In ordine
1916	231	248	55	f	f	In ordine
1849	214	230	55	t	f	In ordine
1883	222	239	9	t	f	In ordine
1897	227	244	367	t	f	In ordine
1921	232	249	367	t	f	In ordine
1794	197	213	347	t	f	In ordine
1854	215	231	347	t	f	In ordine
1891	225	242	347	f	f	In ordine
1886	223	240	347	t	f	In ordine
1805	201	217	347	t	f	In ordine
1848	214	230	365	t	f	In ordine
1915	231	248	365	f	f	In ordine
1911	230	247	365	f	f	In ordine
1882	222	239	10	t	f	In ordine
1785	195	211	293	t	f	In ordine
1831	209	225	23	t	f	In ordine
1832	209	225	354	t	f	In ordine
1930	235	253	109	t	f	Attesa
1935	235	253	368	t	f	Attesa
1933	235	253	108	t	f	Arrivato
1986	274	291	163	f	f	Arrivato
2025	284	301	360	t	f	In ordine
1995	275	292	31	t	f	In ordine
2031	286	303	361	t	f	In ordine
1976	272	289	97	t	f	Attesa
1988	274	291	164	f	f	Attesa
1989	274	291	162	f	f	Attesa
2023	283	300	370	t	f	Attesa
2093	302	319	162	f	f	Attesa
2094	302	319	164	f	f	Attesa
2046	289	306	366	f	f	In ordine
2032	286	303	366	t	f	In ordine
1997	276	293	3	t	f	In ordine
2004	278	295	3	t	f	In ordine
2064	294	311	3	t	f	In ordine
2074	297	314	34	f	f	In ordine
1992	275	292	362	t	f	In ordine
2027	284	301	362	t	f	In ordine
2008	279	296	362	t	f	In ordine
1972	271	288	362	t	f	In ordine
2040	287	304	362	f	f	In ordine
2066	295	312	362	t	f	In ordine
2088	301	318	362	t	f	In ordine
2059	293	310	362	t	f	In ordine
2080	298	315	362	f	f	In ordine
2075	297	314	280	f	f	In ordine
1975	271	288	361	t	f	In ordine
1990	274	291	165	f	f	Arrivato
2042	288	305	361	f	f	In ordine
2039	287	304	361	f	f	In ordine
2050	289	306	361	f	f	In ordine
2069	295	312	361	t	f	In ordine
2060	293	310	361	t	f	In ordine
2087	301	318	361	t	f	In ordine
2079	298	315	361	f	f	In ordine
1931	235	253	60	t	f	In ordine
1936	235	253	369	t	f	In ordine
2072	296	313	346	t	f	In ordine
2021	282	299	23	f	f	In ordine
2029	285	302	23	t	f	In ordine
2085	300	317	23	t	f	In ordine
2073	297	314	35	f	f	In ordine
1928	234	252	54	t	f	In ordine
1973	271	288	360	t	f	In ordine
1993	275	292	360	t	f	In ordine
2007	279	296	360	t	f	In ordine
2055	292	309	159	t	f	Arrivato
2043	288	305	360	f	f	In ordine
2036	287	304	360	f	f	In ordine
2061	293	310	360	t	f	In ordine
2081	298	315	360	f	f	In ordine
2068	295	312	360	t	f	In ordine
2086	301	318	360	t	f	In ordine
1984	273	290	117	f	f	In ordine
1978	272	289	93	t	f	In ordine
1979	272	289	99	t	f	In ordine
2071	296	313	345	t	f	In ordine
2020	282	299	354	f	f	In ordine
2030	285	302	354	t	f	In ordine
2084	300	317	354	t	f	In ordine
2034	286	303	14	t	f	In ordine
2047	289	306	14	f	f	In ordine
2016	281	298	14	t	f	In ordine
1927	233	250	352	t	f	In ordine
2056	292	309	371	t	f	In ordine
1983	273	290	49	f	f	In ordine
2022	283	300	38	t	f	In ordine
2082	299	316	264	f	f	In ordine
2076	297	314	372	f	f	In ordine
1974	271	288	31	t	f	In ordine
1934	235	253	58	t	f	Arrivato
2028	284	301	31	t	f	In ordine
2037	287	304	31	f	f	In ordine
2058	293	310	31	t	f	In ordine
2062	279	296	31	t	f	In ordine
2045	288	305	31	f	f	In ordine
2067	295	312	31	t	f	In ordine
2078	298	315	31	f	f	In ordine
2090	301	318	31	t	f	In ordine
1998	276	293	22	t	f	In ordine
2001	277	294	22	t	f	In ordine
2005	278	295	22	t	f	In ordine
2065	294	311	22	t	f	In ordine
1996	275	292	364	t	f	Arrivato
2077	298	315	364	f	f	Arrivato
2038	287	304	364	f	f	Arrivato
1971	271	288	364	t	f	Arrivato
2089	301	318	364	t	f	Arrivato
2057	293	310	364	t	f	Arrivato
2011	280	297	364	t	f	Arrivato
2026	284	301	364	t	f	Arrivato
2044	288	305	364	f	f	Arrivato
2015	281	298	55	t	f	In ordine
2048	289	306	55	f	f	In ordine
2033	286	303	55	t	f	In ordine
1929	234	252	9	t	f	In ordine
2052	290	307	11	t	f	In ordine
2054	291	308	11	t	f	In ordine
1999	276	293	367	t	f	In ordine
2000	277	294	367	t	f	In ordine
2003	278	295	367	t	f	In ordine
2063	294	311	367	t	f	In ordine
2019	281	298	365	t	f	In ordine
2035	286	303	365	t	f	In ordine
2049	289	306	365	f	f	In ordine
2051	290	307	12	t	f	In ordine
2053	291	308	12	t	f	In ordine
1980	272	289	95	t	f	In ordine
1977	272	289	94	t	f	In ordine
1982	272	289	92	t	f	In ordine
1932	235	253	62	t	f	In ordine
1981	272	289	144	t	f	In ordine
1985	274	291	166	f	f	In ordine
2095	302	319	166	f	f	In ordine
2091	302	319	167	f	f	In ordine
1991	274	291	161	f	f	In ordine
1987	274	291	167	f	f	In ordine
2092	302	319	161	f	f	In ordine
2012	280	297	362	t	f	In ordine
2121	310	327	364	t	f	Arrivato
2160	319	336	378	f	f	In ordine
2168	323	340	381	t	f	In ordine
2167	323	340	382	t	f	In ordine
2159	319	336	304	f	f	Attesa
2193	329	346	62	t	f	In ordine
2165	322	339	370	t	f	Attesa
2170	323	340	385	t	f	Attesa
2204	331	348	389	f	f	Attesa
2215	334	352	17	t	f	Arrivato
2178	325	342	361	f	f	In ordine
2202	331	348	390	f	f	Arrivato
2180	325	342	14	f	f	In ordine
2198	329	346	58	t	f	Arrivato
2189	328	345	361	t	f	In ordine
2142	315	332	9	f	f	In ordine
2135	313	330	375	f	f	In ordine
2098	303	320	365	t	f	In ordine
2173	324	341	366	f	f	In ordine
2183	326	343	370	t	f	Attesa
2194	329	346	109	t	f	Attesa
2199	329	346	368	t	f	Attesa
2209	331	348	392	f	f	Attesa
2100	303	320	366	t	f	In ordine
2182	325	342	366	f	f	In ordine
2185	327	344	3	t	f	In ordine
2134	313	330	376	f	f	In ordine
2145	316	333	376	t	f	In ordine
2221	337	355	376	f	f	In ordine
2214	334	352	19	t	f	In ordine
2105	305	322	362	f	f	In ordine
2115	309	326	362	t	f	In ordine
2120	310	327	362	t	f	In ordine
2191	328	345	362	t	f	In ordine
2136	314	331	362	t	f	In ordine
2129	311	328	362	t	f	In ordine
2097	303	320	361	t	f	In ordine
2104	305	322	361	f	f	In ordine
2118	309	326	361	t	f	In ordine
2123	310	327	361	t	f	In ordine
2128	311	328	361	t	f	In ordine
2138	314	331	361	t	f	In ordine
2174	324	341	361	f	f	In ordine
2127	311	328	364	t	f	Arrivato
2196	329	346	60	t	f	In ordine
2195	329	346	369	t	f	In ordine
2103	304	321	23	t	f	In ordine
2112	307	324	23	t	f	In ordine
2113	308	325	23	t	f	In ordine
2153	318	335	23	t	f	In ordine
2161	320	337	23	t	f	In ordine
2226	338	356	366	t	f	In ordine
2230	339	357	394	t	f	In ordine
2133	313	330	35	f	f	In ordine
2144	316	333	35	t	f	In ordine
2131	312	329	374	f	f	In ordine
2163	321	338	374	t	f	In ordine
2223	337	355	35	f	f	In ordine
2106	305	322	360	f	f	In ordine
2119	309	326	360	t	f	In ordine
2125	311	328	360	t	f	In ordine
2124	310	327	360	t	f	In ordine
2139	314	331	360	t	f	In ordine
2192	328	345	360	t	f	In ordine
2158	319	336	377	f	f	In ordine
2156	319	336	305	f	f	In ordine
2207	331	348	391	f	f	In ordine
2208	331	348	388	f	f	In ordine
2114	308	325	354	t	f	In ordine
2111	307	324	354	t	f	In ordine
2152	318	335	354	t	f	In ordine
2162	320	337	354	t	f	In ordine
2225	338	356	365	t	f	In ordine
2099	303	320	14	t	f	In ordine
2176	324	341	14	f	f	In ordine
2143	316	333	375	t	f	In ordine
2222	337	355	375	f	f	In ordine
2216	334	352	18	t	f	In ordine
2166	322	339	38	t	f	In ordine
2184	326	343	38	t	f	In ordine
2122	310	327	31	t	f	In ordine
2108	305	322	31	f	f	In ordine
2190	328	345	31	t	f	In ordine
2126	311	328	31	t	f	In ordine
2116	309	326	31	t	f	In ordine
2137	314	331	31	t	f	In ordine
2187	327	344	22	t	f	In ordine
2140	314	331	364	t	f	Arrivato
2154	319	336	238	f	f	Arrivato
2188	328	345	364	t	f	Arrivato
2107	305	322	364	f	f	Arrivato
2117	309	326	364	t	f	Arrivato
2096	302	319	163	f	f	Arrivato
2203	331	348	387	f	f	Attesa
2206	331	348	386	f	f	In ordine
2101	303	320	55	t	f	In ordine
2177	324	341	55	f	f	In ordine
2179	325	342	55	f	f	In ordine
2109	306	323	11	t	f	In ordine
2164	321	338	11	t	f	In ordine
2130	312	329	11	f	f	In ordine
2201	330	347	11	t	f	In ordine
2211	332	350	11	t	f	In ordine
2217	335	353	11	t	f	In ordine
2224	337	355	33	f	f	In ordine
2146	316	333	33	t	f	In ordine
2186	327	344	367	t	f	In ordine
2132	313	330	33	f	f	In ordine
2197	329	346	220	t	f	In ordine
2175	324	341	365	f	f	In ordine
2141	315	332	10	f	f	In ordine
2200	330	347	12	t	f	In ordine
2110	306	323	12	t	f	In ordine
2210	332	350	12	t	f	In ordine
2218	335	353	12	t	f	In ordine
2212	333	351	12	t	f	In ordine
2155	319	336	379	f	f	In ordine
2157	319	336	334	f	f	In ordine
2172	323	340	383	t	f	In ordine
2169	323	340	384	t	f	In ordine
2205	331	348	393	f	f	In ordine
2219	336	354	23	t	f	In ordine
2220	336	354	354	t	f	In ordine
2240	342	360	368	f	f	Attesa
2256	347	365	237	f	f	Attesa
2272	350	368	109	t	f	Attesa
2275	351	369	403	f	f	Attesa
2276	351	369	402	f	f	Attesa
2306	359	377	411	f	f	Attesa
2335	370	388	164	t	f	Attesa
2336	370	388	162	t	f	Attesa
2338	371	389	370	t	f	Attesa
2345	373	391	171	t	f	Attesa
2352	374	392	335	f	f	Attesa
2359	375	393	335	f	f	Attesa
2263	348	366	366	t	f	In ordine
2284	353	371	366	t	f	In ordine
2320	365	383	373	f	f	In ordine
2289	354	372	373	t	f	In ordine
2318	364	382	420	f	f	In ordine
2317	364	382	419	f	f	In ordine
2292	355	373	19	t	f	In ordine
2248	345	363	362	f	f	In ordine
2149	317	334	361	f	f	In ordine
2252	345	363	361	f	f	In ordine
2285	353	371	361	t	f	In ordine
2339	372	390	361	t	f	In ordine
2242	342	360	60	f	f	In ordine
2261	348	366	361	t	f	In ordine
2271	350	368	60	t	f	In ordine
2313	362	380	346	t	f	In ordine
2247	343	361	23	f	f	In ordine
2310	361	379	23	t	f	In ordine
2309	360	378	416	f	f	In ordine
2251	345	363	360	f	f	In ordine
2232	339	357	396	t	f	In ordine
2314	363	381	417	t	f	In ordine
2303	359	377	413	f	f	In ordine
2234	339	357	397	t	f	In ordine
2326	368	386	417	t	f	In ordine
2319	364	382	418	f	f	In ordine
2346	373	391	170	t	f	In ordine
2255	347	365	401	f	f	In ordine
2312	362	380	345	t	f	In ordine
2246	343	361	354	f	f	In ordine
2311	361	379	354	t	f	In ordine
2151	317	334	14	f	f	In ordine
2264	348	366	14	t	f	In ordine
2287	353	371	14	t	f	In ordine
2342	372	390	14	t	f	In ordine
2307	360	378	414	f	f	In ordine
2308	360	378	415	f	f	In ordine
2233	339	357	395	t	f	In ordine
2293	355	373	18	t	f	In ordine
2322	366	384	421	t	f	In ordine
2327	368	386	355	t	f	In ordine
2296	358	375	357	f	f	In ordine
2315	363	381	355	t	f	In ordine
2294	356	374	49	t	f	In ordine
2337	371	389	38	t	f	In ordine
2290	354	372	264	t	f	In ordine
2250	345	363	31	f	f	In ordine
2329	369	387	22	t	f	In ordine
2231	339	357	76	t	f	In ordine
2279	352	370	407	t	f	In ordine
2280	352	370	409	t	f	In ordine
2281	352	370	408	t	f	In ordine
2299	358	375	410	f	f	In ordine
2253	346	364	26	f	f	Arrivato
2330	369	387	348	t	f	In ordine
2274	351	369	236	f	f	Arrivato
2243	342	360	58	f	f	Arrivato
2321	365	383	26	f	f	Arrivato
2239	342	360	108	f	f	Arrivato
2282	352	370	406	t	f	In ordine
2316	364	382	72	f	f	Arrivato
2295	356	374	50	t	f	Arrivato
2354	374	392	427	f	f	Attesa
2356	375	393	425	f	f	Arrivato
2323	366	384	159	t	f	Arrivato
2249	345	363	364	f	f	Arrivato
2269	350	368	58	t	f	Arrivato
2328	369	387	422	t	f	Arrivato
2353	374	392	424	f	f	Arrivato
2270	350	368	221	t	f	Arrivato
2361	375	393	424	f	f	Arrivato
2351	374	392	390	f	f	Arrivato
2305	359	377	297	f	f	Arrivato
2358	375	393	390	f	f	Arrivato
2332	370	388	163	t	f	Arrivato
2349	374	392	425	f	f	Arrivato
2262	348	366	55	t	f	In ordine
2286	353	371	55	t	f	In ordine
2148	317	334	55	f	f	In ordine
2343	372	390	55	t	f	In ordine
2266	349	367	9	t	f	In ordine
2236	340	358	11	t	f	In ordine
2300	357	376	11	f	f	In ordine
2325	367	385	11	t	f	In ordine
2237	341	359	11	f	f	In ordine
2267	350	368	220	t	f	In ordine
2147	317	334	365	f	f	In ordine
2288	353	371	365	t	f	In ordine
2302	359	377	365	f	f	In ordine
2265	349	367	10	t	f	In ordine
2235	340	358	12	t	f	In ordine
2238	341	359	12	f	f	In ordine
2301	357	376	12	f	f	In ordine
2324	367	385	12	t	f	In ordine
2348	373	391	95	t	f	In ordine
2257	347	365	400	f	f	In ordine
2259	347	365	379	f	f	In ordine
2347	373	391	172	t	f	In ordine
2244	342	360	62	f	f	In ordine
2268	350	368	62	t	f	In ordine
2331	370	388	166	t	f	In ordine
2277	351	369	405	f	f	In ordine
2278	351	369	404	f	f	In ordine
2334	370	388	161	t	f	In ordine
2258	347	365	399	f	f	In ordine
2273	351	369	234	f	f	In ordine
2344	373	391	169	t	f	In ordine
2355	374	392	426	f	f	In ordine
2245	342	360	61	f	f	In ordine
2357	375	393	426	f	f	In ordine
2333	370	388	167	t	f	In ordine
2350	374	392	423	f	f	In ordine
2360	375	393	423	f	f	In ordine
2291	355	373	17	t	f	Arrivato
1837	211	227	359	t	f	In ordine
2017	281	298	366	t	f	In ordine
2150	317	334	366	f	f	In ordine
2340	372	390	366	t	f	In ordine
2002	277	294	3	t	f	In ordine
2083	299	316	373	f	f	In ordine
2254	346	364	373	f	f	In ordine
1899	227	244	3	t	f	In ordine
2403	377	395	3	t	f	Attesa
2406	378	396	373	f	f	Attesa
2418	381	399	435	f	f	Attesa
2408	379	397	19	f	f	In ordine
1803	200	216	19	t	f	In ordine
1901	228	245	362	t	f	In ordine
1894	226	243	362	t	f	In ordine
2041	288	305	362	f	f	In ordine
1994	275	292	361	t	f	In ordine
2018	281	298	361	t	f	In ordine
2009	279	296	361	t	f	In ordine
2024	284	301	361	t	f	In ordine
2241	342	360	398	f	f	In ordine
2426	344	401	23	f	f	In ordine
2420	381	399	391	f	f	In ordine
2402	376	394	428	f	f	In ordine
2419	381	399	434	f	f	In ordine
2102	304	321	354	t	f	In ordine
2425	344	401	354	f	f	In ordine
2413	380	398	8	f	f	In ordine
1850	214	230	14	t	f	In ordine
2283	352	370	41	t	f	In ordine
1860	216	232	353	t	f	In ordine
2297	358	375	217	f	f	In ordine
2298	358	375	32	f	f	In ordine
2304	359	377	412	f	f	In ordine
2410	379	397	18	f	f	In ordine
1870	219	235	31	t	f	In ordine
2407	378	396	264	f	f	In ordine
2400	376	394	430	f	f	In ordine
2404	377	395	22	t	f	In ordine
2411	380	398	348	f	f	In ordine
2399	376	394	431	f	f	Arrivato
2415	381	399	433	f	f	Arrivato
2362	375	393	427	f	f	Attesa
2417	381	399	438	f	f	Attesa
2423	382	400	9	t	f	In ordine
2213	333	351	11	t	f	In ordine
2405	377	395	367	t	f	In ordine
1866	218	234	347	t	f	In ordine
2412	380	398	347	f	f	In ordine
1881	221	238	365	t	f	In ordine
2181	325	342	365	f	f	In ordine
2260	348	366	365	t	f	In ordine
2341	372	390	365	t	f	In ordine
2424	382	400	10	t	f	In ordine
2894	383	402	445	f	f	Attesa
2895	383	402	440	f	f	Attesa
2897	383	402	442	f	f	Attesa
2898	383	402	446	f	f	Attesa
2899	383	402	453	f	f	Attesa
2901	383	402	452	f	f	Attesa
2902	383	402	447	f	f	Attesa
2903	383	402	441	f	f	Attesa
2904	383	402	443	f	f	Attesa
2905	383	402	451	f	f	Attesa
2906	383	402	444	f	f	Attesa
2907	383	402	450	f	f	Attesa
2908	383	402	454	f	f	Attesa
2910	384	403	356	t	f	Attesa
2911	384	403	355	t	f	Attesa
2912	385	404	11	t	f	Attesa
2913	385	404	12	t	f	Attesa
2921	386	405	455	f	f	Attesa
2915	386	405	456	f	f	Attesa
2918	386	405	457	f	f	Attesa
2919	386	405	458	f	f	Attesa
2923	386	405	459	f	f	Attesa
2920	386	405	460	f	f	Attesa
2922	386	405	461	f	f	Attesa
2914	386	405	462	f	f	Attesa
2917	386	405	463	f	f	Attesa
2916	386	405	464	f	f	Attesa
2401	376	394	307	f	f	In ordine
2909	383	402	449	f	f	In ordine
2422	381	399	426	f	f	In ordine
2896	383	402	448	f	f	In ordine
2171	323	340	380	t	f	In ordine
2396	376	394	432	f	f	In ordine
2397	376	394	429	f	f	In ordine
2398	376	394	308	f	f	In ordine
2900	383	402	338	f	f	In ordine
2963	387	406	411	t	f	Attesa
2964	387	406	413	t	f	Attesa
2965	387	406	412	t	f	Attesa
2966	387	406	365	t	f	Attesa
2967	387	406	297	t	f	Attesa
2968	388	407	8	f	f	Attesa
2969	388	407	347	f	f	Attesa
2970	388	407	348	f	f	Attesa
2971	389	408	466	t	f	Attesa
2972	389	408	348	t	f	Attesa
2229	338	356	55	t	f	In ordine
2228	338	356	361	t	f	In ordine
2227	338	356	14	t	f	In ordine
2010	280	297	361	t	f	In ordine
2014	280	297	360	t	f	In ordine
2013	280	297	31	t	f	In ordine
2409	379	397	17	f	f	Arrivato
2421	381	399	437	f	f	Arrivato
2416	381	399	436	f	f	Arrivato
2414	381	399	439	f	f	Arrivato
2006	279	296	364	t	f	Arrivato
1871	219	235	364	t	f	Arrivato
2070	295	312	364	t	f	Arrivato
\.


--
-- Data for Name: scuole; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scuole (id, nome, tipologia) FROM stdin;
1	Fiamenga	Elementare
2	Monte Cervino	Elementare
3	Santa Caterina	Elementare
4	Bevagna	Elementare
5	Cantalupo	Elementare
6	Borroni	Elementare
7	Piermarini	Media
8	Gentile	Media
9	Carducci	Media
10	Via Mameli	Elementare
11	S.Giovanni Profiamma	Elementare
12	Sportella Marini	Elementare
13	Sterpete	Elementare
14	Piermarini el.	Elementare
16	S. Eraclio	Media
17	Scarpellini	Superiore
18	Colfiorito elementari	Elementare
19	Colfiorito medie	Media
20	Industriali	Superiore
21	Belfiore elem	Elementare
15	Belfiore medie	Media
23	Liceo Artistico	Superiore
24	Valtopina	Elementare
25	Via Fiume Trebbia	Elementare
28	Professionali	Superiore
30	Liceo Scientifico	Superiore
31	S. Eraclio elem.	Elementare
35	Liceo Classico	Superiore
36	Liceo Sc.Perugia	Superiore
29	Alberghiero Assisi	Superiore
37	Montefalco	Elementare
\.


--
-- Data for Name: studenti; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.studenti (id, nome, cognome, classe, residenza, mail, telefono) FROM stdin;
194	Elena 	Stramaccia	97			3393499935
195	Carolina	Corea	98			3474494342
196	Edoardo	Corea	99			3474494342
197	Chiara	Mattoni	100			
198	Marta	Mela	97			
199	Ludovico	Rossi	97			
200	Bianca	Baldelli	97			
201	Mia	Baldelli	100			
205	Diego Leon	Dionigi	102			
206	Luca	Antonini	97			
207	Gaia	Gentili	97			
208	Greta	Donati	103			
209	Gaia	Petrini	103			
210	Ester	Morozzi	104			
211	Viola	Morozzi	105			
212	Giulia	Ceccaroni	106			3927434874
213	Danilo	Catri	106			
214	MariaSole	Tocchi	107			
215	Tocchi	Samuele	100			
216	Federico	Mattonelli	102			
217	Emanuele	Miucci	108			3398352951
218	Edoardo	Ciancaleoni	100			3284669678
219	Maksym	Fedak	106			
220	Emma	Carletti	97			
221	Serena	Angelucci	107			
222	Enea	Tagli	109			
223	Mia	Persichini	100			
224	Ludovica	Trabalza	110			3478161339
225	Beatrice	Galardini	100			3282651327
226	Cesare	Ferracci	108			
227	Tommaso	Ferracci	111			
228	Leonardo	Blasi	106			
229	Mattia	Antonelli	106			
230	Francesco	Perugini	112			
231	Dario	Di Domenico	112			
232	Nicolas	Baiocco	111			3343354314
233	Francesco	Angelucci	102			3400570587
234	Damiano	Angelucci	113			
235	Mattia	Perugini	114			
268	Nicola	Baiocco	111			3343354314
269	Francesco	Angelucci	102			3400570587
271	Sebastiano	Bianchini	108			3922336326
272	Matteo	Guerrini	115			
273	Ginevra	Di Vita	116			3493143441
274	Ludovica	Di Vita	117			3493143441
275	David Domenico	Calicchio	106			3498020045
276	Alessandro	Calicchio	111			3498020045
277	Aurora Anna	Calicchio	111			3498020045
278	Maria Luce	Calicchio	111			3498020045
279	Manuele	Seculoski	106			3245651859
280	Riccardo	Scopolini	108			
281	Gloria	Marinangeli	112			
282	Diego	Anania	103			3401396781
283	Grace	Di Fede	118			
284	Oleksandro	Burkovskyy	106			
285	Sofiya	Byrkovska	103			
286	Mattia	Alunno	112			
287	Alex	Brancaccio	106			
288	Natasha	Brancaccio	120			
289	Giulia	Silvestri	107			
290	Matteo	Rosi	121			3474997189
291	Andrea	Frapiccini	121			
292	Diego	Abazi	122			
293	Fabrizio	Calandri	108			
294	Vittoria	Calandri	111			
295	Elina	Muradi	106			3891562065
296	Selvinas	Elezi	123			3888176696
297	Lorenzo	Donati	124			
298	Alessio	Donati	120			
299	Damiano	Masciotti	125			
300	Filippo	Paoloni	103			
301	Benedetta	Paoloni	108			
302	Lorenzo	Bianchini	126			
303	Angelica	Rosi	107			
304	Gioele	Sbicca	103			
305	Amanda	Bejko	120			
306	Linda	Pieroni	121			
307	Christian	Silvi	119			3473632882
308	Viola	Ventura	103			
309	Maria Sole	Ventura	120			
310	Kloi	Malaj	108			
311	Samuel	Jarua	108			
312	Adele	Bandera	127			
313	Maria Caterina	Bandera	128			
314	Filippo	Silvestri	106			
315	Francesco	Montioni	129			3332344198-3392611182
316	Sofia	Dovara	128			3389075557
317	Giulia	Cioccoloni	112			3498853565
318	Alexsandro	Bogda	119			3455040496
319	Giulio	Masciotti	130			
320	Giorgina	Segura Vasquez	103			3468203834
321	Chiara	Luzi	127			3283322266
322	Viola	Gentili	118			
323	Denise	Fonti	131			
324	Valerio	Ducci	107			
325	Andrea	Filena	107			
326	Alessandro	Faldini	132			
327	Ludovico	Pergolesi	111			3398421724
328	Giorgia	Pergolesi	108			3398421724
329	Sara	Biagioli	133			
330	Simone	Roscini	110			3336776264
331	Maria Giulia	Todini	134			
332	Lorenzo	Bartoloni	110			
333	Sara	O'Boyle	110			
334	Daniele	O'Boyle	97			
335	Dalia	Diotallevi	121			3395968725
336	Emma	Bettini	135			
337	Gabriele	Lepri	128			
338	Cristian	Angelini	112			3802369984
339	Alessandra	Metta	136			3477268065
340	Emma	Magrini	110			3479904713
341	Mattia	Gambacorta	110			
342	Gloria	Gentili	137			
346	Mariano	Abazi	138			
347	Oreste	Abazi	139			
348	Giulia	Orlandi	107			
349	Veronica	Orlandi	109			
350	Nicola	Orlandi	140			
351	Elisa	Jarua	141			
352	Era	Lulaj	142			
353	Aura	Lulaj	107			
354	Francesco	Magaldi	125			3394075547
355	Mattia	Porzi	97			
345	Francesca	Tamburrini	120			3295669188
343	Andrea	Tamburrini	103			3295669188
356	Noemi	Trabalza	144			3332136937
357	Samuele	Massini	110			3409604190
358	Melany	Silva	145			3473964227
359	Matteo	Bileggi	146			3389077028
360	Tomas Junior	Cabrera	147			3473964227
361	Tommaso	Piermarini	135			3473765851
362	Francesco	Riggio	123			3287765772
363	Michele	Dell'amico	148			
364	Rayan	Laabid	149			
365	Basma	Laabid	138			
366	Adelaide	Giannò	150			3392112154
367	Jacopo	Sotis	110			3395491264
368	Alessandro	Di Porzio	151			
369	Greta	Di Porzio	152			
370	Ludovica	Rossi	153			
371	Eleonora	Rossi	154			
372	Lucrezia	Bota	112			3314431205
373	Leonardo	Lini	155			3200287708
374	Margherita	Corea	156			
375	Caterina	Zaganelli	156			
376	Angelica	Porzi	157			
377	Federico	Gellert	111			3284637932
378	Joni	Manxharaj	158			
379	Emma	Roscini	97			
380	Anna	Roscini	100			
381	Noemi	Palomba	159			
382	Jasmine	De Santis	129			3396358412
344	Tommaso	Tamburrini	103			3295669188
383	Elisabetta	Masciotti	160			3472909628 - 3406674794
384	Martina	Catalano	104	Cannara		3923030184
385	Albi	Qose	110			3501315567
386	Ina	Kararaj	161			3896450607
387	Gioele	Ronchetti	146	Foligno		
388	Damiano	Tasselli	100	Foligno		3490879304
389	Tommaso	Del Sero	162	Montefalco		
\.


--
-- Name: casa_editrice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.casa_editrice_id_seq', 61, true);


--
-- Name: classi_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.classi_id_seq', 162, true);


--
-- Name: distributore_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.distributore_id_seq', 22, true);


--
-- Name: libri_classe_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.libri_classe_id_seq', 813, true);


--
-- Name: libri_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.libri_id_seq', 466, true);


--
-- Name: ordine_prenotazioni_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ordine_prenotazioni_id_seq', 1, false);


--
-- Name: ordini_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ordini_id_seq', 119, true);


--
-- Name: prenotazioni_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prenotazioni_id_seq', 408, true);


--
-- Name: prenotazioni_studente_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.prenotazioni_studente_id_seq', 2972, true);


--
-- Name: scuole_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scuole_id_seq', 37, true);


--
-- Name: studenti_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.studenti_id_seq', 389, true);


--
-- Name: case_editrici casa_editrice_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.case_editrici
    ADD CONSTRAINT casa_editrice_pkey PRIMARY KEY (id);


--
-- Name: classi classi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classi
    ADD CONSTRAINT classi_pkey PRIMARY KEY (id);


--
-- Name: distributore distributore_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distributore
    ADD CONSTRAINT distributore_pkey PRIMARY KEY (id);


--
-- Name: libri_classe libri_classe_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri_classe
    ADD CONSTRAINT libri_classe_pkey PRIMARY KEY (id);


--
-- Name: libri libri_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri
    ADD CONSTRAINT libri_pkey PRIMARY KEY (id);


--
-- Name: ordine_prenotazioni ordine_prenotazioni_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordine_prenotazioni
    ADD CONSTRAINT ordine_prenotazioni_pkey PRIMARY KEY (id);


--
-- Name: ordini ordini_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordini
    ADD CONSTRAINT ordini_pkey PRIMARY KEY (id);


--
-- Name: prenotazioni prenotazioni_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni
    ADD CONSTRAINT prenotazioni_pkey PRIMARY KEY (id);


--
-- Name: prenotazioni_studente prenotazioni_studente_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni_studente
    ADD CONSTRAINT prenotazioni_studente_pkey PRIMARY KEY (id);


--
-- Name: scuole scuole_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scuole
    ADD CONSTRAINT scuole_pkey PRIMARY KEY (id);


--
-- Name: studenti studenti_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studenti
    ADD CONSTRAINT studenti_pkey PRIMARY KEY (id);


--
-- Name: v_libri_in_attesa _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_libri_in_attesa AS
 SELECT row_to_json(l.*) AS libro,
    count(ps1.libro) AS num,
    ce.nome AS casa_editrice
   FROM ((public.prenotazioni_studente ps1
     JOIN public.libri l ON ((l.id = ps1.libro)))
     JOIN public.case_editrici ce ON ((ce.id = l.casa_editrice)))
  WHERE ((ps1.stato)::text = 'In ordine'::text)
  GROUP BY l.id, ce.nome;


--
-- Name: v_order_waiting _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_order_waiting AS
 SELECT row_to_json(op.*) AS ordine_prenotazioni,
    row_to_json(ps.*) AS prenotazioni_studente,
    row_to_json(p.*) AS prenotazione,
    json_build_object('libro', row_to_json(l.*), 'num', count(ps1.libro)) AS libri
   FROM ((((public.prenotazioni_studente ps1
     JOIN public.libri l ON ((l.id = ps1.libro)))
     JOIN public.ordine_prenotazioni op ON ((op.id_prenotazione = ps1.id)))
     JOIN public.prenotazioni_studente ps ON ((ps.id = ps1.id)))
     JOIN public.prenotazioni p ON ((p.id = ps.prenotazione)))
  WHERE (((ps1.stato)::text = 'Attesa'::text) AND (ps1.libro = ps.libro))
  GROUP BY l.id, op.*, ps.*, p.*, ps1.*;


--
-- Name: v_libri_per_ordine _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_libri_per_ordine AS
 WITH libri_ordini AS (
         SELECT op.id_ordine,
            ps.libro,
            o.data,
            o.protocollo_ext
           FROM ((public.prenotazioni_studente ps
             JOIN public.ordine_prenotazioni op ON ((op.id_prenotazione = ps.id)))
             JOIN public.ordini o ON ((op.id_ordine = o.id)))
          GROUP BY op.id_ordine, ps.libro, op.id_prenotazione, o.data, o.protocollo_ext
        )
 SELECT ops.id_ordine,
    ops.data,
    row_to_json(l.*) AS libro,
    ce.nome AS casa_editrice,
    count(l.id) AS quantity,
    ops.protocollo_ext
   FROM ((public.libri l
     JOIN ( SELECT libri_ordini.id_ordine,
            libri_ordini.libro,
            libri_ordini.data,
            libri_ordini.protocollo_ext
           FROM libri_ordini) ops ON ((ops.libro = l.id)))
     JOIN public.case_editrici ce ON ((ce.id = l.casa_editrice)))
  GROUP BY l.id, ops.id_ordine, ce.nome, ops.data, ops.protocollo_ext;


--
-- Name: classi classi_scuola_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classi
    ADD CONSTRAINT classi_scuola_fkey FOREIGN KEY (scuola) REFERENCES public.scuole(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: libri libri_casa_editrice_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri
    ADD CONSTRAINT libri_casa_editrice_fkey FOREIGN KEY (casa_editrice) REFERENCES public.case_editrici(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: libri_classe libri_classe_id_classe_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri_classe
    ADD CONSTRAINT libri_classe_id_classe_fkey FOREIGN KEY (id_classe) REFERENCES public.classi(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: libri_classe libri_classe_id_libro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.libri_classe
    ADD CONSTRAINT libri_classe_id_libro_fkey FOREIGN KEY (id_libro) REFERENCES public.libri(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ordine_prenotazioni ordine_prenotazioni_id_ordine_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordine_prenotazioni
    ADD CONSTRAINT ordine_prenotazioni_id_ordine_fkey FOREIGN KEY (id_ordine) REFERENCES public.ordini(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ordine_prenotazioni ordine_prenotazioni_id_prenotazione_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ordine_prenotazioni
    ADD CONSTRAINT ordine_prenotazioni_id_prenotazione_fkey FOREIGN KEY (id_prenotazione) REFERENCES public.prenotazioni_studente(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prenotazioni_studente prenotazioni_studente_libro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni_studente
    ADD CONSTRAINT prenotazioni_studente_libro_fkey FOREIGN KEY (libro) REFERENCES public.libri(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prenotazioni_studente prenotazioni_studente_prenotazione_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni_studente
    ADD CONSTRAINT prenotazioni_studente_prenotazione_fkey FOREIGN KEY (prenotazione) REFERENCES public.prenotazioni(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: prenotazioni_studente prenotazioni_studente_studente_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prenotazioni_studente
    ADD CONSTRAINT prenotazioni_studente_studente_fkey FOREIGN KEY (studente) REFERENCES public.studenti(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: studenti studenti_classe_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.studenti
    ADD CONSTRAINT studenti_classe_fkey FOREIGN KEY (classe) REFERENCES public.classi(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

