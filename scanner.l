%{

#include "parser.h"

extern int yyerror(char *errormsg);

int yylinepos;
#define YY_USER_ACTION { yylinepos += yyleng; }

%}

%option yylineno
%option noyywrap
%option caseless
%option noinput
%option nounput

alpha		[A-Za-z_]
digit		[0-9]
alphanum	[A-Za-z0-9_]
rest		[ \t]+[^;\n]*
restornot	[^;\n]*

delim 		[ \t]
whitespace 	{delim}+

integer		[-]?{digit}+
hex		"0x"[0-9a-fA-F]+
string		\"[^\"]*\"
comment 	"#"[^\n]*

%%

{integer}		{ sscanf(yytext, "%d", &yylval.value); return INTEGER; }
{hex}			{ sscanf(yytext+2, "%x", &yylval.value); return INTEGER; }
{string}		{ yytext[--yyleng] = 0; yylval.str = strdup(yytext+1); return STRING; }

"add"			{ return ADD; }
"clr"			{ return CLR; }
"in"			{ return IN; }
"jmp"			{ return JMP; }
"jnc"			{ return JNC; }
"mov"			{ return MOV; }
"nop"			{ return NOP; }
"out"			{ return OUT; }
"org"			{ return ORG; }

"A"			{ return REGA; }
"B"			{ return REGB; }

\.?[A-Za-z0-9_@][A-Za-z0-9_\-@\.]*	{ yytext[yyleng] = 0; yylval.str = strdup(yytext); return LABEL; }

\n			{ yylinepos = 0; return EOL; }

[\[\]\(\)\+\-\.\$,:]	{ return yytext[0]; }

{comment}		{ /* No action and no return */ }
{whitespace}		{ /* No action and no return */ }

=			{ return yytext[0]; }

.			{ printf("ILLEGAL CHARACTER '%c'\n", yytext[0]); yyerror("illegal character"); }

%%
