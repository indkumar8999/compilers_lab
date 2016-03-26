%{
#include <bits/stdc++.h>

#define DELIMITER "$"
#define tok() terminals.push(string(yytext,yyleng))
#define delim() productions.push(DELIMITER)
#define ppush(x) productions.push(x)
#define dpush(y) depth.push(y);

using namespace std;

extern int yylex();
extern int yyleng;
extern int yylineno;
extern char* yytext;

void yyerror(const char*);

stack<string> productions, terminals;
stack<int> depth;

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
%token <opertype_int> EQ
%token <opertype_int> ARITH
%token <opertype_int> RELN
%token <opertype_int> LOGICAL
%token <opertype_int> LOGICALNOT
%token IF
%token ELSE
%token WHILE
%token FOR
%token RETURN
%token PRINT
%token READ
%token <dtype_bool> BOOLCONST
%token <dtype_int> INTCONST

%%

mad_program:
	supported_declarations { ppush("[N]supported_declarations"); dpush(1); delim(); }
	| supported_declarations mad_program {ppush("[N]supported_declarations"); ppush("[N]mad_program"); ddpush(2); delim();}
	| error '\n' { yyerror("Compilation terminating with errors"); }

supported_declarations:
	variable_declarations {ppush("[N]variable_declarations"); ddpush(1); delim();}
	| function_declarations {ppush("[N]function_declarations"); ddpush(1); delim();}

variable_declarations:
	variable_definitions SEMI {ppush("[N]variable_definitions"); ppush("[T]SEMI"); ddpush(1); delim();}
	| variable_definitions error { yyerror("Possible missing semicolon in variable declaration list"); }

variable_definitions:
	dtype ID {ppush("[N]dtype"); ppush("[V]ID"); ddpush(1); delim();}
	| variable_definitions COMMA ID {ppush("[N]variable_definitions"); ppush("[T]COMMA"); ppush("[V]ID"); ddpush(1); delim();}
	| variable_definitions error ID '\n' { yyerror("Missing comma in definitions list"); }

dtype:
	DTYPE_INT {ppush("[T]DTYPE_INT");ddpush(0); delim();}
	| DTYPE_BOOL {ppush("[T]DTYPE_BOOL"); ddpush(0); delim();}
	| error { yyerror("Unknown type declaration"); }

function_declarations:
	dtype ID OPENPAREN argument_list CLOSEPAREN statement_block {ppush("[N]dtype"); ppush("[V]ID"); ppush("[T]OPENPAREN"); ppush("[N]argument_list"); ppush("[T]CLOSEPAREN"); ppush("[N]statement_block"); ddpush(3); delim();}
	| VOID ID OPENPAREN argument_list CLOSEPAREN statement_block {ppush("[T]VOID"); ppush("[V]ID"); ppush("[T]OPENPAREN"); ppush("[N]argument_list"); ppush("[T]CLOSEPAREN"); ppush("[N]statement_block"); ddpush(2); delim();}

argument_list:
	dtype ID COMMA argument_list {ppush("[N]dtype"); ppush("[V]ID"); ppush("[T]COMMA"); ppush("[N]argument_list"); ddpush(2); delim();}
	|dtype ID {ppush("[N]dtype"); ppush("[V]ID"); ddpush(1); delim();}
	|%empty /*epsilon production*/ {ppush("[T]EPSILON");ddpush(0); delim();}
	| dtype ID error argument_list { yyerror("Missing comma in argument list"); }
	| dtype error COMMA argument_list { yyerror("Missing identifier in argument list"); }

statement_block: 
	OPENCURLY variable_list statement_list CLOSECURLY {ppush("[T]OPENCURLY"); ppush("[N]variable_list"); ppush("[N]statement_list"); ppush("[T]CLOSECURLY"); ddpush(2); delim();}
	| OPENCURLY variable_list statement_list error { yyerror("Possible missing semicolon in statement block"); }

variable_list:
	%empty /*epsilon production*/ {ppush("[T]EPSILON");ddpush(0); delim();}
	| variable_declarations variable_list {ppush("[N]variable_declarations"); ppush("[N]variable_list"); ddpush(2); delim();}

statement_list:
	%empty {ppush("[T]EPSILON");ddpush(2); delim();}
	| supported_statement statement_list

supported_statement:
	alr_subexpression SEMI {}
	| if_statement {}
	| while_statement {}
	| for_statement {}
	| return_statement {}
	| print_statement {}
	| statement_block {}
	| alr_subexpression error { yyerror("Possible missing semicolon with alr_subexpression"); }

if_statement:
	IF OPENPAREN alr_subexpression CLOSEPAREN statement_block else_statement {} //CHANGED IF EXPRESSION INTERNAL TO STATEMENT BLOCK

else_statement:
	%empty {}
	| ELSE supported_statement {}

while_statement:
	WHILE OPENPAREN alr_subexpression CLOSEPAREN {}

for_statement:
	FOR OPENPAREN alr_subexpression SEMI alr_subexpression SEMI alr_subexpression CLOSEPAREN statement_block {} //CHANGED FOR EXPRESSION INTERNAL TO STATEMENT BLOCK
	| FOR OPENPAREN alr_subexpression error alr_subexpression SEMI alr_subexpression CLOSEPAREN statement_block { yyerror("Possible missing semicolon in for"); }
	| FOR OPENPAREN alr_subexpression SEMI alr_subexpression error alr_subexpression CLOSEPAREN statement_block { yyerror("Possible missing semicolon in for"); }
	| FOR OPENPAREN alr_subexpression SEMI alr_subexpression SEMI alr_subexpression error statement_block { yyerror("Possible missing closing parenthesis in for"); }

return_statement: 
	RETURN SEMI {}
	| RETURN alr_subexpression SEMI {}
	| RETURN error { yyerror("Missing semicolon with return"); }
	| RETURN alr_subexpression error { yyerror("Missing semicolon with return"); }

print_statement:
	PRINT OPENPAREN alr_subexpression CLOSEPAREN SEMI {}
	| PRINT error alr_subexpression CLOSEPAREN SEMI { yyerror("Possile missing open parenthesis"); }
	| PRINT OPENPAREN alr_subexpression error SEMI { yyerror("Possible missing closing parenthesis"); }
	| PRINT OPENPAREN alr_subexpression CLOSEPAREN error { yyerror("Missing semicolon with print"); }

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
	| error EQ alr_subexpression { yyerror("Missing identifier name"); }
	| ID error alr_subexpression { yyerror("Possible missing equalty sign"); }
	| ID OPENPAREN id_list error { yyerror("Possible missing closing parenthesis"); }
	| READ OPENPAREN error { yyerror("Possible missing closing parenthesis"); }
	| READ error CLOSEPAREN { yyerror("Possible missing opening parenthesis"); }

id_list:
	ID COMMA id_list {ppush("[V]ID"); ppush("[T]COMMA"); ppush("[N]id_list"); ddpush(1); delim(); tok();}
	| ID {ppush("[V]ID"); ddpush(0); delim(); tok(); }
	| %empty { ppush("[T]EPSILON"); ddpush(0); delim();}
	| error COMMA id_list { yyerror("Missing identifier name"); }

supported_constant:
	INTCONST { ppush("[V]INTCONST"); tok(); }
	| BOOLCONST { ppush("[V]BOOLCONST"); tok();}
	| OPENNEGATE INTCONST CLOSEPAREN {ppush("[T]OPENNEGATE"); ppush("[V]INTCONST"); ppush("[T]CLOSEPAREN"); ddpush(0); delim(); tok();}


%%

void yyerror(const char* err_msg)
{
	cout<<"Line "<<yylineno<<": "<<err_msg<<endl;
}

void print_tree()
{
	stack<int> tab_stack;	
	int tab_count=0;
	for(;!productions.empty();depth.pop(),productions.pop())
	{
		for(int j = 0; j < tab_count; j++)
			cout<<" ";
		if(depth.top()) cout<<"+"; else cout<<"\\";
		cout<<production.top();
		if(depth.top()) tab_count++, tab_stack.push(--depth.top());
		else
		{
			for(;!tab.empty() && !tab_stack.top();tab_stack.pop()) tab_count--;
			if(!tab_stack.empty()) { int t = tab_stack.top(); tab_stack.pop(); tab_stack.push(--t); }
		}
					
		if(productions.top() == DELIMITER) productions.pop();
	}
}

int main()
{
	yydebug = 0;
		
	yyparse();
	print_tree();
}
