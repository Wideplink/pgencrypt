\echo Use "CREATE EXTENSION pgencrypt" to load this file. \quit

CREATE FUNCTION HASH
	(
	    IN password TEXT,
	    IN salt TEXT,
	    IN iterations INT DEFAULT 3,
	    IN memory INT DEFAULT 12,
	    IN parallelism INT DEFAULT 1,
	    IN outlen INT DEFAULT 32
	) RETURNS TEXT AS 'MODULE_PATHNAME', 'pg_hash'
    LANGUAGE C IMMUTABLE STRICT;

CREATE FUNCTION VERIFY 
	 (IN encoded TEXT, IN password TEXT) RETURNS BOOL AS 'MODULE_PATHNAME',
	'pg_verify' LANGUAGE C IMMUTABLE
STRICT; 
