#include "postgres.h"

#include "argon2.h"
#include "core.h"
#include "fmgr.h"
#include "utils/builtins.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(pg_hash);
Datum pg_hash(PG_FUNCTION_ARGS)
{
    text *raw_password = PG_GETARG_TEXT_P(0);
    text *raw_salt     = PG_GETARG_TEXT_P(1);
    int iterations     = PG_GETARG_INT32(2); // computation
    int memory         = PG_GETARG_INT32(3); // memory usage
    int parallelism    = PG_GETARG_INT32(4);
    int hashlen        = PG_GETARG_INT32(5);

    char *password   = VARDATA(raw_password);
    char *salt       = VARDATA(raw_salt);
    int password_len = VARSIZE(raw_password) - VARHDRSZ;
    int salt_len     = VARSIZE(raw_salt) - VARHDRSZ;

    text *result;
    size_t encodedlen;
    int status;

    if (iterations < 1) {
        secure_wipe_memory(password, password_len);
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("iterations must be greater than 0")));
        PG_RETURN_NULL();
    }
    if (memory < 1) {
        secure_wipe_memory(password, password_len);
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("memory must be greater than 0")));
        PG_RETURN_NULL();
    }
    if (parallelism < 1) {
        secure_wipe_memory(password, password_len);
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("parallelism must be greater than 0")));
        PG_RETURN_NULL();
    }

    encodedlen = argon2_encodedlen(iterations, memory, parallelism, salt_len, hashlen, Argon2_id);
    result     = palloc(encodedlen + VARHDRSZ);
    SET_VARSIZE(result, encodedlen + VARHDRSZ);

    status = argon2id_hash_encoded(iterations, memory, parallelism, password, password_len, salt, salt_len, hashlen, VARDATA(result), encodedlen);

    secure_wipe_memory(password, password_len);

    if (status != ARGON2_OK) {
        ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR), errmsg("argon2id_hash_encoded failed with status %d", status)));
        PG_RETURN_NULL();
    }

    PG_RETURN_TEXT_P(result);
}

PG_FUNCTION_INFO_V1(pg_verify);
Datum pg_verify(PG_FUNCTION_ARGS)
{
    char *encoded      = text_to_cstring(PG_GETARG_TEXT_P(0));
    text *raw_password = PG_GETARG_TEXT_P(1);

    char *password   = VARDATA(raw_password);
    int password_len = VARSIZE(raw_password) - VARHDRSZ;

    int status;

    if (strncmp(encoded, "$argon2id", 9) != 0 || strlen(encoded) < 10) {
        secure_wipe_memory(password, password_len);
        ereport(ERROR, (errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("Not a valid Argon2 hash")));
        PG_RETURN_NULL();
    }

    status = argon2id_verify(encoded, password, password_len);

    secure_wipe_memory(password, password_len);
    switch (status) {
    case ARGON2_OK:
        PG_RETURN_BOOL(1);

    case ARGON2_VERIFY_MISMATCH:
        PG_RETURN_BOOL(0);

    default:
        ereport(ERROR, (errcode(ERRCODE_INTERNAL_ERROR), errmsg("secure_wipe_memory failed with status %d", status)));
        PG_RETURN_NULL();
    }
}
