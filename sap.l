%{

#include <stdio.h>

#include <stdlib.h>

#include <string>

#include "sap.tab.h" // generated via yacc -d (has INT and PRINT etc...)

YY_BUFFER_STATE current();

extern void yyerror(char const *);

%}

%option noyywrap

%%

\"[^"]*\"		{ 

	std::string str(yytext);
	str.erase(0,1);
	str.erase(str.length() - 1, str.length());	
	yylval.s = strdup(str.c_str()); 
	return STRING; 
}

\{[^{}]*\}		{ 

	std::string body(yytext);
	body.erase(0,1);
	body.erase(body.length() - 1, body.length());
	yylval.s = strdup(body.c_str());
	return BODY;
}

#[^#]*#		{ ; } 

"=="			{ return EQU; }

[<]			{ return LES; }

[>]			{ return GRE; }

[+]			{ return ADD; }

[-]			{ return SUB; }

[*]			{ return MUL; }

[/]			{ return DIV; }

[(]			{ return LPAR; }

[)]			{ return RPAR; }

if			{ return IF; }

function		{ return FUNCTION; }

run			{ return RUN; }

print			{ return PRINT; }

let			{ return LET; }

ini			{ return INI; }

sqrt			{ return SQRT; }

exit			{ return EXIT; }

[a-zA-Z][0-9a-zA-Z]*			{ yylval.s = strdup(yytext); return VAR; }

[-+]?(([0-9]+)|([0-9]+\.[0-9]+))	{ yylval.d = atof(yytext); return DBL; }

[\n\r]			{ return END; }

[ \t\f\v]+		{ ; }

.			{ 

	std::string err("Unexpected token: ");
	err += yytext;
	yyerror(err.c_str()); 
}

%%

YY_BUFFER_STATE current()
{
	return YY_CURRENT_BUFFER;
}
