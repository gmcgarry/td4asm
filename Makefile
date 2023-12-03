#CFLAGS += -DYYDEBUG -DYYERROR_VERBOSE=1 -g -Wall 
CFLAGS += -DYYERROR_VERBOSE=1 -g -Wall 

LDLIBS += -lfl

SRCS = parser.c scanner.c

OBJS = $(SRCS:.c=.o)

all:	as

as:	$(OBJS)
	$(LINK.o) $^ -o $@ $(LDLIBS)

$(OBJS):	parser.h

.SUFFIXES: .c .h .y .l

.y.c .y.h:
	$(YACC) -v -Wall -d -t $<
	mv y.tab.c $@
	mv y.tab.h $(@:.c=.h)

.l.c:
	lex -o $@ $^

.c.o:
	$(COMPILE.c) $(CFLAGS) -o $@ $<

clean:
	rm -f $(OBJS) $(GENSRC) as parser.h y.output
