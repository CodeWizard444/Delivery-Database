--
-- PostgreSQL database dump
--

-- Dumped from database version 17.2
-- Dumped by pg_dump version 17.2

-- Started on 2025-05-24 16:03:01

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
-- TOC entry 242 (class 1255 OID 33145)
-- Name: actualizeaza_total_comanda(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.actualizeaza_total_comanda(IN p_comanda_id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_nou DECIMAL(10,2);
BEGIN
    total_nou := calcul_total_comanda(p_comanda_id);
    
    UPDATE Comenzi
    SET total = total_nou
    WHERE comanda_id = p_comanda_id;
END;
$$;


ALTER PROCEDURE public.actualizeaza_total_comanda(IN p_comanda_id integer) OWNER TO postgres;

--
-- TOC entry 240 (class 1255 OID 33143)
-- Name: adauga_comanda(integer, date, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.adauga_comanda(IN p_client_id integer, IN p_data date, IN p_status character varying, OUT p_comanda_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Comenzi(client_id, data_comanda, status, total)
    VALUES (p_client_id, p_data, p_status, 0)
    RETURNING comanda_id INTO p_comanda_id;
END;
$$;


ALTER PROCEDURE public.adauga_comanda(IN p_client_id integer, IN p_data date, IN p_status character varying, OUT p_comanda_id integer) OWNER TO postgres;

--
-- TOC entry 241 (class 1255 OID 33144)
-- Name: adauga_produs_la_comanda(integer, integer, integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.adauga_produs_la_comanda(IN p_comanda_id integer, IN p_produs_id integer, IN p_cantitate integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Comanda_Produse(comanda_id, produs_id, cantitate)
    VALUES (p_comanda_id, p_produs_id, p_cantitate)
    ON CONFLICT (comanda_id, produs_id)
    DO UPDATE SET cantitate = Comanda_Produse.cantitate + EXCLUDED.cantitate;
END;
$$;


ALTER PROCEDURE public.adauga_produs_la_comanda(IN p_comanda_id integer, IN p_produs_id integer, IN p_cantitate integer) OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 33137)
-- Name: calcul_total_coamnda(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.calcul_total_coamnda(p_comana_id integer) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
DECLARE 
total DECIMAL(10,2);
BEGIN 
SELECT SUM(p.pret*cp.cantitate)
INTO total
FROM Comanda_Produse cp
JOIN Produse p ON cp.produs_id=p.produs_id
WHERE cp.comanda_id=p_comanda_id;
RETURN COALESCE(total,0);
END;
$$;


ALTER FUNCTION public.calcul_total_coamnda(p_comana_id integer) OWNER TO postgres;

--
-- TOC entry 237 (class 1255 OID 33139)
-- Name: este_vip(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.este_vip(p_client_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
suma_totala DECIMAL(10,2);
BEGIN 
SELECT SUM(total)
INTO suma_totala
FROM Comenzi
WHERE client_id=p_client_id AND status != 'anulata';
RETURN COALESCE(suma_totala,0)>5000;
END;
$$;


ALTER FUNCTION public.este_vip(p_client_id integer) OWNER TO postgres;

--
-- TOC entry 238 (class 1255 OID 33140)
-- Name: estimare_durata_livrare(numeric); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.estimare_durata_livrare(p_distanta numeric) RETURNS numeric
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN ROUND(p_distanta/60.0,2);
END;
$$;


ALTER FUNCTION public.estimare_durata_livrare(p_distanta numeric) OWNER TO postgres;

--
-- TOC entry 249 (class 1255 OID 33160)
-- Name: format_telefon_client(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.format_telefon_client() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.telefon IS NOT NULL AND LENGTH(NEW.telefon) = 10 AND NEW.telefon NOT LIKE '+%'
    THEN
        NEW.telefon := '+4' || NEW.telefon;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.format_telefon_client() OWNER TO postgres;

--
-- TOC entry 243 (class 1255 OID 33146)
-- Name: inregistreaza_traseu_livrare(integer, integer, date, date, numeric); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.inregistreaza_traseu_livrare(IN p_comanda_id integer, IN p_sofer_id integer, IN p_ora_plecare date, IN p_ora_sosire date, IN p_distanta numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO Trasee_Livrari(comanda_id, sofer_id, ora_plecare, ora_sosire, distanta)
    VALUES (p_comanda_id, p_sofer_id, p_ora_plecare, p_ora_sosire, p_distanta);
END;
$$;


ALTER PROCEDURE public.inregistreaza_traseu_livrare(IN p_comanda_id integer, IN p_sofer_id integer, IN p_ora_plecare date, IN p_ora_sosire date, IN p_distanta numeric) OWNER TO postgres;

--
-- TOC entry 248 (class 1255 OID 33158)
-- Name: log_comenzi_anulate(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_comenzi_anulate() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.status = 'anulata' THEN
        INSERT INTO Log_Comenzi_Anulate(comanda_id, client_id)
        VALUES (NEW.comanda_id, NEW.client_id);
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.log_comenzi_anulate() OWNER TO postgres;

--
-- TOC entry 239 (class 1255 OID 33142)
-- Name: numar_comenzi_luna(integer, integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.numar_comenzi_luna(p_an integer, p_luna integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
nr INTEGER;
BEGIN 
SELECT COUNT(*)
INTO nr
FROM Comenzi
WHERE EXTRACT(YEAR FROM data_comanda)=p_an
AND EXTRACT(MONTH FROM data_comanda)=p_luna;
RETURN nr;
END;
$$;


ALTER FUNCTION public.numar_comenzi_luna(p_an integer, p_luna integer) OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 33138)
-- Name: produse_comanda(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.produse_comanda(p_comanda_id integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
produse TEXT;
BEGIN 
SELECT STRING_AGG(p.nume || ' x' || cp.cantitate,', ')
INTO produse
FROM Comanda_Produse cp
JOIN Produse p ON cp.produs_id=p.produs_id
WHERE cp.comanda_i=p_comanda_id;
RETURN COALESCE(produse,'Nicio comanda gasita');
END;
$$;


ALTER FUNCTION public.produse_comanda(p_comanda_id integer) OWNER TO postgres;

--
-- TOC entry 244 (class 1255 OID 33147)
-- Name: schimba_status_comanda(integer, character varying); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.schimba_status_comanda(IN p_comanda_id integer, IN p_nou_status character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE Comenzi
    SET status = p_nou_status
    WHERE comanda_id = p_comanda_id;
END;
$$;


ALTER PROCEDURE public.schimba_status_comanda(IN p_comanda_id integer, IN p_nou_status character varying) OWNER TO postgres;

--
-- TOC entry 245 (class 1255 OID 33148)
-- Name: trigger_actualizeaza_total(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.trigger_actualizeaza_total() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    CALL actualizeaza_total_comanda(NEW.comanda_id);
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.trigger_actualizeaza_total() OWNER TO postgres;

--
-- TOC entry 246 (class 1255 OID 33150)
-- Name: verifica_produse_comanda(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verifica_produse_comanda() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    numar_produse INT;
BEGIN
    SELECT COUNT(*) INTO numar_produse
    FROM Comanda_Produse
    WHERE comanda_id = OLD.comanda_id;

    IF numar_produse = 0 THEN
        RAISE EXCEPTION 'Comanda % nu mai are produse!', OLD.comanda_id;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.verifica_produse_comanda() OWNER TO postgres;

--
-- TOC entry 247 (class 1255 OID 33152)
-- Name: verifica_timp_livrare(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.verifica_timp_livrare() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF NEW.ora_sosire <= NEW.ora_plecare THEN
        RAISE EXCEPTION 'Ora sosirii trebuie să fie după ora plecării.';
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.verifica_timp_livrare() OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 33025)
-- Name: seq_client_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_client_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_client_id OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 223 (class 1259 OID 33037)
-- Name: clienti; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.clienti (
    client_id integer DEFAULT nextval('public.seq_client_id'::regclass) NOT NULL,
    nume character varying(30),
    email character varying(50),
    telefon character varying(10),
    adresa character varying(50),
    oras character varying(30),
    zona_livrare character varying(50)
);


ALTER TABLE public.clienti OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 33071)
-- Name: comanda_produse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comanda_produse (
    comanda_id integer NOT NULL,
    produs_id integer NOT NULL,
    cantitate integer NOT NULL,
    CONSTRAINT comanda_produse_cantitate_check CHECK ((cantitate > 0))
);


ALTER TABLE public.comanda_produse OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 33028)
-- Name: seq_comenzi_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_comenzi_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_comenzi_id OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33058)
-- Name: comenzi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comenzi (
    comanda_id integer DEFAULT nextval('public.seq_comenzi_id'::regclass) NOT NULL,
    client_id integer NOT NULL,
    data_comanda date NOT NULL,
    status character varying(30),
    total numeric(10,2),
    CONSTRAINT comenzi_status_check CHECK (((status)::text = ANY ((ARRAY['plasata'::character varying, 'expediata'::character varying, 'anulata'::character varying, 'in procesare'::character varying, 'primita'::character varying])::text[]))),
    CONSTRAINT comenzi_total_check CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.comenzi OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 33027)
-- Name: seq_produse_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_produse_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_produse_id OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 33050)
-- Name: produse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produse (
    produs_id integer DEFAULT nextval('public.seq_produse_id'::regclass) NOT NULL,
    nume character varying(30),
    categorie character varying(30),
    pret numeric(10,2),
    CONSTRAINT produse_categorie_check CHECK (((categorie)::text = ANY ((ARRAY['alimente'::character varying, 'tech'::character varying, 'imbracaminte'::character varying, 'incaltaminte'::character varying, 'diverse'::character varying])::text[]))),
    CONSTRAINT produse_pret_check CHECK ((pret >= (0)::numeric))
);


ALTER TABLE public.produse OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 33130)
-- Name: detalii_comenzi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.detalii_comenzi AS
 SELECT c.comanda_id,
    c.data_comanda,
    cl.nume AS client,
    p.nume AS produs,
    p.categorie,
    cp.cantitate,
    p.pret,
    ((cp.cantitate)::numeric * p.pret) AS total_linie
   FROM (((public.comenzi c
     JOIN public.clienti cl ON ((c.client_id = cl.client_id)))
     JOIN public.comanda_produse cp ON ((c.comanda_id = cp.comanda_id)))
     JOIN public.produse p ON ((cp.produs_id = p.produs_id)))
  ORDER BY c.comanda_id, p.categorie;


ALTER VIEW public.detalii_comenzi OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 33154)
-- Name: log_comenzi_anulate; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_comenzi_anulate (
    comanda_id integer,
    client_id integer,
    data_anulare timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.log_comenzi_anulate OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 33120)
-- Name: performantasoferi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.performantasoferi AS
SELECT
    NULL::character varying(30) AS nume,
    NULL::character varying(30) AS vehicul,
    NULL::bigint AS numar_livrari,
    NULL::numeric AS distanta_totala_km,
    NULL::numeric AS timp_mediu_ore;


ALTER VIEW public.performantasoferi OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 33029)
-- Name: seq_comanda_produse_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_comanda_produse_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_comanda_produse_id OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 33026)
-- Name: seq_soferi_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_soferi_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_soferi_id OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 33030)
-- Name: seq_trasee_livrari_id; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.seq_trasee_livrari_id
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.seq_trasee_livrari_id OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 33043)
-- Name: soferi; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.soferi (
    sofer_id integer DEFAULT nextval('public.seq_soferi_id'::regclass) NOT NULL,
    nume character varying(30),
    telefon character varying(10),
    vehicul character varying(30),
    zona_acoperita character varying(50),
    CONSTRAINT soferi_vehicul_check CHECK (((vehicul)::text = ANY ((ARRAY['Van'::character varying, 'Motocicleta'::character varying, 'Masina'::character varying, 'Camion'::character varying])::text[])))
);


ALTER TABLE public.soferi OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 33087)
-- Name: trasee_livrari; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trasee_livrari (
    traseu_id integer DEFAULT nextval('public.seq_trasee_livrari_id'::regclass) NOT NULL,
    comanda_id integer NOT NULL,
    sofer_id integer NOT NULL,
    ora_plecare timestamp without time zone NOT NULL,
    ora_sosire timestamp without time zone NOT NULL,
    distanta numeric(16,2),
    CONSTRAINT trasee_livrari_distanta_check CHECK ((distanta > (0)::numeric))
);


ALTER TABLE public.trasee_livrari OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 33125)
-- Name: timp_livrare_zona; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.timp_livrare_zona AS
 SELECT cl.zona_livrare,
    round(avg((EXTRACT(epoch FROM (t.ora_sosire - t.ora_plecare)) / (3600)::numeric)), 2) AS timp_mediu_ore
   FROM ((public.trasee_livrari t
     JOIN public.comenzi c ON ((t.comanda_id = c.comanda_id)))
     JOIN public.clienti cl ON ((c.client_id = cl.client_id)))
  GROUP BY cl.zona_livrare
  ORDER BY (round(avg((EXTRACT(epoch FROM (t.ora_sosire - t.ora_plecare)) / (3600)::numeric)), 2)) DESC;


ALTER VIEW public.timp_livrare_zona OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 33115)
-- Name: top_5_clienti; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.top_5_clienti AS
SELECT
    NULL::character varying(30) AS nume,
    NULL::character varying(50) AS email,
    NULL::numeric AS suma_totala;


ALTER VIEW public.top_5_clienti OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 33110)
-- Name: vanzari_lunare_categorie; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vanzari_lunare_categorie AS
 SELECT date_trunc('month'::text, (c.data_comanda)::timestamp with time zone) AS luna,
    p.categorie,
    sum(((cp.cantitate)::numeric * p.pret)) AS total_vanzaru
   FROM ((public.comenzi c
     JOIN public.comanda_produse cp ON ((c.comanda_id = cp.comanda_id)))
     JOIN public.produse p ON ((cp.produs_id = p.produs_id)))
  WHERE ((c.status)::text <> 'anulata'::text)
  GROUP BY (date_trunc('month'::text, (c.data_comanda)::timestamp with time zone)), p.categorie
  ORDER BY (date_trunc('month'::text, (c.data_comanda)::timestamp with time zone)), p.categorie;


ALTER VIEW public.vanzari_lunare_categorie OWNER TO postgres;

--
-- TOC entry 4960 (class 0 OID 33037)
-- Dependencies: 223
-- Data for Name: clienti; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.clienti (client_id, nume, email, telefon, adresa, oras, zona_livrare) FROM stdin;
1	Popescu Ion	popescu.ion@email.com	0721123456	Str. Primăverii nr. 10	București	Sector 1
2	Ionescu Maria	maria.ionescu@email.com	0732123456	Bd. Libertății nr. 25	Cluj-Napoca	Centru
3	Radulescu Andrei	andrei.radulescu@email.com	0745123456	Str. Dealului nr. 5	Timișoara	Circumvalațiunii
4	Dumitrescu Elena	elena.d@email.com	0756123456	Str. Păcii nr. 15	Iași	Copou
5	Stanciu Mihai	mihai.stanciu@email.com	0767123456	Str. Mihai Eminescu nr. 30	Constanța	Peninsula
6	Georgescu Ana	ana.georgescu@email.com	0778123456	Str. Tudor Vladimirescu nr. 7	Brașov	Centru
7	Marin Vlad	vlad.marin@email.com	0789123456	Str. Unirii nr. 22	Sibiu	Piața Mare
8	Florescu Cristina	cristina.florescu@email.com	0790123456	Str. Revoluției nr. 18	Craiova	Electroputere
9	Munteanu Adrian	adrian.munteanu@email.com	0723456789	Str. Mărăști nr. 3	Oradea	Centru
10	Neagu Gabriela	gabriela.neagu@email.com	0734567890	Str. Viitorului nr. 12	Ploiești	Vest
11	Constantinescu Alin	alin.constantinescu@example.com	0721123457	Str. Mihai Bravu nr. 45	București	Sector 2
12	Popa Andreea	andreea.popa@example.com	0732123457	Bd. Ion Mihalache nr. 12	București	Sector 1
13	Stan Gabriel	gabriel.stan@example.com	0745123457	Str. Lipscani nr. 8	București	Centru Vechi
14	Dobre Carmen	carmen.dobre@example.com	0756123457	Str. Virtuții nr. 3	București	Sector 3
15	Mihai Radu	radu.mihai@example.com	0767123457	Str. Eroilor nr. 17	București	Sector 5
16	Tudor Alexandra	alexandra.tudor@example.com	0778123457	Str. Dorobanți nr. 25	București	Sector 1
17	Nistor Cristian	cristian.nistor@example.com	0789123457	Str. Buzesti nr. 40	București	Sector 6
18	Olteanu Mihaela	mihaela.olteanu@example.com	0790123457	Str. Franceză nr. 9	București	Centru
19	Avram Vlad	vlad.avram@example.com	0723456781	Str. Banul Dumitrache nr. 6	București	Sector 4
20	Barbu Ioana	ioana.barbu@example.com	0734567891	Str. Nicolae G. Caramfil nr. 11	București	Sector 2
21	Sandu George	george.sandu@example.com	0745678912	Str. Memorandumului nr. 14	Cluj-Napoca	Gheorgheni
22	Pavel Daniela	daniela.pavel@example.com	0756789123	Str. Horea nr. 5	Cluj-Napoca	Zorilor
23	Luca Bogdan	bogdan.luca@example.com	0767891234	Str. 1 Decembrie nr. 33	Timișoara	Fabric
24	Balan Simona	simona.balan@example.com	0778912345	Str. Take Ionescu nr. 7	Timișoara	Iosefin
25	Cristea Adrian	adrian.cristea@example.com	0789123456	Str. Cuza Vodă nr. 19	Iași	Tătărași
26	Mocanu Raluca	raluca.mocanu@example.com	0791234567	Str. Sf. Lazăr nr. 8	Iași	Podu Roș
27	Gheorghe Marian	marian.gheorghe@example.com	0722345678	Str. Ovidiu nr. 12	Constanța	Tomis
28	Stoica Larisa	larisa.stoica@example.com	0733456789	Str. Traian nr. 45	Constanța	Faleza Nord
29	Diaconu Ciprian	ciprian.diaconu@example.com	0744567890	Str. Castanilor nr. 3	Brașov	Noua
30	Voicu Diana	diana.voicu@example.com	0755678901	Str. Republicii nr. 28	Brașov	Centru
31	Iacob Sebastian	sebastian.iacob@example.com	0766789012	Str. Gării nr. 10	Sibiu	Sub Arini
32	Rusu Claudia	claudia.rusu@example.com	0777890123	Str. 9 Mai nr. 15	Sibiu	Ștrand
33	Dinu Valentin	valentin.dinu@example.com	0788901234	Str. 1 Mai nr. 7	Craiova	1 Decembrie
34	Moise Alina	alina.moise@example.com	0799012345	Str. Tudor Arghezi nr. 4	Craiova	Centru
35	Toma Dragos	dragos.toma@example.com	0720123456	Str. Republicii nr. 22	Oradea	Nufărul
36	Grigorescu Bianca	bianca.grigorescu@example.com	0731234567	Str. Crișului nr. 9	Oradea	Rogerius
37	Marinescu Horia	horia.marinescu@example.com	0742345678	Str. Bălcescu nr. 13	Ploiești	Centru Civic
38	Petrescu Corina	corina.petrescu@example.com	0753456789	Str. Independenței nr. 5	Ploiești	Astra
39	Enache Robert	robert.enache@example.com	0764567890	Str. Mărășești nr. 18	Galați	Dunărea
40	Dumitru Georgiana	georgiana.dumitru@example.com	0775678901	Str. Brăilei nr. 6	Galați	Țiglina
41	Mihalache Cosmin	cosmin.mihalache@example.com	0786789012	Str. Principală nr. 44	Buzău	Centru
42	Paraschiv Irina	irina.paraschiv@example.com	0797890123	Str. Viitorului nr. 3	Buzău	Stadion
43	Tănase Octavian	octavian.tanase@example.com	0728901234	Str. Libertății nr. 12	Pitești	Trivale
44	Șerban Anca	anca.serban@example.com	0739012345	Str. Victoriei nr. 7	Pitești	Centru
45	Coman Sorin	sorin.coman@example.com	0740123456	Str. Unirii nr. 19	Baia Mare	Centru
46	Popovici Camelia	camelia.popovici@example.com	0751234567	Str. Minerilor nr. 5	Baia Mare	Firiza
47	Adam Victor	victor.adam@example.com	0762345678	Str. Tudor Vladimirescu nr. 8	Suceava	Șcheia
48	Badea Elena	elena.badea@example.com	0773456789	Str. 22 Decembrie nr. 11	Suceava	Burdujeni
49	Ștefănescu Teodor	teodor.stefanescu@example.com	0784567890	Str. Livezii nr. 2	Târgu Mureș	Centru
50	Manole Loredana	loredana.manole@example.com	0795678901	Str. Gheorghe Doja nr. 15	Târgu Mureș	Dâmbul Pietros
51	Bălan Dragoș	dragos.balan@example.com	0721123478	Str. Dealul Viilor nr. 4	Alba Iulia	Cetate
52	Cazacu Iuliana	iuliana.cazacu@example.com	0732123478	Str. Mihai Viteazul nr. 15	Alba Iulia	Centru
53	Dincă Laurențiu	laurentiu.dinca@example.com	0745123478	Str. Aurel Vlaicu nr. 7	Slobozia	Zona Industrială
54	Ene Mihai	mihai.ene@example.com	0756123478	Str. Nicolae Bălcescu nr. 22	Slobozia	Centru
55	Fieraru Andreea	andreea.fieraru@example.com	0767123478	Str. Tudor Vladimirescu nr. 3	Râmnicu Vâlcea	Olt
56	Găman Ovidiu	ovidiu.gaman@example.com	0778123478	Str. Alexandru Ioan Cuza nr. 18	Râmnicu Vâlcea	Gării
57	Hanganu Larisa	larisa.hanganu@example.com	0789123478	Str. Libertății nr. 9	Focșani	Bacovia
58	Irimia Claudiu	claudiu.irimia@example.com	0790123478	Str. Ștefan cel Mare nr. 11	Focșani	Centru
59	Jianu Radu	radu.jianu@example.com	0723456782	Str. Unirii nr. 5	Tulcea	Port
60	Kovacs Emese	emese.kovacs@example.com	0734567892	Str. Dunării nr. 14	Tulcea	Centru
61	Lupu Alexandra	alexandra.lupu@example.com	0745678923	Str. Studentilor nr. 1	Iași	Titu Maiorescu
62	Moldovan Cătălin	catalin.moldovan@example.com	0756789234	Str. Sf. Andrei nr. 6	Iași	Copou
63	Năstase Bianca	bianca.nastase@example.com	0767892345	Str. Universității nr. 3	Cluj-Napoca	Zorilor
64	Oprea Denis	denis.oprea@example.com	0778923456	Str. Memorandului nr. 8	Cluj-Napoca	Marasti
65	Păun Ruxandra	ruxandra.paun@example.com	0789234567	Str. Observatorului nr. 12	Timișoara	Complexul Studențesc
66	Rădulescu Ștefan	stefan.radulescu@example.com	0790345678	Str. Academic nr. 7	Timișoara	Soarelui
67	Stoian Gabriela	gabriela.stoian@example.com	0721456789	Str. Universitară nr. 4	București	Regie
68	Țucă Adrian	adrian.tuca@example.com	0732567890	Str. Politehnicii nr. 9	București	Politehnica
69	Ungureanu Sonia	sonia.ungureanu@example.com	0743678901	Str. Studențească nr. 2	Brașov	Bartolomeu
70	Văduva George	george.vaduva@example.com	0754789012	Str. Căminului nr. 5	Brașov	Observator
71	Zaharia Ionel	ionel.zaharia@example.com	0765890123	Sat Comuna Vânători, nr. 47	Vaslui	Zona Rurală
72	Bucur Marinela	marinela.bucur@example.com	0776901234	Sat Comuna Movilița, nr. 12	Ialomița	Zona Rurală
73	Cristescu Dumitru	dumitru.cristescu@example.com	0787012345	Sat Comuna Perieți, nr. 3	Olt	Zona Rurală
74	Dumitrașcu Florina	florina.dumitrascu@example.com	0798123456	Sat Comuna Ștefan cel Mare, nr. 8	Neamț	Zona Rurală
75	Eftimie Gheorghe	gheorghe.eftimie@example.com	0729234567	Sat Comuna Dobreni, nr. 15	Dâmbovița	Zona Rurală
76	Fătu Carmen	carmen.fatu@example.com	0730345678	Sat Comuna Măgurele, nr. 6	Ilfov	Zona Periurbană
77	Grigoraș Vasile	vasile.grigoras@example.com	0741456789	Sat Comuna Șirna, nr. 22	Prahova	Zona Rurală
78	Huluba Daniel	daniel.huluba@example.com	0752567890	Sat Comuna Băleni, nr. 9	Gorj	Zona Rurală
79	Ioniță Mariana	mariana.ionita@example.com	0763678901	Sat Comuna Văleni, nr. 17	Vâlcea	Zona Rurală
80	Jităreanu Silviu	silviu.jitareanu@example.com	0774789012	Sat Comuna Păulești, nr. 4	Argeș	Zona Rurală
81	Lăcătușu Valentin	valentin.lacatusu@example.com	0785890123	Str. Uzinei nr. 10	Reșița	Zona Industrială
82	Mărginean Roxana	roxana.marginean@example.com	0796901234	Str. Fabrica de Zahăr nr. 5	Luduș	Centru
83	Nicoară Sebastian	sebastian.nicoara@example.com	0728012345	Str. Combinatului nr. 7	Hunedoara	Zona Industrială
84	Olaru Claudia	claudia.olaru@example.com	0739123456	Str. Siderurgiștilor nr. 3	Galați	Zona Industrială
85	Păvăloiu Ionuț	ionut.pavaloiu@example.com	0740234567	Str. Chimiei nr. 9	Pitești	Platforma Industrială
86	Rădoi Mihaela	mihaela.radoi@example.com	0751345678	Str. Industrială nr. 12	Onești	Zona Fabrilor
87	Săvescu George	george.savescu@example.com	0762456789	Str. Uzinei nr. 6	Călărași	Platforma Industrială
88	Tănăsescu Alina	alina.tanasescu@example.com	0773567890	Str. Fabrica de Înghețată nr. 2	Botoșani	Zona Industrială
89	Ursache Marian	marian.ursache@example.com	0784678901	Str. Combinat nr. 8	Brăila	Zona Portuară
90	Vlădescu Andrei	andrei.vladescu@example.com	0795789012	Str. Industrială nr. 4	Ploiești	Platforma Petrochimică
91	Ardelean Ana	ana.ardelean@example.com	0726890123	Str. Bradului nr. 7	Sinaia	Zona Centrală
92	Bădiță Lucian	lucian.badita@example.com	0737901234	Str. Telegondolei nr. 3	Poiana Brașov	Zona Hotelurilor
93	Căpățână Elena	elena.capatana@example.com	0748012345	Str. Muntele Mic nr. 12	Predeal	Zona Pârtii
94	Dobreanu Radu	radu.dobreanu@example.com	0759123456	Str. Trandafirilor nr. 5	Mamaia	Zona Hotelurilor
95	Fierăstrău Diana	diana.fierastrau@example.com	0760234567	Str. Mării nr. 8	Neptun	Zona Plajei
96	Gorun Liviu	liviu.gorun@example.com	0771345678	Str. Pădurii nr. 2	Bușteni	Zona Cabane
97	Hărăbor Mihai	mihai.harabor@example.com	0782456789	Str. Valea Prahovei nr. 9	Azuga	Zona Pârtii
98	Ivașcu Corina	corina.ivascu@example.com	0793567890	Str. Cumpene nr. 1	Vatra Dornei	Zona Centrală
99	Jeleru Paul	paul.jeleru@example.com	0724678901	Str. Băilor nr. 6	Băile Herculane	Zona Balneară
100	Lemnaru Adriana	adriana.lemnaru@example.com	0735789012	Str. Izvorul Minunilor nr. 3	Slănic Moldova	Zona Centrală
101	Antonescu Robert	robert.antonescu@corporatie.com	0721123489	Bd. Expoziției nr. 100	București	Sector 5 - ParkLake
102	Barbu Andreea	andreea.barbu@business.com	0732123489	Str. Barbu Văcărescu nr. 50	București	Sector 2 - Aurel Vlaicu
103	Cristea Daniel	daniel.cristea@executive.com	0745123489	Str. Charles de Gaulle nr. 15	București	Sector 1 - Pipera
104	Dumitrache Elena	elena.dumitrache@office.com	0756123489	Str. Preciziei nr. 22	București	Sector 6 - Orhideea
105	Ene Bogdan	bogdan.ene@management.com	0767123489	Bd. Timișoara nr. 65	București	Sector 4 - Berceni
106	Florescu Laura	laura.florescu@corp.com	0778123489	Str. Nerva Traian nr. 8	București	Sector 3 - Titan
107	Gheorghiu Radu	radu.gheorghiu@enterprise.com	0789123489	Str. Dimitrie Pompei nr. 12	București	Sector 2 - Floreasca
108	Hanganu Oana	oana.hanganu@business.com	0790123489	Str. Semafor nr. 7	București	Sector 1 - Aviatiei
109	Iordache Mihai	mihai.iordache@exec.com	0723456783	Str. Fabrica de Glucoza nr. 3	București	Sector 5 - Cotroceni
110	Jianu Alina	alina.jianu@office.com	0734567893	Str. Drumul Taberei nr. 30	București	Sector 6 - Drumul Taberei
111	Lazăr Gheorghe	gheorghe.lazar@example.com	0745678934	Str. Bisericii nr. 11	Bârlad	Centru
112	Mocanu Maria	maria.mocanu@example.com	0756789345	Str. Păcii nr. 5	Turnu Măgurele	Zona Gara
113	Năstase Ion	ion.nastase@example.com	0767893456	Str. Bătrânilor nr. 2	Moreni	Cartier Vechi
114	Oprea Viorica	viorica.oprea@example.com	0778934567	Str. Crizantemelor nr. 7	Câmpina	Zona Centrală
115	Popescu Dumitru	dumitru.popescu@example.com	0789345678	Str. Castanilor nr. 9	Rădăuți	Cartier Linistit
116	Răducu Elena	elena.raducu@example.com	0790456789	Str. Băncii nr. 1	Buhuși	Centru
117	Stănescu Vasile	vasile.stanescu@example.com	0721567890	Str. Morii nr. 3	Darabani	Zona Veche
118	Tudor Ana	ana.tudor@example.com	0732678901	Str. Vișinilor nr. 6	Beclean	Cartier Pensionari
119	Ungur Ilie	ilie.ungur@example.com	0743789012	Str. Liniștii nr. 4	Zalău	Zona Silentioasă
120	Văduva Gheorghe	gheorghe.vaduva@example.com	0754890123	Str. Rozelor nr. 8	Carei	Cartier Vechi
121	Zamfir Dorin	dorin.zamfir@example.com	0765901234	Sat Comuna Pădureni, nr. 23	Harghita	Zona Montană
122	Bucșă Marcel	marcel.bucsa@example.com	0776012345	Sat Comuna Păulești, nr. 17	Covasna	Zona Forestieră
123	Cătană Iulian	iulian.catana@example.com	0787123456	Sat Comuna Măgura, nr. 9	Buzău	Zona Dealuri
124	Dobrescu Mariana	mariana.dobrescu@example.com	0798234567	Sat Comuna Livezi, nr. 5	Vrancea	Zona Viticolă
125	Enache Gheorghe	gheorghe.enache@example.com	0729345678	Sat Comuna Pănicova, nr. 12	Arad	Zona Agricolă
126	Fătu Ion	ion.fatu@example.com	0730456789	Sat Comuna Grădiștea, nr. 3	Călărași	Zona Lacustră
127	Grigore Vasile	vasile.grigore@example.com	0741567890	Sat Comuna Călinești, nr. 7	Maramureș	Zona Submontană
128	Hulubă Maria	maria.huluba@example.com	0752678901	Sat Comuna Dumbrava, nr. 11	Mehedinți	Zona Deluroasă
129	Iacob Silvia	silvia.iacob@example.com	0763789012	Sat Comuna Văleni, nr. 6	Sălaj	Zona Izolată
130	Jeler Dumitru	dumitru.jeler@example.com	0774890123	Sat Comuna Poiana, nr. 2	Satu Mare	Zona de Frontieră
131	Ionescu Andrei	andrei.ionescu@example.com	0721123490	Str. Principală nr. 45	Miercurea Ciuc	Zona Centrală
132	Popescu Elena	elena.popescu@example.com	0732123490	Str. Horea nr. 8	Târgu Secuiesc	Cartier Nou
133	Marin Daniel	daniel.marin@example.com	0745123490	Str. Libertății nr. 12	Sfântu Gheorghe	Centru Civic
134	Radu Ștefan	stefan.radu@example.com	0756123490	Str. Revoluției nr. 3	Odorheiu Secuiesc	Zona Gării
135	Dumitru Cristian	cristian.dumitru@example.com	0767123490	Str. Castanilor nr. 7	Gheorgheni	Cartier Subdeal
136	Mihai Laurențiu	laurentiu.mihai@example.com	0778123490	Str. Muncii nr. 5	Toplița	Zona Industrială
137	Stoica Maria	maria.stoica@example.com	0789123490	Str. Păcii nr. 9	Covasna	Cartier Silvestru
138	Toma Ioan	ioan.toma@example.com	0790123490	Str. 1 Decembrie nr. 11	Baraolt	Zona Comercială
139	Vasile Iulia	iulia.vasile@example.com	0723456784	Str. Izvorul Minerale nr. 2	Borsec	Zona Balneară
140	Dobre Francisc	francisc.dobre@example.com	0734567894	Str. Salinei nr. 6	Praid	Zona Salină
141	Anghel Raluca	raluca.anghel@example.com	0745678945	Str. Spitalului nr. 1	Slatina	Zona Medicală
142	Bălan Sorin	sorin.balan@example.com	0756789456	Str. Școlii nr. 4	Orăștie	Lângă Liceu
143	Călinescu Ana	ana.calinescu@example.com	0767894567	Str. Tribunalului nr. 3	Roman	Zona Judiciară
144	Dinu Mihnea	mihnea.dinu@example.com	0778945678	Str. Constructorilor nr. 8	Deva	Zona Constructori
145	Economu Victor	victor.economu@example.com	0789456789	Str. Băncii nr. 5	Sighetu Marmației	Centru Financiar
146	Pop Larisa	larisa.pop@example.com	0790567890	Str. Farmaciei nr. 2	Huși	Lângă Farmacie
147	Gheorghiu Teodor	teodor.gheorghiu@example.com	0721678901	Str. Inginerilor nr. 7	Videle	Zona Tehnică
148	Hagi Marius	marius.hagi@example.com	0732789012	Str. Afacerilor nr. 9	Mizil	Zona Industrială
149	Ionescu Adriana	adriana.ionescu@example.com	0743890123	Str. Calculatoarelor nr. 1	Ștefănești	Zona IT
150	Marinescu Claudiu	claudiu.marinescu@example.com	0754901234	Str. Dreptății nr. 6	Curtea de Argeș	Lângă Tribunal
\.


--
-- TOC entry 4964 (class 0 OID 33071)
-- Dependencies: 227
-- Data for Name: comanda_produse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comanda_produse (comanda_id, produs_id, cantitate) FROM stdin;
1	1	3
1	2	2
1	3	1
2	5	2
2	10	1
3	16	1
4	33	1
4	41	1
5	19	1
5	11	2
6	18	1
6	32	1
7	20	1
8	21	1
9	19	1
10	34	1
11	25	2
12	30	1
13	35	1
14	42	1
15	43	1
15	44	1
16	45	1
17	47	1
18	48	1
19	49	1
20	50	1
21	50	2
22	51	3
23	52	2
24	53	5
25	54	4
26	55	1
27	56	2
28	57	1
29	58	1
30	59	3
31	60	2
32	61	1
33	62	6
34	63	4
35	64	1
36	66	1
37	67	1
38	68	1
39	69	1
40	70	1
41	71	1
42	72	1
43	73	1
44	74	1
45	75	1
46	76	1
47	77	1
48	78	1
49	79	2
50	80	1
51	81	1
52	82	1
53	83	1
54	84	1
55	85	1
56	86	1
57	87	1
58	88	1
59	89	1
60	90	1
61	91	1
62	92	1
63	93	1
64	94	1
65	95	1
66	96	1
67	97	1
68	98	1
69	99	1
70	100	1
71	101	1
72	102	1
73	103	1
74	104	1
75	105	1
76	106	1
77	107	1
78	108	1
79	109	1
80	110	1
81	111	1
82	112	1
83	113	1
84	114	1
85	115	1
86	116	1
87	117	1
88	118	1
89	119	1
90	120	1
91	121	2
92	122	1
93	123	1
94	124	3
95	125	1
96	126	1
97	127	1
98	128	1
99	129	1
100	130	1
301	131	1
102	132	2
103	133	1
104	134	1
105	135	1
106	136	1
107	137	1
108	138	1
109	139	1
110	140	1
111	141	1
112	142	1
113	143	1
114	144	1
115	145	1
116	146	1
117	147	1
118	148	1
119	149	1
120	150	1
121	151	1
122	152	2
123	153	1
124	154	1
125	155	1
126	156	1
127	157	1
128	158	1
129	159	1
130	160	1
131	161	1
132	162	1
133	163	1
134	164	1
135	165	1
136	166	1
137	167	1
138	168	1
139	169	1
140	170	1
141	171	2
142	172	3
143	173	1
144	174	2
145	175	1
146	176	5
147	177	1
148	178	1
149	179	1
150	180	1
151	181	1
152	182	1
153	183	1
154	184	1
155	185	1
156	186	1
157	187	1
158	188	1
159	189	1
160	190	1
161	191	1
162	192	1
163	193	1
164	194	1
165	195	1
166	196	1
167	197	1
168	198	1
169	199	1
170	200	1
171	201	1
172	202	1
173	203	1
174	204	1
175	205	1
176	206	1
177	207	1
178	208	1
179	209	1
180	210	1
181	211	1
182	212	1
183	213	1
184	214	1
185	215	1
186	216	1
187	217	1
188	218	1
189	219	1
190	220	1
\.


--
-- TOC entry 4963 (class 0 OID 33058)
-- Dependencies: 226
-- Data for Name: comenzi; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.comenzi (comanda_id, client_id, data_comanda, status, total) FROM stdin;
1	1	2024-05-15	primita	245.99
2	5	2024-05-16	expediata	189.50
3	12	2024-05-17	plasata	356.75
4	3	2024-05-18	in procesare	420.00
5	7	2024-05-19	expediata	99.99
6	15	2024-05-20	primita	575.25
7	22	2024-05-21	anulata	230.00
8	8	2024-05-22	expediata	149.99
9	33	2024-05-23	in procesare	299.50
10	17	2024-05-24	primita	189.00
11	44	2024-05-25	expediata	678.30
12	9	2024-05-26	plasata	125.75
13	28	2024-05-27	primita	345.60
14	50	2024-05-28	expediata	210.00
15	6	2024-05-29	in procesare	499.99
16	38	2024-05-30	primita	159.50
17	11	2024-05-31	expediata	289.75
18	24	2024-06-01	plasata	175.25
19	47	2024-06-02	primita	620.40
20	14	2024-06-03	expediata	89.99
21	2	2024-04-10	primita	320.50
22	19	2024-04-12	expediata	145.75
23	31	2024-04-15	anulata	230.00
24	4	2024-04-18	primita	189.99
25	26	2024-04-20	expediata	275.60
26	13	2024-04-22	primita	420.75
27	35	2024-04-25	expediata	99.50
28	10	2024-04-28	primita	310.25
29	42	2024-05-01	expediata	189.00
30	16	2024-05-03	primita	550.40
31	29	2024-05-05	expediata	230.75
32	7	2024-05-08	primita	129.99
33	21	2024-05-10	expediata	389.50
34	48	2024-05-12	primita	210.25
35	18	2024-05-14	expediata	175.60
36	34	2024-05-16	primita	499.99
37	23	2024-05-18	expediata	289.50
38	40	2024-05-20	primita	159.75
39	27	2024-05-22	expediata	320.25
40	49	2024-05-24	primita	189.00
41	1	2024-03-05	primita	175.50
42	1	2024-04-15	expediata	289.99
43	5	2024-02-18	primita	420.25
44	5	2024-03-22	expediata	159.75
45	12	2024-01-10	primita	230.00
46	12	2024-02-15	expediata	345.60
47	3	2024-03-08	primita	189.99
48	3	2024-04-12	expediata	275.50
49	7	2024-02-20	primita	199.75
50	7	2024-03-25	expediata	310.25
51	15	2024-01-15	primita	289.50
52	15	2024-02-28	expediata	175.60
53	22	2024-03-10	primita	499.99
54	22	2024-04-18	expediata	210.25
55	8	2024-02-05	primita	159.75
56	8	2024-03-15	expediata	320.50
57	33	2024-01-20	primita	189.00
58	33	2024-02-22	expediata	289.99
59	17	2024-03-12	primita	230.75
60	17	2024-04-20	expediata	175.25
61	45	2024-05-05	in procesare	1299.99
62	30	2024-05-08	expediata	1799.00
63	55	2024-05-10	primita	2499.99
64	37	2024-05-12	expediata	1899.00
65	60	2024-05-15	in procesare	3499.00
66	25	2024-05-18	primita	1099.99
67	52	2024-05-20	expediata	1599.50
68	41	2024-05-22	primita	2099.99
69	65	2024-05-25	in procesare	1799.00
70	32	2024-05-28	expediata	2899.99
71	58	2024-05-30	primita	1999.50
72	20	2024-06-01	expediata	2299.99
73	53	2024-06-03	in procesare	1799.00
74	36	2024-06-05	primita	3099.99
75	62	2024-06-08	expediata	1599.50
76	39	2024-06-10	primita	2499.99
77	54	2024-06-12	expediata	1899.00
78	43	2024-06-15	in procesare	2799.99
79	67	2024-06-18	primita	1999.50
80	46	2024-06-20	expediata	3499.00
81	68	2024-06-22	plasata	189.99
82	72	2024-06-23	in procesare	275.50
83	75	2024-06-24	primita	420.25
84	80	2024-06-25	expediata	159.75
85	85	2024-06-26	plasata	230.00
86	90	2024-06-27	in procesare	345.60
87	95	2024-06-28	primita	189.99
88	100	2024-06-29	expediata	275.50
89	105	2024-06-30	plasata	199.75
90	110	2024-07-01	in procesare	310.25
91	115	2024-07-02	primita	289.50
92	120	2024-07-03	expediata	175.60
93	125	2024-07-04	plasata	499.99
94	130	2024-07-05	in procesare	210.25
95	135	2024-07-06	primita	159.75
96	140	2024-07-07	expediata	320.50
97	145	2024-07-08	plasata	189.00
98	150	2024-07-09	in procesare	289.99
99	70	2024-07-10	primita	230.75
100	78	2024-07-11	expediata	175.25
102	3	2024-05-12	plasata	2890.50
103	7	2024-07-20	in procesare	763.00
104	15	2024-09-08	anulata	4200.00
105	1	2024-10-03	primita	1560.75
106	12	2024-11-15	expediata	934.90
107	5	2024-12-01	in procesare	9999.99
108	2	2024-12-20	anulata	350.00
109	9	2025-01-10	primita	2899.99
110	20	2025-01-17	in procesare	735.75
111	11	2025-02-01	expediata	6700.00
112	8	2025-02-15	in procesare	480.00
113	13	2025-03-01	primita	1250.00
114	6	2025-03-10	expediata	2110.30
115	14	2025-03-20	anulata	950.00
116	4	2025-04-05	in procesare	540.00
117	10	2025-04-10	primita	2999.00
118	16	2025-04-15	primita	1800.00
119	17	2025-04-20	primita	3500.00
120	18	2025-04-25	anulata	1120.00
121	19	2025-05-01	primita	900.00
122	3	2025-05-05	primita	420.00
123	7	2025-05-10	in procesare	750.00
124	15	2025-05-15	primita	3500.00
125	1	2025-05-20	primita	1600.00
126	12	2025-05-25	primita	900.00
127	5	2025-05-30	in procesare	10000.00
128	2	2025-06-02	anulata	360.00
129	9	2025-06-05	primita	2800.00
130	20	2025-06-10	in procesare	730.00
131	11	2025-06-15	expediata	6800.00
132	8	2025-06-18	in procesare	500.00
133	13	2025-06-20	primita	1200.00
134	6	2025-06-22	primita	2100.00
135	14	2025-06-24	anulata	900.00
136	4	2025-06-26	in procesare	550.00
137	10	2025-06-28	primita	3000.00
138	16	2025-06-29	primita	1850.00
139	17	2025-06-30	primita	3550.00
140	18	2025-07-01	anulata	1150.00
141	19	2025-07-02	primita	920.00
142	3	2025-07-03	primita	430.00
143	7	2025-07-04	in procesare	760.00
144	15	2025-07-05	primita	3600.00
145	1	2025-07-06	primita	1650.00
146	12	2025-07-07	primita	950.00
147	5	2025-07-08	in procesare	10100.00
148	2	2025-07-09	anulata	370.00
149	9	2025-07-10	primita	2850.00
150	20	2025-07-11	in procesare	740.00
151	11	2025-07-12	expediata	6900.00
152	1	2025-06-01	plasata	1450.75
153	2	2025-06-03	in procesare	980.00
154	3	2025-06-05	expediata	2760.20
155	4	2025-06-07	primita	3600.00
156	5	2025-06-09	anulata	450.00
157	6	2025-06-11	plasata	1200.50
158	7	2025-06-13	in procesare	3340.00
159	8	2025-06-15	primita	2900.10
160	9	2025-06-17	expediata	850.00
161	10	2025-06-19	plasata	1400.75
162	11	2025-06-21	in procesare	1120.00
163	12	2025-06-23	anulata	700.00
164	13	2025-06-25	primita	1950.45
165	14	2025-06-27	plasata	2200.00
166	15	2025-06-29	expediata	4100.20
167	16	2025-07-01	in procesare	3300.00
168	17	2025-07-03	primita	2400.00
169	18	2025-07-05	plasata	1350.00
170	19	2025-07-07	anulata	550.00
171	20	2025-07-09	expediata	2650.35
172	21	2025-07-11	primita	4800.00
173	22	2025-07-13	in procesare	3100.75
174	23	2025-07-15	plasata	770.00
175	24	2025-07-17	expediata	1925.60
176	25	2025-07-19	primita	1380.00
177	26	2025-07-21	anulata	400.00
178	27	2025-07-23	plasata	2200.00
179	28	2025-07-25	in procesare	3150.00
180	29	2025-07-27	primita	3900.00
181	30	2025-07-29	expediata	4550.50
182	31	2025-08-01	plasata	3200.00
183	32	2025-08-03	in procesare	1100.00
184	33	2025-08-05	primita	880.50
185	34	2025-08-07	expediata	2650.00
186	35	2025-08-09	plasata	1020.00
187	36	2025-08-11	anulata	150.00
188	37	2025-08-13	primita	1350.00
189	38	2025-08-15	in procesare	2900.00
190	39	2025-08-17	plasata	4200.00
191	40	2025-08-19	expediata	3550.00
192	41	2025-08-21	primita	4100.00
193	42	2025-08-23	plasata	2700.00
194	43	2025-08-25	in procesare	650.00
195	44	2025-08-27	anulata	750.00
196	45	2025-08-29	expediata	1380.00
197	46	2025-09-01	primita	1800.00
198	47	2025-09-03	plasata	3200.00
199	48	2025-09-05	in procesare	4900.00
200	49	2025-09-07	expediata	5300.00
201	50	2025-09-09	primita	2800.00
202	51	2025-09-11	plasata	1750.00
203	52	2025-09-13	in procesare	2900.50
204	53	2025-09-15	expediata	3400.75
205	54	2025-09-17	primita	2200.00
206	55	2025-09-19	anulata	600.00
207	56	2025-09-21	plasata	1450.00
208	57	2025-09-23	in procesare	2800.00
209	58	2025-09-25	primita	3900.20
210	59	2025-09-27	expediata	4500.00
211	60	2025-09-29	plasata	3200.50
212	61	2025-10-01	in procesare	2100.00
213	62	2025-10-03	anulata	450.00
214	63	2025-10-05	primita	1850.00
215	64	2025-10-07	plasata	2200.75
216	65	2025-10-09	expediata	3750.00
217	66	2025-10-11	in procesare	2900.00
218	67	2025-10-13	primita	2600.00
219	68	2025-10-15	plasata	1550.00
220	69	2025-10-17	anulata	800.00
221	70	2025-10-19	expediata	2950.50
222	71	2025-10-21	primita	4800.00
223	72	2025-10-23	in procesare	3100.00
224	73	2025-10-25	plasata	1250.00
225	74	2025-10-27	expediata	1950.00
226	75	2025-10-29	primita	1400.00
227	76	2025-11-01	anulata	400.00
228	77	2025-11-03	plasata	2300.00
229	78	2025-11-05	in procesare	3200.00
230	79	2025-11-07	primita	3800.00
231	80	2025-11-09	expediata	4700.00
232	81	2025-11-11	plasata	3300.00
233	82	2025-11-13	in procesare	1150.00
234	83	2025-11-15	primita	880.00
235	84	2025-11-17	expediata	2700.00
236	85	2025-11-19	plasata	1050.00
237	86	2025-11-21	anulata	250.00
238	87	2025-11-23	primita	1300.00
239	88	2025-11-25	in procesare	3000.00
240	89	2025-11-27	plasata	4300.00
241	90	2025-11-29	expediata	3600.00
242	91	2025-12-01	primita	4200.00
243	92	2025-12-03	plasata	2800.00
244	93	2025-12-05	in procesare	700.00
245	94	2025-12-07	anulata	800.00
246	95	2025-12-09	expediata	1400.00
247	96	2025-12-11	primita	1900.00
248	97	2025-12-13	plasata	3300.00
249	98	2025-12-15	in procesare	5100.00
250	99	2025-12-17	expediata	5400.00
251	100	2025-12-19	primita	2900.00
252	101	2025-12-21	plasata	2300.00
253	102	2025-12-22	in procesare	1500.50
254	103	2025-12-23	expediata	2700.75
255	104	2025-12-24	primita	3200.00
256	105	2025-12-25	anulata	450.00
257	106	2025-12-26	plasata	2800.00
258	107	2025-12-27	in procesare	2900.00
259	108	2025-12-28	primita	3100.20
260	109	2025-12-29	expediata	3400.00
261	110	2025-12-30	plasata	2100.50
262	111	2025-12-31	in procesare	1900.00
263	112	2026-01-01	anulata	600.00
264	113	2026-01-02	primita	1850.00
265	114	2026-01-03	plasata	1950.75
266	115	2026-01-04	expediata	3750.00
267	116	2026-01-05	in procesare	2200.00
268	117	2026-01-06	primita	2600.00
269	118	2026-01-07	plasata	1950.00
270	119	2026-01-08	anulata	900.00
271	120	2026-01-09	expediata	3100.50
272	121	2026-01-10	primita	4800.00
273	122	2026-01-11	in procesare	3300.00
274	123	2026-01-12	plasata	1250.00
275	124	2026-01-13	expediata	1950.00
276	125	2026-01-14	primita	1400.00
277	126	2026-01-15	anulata	400.00
278	127	2026-01-16	plasata	2300.00
279	128	2026-01-17	in procesare	3200.00
280	129	2026-01-18	primita	3800.00
281	130	2026-01-19	expediata	4700.00
282	131	2026-01-20	plasata	3300.00
283	132	2026-01-21	in procesare	1150.00
284	133	2026-01-22	primita	880.00
285	134	2026-01-23	expediata	2700.00
286	135	2026-01-24	plasata	1050.00
287	136	2026-01-25	anulata	250.00
288	137	2026-01-26	primita	1300.00
289	138	2026-01-27	in procesare	3000.00
290	139	2026-01-28	plasata	4300.00
291	140	2026-01-29	expediata	3600.00
292	141	2026-01-30	primita	4200.00
293	142	2026-01-31	plasata	2800.00
294	143	2026-02-01	in procesare	700.00
295	144	2026-02-02	anulata	800.00
296	145	2026-02-03	expediata	1400.00
297	146	2026-02-04	primita	1900.00
298	147	2026-02-05	plasata	3300.00
299	148	2026-02-06	in procesare	5100.00
300	149	2026-02-07	expediata	5400.00
301	150	2026-02-08	primita	2900.00
\.


--
-- TOC entry 4966 (class 0 OID 33154)
-- Dependencies: 234
-- Data for Name: log_comenzi_anulate; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log_comenzi_anulate (comanda_id, client_id, data_anulare) FROM stdin;
\.


--
-- TOC entry 4962 (class 0 OID 33050)
-- Dependencies: 225
-- Data for Name: produse; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.produse (produs_id, nume, categorie, pret) FROM stdin;
1	Pâine albă	alimente	3.50
2	Lapte 1L	alimente	6.99
3	Ouă 10 buc	alimente	12.50
4	Brânză telemea 500g	alimente	15.75
5	Șuncă premium 200g	alimente	18.99
6	Pui întreg	alimente	25.00
7	Mere Golden 1kg	alimente	5.49
8	Banane 1kg	alimente	8.99
9	Cartofi 2.5kg	alimente	7.50
10	Cafea boabe 250g	alimente	22.90
11	Ciocolată cu lapte 100g	alimente	6.25
12	Biscuiți cu ciocolată	alimente	8.40
13	Suc natural 1L	alimente	9.99
14	Ulei de floarea soarelui 1L	alimente	12.30
15	Făină albă 1kg	alimente	4.20
16	Telefon Xiaomi Redmi Note 12	tech	1299.99
17	Laptop Lenovo IdeaPad 5	tech	3499.00
18	Tabletă Samsung Galaxy Tab A8	tech	899.99
19	Căști wireless Sony WH-CH520	tech	299.50
20	Smartwatch Huawei Band 8	tech	349.00
21	Boxă portabilă JBL Flip 6	tech	599.99
22	Mouse gaming Logitech G502	tech	249.99
23	Tastatură Redragon K530	tech	199.99
24	Monitor LED 24" Full HD	tech	699.00
25	Hard disk extern 1TB	tech	349.99
26	Router TP-Link AX10 WiFi6	tech	399.00
27	Camera de supraveghere IP	tech	199.99
28	Nintendo Switch Lite	tech	1099.00
29	Încărcător rapid 65W	tech	129.99
30	Power bank 20000mAh	tech	149.00
31	Tricou alb bumbac	imbracaminte	49.99
32	Blugi negri slim fit	imbracaminte	129.99
33	Geacă de iarnă	imbracaminte	349.00
34	Costum bărbătesc	imbracaminte	599.99
35	Rochie de vară	imbracaminte	159.99
36	Pulover cu guler	imbracaminte	89.99
37	Bluză femeiască	imbracaminte	79.50
38	Pijama bumbac	imbracaminte	119.99
39	Salopetă damă	imbracaminte	199.99
40	Cămașă formală albă	imbracaminte	149.00
41	Adidași running	incaltaminte	249.99
42	Pantofi de lucru	incaltaminte	199.50
43	Sandale vara	incaltaminte	129.99
44	Ghete de iarnă	incaltaminte	299.00
45	Balerini damă	incaltaminte	159.99
46	Carte "Ion"	diverse	29.99
47	Lego Star Wars	diverse	199.99
48	Set bijuterii argint	diverse	349.50
49	Ghiveci pentru flori	diverse	45.00
50	Tablou decorativ	diverse	129.99
51	Paste făinoase 500g	alimente	5.99
52	Orez basmati 1kg	alimente	12.50
53	Sare iodată 1kg	alimente	2.99
54	Zahăr alb 1kg	alimente	4.25
55	Miere naturală 500g	alimente	22.99
56	Gem de căpșuni 370g	alimente	8.75
57	Salam Sibiu 200g	alimente	14.50
58	Cașcaval românesc 300g	alimente	18.99
59	Ton în ulei 160g	alimente	9.99
60	Porumb conservă 330g	alimente	4.50
63	Apa minerală 2L	alimente	2.50
64	Înghețată vanilie 500ml	alimente	12.99
65	Snackuri sărate 150g	alimente	6.50
66	Tabletă grafică Wacom	tech	599.99
67	Dronă DJI Mini 2 SE	tech	1799.00
68	Proiector BenQ Full HD	tech	2499.99
69	SSD 500GB NVMe	tech	299.00
70	RAM 16GB DDR4	tech	249.99
71	Placă video RTX 3060	tech	1899.00
72	Webcam Logitech C920	tech	349.99
73	Microfon Blue Yeti	tech	599.00
74	Mouse pad gaming XL	tech	89.99
75	Hub USB-C 7-porturi	tech	129.50
76	Cablu HDMI 2.1 3m	tech	79.99
77	Stick WiFi 6	tech	149.00
78	E-reader Kindle Paperwhite	tech	699.99
79	Smart bulb RGB	tech	89.99
80	Stație de încărcare wireless	tech	199.50
81	Costum de baie	imbracaminte	129.99
82	Bluză cu mâneci lungi	imbracaminte	69.99
83	Pantaloni de trening	imbracaminte	89.50
84	Vestă termoizolantă	imbracaminte	179.99
85	Cămașă flanel	imbracaminte	119.50
87	Set termic subțire	imbracaminte	129.00
88	Eșarfă din lână	imbracaminte	59.99
89	Pantaloni scurți sport	imbracaminte	79.50
90	Halat de baie	imbracaminte	149.99
91	Pantofi sport	incaltaminte	279.99
92	Cizme de ploaie	incaltaminte	159.50
93	Pantofi casual	incaltaminte	199.99
94	Sandale ortopedice	incaltaminte	229.00
95	Papuci de casă	incaltaminte	49.99
96	Carte de bucate	diverse	39.99
97	Puzzle 1000 piese	diverse	89.50
98	Set scule universale	diverse	199.99
99	Umidificator aer	diverse	159.00
100	Lampă de citit LED	diverse	79.99
101	Café specialty 250g	alimente	45.00
102	Somon afumat 200g	alimente	32.99
103	Măsline Kalamata 500g	alimente	28.50
104	Trufe negre 50g	alimente	89.99
105	Șampanie brut 750ml	alimente	149.00
106	Husă telefon silicon	tech	39.99
107	Film protecție ecran	tech	29.50
108	Suport laptop ergonomic	tech	159.99
109	Cooler laptop	tech	129.00
110	Baterie externă solară	tech	249.99
111	Set pahare cristal	diverse	199.99
112	Cutie muzicală	diverse	129.50
113	Tabla de șah	diverse	159.00
114	Umbrelă auto	diverse	59.99
115	Aerator de vin	diverse	39.50
116	Set pensule machiaj	diverse	89.99
117	Ceară de masaj	diverse	24.99
118	Grătar portabil	diverse	179.00
119	Lanternă camping	diverse	129.99
120	Set piscină inflabilă	diverse	349.50
121	Iaurt natural 400g	alimente	4.99
122	Salam uscat 300g	alimente	16.50
123	Apă plată 2L	alimente	3.99
124	Pate vegetal	alimente	2.80
125	Cereale integrale	alimente	9.99
126	Gem de căpșuni 300g	alimente	7.50
127	Zahăr alb 1kg	alimente	5.20
128	Sare iodată 500g	alimente	2.30
129	Orez bob lung 1kg	alimente	6.80
130	Paste penne 500g	alimente	4.90
131	Ton în ulei 160g	alimente	8.25
132	Smântână 200g	alimente	3.70
133	Conserve mazăre	alimente	4.40
135	Cremă de ciocolată 400g	alimente	9.80
136	Cablu USB-C 1m	tech	19.99
137	Adaptor HDMI-VGA	tech	34.50
138	Tastatură wireless	tech	109.99
139	SSD 512GB NVMe	tech	299.00
140	Hub USB 4 porturi	tech	49.99
141	Webcam Full HD	tech	139.99
142	Mouse optic wireless	tech	89.99
143	Baterie externă 10000mAh	tech	89.00
144	Suport laptop reglabil	tech	74.90
145	Husă tabletă 10 inch	tech	59.00
146	Lumină LED selfie	tech	39.99
147	Cititor carduri SD	tech	24.99
148	Cooler laptop universal	tech	69.99
149	Tastatură iluminată	tech	149.99
150	Boxe PC stereo	tech	129.50
151	Hanorac unisex	imbracaminte	159.00
152	Șosete bumbac 3 perechi	imbracaminte	24.99
153	Jachetă sport	imbracaminte	229.00
154	Pantaloni trening	imbracaminte	109.99
155	Rochie de seară	imbracaminte	299.99
156	Cardigan damă	imbracaminte	139.99
157	Maiou fitness	imbracaminte	59.99
158	Șort plajă	imbracaminte	69.99
159	Cămașă casual	imbracaminte	119.99
160	Fustă plisată	imbracaminte	89.99
161	Papuci casă	incaltaminte	49.99
162	Espadrile vară	incaltaminte	109.99
163	Pantofi sport damă	incaltaminte	199.99
164	Sandale bărbătești	incaltaminte	139.00
165	Ghete piele	incaltaminte	349.00
166	Ceas de perete	diverse	89.99
167	Set pixuri colorate	diverse	19.99
168	Lanternă LED	diverse	39.90
169	Puzzle 1000 piese	diverse	59.00
170	Set pictură copii	diverse	79.99
171	Croissant simplu	alimente	2.50
172	Iaurt cu fructe 150g	alimente	3.80
173	Miez de nucă 100g	alimente	6.50
174	Castraveți murați	alimente	5.20
175	Napolitane cacao	alimente	3.40
176	Pufuleți simpli	alimente	1.99
177	Granola cu miere	alimente	8.90
178	Sos de roșii 300ml	alimente	4.99
179	Miere polifloră 500g	alimente	17.99
180	Fasole boabe 1kg	alimente	6.30
181	Fructe confiate mix	alimente	9.50
182	Chipsuri sare 100g	alimente	4.30
184	Unt 82% grăsime	alimente	7.80
185	Morcovi 1kg	alimente	3.20
186	Cablu HDMI 2m	tech	29.99
187	Mousepad gaming	tech	39.50
188	Încărcător wireless	tech	119.99
189	Bec smart WiFi	tech	69.00
190	SSD extern 1TB	tech	399.99
191	Carcasă PC ATX	tech	249.00
192	Tastatură RGB TKL	tech	199.00
193	Controller PC USB	tech	129.99
194	Card microSD 128GB	tech	89.99
195	Suport telefon auto	tech	49.99
196	Căști cu microfon	tech	79.90
197	Husă telefon silicon	tech	39.99
198	Brățară fitness	tech	149.50
199	Cameră web 720p	tech	99.00
200	Boxă Bluetooth mică	tech	119.00
201	Pantaloni scurți	imbracaminte	99.99
202	Căciulă tricotată	imbracaminte	39.99
203	Colanți sport	imbracaminte	89.99
204	Eșarfă colorată	imbracaminte	59.99
205	Geacă impermeabilă	imbracaminte	189.99
206	Pulover lână	imbracaminte	129.99
207	Cămașă în carouri	imbracaminte	109.00
208	Vestă matlasată	imbracaminte	159.99
209	Fustă denim	imbracaminte	99.50
210	Bluză tricot fin	imbracaminte	69.99
211	Papuci plajă	incaltaminte	59.99
212	Cizme damă	incaltaminte	249.00
213	Teniși bumbac	incaltaminte	109.99
214	Pantofi casual	incaltaminte	189.99
215	Ghete sport	incaltaminte	229.00
216	Set carioci lavabile	diverse	24.99
217	Cana ceramică	diverse	19.99
218	Scaun camping pliabil	diverse	119.00
219	Set lumânări parfumate	diverse	39.50
220	Perne decorative	diverse	89.99
61	Coca Cola 1.25l	alimente	29.99
62	Pepsi 2l	alimente	3.99
86	Fustă 	imbracaminte	99.99
134	Dr. Pepper 0.33l	alimente	24.99
183	Pepsi doza	alimente	3.70
\.


--
-- TOC entry 4961 (class 0 OID 33043)
-- Dependencies: 224
-- Data for Name: soferi; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.soferi (sofer_id, nume, telefon, vehicul, zona_acoperita) FROM stdin;
1	Popescu Ion	0721123450	Masina	București - Sector 1
2	Ionescu Marian	0732123450	Masina	București - Sector 2
3	Dumitrescu Andrei	0745123450	Masina	București - Sector 3
4	Stanciu Mihai	0756123450	Masina	București - Sector 4
5	Florescu George	0767123450	Masina	București - Sector 5
6	Radu Adrian	0778123450	Masina	București - Sector 6
7	Gheorghe Daniel	0789123450	Masina	Ilfov - Nord
8	Marin Cristian	0790123450	Masina	Ilfov - Sud
9	Toma Alexandru	0722345670	Masina	Cluj-Napoca - Centru
10	Munteanu Bogdan	0733456780	Masina	Cluj-Napoca - Zorilor
11	Dobre Gabriel	0744567890	Masina	Timișoara - Centru
12	Nistor Valentin	0755678901	Masina	Timișoara - Iosefin
13	Sandu Raul	0766789012	Masina	Iași - Copou
14	Luca Sebastian	0777890123	Masina	Iași - Tătărași
15	Manole Ciprian	0788901234	Masina	Constanța - Peninsula
16	Badea Robert	0721123451	Motocicleta	București - Centru Vechi
17	Neagu Cosmin	0732123451	Motocicleta	București - Zona Universității
18	Zaharia Andrei	0745123451	Motocicleta	București - Herăstrău
19	Oprea Mihai	0756123451	Motocicleta	Brașov - Centru
20	Pavel Dragos	0767123451	Motocicleta	Brașov - Noua
21	Ungureanu Florin	0778123451	Motocicleta	Sibiu - Piața Mare
22	Cristea Radu	0789123451	Motocicleta	Sibiu - Sub Arini
23	Diaconu Alin	0790123451	Motocicleta	Craiova - Centru
24	Ene Claudiu	0722345671	Motocicleta	Craiova - Electroputere
25	Rusu Marius	0733456781	Motocicleta	Oradea - Centru
26	Popa Valentin	0744567891	Motocicleta	Oradea - Nufărul
27	Vlad Lucian	0755678902	Motocicleta	Ploiești - Centru
28	Mihai Adrian	0766789013	Motocicleta	Ploiești - Astra
29	Dincă George	0777890124	Motocicleta	Galați - Centru
30	Serban Andrei	0788901235	Motocicleta	Galați - Țiglina
31	Barbu Marian	0721123452	Van	București - Zona Metrou
32	Constantin Gabriel	0732123452	Van	București - Zona Mall-uri
33	Grigore Ionut	0745123452	Van	Cluj-Napoca - Mănăștur
34	Dumitrache Bogdan	0756123452	Van	Cluj-Napoca - Gheorgheni
35	Mocanu Vasile	0767123452	Van	Timișoara - Fabric
36	Olteanu Cristi	0778123452	Van	Timișoara - Elisabetin
37	Avram Dorin	0789123452	Van	Iași - Nicolina
38	Irimia George	0790123452	Van	Iași - Pacurari
39	Tudor Andrei	0722345672	Van	Constanța - Tomis
40	Balan Mihai	0733456782	Van	Constanța - Mamaia
41	Coman Alexandru	0744567892	Camion	Zona Metropolitană București
42	Stoica Valentin	0755678903	Camion	Zona Metropolitană Cluj
43	Dobre Mihai	0766789014	Camion	Zona Metropolitană Timișoara
44	Petrescu Gabriel	0777890125	Camion	Zona Metropolitană Iași
45	Lazăr Andrei	0788901236	Camion	Zona Metropolitană Constanța
46	Mihalache Ion	0721123453	Camion	Zona Industrială Ploiești
47	Popovici George	0732123453	Camion	Zona Industrială Brașov
48	Radulescu Marian	0745123453	Camion	Zona Industrială Craiova
49	Gheorghe Daniel	0756123453	Camion	Zona Industrială Oradea
50	Stan Adrian	0767123453	Camion	Zona Industrială Sibiu
51	Bălan Gabriel	0721123460	Masina	București - Pipera
52	Ciobanu Andrei	0732123460	Masina	București - Băneasa
53	Dinu Claudiu	0745123460	Masina	București - Pantelimon
54	Enache Marius	0756123460	Masina	București - Drumul Taberei
55	Fieraru Ionuț	0767123460	Masina	București - Militari
56	Gavrilă Robert	0778123460	Masina	Pitești - Centru
57	Hanganu Bogdan	0789123460	Masina	Pitești - Trivale
58	Iacob Mihai	0790123460	Masina	Ploiești - Centru Civic
59	Jianu Adrian	0722345678	Masina	Ploiești - Astra
60	Lăcătușu George	0733456789	Masina	Brașov - Racadau
61	Mihai Cristian	0744567891	Masina	Brașov - Schei
62	Nicoară Valentin	0755678912	Masina	Sibiu - Centru Istoric
63	Oprea Raul	0766789123	Masina	Sibiu - Valea Aurie
64	Păun Andrei	0777891234	Masina	Craiova - Centru
65	Rădulescu Cosmin	0788901235	Masina	Craiova - 1 Decembrie
66	Șerban Daniel	0721123461	Motocicleta	București - Dorobanți
67	Tănase Florin	0732123461	Motocicleta	București - Floreasca
68	Ursu Robert	0745123461	Motocicleta	București - Aviației
69	Vladimir Andrei	0756123461	Motocicleta	Cluj-Napoca - Marasti
70	Zaharia Bogdan	0767123461	Motocicleta	Cluj-Napoca - Zorilor
71	Bîrsan George	0778123461	Motocicleta	Timișoara - Circumvalațiunii
72	Călinescu Radu	0789123461	Motocicleta	Timișoara - Freidorf
73	Dumitrescu Alex	0790123461	Motocicleta	Iași - Copou
74	Ene George	0722345679	Motocicleta	Iași - Tătărași
75	Florea Adrian	0733456790	Motocicleta	Constanța - Faleza Nord
76	Grigorescu Ion	0744567901	Motocicleta	Constanța - Faleza Sud
77	Hagi Mihai	0755679012	Motocicleta	Galați - Centru
78	Iordache Robert	0766789013	Motocicleta	Galați - Dunărea
79	Jitariu Andrei	0777890124	Motocicleta	Oradea - Centru
80	Lupu George	0788901236	Motocicleta	Oradea - Nufărul
81	Mănescu Bogdan	0721123462	Van	București - Zona Logistică Nord
82	Năstase Ionuț	0732123462	Van	București - Zona Logistică Sud
83	Olaru George	0745123462	Van	Cluj-Napoca - Zona Industrială
84	Petrache Marian	0756123462	Van	Timișoara - Zona Industrială
85	Rus Adrian	0767123462	Van	Iași - Zona Industrială
86	Ștefan Daniel	0778123462	Van	Constanța - Port
87	Tudor Andrei	0789123462	Van	Ploiești - Zona Industrială
88	Ungureanu George	0790123462	Van	Brașov - Câmpul lui Neag
89	Văduva Ion	0722345680	Van	Sibiu - Zona Industrială
90	Zamfir Marian	0733456801	Van	Craiova - Zona Industrială
91	Anton George	0744568023	Camion	Zona Industrială București
92	Bădescu Marian	0755678034	Camion	Zona Industrială Cluj
93	Cristea Ionuț	0766789045	Camion	Zona Industrială Timișoara
94	Drăgan Andrei	0777890056	Camion	Zona Industrială Iași
95	Făgărășan George	0788901067	Camion	Zona Industrială Constanța
96	Gheorghiu Bogdan	0721123463	Camion	Zona Petrochimică Ploiești
97	Hristu Marian	0732123463	Camion	Zona Industrială Brașov
98	Ioniță George	0745123463	Camion	Zona Industrială Craiova
99	Jeleru Marian	0756123463	Camion	Zona Industrială Oradea
100	Kovacs Andrei	0767123463	Camion	Zona Industrială Sibiu
101	Lăzureanu Ion	0778123463	Van	Zona Rurală Ilfov
102	Mocanu George	0789123463	Van	Zona Rurală Dâmbovița
103	Nemeș Marian	0790123463	Van	Zona Rurală Prahova
104	Oprea Ionuț	0722345681	Van	Zona Rurală Buzău
105	Popescu George	0733456812	Van	Zona Rurală Vâlcea
\.


--
-- TOC entry 4965 (class 0 OID 33087)
-- Dependencies: 228
-- Data for Name: trasee_livrari; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trasee_livrari (traseu_id, comanda_id, sofer_id, ora_plecare, ora_sosire, distanta) FROM stdin;
84	1	1	2024-05-15 00:00:00	2024-05-15 00:00:00	5.20
85	41	1	2024-03-05 00:00:00	2024-03-05 00:00:00	4.80
86	42	1	2024-04-15 00:00:00	2024-04-15 00:00:00	6.10
87	105	1	2024-10-03 00:00:00	2024-10-03 00:00:00	5.50
88	152	1	2025-06-01 00:00:00	2025-06-01 00:00:00	4.30
89	2	2	2024-05-16 00:00:00	2024-05-16 00:00:00	6.70
90	21	2	2024-04-10 00:00:00	2024-04-10 00:00:00	5.90
91	108	2	2024-12-20 00:00:00	2024-12-20 00:00:00	7.20
92	128	2	2025-06-02 00:00:00	2025-06-02 00:00:00	6.80
93	153	2	2025-06-03 00:00:00	2025-06-03 00:00:00	5.50
94	3	3	2024-05-17 00:00:00	2024-05-17 00:00:00	7.50
95	4	3	2024-05-18 00:00:00	2024-05-18 00:00:00	6.20
96	47	3	2024-03-08 00:00:00	2024-03-08 00:00:00	5.80
97	102	3	2024-05-12 00:00:00	2024-05-12 00:00:00	6.40
98	122	3	2025-05-05 00:00:00	2025-05-05 00:00:00	5.10
99	142	3	2025-07-03 00:00:00	2025-07-03 00:00:00	4.90
100	154	3	2025-06-05 00:00:00	2025-06-05 00:00:00	7.30
101	5	16	2024-05-19 00:00:00	2024-05-19 00:00:00	3.20
102	8	17	2024-05-22 00:00:00	2024-05-22 00:00:00	4.10
103	12	18	2024-05-26 00:00:00	2024-05-26 00:00:00	3.80
104	18	19	2024-06-01 00:00:00	2024-06-01 00:00:00	4.50
105	20	20	2024-06-03 00:00:00	2024-06-03 00:00:00	3.70
106	9	9	2024-05-23 00:00:00	2024-05-23 00:00:00	6.80
107	33	10	2024-05-10 00:00:00	2024-05-10 00:00:00	7.50
108	69	33	2024-06-25 00:00:00	2024-06-25 00:00:00	6.30
109	83	34	2024-06-24 00:00:00	2024-06-24 00:00:00	7.10
110	70	70	2024-05-28 00:00:00	2024-05-28 00:00:00	8.20
111	11	11	2024-05-25 00:00:00	2024-05-25 00:00:00	5.90
112	25	12	2024-04-20 00:00:00	2024-04-20 00:00:00	6.40
113	36	35	2024-05-16 00:00:00	2024-05-16 00:00:00	7.00
114	84	36	2024-06-25 00:00:00	2024-06-25 00:00:00	6.80
115	75	43	2024-06-08 00:00:00	2024-06-08 00:00:00	8.10
116	13	13	2024-05-27 00:00:00	2024-05-27 00:00:00	5.60
117	26	14	2024-04-22 00:00:00	2024-04-22 00:00:00	6.30
118	37	37	2024-05-18 00:00:00	2024-05-18 00:00:00	7.20
119	63	38	2024-05-10 00:00:00	2024-05-10 00:00:00	6.90
120	113	14	2025-03-01 00:00:00	2025-03-01 00:00:00	7.50
121	14	15	2024-05-28 00:00:00	2024-05-28 00:00:00	5.40
122	39	39	2024-05-22 00:00:00	2024-05-22 00:00:00	6.70
123	40	40	2024-05-24 00:00:00	2024-05-24 00:00:00	7.00
124	80	45	2024-06-20 00:00:00	2024-06-20 00:00:00	8.30
125	96	40	2024-07-07 00:00:00	2024-07-07 00:00:00	7.80
126	19	19	2024-06-02 00:00:00	2024-06-02 00:00:00	6.50
127	20	20	2024-06-03 00:00:00	2024-06-03 00:00:00	7.10
128	88	20	2024-06-29 00:00:00	2024-06-29 00:00:00	6.80
129	72	60	2024-06-01 00:00:00	2024-06-01 00:00:00	7.40
130	205	60	2025-09-17 00:00:00	2025-09-17 00:00:00	6.90
131	61	41	2024-05-05 00:00:00	2024-05-05 00:00:00	15.20
132	62	42	2024-05-08 00:00:00	2024-05-08 00:00:00	18.50
133	64	44	2024-05-12 00:00:00	2024-05-12 00:00:00	22.70
134	65	41	2024-05-15 00:00:00	2024-05-15 00:00:00	20.30
135	77	47	2024-06-12 00:00:00	2024-06-12 00:00:00	19.80
136	30	41	2024-05-03 00:00:00	2024-05-03 00:00:00	65.20
137	53	42	2024-03-10 00:00:00	2024-03-10 00:00:00	78.50
138	67	43	2024-05-20 00:00:00	2024-05-20 00:00:00	82.30
139	79	45	2024-06-18 00:00:00	2024-06-18 00:00:00	95.70
140	109	42	2025-01-10 00:00:00	2025-01-10 00:00:00	88.40
141	81	16	2024-06-22 00:00:00	2024-06-22 00:00:00	3.50
142	82	17	2024-06-23 00:00:00	2024-06-23 00:00:00	4.20
143	85	18	2024-06-26 00:00:00	2024-06-26 00:00:00	3.80
144	89	19	2024-06-30 00:00:00	2024-06-30 00:00:00	4.00
145	93	20	2024-07-04 00:00:00	2024-07-04 00:00:00	3.60
146	104	91	2024-09-08 00:00:00	2024-09-08 00:00:00	25.70
147	107	92	2024-12-01 00:00:00	2024-12-01 00:00:00	32.40
148	111	93	2025-02-01 00:00:00	2025-02-01 00:00:00	45.80
149	119	94	2025-04-20 00:00:00	2025-04-20 00:00:00	38.60
150	124	95	2025-05-15 00:00:00	2025-05-15 00:00:00	42.30
151	301	101	2024-06-22 00:00:00	2024-06-22 00:00:00	18.20
152	103	102	2024-07-20 00:00:00	2024-07-20 00:00:00	22.50
153	110	103	2025-01-17 00:00:00	2025-01-17 00:00:00	20.80
154	116	104	2025-04-05 00:00:00	2025-04-05 00:00:00	19.70
155	120	105	2025-04-25 00:00:00	2025-04-25 00:00:00	21.40
156	6	31	2024-05-20 00:00:00	2024-05-20 00:00:00	8.70
157	15	32	2024-05-29 00:00:00	2024-05-29 00:00:00	10.20
158	17	31	2024-05-31 00:00:00	2024-05-31 00:00:00	9.50
159	22	32	2024-04-12 00:00:00	2024-04-12 00:00:00	11.30
160	28	31	2024-04-28 00:00:00	2024-04-28 00:00:00	8.90
161	145	51	2025-07-06 00:00:00	2025-07-06 00:00:00	7.80
162	146	52	2025-07-07 00:00:00	2025-07-07 00:00:00	9.20
163	147	53	2025-07-08 00:00:00	2025-07-08 00:00:00	10.50
164	148	54	2025-07-09 00:00:00	2025-07-09 00:00:00	8.30
165	149	55	2025-07-10 00:00:00	2025-07-10 00:00:00	9.70
166	150	56	2025-07-11 00:00:00	2025-07-11 00:00:00	8.90
\.


--
-- TOC entry 4972 (class 0 OID 0)
-- Dependencies: 217
-- Name: seq_client_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_client_id', 150, true);


--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 221
-- Name: seq_comanda_produse_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_comanda_produse_id', 1, false);


--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 220
-- Name: seq_comenzi_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_comenzi_id', 301, true);


--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 219
-- Name: seq_produse_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_produse_id', 220, true);


--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 218
-- Name: seq_soferi_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_soferi_id', 105, true);


--
-- TOC entry 4977 (class 0 OID 0)
-- Dependencies: 222
-- Name: seq_trasee_livrari_id; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.seq_trasee_livrari_id', 166, true);


--
-- TOC entry 4773 (class 2606 OID 33042)
-- Name: clienti clienti_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.clienti
    ADD CONSTRAINT clienti_pkey PRIMARY KEY (client_id);


--
-- TOC entry 4789 (class 2606 OID 33076)
-- Name: comanda_produse comanda_produse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comanda_produse
    ADD CONSTRAINT comanda_produse_pkey PRIMARY KEY (comanda_id, produs_id);


--
-- TOC entry 4785 (class 2606 OID 33065)
-- Name: comenzi comenzi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comenzi
    ADD CONSTRAINT comenzi_pkey PRIMARY KEY (comanda_id);


--
-- TOC entry 4783 (class 2606 OID 33057)
-- Name: produse produse_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produse
    ADD CONSTRAINT produse_pkey PRIMARY KEY (produs_id);


--
-- TOC entry 4779 (class 2606 OID 33049)
-- Name: soferi soferi_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.soferi
    ADD CONSTRAINT soferi_pkey PRIMARY KEY (sofer_id);


--
-- TOC entry 4793 (class 2606 OID 33093)
-- Name: trasee_livrari trasee_livrari_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trasee_livrari
    ADD CONSTRAINT trasee_livrari_pkey PRIMARY KEY (traseu_id);


--
-- TOC entry 4774 (class 1259 OID 33162)
-- Name: idx_clienti_email; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clienti_email ON public.clienti USING btree (email);


--
-- TOC entry 4775 (class 1259 OID 33163)
-- Name: idx_clienti_oras_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_clienti_oras_zona ON public.clienti USING btree (oras, zona_livrare);


--
-- TOC entry 4786 (class 1259 OID 33168)
-- Name: idx_comenzi_client; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comenzi_client ON public.comenzi USING btree (client_id);


--
-- TOC entry 4787 (class 1259 OID 33169)
-- Name: idx_comenzi_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_comenzi_status ON public.comenzi USING btree (status);


--
-- TOC entry 4780 (class 1259 OID 33166)
-- Name: idx_produse_categorie; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_produse_categorie ON public.produse USING btree (categorie);


--
-- TOC entry 4781 (class 1259 OID 33167)
-- Name: idx_produse_pret; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_produse_pret ON public.produse USING btree (pret);


--
-- TOC entry 4776 (class 1259 OID 33165)
-- Name: idx_soferi_vehicul; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_soferi_vehicul ON public.soferi USING btree (vehicul);


--
-- TOC entry 4777 (class 1259 OID 33164)
-- Name: idx_soferi_zona; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_soferi_zona ON public.soferi USING btree (zona_acoperita);


--
-- TOC entry 4790 (class 1259 OID 33171)
-- Name: idx_trasee_comanda; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trasee_comanda ON public.trasee_livrari USING btree (comanda_id);


--
-- TOC entry 4791 (class 1259 OID 33170)
-- Name: idx_trasee_sofer; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trasee_sofer ON public.trasee_livrari USING btree (sofer_id);


--
-- TOC entry 4950 (class 2618 OID 33118)
-- Name: top_5_clienti _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.top_5_clienti AS
 SELECT cl.nume,
    cl.email,
    sum(c.total) AS suma_totala
   FROM (public.clienti cl
     JOIN public.comenzi c ON ((cl.client_id = c.client_id)))
  WHERE ((c.status)::text <> 'anulata'::text)
  GROUP BY cl.client_id
  ORDER BY (sum(c.total)) DESC
 LIMIT 5;


--
-- TOC entry 4951 (class 2618 OID 33123)
-- Name: performantasoferi _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.performantasoferi AS
 SELECT s.nume,
    s.vehicul,
    count(t.traseu_id) AS numar_livrari,
    sum(t.distanta) AS distanta_totala_km,
    round(avg((EXTRACT(epoch FROM (t.ora_sosire - t.ora_plecare)) / (3600)::numeric)), 2) AS timp_mediu_ore
   FROM (public.soferi s
     JOIN public.trasee_livrari t ON ((s.sofer_id = t.sofer_id)))
  GROUP BY s.sofer_id;


--
-- TOC entry 4801 (class 2620 OID 33149)
-- Name: comanda_produse trg_actualizeaza_total; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_actualizeaza_total AFTER INSERT OR DELETE OR UPDATE ON public.comanda_produse FOR EACH ROW EXECUTE FUNCTION public.trigger_actualizeaza_total();


--
-- TOC entry 4799 (class 2620 OID 33161)
-- Name: clienti trg_format_telefon; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_format_telefon BEFORE INSERT OR UPDATE ON public.clienti FOR EACH ROW EXECUTE FUNCTION public.format_telefon_client();


--
-- TOC entry 4800 (class 2620 OID 33159)
-- Name: comenzi trg_log_anulare; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_anulare AFTER UPDATE ON public.comenzi FOR EACH ROW WHEN (((old.status)::text IS DISTINCT FROM (new.status)::text)) EXECUTE FUNCTION public.log_comenzi_anulate();


--
-- TOC entry 4802 (class 2620 OID 33151)
-- Name: comanda_produse trg_verifica_produse; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_verifica_produse AFTER DELETE ON public.comanda_produse FOR EACH ROW EXECUTE FUNCTION public.verifica_produse_comanda();


--
-- TOC entry 4803 (class 2620 OID 33153)
-- Name: trasee_livrari trg_verifica_timp_livrare; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_verifica_timp_livrare BEFORE INSERT OR UPDATE ON public.trasee_livrari FOR EACH ROW EXECUTE FUNCTION public.verifica_timp_livrare();


--
-- TOC entry 4795 (class 2606 OID 33077)
-- Name: comanda_produse comanda_produse_comanda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comanda_produse
    ADD CONSTRAINT comanda_produse_comanda_id_fkey FOREIGN KEY (comanda_id) REFERENCES public.comenzi(comanda_id);


--
-- TOC entry 4796 (class 2606 OID 33082)
-- Name: comanda_produse comanda_produse_produs_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comanda_produse
    ADD CONSTRAINT comanda_produse_produs_id_fkey FOREIGN KEY (produs_id) REFERENCES public.produse(produs_id);


--
-- TOC entry 4794 (class 2606 OID 33066)
-- Name: comenzi comenzi_client_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comenzi
    ADD CONSTRAINT comenzi_client_id_fkey FOREIGN KEY (client_id) REFERENCES public.clienti(client_id);


--
-- TOC entry 4797 (class 2606 OID 33094)
-- Name: trasee_livrari trasee_livrari_comanda_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trasee_livrari
    ADD CONSTRAINT trasee_livrari_comanda_id_fkey FOREIGN KEY (comanda_id) REFERENCES public.comenzi(comanda_id);


--
-- TOC entry 4798 (class 2606 OID 33099)
-- Name: trasee_livrari trasee_livrari_sofer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trasee_livrari
    ADD CONSTRAINT trasee_livrari_sofer_id_fkey FOREIGN KEY (sofer_id) REFERENCES public.soferi(sofer_id);


-- Completed on 2025-05-24 16:03:02

--
-- PostgreSQL database dump complete
--

