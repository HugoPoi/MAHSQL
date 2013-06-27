%{

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

%}

%union { 
	double val;
	char* var;
}

%token  <val> NOMBRE
%token  <var> VARIABLE
%token   SELECT FROM WHERE
%token   PARENTHESE_GAUCHE PARENTHESE_DROITE
%token   COMMA REQUETEDELIMITER


%start Input
%%

Input:
    /* Vide */
  | Input Requete
  ;

Requete:
	REQUETEDELIMITER
	| SELECT Champs FROM Tables REQUETEDELIMITER
	;
	
Champs:
	VARIABLE
	| VARIABLE COMMA Champs { printf("c:%s",$1); }
	;

Tables:
	VARIABLE
	| VARIABLE COMMA Tables { printf("t:%s",$1); }
	;




%%

int yyerror(char *s) {
  printf("%s\n",s);
}

int main(void) {
  yyparse();
}
