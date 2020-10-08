CC=gcc
CFLAGS=-ggdb -DMAXCOLUMNS=8 #-D__DODEBUG 
SRC=columns.c
OUT=columns

all:
	${CC} ${SRC} ${CFLAGS} -o ${OUT}
	make static

static:
	${CC} ${SRC} ${CFLAGS} -static -o ${OUT}

clean:
	@rm -rvf ${OUT} s${OUT}


