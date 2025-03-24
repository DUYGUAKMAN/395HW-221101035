%{
#include "calculator.tab.h"
#include <stdlib.h>
%}

DIGIT   [0-9]+

%%

\n          { return '\n'; }         
{DIGIT}     { 
              yylval = atoi(yytext); 
              return NUMBER; 
            }
\+          { return PLUS; }
\-          { return MINUS; }
\*          { return TIMES; }
\/          { return DIVIDE; }
\(          { return LPAREN; }
\)          { return RPAREN; }
[ \t]+      {  }
.           { printf("Geçersiz karakter: %s\n", yytext); }

%%

int yywrap(void) {
    return 1;
}
