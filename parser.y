%{

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


extern int yyparse();
extern int yylex();

extern int yylineno;
extern int yydebug;

void yyerror(const char *s);

struct label {
	int is_defined;
	const char* name;
	int value;
	struct label* next;
};


struct label* labels = NULL;
int dot;
int pass;

struct label* label_lookup(const char* str);
void emit(int inst);

%}

%union { int value; struct label* label; const char* str; }

%token ORG
%token CLR ADD OUTB NOP MOV JMP JNC OUT IN
%token REGA REGB

%token EOL
%token <value> INTEGER
%token <str> STRING LABEL
%type <label> label
%type <value> reg
%type <value> addr imm optimm

%%

program: /* empty string */
	| program line
	;

line:	EOL
	| label EOL
	| label statement EOL
	| statement EOL 
	| error EOL		{ yyerrok; } 
	;

label:	LABEL ':'		{ $$ = label_lookup($1); if (pass == 1 && $$->is_defined) yyerror("label redefined"); $$->value = dot; $$->is_defined = 1; }
	;

statement:
	ORG INTEGER		{ dot = $2; }
	| LABEL '=' INTEGER	{ struct label* label = label_lookup($1); if (pass == 1 && label->is_defined) yyerror("label redefined"); label->value = $3; label->is_defined = 1; }
	| NOP			{ emit(0x00); }
	| CLR	reg		{ if ($2 == REGA) emit(0x30); else emit(0x70); }
	| MOV	reg ',' imm	{ if ($2 == REGA) emit(0x30 | $4); else emit(0x70 | $4); }
	| ADD	reg ',' imm	{ if ($2 == REGA) emit(0x00 | $4); else emit(0x50 | $4); }

	| IN	reg		{ if ($2 == REGA) emit(0x20); else emit(0x60); }
	| OUT	REGB		{ emit(0x90); }
	| OUT	imm		{ emit(0xb0 | $2); }

	| MOV	reg ',' reg	{ if ($2 == $4) yyerror("bad register operands"); if ($2 == REGA) emit(0x10); else emit(0x40); }

	| MOV	reg ',' reg '+' INTEGER
				{ if ($2 == $4) yyerror("bad register operands"); if ($2 == REGA) emit(0x10 | $6); else emit(0x40 | $6); }

	| JNC	optimm '(' REGB ')'	{ emit(0xC0 | $2); }
	| JMP	optimm '(' REGB ')'	{ emit(0xD0 | $2); }

	| JNC	addr		{ emit(0xE0 | $2); }
	| JMP	addr		{ emit(0xF0 | $2); }
	;

addr:	LABEL			{
					struct label *label = label_lookup($1);
					if (pass == 2 && !label->is_defined) yyerror("undefined label");
					if (pass == 2 && (label->value & ~0x0F)) yyerror("address too large");
					$$ = label->value & 0x0F;
				}
	| INTEGER		{ if ($1 & ~0x0F) yyerror("address too large"); $$ = $1 & 0x0F; }
	;

imm:	INTEGER			{ if ($1 & ~0x0F) yyerror("immediate too large"); $$ = $1 & 0x0F; }
	;

optimm:	/* empty */		{ $$ = 0; }
	| imm			{ $$ = $1; }
	;

reg:	REGA			{ $$ = REGA; }
	| REGB 			{ $$ = REGB; }

%%

void
yyerror(const char *s)
{
	printf("ERROR (line %d): %s\n", yylineno, s);
	exit(1);
}

struct label*
label_lookup(const char* str)
{
//	printf("LABEL LOOKUP!: %s\n", str);
	struct label *label = labels;
	while (label != NULL) {
		if (strcmp(label->name, str) == 0)
			return label;
		label = label->next;
	}
	if (label == NULL) {
		label = malloc(sizeof(struct label));
		label->name = str;
		label->value = 0;
		label->is_defined = 0;
		label->next = labels;
		labels = label;
	}
	return label;
}

void
emit(int inst)
{
	if (dot & ~0x0F)
		yyerror("exceeded address space");

	// printf("EMIT! (0x%02x)\n", inst);
	if (pass == 2)
		printf("%02x: %02x\n", dot, inst);
	dot++;
}

static void
assemble(const char* file)
{
	extern FILE *yyin;

	yyin = fopen(file, "r");
	yyparse();
	fclose(yyin);
}

static void
dump_labels()
{
	struct label* label = labels;
	printf("--- labels ---\n");
	while (label != NULL) {
		printf("%s:\t", label->name);
		if (label->is_defined)
			printf("%02x", label->value);
		else
			printf("<undefined>\n");
		printf("\n");
		label = label->next;
	}
}


int
main(int argc, char* argv[])
{
	yydebug = 0;

	printf("TD4 Assembler\n");

	if (argc != 2) {
		printf("%s <input-file>\n", argv[0]);
		return 1;
	}

	pass = 1; dot = 0; yylineno = 1;
	assemble(argv[1]);
	pass = 2; dot = 0; yylineno = 1;
	assemble(argv[1]);

	dump_labels();

	return 0;
}
