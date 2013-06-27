%option noyywrap
%{

#include "sql_parser.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

%}

/* Declarations */

blancs    [ \t]+

chiffre   [0-9]
entier    {chiffre}+
exposant  [eE][+-]?{entier}

reel    {entier}("."{entier})?{exposant}?

variable  [a-zA-Z]+

%%

{blancs}  { /* On ignore */ }

{reel}    {
	yylval.val=atof(yytext);
	return(NOMBRE);
    }

{variable}    {
	yylval.var=(char*) strdup(yytext);
	return(VARIABLE);
    }

"select|SELECT" return(SELECT);

"from|FROM" return(FROM);

"where|WHERE" return(WHERE);

"," return(COMMA);

";\n" return(REQUETEDELIMITER);

"("   return(PARENTHESE_GAUCHE);
")"   return(PARENTHESE_DROITE);

%%

