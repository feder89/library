--
-- PostgreSQL database dump
--

-- Dumped from database version 10.10
-- Dumped by pg_dump version 10.10

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

CREATE FUNCTION public.get_libri_associated_by_class_id(classid integer) RETURNS TABLE(id integer, casa_editrice character varying, titolo character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
     EXECUTE 'SELECT l.id, ce.nome, l.titolo FROM libri l
INNER JOIN case_editrici ce ON ce.id = l.casa_editrice
WHERE l."id" in (select id_libro FROM libri_classe where id_classe = $1)'
    USING classid;
  RETURN;
END;
$_$;


ALTER FUNCTION public.get_libri_associated_by_class_id(classid integer) OWNER TO postgres;

--
-- Name: get_libri_not_associated_by_class_id(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.get_libri_not_associated_by_class_id(classid integer) RETURNS TABLE(id integer, casa_editrice character varying, titolo character varying)
    LANGUAGE plpgsql
    AS $_$
BEGIN
  RETURN QUERY
     EXECUTE 'SELECT l.id, ce.nome, l.titolo FROM libri l
INNER JOIN case_editrici ce ON ce.id = l.casa_editrice
WHERE l."id" NOT in (select id_libro FROM libri_classe where id_classe = $1)'
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
    caparra real
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
-- Name: v_libri_in_attesa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.v_libri_in_attesa AS
SELECT
    NULL::json AS libro,
    NULL::bigint AS num;


ALTER TABLE public.v_libri_in_attesa OWNER TO postgres;

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
    s.cognome
   FROM ((public.prenotazioni_studente ps
     JOIN public.studenti s ON ((s.id = ps.studente)))
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
-- Name: v_libri_in_attesa _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.v_libri_in_attesa AS
 SELECT row_to_json(l.*) AS libro,
    count(ps1.libro) AS num
   FROM (public.prenotazioni_studente ps1
     JOIN public.libri l ON ((l.id = ps1.libro)))
  WHERE ((ps1.stato)::text = 'In ordine'::text)
  GROUP BY l.id;


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

