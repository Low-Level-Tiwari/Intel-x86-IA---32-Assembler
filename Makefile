all: lex.l
	yacc -d parse.y
	lex lex.l
	gcc -o gen_imd y.tab.c lex.yy.c -ll
clean:
	rm -f scan lex.yy.c y.tab.c y.tab.h a.out
