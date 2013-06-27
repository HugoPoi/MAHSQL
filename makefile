
CC=gcc
CFLAGS=-Wall -ggdb
LDFLAGS=-ggdb
EXEC=sql_parser.exe

all: $(EXEC)


$(EXEC): sql_parser.lex.o sql_parser.y.o
		$(CC) -o $@ $^ $(LDFLAGS)

sql_parser.lex.o: sql_parser.lex.c
		$(CC) -c $< -o $@ $(CFLAGS)

sql_parser.y.o: sql_parser.y.c
		$(CC) -c $< -o $@ $(CFLAGS)

sql_parser.h: sql_parser.y
		bison -d sql_parser.y
		mv sql_parser.tab.h sql_parser.h

sql_parser.lex.c: sql_parser.h sql_parser.l
		flex sql_parser.l
		mv  lex.yy.c sql_parser.lex.c

sql_parser.y.c:sql_parser.tab.c
		mv  $< $@


clean:
		rm -f *.h *.c *.o $(EXEC)