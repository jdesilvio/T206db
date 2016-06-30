/*********************************************************/
/* T206 Card and Population Database                     */
/*********************************************************/


-----------------------------------------------------------
-- Create Database 
-----------------------------------------------------------

-- Set run-time configuration parameters
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- Drop database if it exists
DROP DATABASE monster;

-- Create the database
CREATE DATABASE monster
  WITH TEMPLATE = template0 
       ENCODING = 'UTF8' 
       LC_COLLATE = 'en_US.UTF-8' 
       LC_CTYPE = 'en_US.UTF-8';

ALTER DATABASE monster OWNER TO jdesilvio;

-- Connect to database
\connect monster

-- Set run-time configuration parameters
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

-- Create schema 
CREATE SCHEMA public;
ALTER SCHEMA public OWNER TO jdesilvio;
COMMENT ON SCHEMA public IS 'standard public schema';

-- Create extension for PL/pgSQL language
CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
SET search_path = public, pg_catalog;


-----------------------------------------------------------
-- Create Tables
-----------------------------------------------------------

-- Set run-time configuration parameters
SET default_tablespace = '';
SET default_with_oids = false;

-- CARDS
-- All 524 card fronts and their metadata
CREATE TABLE cards (
    id_card integer PRIMARY KEY,
    card text NOT NULL,
    first_name text NOT NULL,
    last_name text NOT NULL,
    variety text,
    full_name text NOT NULL,
    full_name_transposed text NOT NULL
);

ALTER TABLE cards OWNER TO jdesilvio;

-- PSA CARD
-- Card names as they appear in the PSA card registry
-- PSA includes 4 cards with "missing red ink" as individual cards
CREATE TABLE psa_card (
    id_psa_card integer PRIMARY KEY,
    id_card integer REFERENCES cards,
    psa_card text NOT NULL
);

ALTER TABLE psa_card OWNER TO jdesilvio;

-- BACKS
-- All back types and their metadata
CREATE TABLE backs (
    id_back integer PRIMARY KEY,
    psa_back text,
    full_back text NOT NULL,
    brand text NOT NULL,
    short_back text NOT NULL,
    variation text NOT NULL,
    series text NOT NULL,
    factory_short text NOT NULL,
    factory_long text NOT NULL
);

ALTER TABLE backs OWNER TO jdesilvio;

-- PSA
-- Population report table for the PSA card grading registry
-- PSA includes 4 cards with "missing red ink" as individual cards
CREATE TABLE psa (
    id_psa_pop integer PRIMARY KEY,
    id_card_psa integer REFERENCES psa_card,
    first_name text NOT NULL,
    last_name text NOT NULL,
    variety text,
    card text NOT NULL,
    alt_card text NOT NULL,
    brand text NOT NULL,
    grade text NOT NULL,
    amount integer NOT NULL
);

ALTER TABLE psa OWNER TO jdesilvio;

-- GRADES
-- All card grade levels for PSA
CREATE TABLE grades (
    id_grade integer PRIMARY KEY,
    psa_grade_name text NOT NULL
);

ALTER TABLE grades OWNER TO jdesilvio;

-- PSA POP
-- Population report table for the PSA card grading registry
CREATE TABLE psa_pop (
    id_psa_pop integer PRIMARY KEY,
    id_card_psa integer REFERENCES psa_card,
    id_back integer REFERENCES backs,
    id_grade integer REFERENCES grades,
    psa_amount integer NOT NULL
);

ALTER TABLE psa_pop OWNER TO jdesilvio;

-- SMR
-- Price guide information from SMR
CREATE TABLE smr (
    id_smr integer PRIMARY KEY,
    id_card integer REFERENCES cards,
    id_grade integer REFERENCES grades,
    value numeric
);

ALTER TABLE smr OWNER TO jdesilvio;

-- BACK MULTIPLIER
-- The price multiplier for rarer backs vs. common backs
CREATE TABLE back_mult (
    id_back integer PRIMARY KEY,
    multiplier numeric
);

ALTER TABLE back_mult OWNER TO jdesilvio;


-----------------------------------------------------------
-- Create Views
-----------------------------------------------------------

-- Name: psa_pop_view; Type: VIEW; Schema: public; Owner: jdesilvio
CREATE VIEW psa_pop_view AS
 SELECT psa_card.psa_card,
    backs.full_back,
    grades.psa_grade_name,
    psa_pop.psa_amount,
    sum((smr.value * back_mult.multiplier)) AS val
   FROM ((((((psa_pop
     LEFT JOIN backs backs 
       ON ((psa_pop.id_back = backs.id_back)))
     LEFT JOIN grades grades 
       ON ((psa_pop.id_grade = grades.id_grade)))
     LEFT JOIN cards cards 
       ON ((psa_pop.id_card_psa = cards.id_psa_card)))
     LEFT JOIN psa_card psa_card 
       ON ((psa_pop.id_card_psa = psa_card.id_psa_card)))
     RIGHT JOIN smr smr 
       ON (((cards.id_card = smr.id_card) 
            AND ((grades.id_grade)::numeric = smr.id_grade))))
     LEFT JOIN back_mult back_mult 
       ON ((psa_pop.id_back = back_mult.id_back)))
  GROUP BY psa_card.psa_card, 
           backs.full_back, 
           grades.psa_grade_name, 
           psa_pop.psa_amount;

ALTER TABLE psa_pop_view OWNER TO jdesilvio;


-----------------------------------------------------------
-- Create Functions
-----------------------------------------------------------

-- Takes a `card` as an arguement
-- Returns a table of the different backs and the population report
CREATE FUNCTION agg_backs(text) 
  RETURNS TABLE(back text, amt bigint)
    LANGUAGE plpgsql
    AS $_$
    BEGIN
      RETURN QUERY
        SELECT full_back, 
               SUM(psa_amount) AS total_amount
        FROM psa_pop_view
        WHERE psa_card = $1 AND psa_amount > 0
        GROUP BY full_back
        ORDER BY full_back;
    END;
  $_$;

ALTER FUNCTION public.agg_backs(text) OWNER TO jdesilvio;

-- Returns a population report for all backs for all cards
CREATE FUNCTION agg_backs_all() 
  RETURNS TABLE(back text, amt bigint)
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN QUERY
        SELECT full_back, 
               SUM(psa_amount) AS total_amount
        FROM psa_pop_view
        WHERE psa_amount > 0
        GROUP BY full_back
        ORDER BY full_back;
    END;
$$;

ALTER FUNCTION public.agg_backs_all() OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns a table of grades and number of cards in that grade
CREATE FUNCTION agg_grades(text) 
  RETURNS TABLE(grade text, amt bigint)
    LANGUAGE plpgsql
    AS $_$
    BEGIN
      RETURN QUERY
        SELECT psa_grade_name, 
               SUM(psa_amount) AS total_amount
        FROM psa_pop_view
        WHERE psa_card = $1 AND psa_amount > 0
        GROUP BY psa_grade_name
        ORDER BY psa_grade_name;
    END;
  $_$;

ALTER FUNCTION public.agg_grades(text) OWNER TO jdesilvio;

-- Returns a table of grades and number of cards in that grade for all cards
CREATE FUNCTION agg_grades_all() 
  RETURNS TABLE(grade text, amt bigint)
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN QUERY
        SELECT psa_grade_name, 
               SUM(psa_amount) AS total_amount
        FROM psa_pop_view
        WHERE psa_amount > 0
        GROUP BY psa_grade_name
        ORDER BY psa_grade_name;
    END;
 $$;

ALTER FUNCTION public.agg_grades_all() OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns a table of the percent of cards in each back
CREATE FUNCTION percent_backs(text) 
  RETURNS TABLE(back text, percent double precision)
    LANGUAGE plpgsql
    AS $_$
    DECLARE percent_total float;
    BEGIN
      RETURN QUERY
        SELECT full_back, 
               SUM(psa_amount) / CAST(total_cards($1) AS float) AS percent_total
        FROM psa_pop_view
        WHERE psa_card = $1 AND psa_amount > 0
        GROUP BY full_back
        ORDER BY full_back;
    END;
  $_$;

ALTER FUNCTION public.percent_backs(text) OWNER TO jdesilvio;

-- Returns a table of the percent of cards in each back for all cards
CREATE FUNCTION percent_backs_all() 
  RETURNS TABLE(back text, amt bigint, percent double precision)
    LANGUAGE plpgsql
    AS $$
    DECLARE percent_total float;
    DECLARE total bigint := total_cards_all();
    BEGIN
      RETURN QUERY
        SELECT full_back, 
               SUM(psa_amount),
               SUM(psa_amount) / CAST(total AS float) AS percent_total
        FROM psa_pop_view
        WHERE psa_amount > 0
        GROUP BY full_back
        ORDER BY full_back;
    END;
  $$;

ALTER FUNCTION public.percent_backs_all() OWNER TO jdesilvio;

-- Returns a table of the percent of cards in each back for all cards
-- Excludes "unknown" backs
CREATE FUNCTION percent_backs_all_nounknown() 
  RETURNS TABLE(back text, amt bigint, percent double precision)
    LANGUAGE plpgsql
    AS $$
    DECLARE percent_total float;
    DECLARE total bigint := total_cards_all_nounknown();
    BEGIN
      RETURN QUERY
        SELECT full_back, 
               SUM(psa_amount),
               SUM(psa_amount) / CAST(total AS float) AS percent_total
        FROM psa_pop_view
        WHERE psa_amount > 0
        GROUP BY full_back
        ORDER BY full_back;
    END;
  $$;


ALTER FUNCTION public.percent_backs_all_nounknown() OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns a table of the percent of cards in each grade
CREATE FUNCTION percent_grades(text) 
  RETURNS TABLE(grade text, percent double precision)
    LANGUAGE plpgsql
    AS $_$
    DECLARE percent_total float;
    BEGIN
      RETURN QUERY
        SELECT psa_grade_name, 
               SUM(psa_amount) / CAST(total_cards($1) AS float) AS percent_total
        FROM psa_pop_view
        WHERE psa_card = $1 AND psa_amount > 0
        GROUP BY psa_grade_name
        ORDER BY psa_grade_name;
    END;
  $_$;

ALTER FUNCTION public.percent_grades(text) OWNER TO jdesilvio;

-- Returns a table of the percent of cards in each grade for all cards
CREATE FUNCTION percent_grades_all() 
  RETURNS TABLE(grade text, amt bigint, percent double precision)
    LANGUAGE plpgsql
    AS $$
    DECLARE percent_total float;
    DECLARE total bigint := total_cards_all();
    BEGIN
      RETURN QUERY
        SELECT psa_grade_name, 
               SUM(psa_amount),
               CAST(SUM(psa_amount) AS float) / CAST(total AS float)
                 AS percent_total
        FROM psa_pop_view
        WHERE psa_amount > 0
        GROUP BY psa_grade_name
        ORDER BY psa_grade_name;
    END;
$$;

ALTER FUNCTION public.percent_grades_all() OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns a table with the amount and percent of each back
CREATE FUNCTION summary_backs(text) 
  RETURNS TABLE(back text, amt bigint, percent double precision)
    LANGUAGE plpgsql
    AS $_$
    BEGIN
      RETURN QUERY
        SELECT temp1.back, temp1.amt, temp2.percent 
        FROM agg_backs($1) AS temp1 
        LEFT JOIN percent_backs($1) AS temp2 ON temp1.back = temp2.back;
    END;
 $_$;

ALTER FUNCTION public.summary_backs(text) OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns a table with the amount and percent for each grade
CREATE FUNCTION summary_grades(text) 
  RETURNS TABLE(grade text, amt bigint, percent double precision)
    LANGUAGE plpgsql
    AS $_$
    BEGIN
      RETURN QUERY
        SELECT temp1.grade, temp1.amt, temp2.percent 
        FROM agg_grades($1) AS temp1 
        LEFT JOIN percent_grades($1) AS temp2 ON temp1.grade = temp2.grade;
    END;
 $_$;

ALTER FUNCTION public.summary_grades(text) OWNER TO jdesilvio;

-- Takes a `card` as an arguement
-- Returns the total number of cards in the population
CREATE FUNCTION total_cards(text) 
  RETURNS bigint
    LANGUAGE plpgsql
    AS $_$
    BEGIN
      RETURN SUM(psa_amount) AS total_amount
      FROM psa_pop_view
      WHERE psa_card = $1;
    END;
  $_$;

ALTER FUNCTION public.total_cards(text) OWNER TO jdesilvio;

-- Returns the total number of cards in the population of all cards
CREATE FUNCTION total_cards_all() 
  RETURNS bigint
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN SUM(psa_amount) AS total_amount
      FROM psa_pop_view;
    END;
$$;

ALTER FUNCTION public.total_cards_all() OWNER TO jdesilvio;

-- Returns the total number of cards in the population of all cards
-- Excludes "unknown" backs
CREATE FUNCTION total_cards_all_nounknown() 
  RETURNS bigint
    LANGUAGE plpgsql
    AS $$
    BEGIN
      RETURN SUM(psa_amount) AS total_amount
      FROM psa_pop_view
      WHERE full_back != 'Unknown';
    END;
$$;

ALTER FUNCTION public.total_cards_all_nounknown() OWNER TO jdesilvio;


-----------------------------------------------------------
-- Revoke / Grant Privileges
-----------------------------------------------------------

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM jdesilvio;
GRANT ALL ON SCHEMA public TO jdesilvio;
GRANT ALL ON SCHEMA public TO PUBLIC;
