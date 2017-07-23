%{

#include <stdio.h>

#include <stdlib.h>

#include <iostream>

#include <string.h>

#include <cmath>

#include <map>

#include <string>

#include "lex.yy.h"

extern int yylex();

extern YY_BUFFER_STATE current();

void yyerror(char const * msg);

void yyerror(char const * msg, bool fatal);

void yyparse_string(char const * input);

void yyparse_file(FILE * file);

std::map<std::string, double> usr_vars; 

std::map<std::string, std::string> usr_funcs;

%}

%union
{
	char const * s;

	double d;
}

%debug

%error-verbose

%verbose

%locations

%token EXIT
%token IF
%token EQU LES GRE
%token PRINT LET FUNCTION RUN INI
%token ADD SUB MUL DIV
%token LPAR RPAR
%token SQRT
%token END 

%token <d> DBL

%token <s> STRING VAR BODY

%type <d> RES M_RES A_RES NUM

%%

S	:	R 
	|	S R 
	;

R	:	END
	;

R	:	IF RES BODY		{
	if($2 != 0)
	{
		YY_BUFFER_STATE prev = current();

		char * functionBody = strdup($3);
		YY_BUFFER_STATE functionState = yy_scan_string(functionBody);
		yy_switch_to_buffer(functionState);
		yyparse();

		yy_delete_buffer(functionState);
		yy_switch_to_buffer(prev);
	}
}
	;

R	:	FUNCTION VAR BODY	{ 

	if(usr_funcs.count($2) > 0)
	{
		std::string err("function already defined: ");

		err += $2;

		yyerror(err.c_str(), false);	
	}
	else
	{	
		usr_funcs.emplace($2, $3); 
	}
}
	;

R	:	RUN VAR	{ 
	
	if(usr_funcs.count($2) <= 0)
	{
		std::string err("function does not exist: ");
		err += $2;
		yyerror(err.c_str(), false);
	}
	else
	{
		YY_BUFFER_STATE prev = current();

		char * functionBody = strdup(usr_funcs.at($2).c_str());
		YY_BUFFER_STATE functionState = yy_scan_string(functionBody);
		yy_switch_to_buffer(functionState);
		yyparse();

		yy_delete_buffer(functionState);
		yy_switch_to_buffer(prev);
	}
}
	;


R	:	PRINT RES 		{ printf("%g\n", $2); }
	|	PRINT STRING		{ printf("%s\n", $2); }
	;

R	:	LET VAR RES		{ usr_vars.emplace($2, $3); usr_vars.at($2) = $3; }
	;

R	:	INI VAR			{
	if(usr_vars.count($2) <= 0)
	{
		usr_vars.emplace($2, 0.0);
	}
}
	|	INI VAR RES		{
	if(usr_vars.count($2) <= 0)
	{
		usr_vars.emplace($2, $3);
	}
}
	;

R	:	EXIT			{ exit(0); }
	;

RES	:	SQRT A_RES	{ $$ = std::sqrt($2); }
	;

/*
	OPERATION LVL
*/


RES	:	A_RES		{ $$ = $1; }
	;

RES	: 	A_RES EQU A_RES	{ $$ = $1 == $3; }
	|	A_RES LES A_RES	{ $$ = $1 < $3; }
	|	A_RES GRE A_RES	{ $$ = $1 > $3; }
	;

A_RES	:	A_RES ADD M_RES	{ $$ = $1 + $3; }
	|	A_RES SUB M_RES	{ $$ = $1 - $3; }
	|	M_RES
	;

M_RES	:	M_RES MUL NUM	{ $$ = $1 * $3; }
	|	M_RES DIV NUM	{ $$ = $1 / $3; }
	|	NUM
	;

NUM	:	DBL		{ $$ = $1; }
	|	VAR		{ 
	
	if(usr_vars.count($1) <= 0)
	{
		std::string err("variable does not exist: ");
		err += $1;
		yyerror(err.c_str(), true);
	}
	
	$$ = usr_vars.at($1); 
}
	|	LPAR A_RES RPAR	{ $$ = $2; }
	;

/*
	END OPERATION LVL
*/

%%

void yyerror(char const * msg)
{
	fprintf(stderr, "<error> %s <fatal>\n", msg);

	exit(1);
}

void yyerror(char const *  msg, bool fatal)
{
	fprintf(stderr, "<error> %s", msg);
	
	if(fatal == true)
	{
		fprintf(stderr, " <fatal>\n");
	
		exit(1);
	}

	fprintf(stderr, " <non-fatal>\n");
}

void yyparse_string(char const * input)
{

}

void yyparse_file(FILE * file)
{
	
}

void load_interactive_functions()
{
	std::string help("");
	help += "print \"\" print \"Welcome to SAP!\" print \"\"";
	help += "print \"print <string/value/variable> 		- prints to the console\"";
	help += "print \"let <variable> <value>			- assignes the value to the variable\"";
	help += "print \"ini <varibale> <value:optional> 	- will set an undefined variable\"";
	help += "print \"exit					- will exit the SAP program\"";
	help += "print \"\"";
	help += "print \"function <function name> { <body> } 	- stores the body into memory\"";
	help += "print \"run <function name> 			- runs the body of the function\"";
	help += "print \"\"";
	usr_funcs.emplace("help", help);
}

void load_system_functions()
{

}

int main(int argc, char ** argv)
{
	load_system_functions();

	FILE * file = fopen(argv[1], "r");

	if(!file)
	{
		load_interactive_functions();

		printf("-- Interactive Mode --\n");
	}
	else
	{
		for(int index = 2; index < argc; ++index)
		{
			std::string usrVar("in");

			usrVar += std::to_string(index - 1);
	
			usr_vars.emplace(usrVar, atof(argv[index]));
		}

		yyin = file; 
	}
	
	yyparse();

	return 0;
}
