%{
#include "y.tab.h"
#include<string.h>
#include<stdlib.h>
%}
SPACE [ \t]+
LETTER [a-zA-Z]+
ALPHNUM [a-zA-Z0-9]*
NUM [0-9]*
COLON :
COMMA ,
DbQt \"[^"]*\"
%%
{SPACE} ;
{DbQt} {
	for(int i=0;i<strlen(yytext)-1;i++) yytext[i]=yytext[i+1];
	yytext[strlen(yytext)-2]='\0';
	yylval.data = strdup(yytext);
	return DbQt;
}
dword return dwd;
{SPACE}\.bss { yylval.data="b";return SEC;}
{SPACE}\.text { yylval.data="t";return SEC;}
{SPACE}\.data { yylval.data="d";return SEC;}
mov|add|sub|cmp { 
	yylval.data = strdup(yytext);
	return OP2;
}
mul|div|jmp|jnz|jz|inc|dec {
	yylval.data = strdup(yytext);
	return OP1;
}
ret return OP0;
section return section;
equ|global|extern return DIRC;
dd { yylval.num=4;return DEF;}
dw { yylval.num=2;return DEF;}
db { yylval.num=1;return DEF;}
dq { yylval.num=8;return DEF;}
resd { yylval.num=4;return BDEF;}
resw { yylval.num=2;return BDEF;}
resb { yylval.num=1;return BDEF;}
resq { yylval.num=8;return BDEF;}
eax { yylval.num=0;return REG;}
ecx { yylval.num=1;return REG;}
edx { yylval.num=2;return REG;}
ebx { yylval.num=3;return REG;}
esp { yylval.num=4;return REG;}
ebp { yylval.num=5;return REG;}
esi { yylval.num=6;return REG;}
edi { yylval.num=7;return REG;}
[a-zA-Z_]{ALPHNUM} { 
	yylval.data = strdup(yytext);
	return SYM;
}
{NUM} { 
	yylval.num = atoi(yytext);
	return NUM;
}
{COLON} return COLON;
{COMMA} return COMMA;
\n return END;
\[ return opn;
\] return clos;
. ;
%%
