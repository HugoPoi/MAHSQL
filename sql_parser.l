%option noyywrap
%{

#include "sql_parser.h"
#include <stdlib.h>
#include <string.h>

%}

chiffre   [0-9]
entier    {chiffre}+
exposant  [eE][+-]?{entier}
valeur    {entier}("."{entier})?{exposant}?

variable  [a-z]+[a-zA-Z0-9*]+

%%
[ \t\n]
("select"|"SELECT")	return SELECT;
("from"|"FROM")		return FROM;
","			return COMMA;
";"			return SEMICOLON;
("where"|"WHERE")	return WHERE;
"="			return EQUAL;
("and"|"AND") return AND;
("or"|"OR") return OR;

("insert"|"INSERT")	return INSERT;
"("		return PARENTHLEFT;
")"		return PARENTHRIGHT;
("values"|"VALUES")		return VALUES;

("update"|"UPDATE")	return UPDATE;
("set"|"SET")	return SET;

("delete"|"DELETE")	return DELETE;

("create"|"CREATE")	return CREATE;
("table"|"TABLE")	return TABLE;

("VARCHAR"|"varchar")	return VARCHAR;
("INTEGER"|"integer")	return INTEGER;
("CHAR"|"char")	return CHAR;

("PRIMARY"|"primary")	return PRIMARY;
("KEY"|"key")	return KEY;

{valeur}    {
	yylval.val=atof(yytext);
    //printf("Valeur found: %d\n", yylval.val);
	return(VALEUR);
    }
{variable}    {
	yylval.var=(char*)strdup(yytext);
    //printf("Variable found: %s\n", yylval.var);
	return(VARIABLE);
    }

