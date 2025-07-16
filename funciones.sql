



CREATE OR REPLACE FUNCTION public.pgtcpcheck(
                                             p_ip_servers TEXT,
                                             p_port INTEGER DEFAULT 5432,
                                             p_timeout INTEGER DEFAULT 2
                                            )												
RETURNS TABLE( 
               ip_server INET, 
               port INT,
			   status_connect BOOLEAN
			 )
SET client_min_messages='notice'
STRICT
AS $_fn_$
DECLARE

	v_tcp_shell TEXT := 'if timeout %s bash -c "echo > /dev/tcp/%s/%s" 2>/dev/null; then echo 1; else  echo 0; fi';
	v_copy_exec TEXT := 'COPY tmp_test_telnet from  PROGRAM $__$ %s  $__$ WITH (DELIMITER ''^'');';
	v_query_exec TEXT; 
	v_element_foreach TEXT; 
	
BEGIN

	IF (select status from verify_ip_entries(p_ip_servers)) THEN
		--  drop table tmp_test_telnet;
		CREATE TEMP TABLE tmp_test_telnet (
			connection  INT
		);
		-- select * from tmp_test_telnet;
		FOREACH v_element_foreach IN ARRAY (select result from verify_ip_entries(p_ip_servers)) LOOP
		 
		ip_server := split_part(v_element_foreach,':',1);
		IF (split_part(v_element_foreach,':',2) != '' ) THEN
			port := split_part(v_element_foreach,':',2)::INT;
		ELSE 
			port := p_port;
		END IF;
		
		v_query_exec := FORMAT(v_tcp_shell, p_timeout,  ip_server , port );
		v_query_exec := FORMAT(v_copy_exec, v_query_exec );
		
		BEGIN
		
	
			EXECUTE v_query_exec ;
			
			IF (SELECT connection FROM tmp_test_telnet) then
				status_connect := TRUE;
			ELSE
			    status_connect := FALSE;
			END IF;
			
			RETURN NEXT;
			
			EXCEPTION
			  WHEN OTHERS THEN
				RAISE NOTICE 'Este es el error : %', SQLERRM;
				RETURN NEXT;
		 
		END;

		TRUNCATE tmp_test_telnet;	
		END LOOP;
	
	ELSE 
		RAISE EXCEPTION ' - Agrega IPs en el formato correcto.';	
	END IF;

	DROP TABLE IF EXISTS tmp_test_telnet;
	
	
END;
$_fn_$ LANGUAGE plpgsql  ;



-- SELECT * from pgtcpcheck('100.28.192.123', 5432);
-- SELECT * from pgtcpcheck('127.0.0.1:5418,127.0.0.1:5416');

 
-- ##########################################################################################################################################################



-- DROP FUNCTION verify_ip_entries(p_valor TEXT);
CREATE OR REPLACE FUNCTION verify_ip_entries(p_valor TEXT)
RETURNS table(status BOOLEAN, result TEXT[]) AS $$
DECLARE
  v_partes TEXT[];
  v_elemento TEXT;
BEGIN

  select array_agg(a) into v_partes from (select distinct unnest(string_to_array(public.clean_string(p_valor),',')) as a ) as a ;

  FOREACH v_elemento IN ARRAY v_partes LOOP
    -- Validar IP
    --IF v_elemento ~ '^([0-9]{1,3}\.){3}[0-9]{1,3}$' THEN
	IF v_elemento ~ '^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$' THEN
      CONTINUE;

    -- Validar IP:Puerto
    ELSIF v_elemento ~ '^([0-9]{1,3}\.){3}[0-9]{1,3}:[0-9]{1,5}$' THEN
      CONTINUE;

    -- Si no cumple ninguno, es inválido
    ELSE
      RETURN QUERY SELECT FALSE, ARRAY[]::TEXT[];
	  RETURN;
    END IF;
  END LOOP;

   RETURN QUERY SELECT TRUE, v_partes;
  
  
END;
$$ LANGUAGE plpgsql;


