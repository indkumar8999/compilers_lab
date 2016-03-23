%{
#include <bits/stdc++.h>
%}

%option noyywrap

%{
int num_lines = 0, num_chars = 0;
%}

ID [a-zA-Z][a-zA-Z0-9]*
COMMA (",")
SEMI (";")
OPENPAREN "(" 
CLOSEPAREN ")"
OPENCURLY "{"
CLOSECURLY "}"
OPENNEGATE "-("
VOID ("void")
DTYPE ("int"|"bool")
EQ ("=")
ARITH [-+*/%] 
RELN ("=="|"<"|">"|"<="|">="|"!=")
LOGICAL ("&&"|"||")
LOGICALNOT ("!")
IF ("if")
ELSE ("else")
WHILE ("while")
FOR ("for")
RETURN ("return")
PRINT ("print")
READ ("readInteger"|"readBool")
BOOLCONST ("true"|"false")
INTCONST [0-9]+

%%
{DTYPE} {if (yyleng == 3) return DTYPE_INT; else return DTYPE_BOOL; } //printf( "%s : DTYPE\n", yytext );}
{VOID} {return VOID; } //printf( "%s : VOID\n", yytext );}
{IF} {return IF; } //printf( "%s : IF\n", yytext );}
{ELSE} {return ELSE; } //printf( "%s : ELSE\n", yytext );}
{WHILE} {return WHILE; } //printf( "%s : WHILE\n", yytext );}
{FOR} {return FOR; } //printf( "%s : FOR\n", yytext );}
{RETURN} {return RETURN; } //printf( "%s : RETURN\n", yytext );}
{PRINT} {return PRINT; } //printf( "%s : PRINT\n", yytext );}
{READ} {return READ; } //printf( "%s : READ\n", yytext );}
{COMMA} {return COMMA; } //printf( "%s : COMMA\n", yytext );}
{SEMI} {return SEMI; } //printf( "%s : SEMI\n", yytext );}
{OPENPAREN} {return OPENPAREN; } //printf( "%s : OPENPAREN\n", yytext );}
{CLOSEPAREN} {return CLOSEPAREN; } //printf( "%s : CLOSEPAREN\n", yytext );}
{OPENCURLY} {return OPENCURLY; } //printf( "%s : OPENCURLY\n", yytext );}
{CLOSECURLY} {return CLOSECURLY; } //printf( "%s : CLOSECURLY\n", yytext );}
{OPENNEGATE} {return OPENNEGATE; } //printf( "%s : OPENNEGATE\n", yytext );} //Added token for negation
{EQ} {return EQ; } //printf( "%s : EQ\n", yytext );}
{ARITH} {return ARITH; } //printf( "%s : ARITH\n", yytext ); }
{RELN} {return RELN; } //printf( "%s : RELN\n", yytext );}
{LOGICAL} {return LOGICAL; } //printf( "%s : LOGICAL\n", yytext );}
{LOGICALNOT} {return LOGICALNOT; } //printf( "%s : LOGICAL\n", yytext );} //Separated LOGICALNOT from LOGICAL as it is unary
{BOOLCONST} {return BOOLCONST; } //printf( "%s : BOOLCONST\n", yytext );}
{INTCONST} {return INTCONST; } //printf( "%s : INTCONST\n", yytext );}
{ID} {return ID; } //printf( "%s : ID\n", yytext );}

[ \t]+          /* eat up whitespace */
[\n]+ ++num_lines;
.          printf( "Unrecognized character: %s\n", yytext );
%%

int main( int argc, char **argv )
{
        yylex();
}