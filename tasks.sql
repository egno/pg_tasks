--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.10
-- Dumped by pg_dump version 9.5.0

-- Started on 2016-02-03 13:32:36 NOVT

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 25 (class 2615 OID 47417816)
-- Name: tools; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA tools;


SET search_path = tools, pg_catalog;

--
-- TOC entry 1908 (class 1255 OID 47417854)
-- Name: do(text, bigint, bigint, integer); Type: FUNCTION; Schema: tools; Owner: -
--

CREATE FUNCTION "do"(_q text, _s bigint DEFAULT 0, _e bigint DEFAULT 0, _p integer DEFAULT 10000) RETURNS void
    LANGUAGE plpgsql
    AS $$declare
	_rec tools.task%rowtype;
begin
 if not exists(select pid 
               from pg_stat_activity 
              where pid <> pg_backend_pid() 
              and state = 'active'
              and query like '%tools.run(''' || _q || '%')  then
	delete from tools.task where query = _q;
	insert into tools.task (query, part, condition)
	select _q
	, row_number() over (order by a.a)
	, '(id between ' || a.a::text || ' and ' || (a.a+_p)::text || ')'
	from (select generate_series(_s,_e,_p) a ) a;
	
	for _rec in select * from tools.task where query = _q loop
		if not _rec.result then
			update tools.task t 
			set result=tools.run(_q || ' and ' || _rec.condition) 
			where t.id=_rec.id;
		end if;
	end loop;
else
	raise notice 'procedure is running. Query: %', _q;
end if;
	
end;$$;


--
-- TOC entry 7398 (class 0 OID 0)
-- Dependencies: 1908
-- Name: FUNCTION "do"(_q text, _s bigint, _e bigint, _p integer); Type: COMMENT; Schema: tools; Owner: -
--

COMMENT ON FUNCTION "do"(_q text, _s bigint, _e bigint, _p integer) IS 'Example:
select tools.do($$update regop_transfer set id=id where reason in (''Возврат взносов на КР'',''Возврат средств'')$$, (select min(id) from regop_transfer), (select max(id) from regop_transfer), 100000)';


--
-- TOC entry 1870 (class 1255 OID 47417837)
-- Name: run(text); Type: FUNCTION; Schema: tools; Owner: -
--

CREATE FUNCTION run(_q text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$declare foid oid:= 'tools.run'::regproc::oid;
_res text;
begin
--	raise notice '%', _q;
  if not exists(select pid 
               from pg_stat_activity 
              where pid <> pg_backend_pid() 
              and state = 'active'
              and query like '%tools.run(''' || _q || '%')  then
    select dblink_exec('dbname=' || current_database(), _q) into _res;
    raise notice 'Query: %
Result: %', _q, _res;
  else
    raise notice 'procedure is running. Query: %', _q;
    return false;
  end if;
  return true;
end;
$$;


SET default_with_oids = false;

--
-- TOC entry 1761 (class 1259 OID 47417840)
-- Name: task; Type: TABLE; Schema: tools; Owner: -
--

CREATE TABLE task (
    id bigint NOT NULL,
    query text,
    part integer,
    condition text,
    result boolean DEFAULT false NOT NULL
);


--
-- TOC entry 1760 (class 1259 OID 47417838)
-- Name: task_id_seq; Type: SEQUENCE; Schema: tools; Owner: -
--

CREATE SEQUENCE task_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- TOC entry 7399 (class 0 OID 0)
-- Dependencies: 1760
-- Name: task_id_seq; Type: SEQUENCE OWNED BY; Schema: tools; Owner: -
--

ALTER SEQUENCE task_id_seq OWNED BY task.id;


--
-- TOC entry 7234 (class 2604 OID 47417843)
-- Name: id; Type: DEFAULT; Schema: tools; Owner: -
--

ALTER TABLE ONLY task ALTER COLUMN id SET DEFAULT nextval('task_id_seq'::regclass);


--
-- TOC entry 7237 (class 2606 OID 47417849)
-- Name: pk_task; Type: CONSTRAINT; Schema: tools; Owner: -
--

ALTER TABLE ONLY task
    ADD CONSTRAINT pk_task PRIMARY KEY (id);


--
-- TOC entry 7239 (class 2606 OID 47417851)
-- Name: uk_task; Type: CONSTRAINT; Schema: tools; Owner: -
--

ALTER TABLE ONLY task
    ADD CONSTRAINT uk_task UNIQUE (query, part);


-- Completed on 2016-02-03 13:32:48 NOVT

--
-- PostgreSQL database dump complete
--

