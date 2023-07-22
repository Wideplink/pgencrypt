EXTENSION = pgencrypt
PG_CONFIG ?= pg_config
DATA = $(wildcard *--*.sql)
PGXS := $(shell $(PG_CONFIG) --pgxs)
MODULE_big = pgencrypt
OBJS = $(patsubst %.c,%.o,$(wildcard pgencrypt.c))
SHLIB_LINK = -Largon2 -largon2
PG_LDFLAGS += -Largon2
PG_CPPFLAGS += -Iargon2/include -Iargon2/src

include $(PGXS)

argon2/libargon2.a: argon2
	(cd argon2; $(MAKE) CC=gcc LIB_EXT=a CFLAGS="-fPIC -Iinclude -Isrc" libargon2.a)

pgencrypt.o:: argon2/libargon2.a

clean:
	rm -f $(OBJS)
	(cd argon2; $(MAKE) clean)
