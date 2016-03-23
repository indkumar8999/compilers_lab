%{
#include <bits/stdc++.h>

using namespace std;

extern int yylex();
extern int yyleng;
extern int yylineno;
extern char* yytext;

void yyerror(const char*);
%}

%union{
	int dtype_int;
	bool dtype_bool;
	int opertype_int;
}

%start mad_program

%token ID
%token COMMA
%token SEMI
%token OPENPAREN
%token CLOSEPAREN
%token OPENCURLY
%token CLOSECURLY
%token OPENNEGATE
%token VOID
%token DTYPE_INT
%token DTYPE_BOOL
%token EQ
%token ARITH
%token RELN
%token LOGICAL
%token LOGICALNOT
%token IF
%token ELSE
%token WHILE
%token FOR
%token RETURN
%token PRINT
%token READ
%token BOOLCONST
%token INTCONST

%%

mad_program:
	supported_declarations {}
	| supported_declarations mad_program {}

supported_declarations:
	variable_declarations {}
	| function_declarations {}

variable_declarations:
	variable_definitions SEMI {}

variable_definitions:
	dtype ID {}
	| variable_definitions COMMA ID {}

dtype:
	DTYPE_INT {}
	| DTYPE_BOOL {}

function_declarations:
	dtype ID OPENPAREN argument_list CLOSEPAREN statement_block {}
	| VOID ID OPENPAREN argument_list CLOSEPAREN statement_block {}

argument_list:
	dtype ID COMMA argument_list {}
	|dtype ID {}
	|%empty /*epsilon production*/ {}

statement_block: 
	OPENCURLY variable_list statement_list CLOSECURLY {}

variable_list:
	%empty /*epsilon production*/ {}
	| variable_declarations variable_list {}

statement_list:
	%empty
	| supported_statement statement_list

supported_statement:
	alr_subexpression SEMI {}
	| if_statement {}
	| while_statement {}
	| for_statement {}
	| return_statement {}
	| print_statement {}
	| statement_block {}

if_statement:
	IF OPENPAREN alr_subexpression CLOSEPAREN statement_block else_statement {} //CHANGED IF EXPRESSION INTERNAL TO STATEMENT BLOCK

else_statement:
	%empty {}
	| ELSE supported_statement {}

while_statement:
	WHILE OPENPAREN alr_subexpression CLOSEPAREN {}
for_statement:
	FOR OPENPAREN alr_subexpression SEMI alr_subexpression SEMI alr_subexpression OPENPAREN statement_block {} //CHANGED FOR EXPRESSION INTERNAL TO STATEMENT BLOCK

return_statement: 
	RETURN SEMI {}
	| RETURN alr_subexpression SEMI {}

print_statement:
	PRINT OPENPAREN alr_subexpression CLOSEPAREN SEMI {}

alr_subexpression:
	ID EQ alr_subexpression {}
	| supported_constant {}
	| ID {}
	| ID OPENPAREN id_list CLOSEPAREN  {}
	| OPENPAREN alr_subexpression CLOSEPAREN {}
	| alr_subexpression ARITH alr_subexpression {}
	| OPENNEGATE alr_subexpression CLOSEPAREN {}
	| alr_subexpression RELN alr_subexpression {}
	| alr_subexpression LOGICAL alr_subexpression {}	
	| LOGICALNOT alr_subexpression {}
	| READ OPENPAREN CLOSEPAREN {}

id_list:
	ID COMMA id_list {}
	| ID {}
	| %empty {}

supported_constant:
	INTCONST {}
	| BOOLCONST {}
	| OPENNEGATE INTCONST CLOSEPAREN {}


%%

void yyerror(const char* err_msg)
{
	cout<<"Line "<<yylineno<<": "<<err_msg<<" at "<<string(yytext, yyleng)<<endl;
}

int main()
{
	yydebug = 0;
	yyparse();
}
