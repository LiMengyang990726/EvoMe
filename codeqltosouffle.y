/* Parser for codeql subset */
%{
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <stdio.h>
#include <symbolTable.c>

/* from the lexer */
extern int yylex();
void yyerror(char *s, ...);

/* utility function */
char* concatf(char *s, ...);

/* nodes in the abstract syntax tree */
struct ast {
  int nodetype;
  struct ast *l;
  struct ast *m;
  struct ast *r;
};
struct stringval {
  int nodetype;
  char *value;
};

/* methods for constructing nodes */
struct ast *newast_1(int nodetype, struct ast *l, struct ast *m, struct ast *r);
struct ast *newast_2(int nodetype, char *valueL, char *valueM, struct ast *r);
struct ast *newast_3(int nodetype, char *valueL, struct ast *m, char *valueR);
struct ast *newast_4(int nodetype, char *valueL, char *valueM, char *valueR);
struct ast *newstringval(char *value);

/* evaluate an AST */
void translateImportStmt(struct ast *);
void translateFrom(struct ast *);
void translateWhere(struct ast *);
void translateSelect(struct ast *);
void eval(struct ast *);
%}

%union {
        struct ast *a;
        char *strval;
        int intval;
        int subtok;
}

%token <strval> IMPORT
%token <strval> JAVA
%token <strval> GO
%token <strval> CSHARP
%token <strval> CPP
%token <strval> PYTHON
%token <strval> JAVASCRIPT
%token <strval> FROM
%token <strval> WHERE
%token <strval> OR
%token <strval> AND
%token <strval> IMPLIES
%token <strval> IF
%token <strval> ELSE
%token <strval> THEN
%token <strval> NOT
%token <strval> SELECT
%token <strval> AS
%token <strval> STRING_LITERAL
%token <strval> UPPER_ID
%token <strval> LOWER_ID
%token <strval> COMMA
%token <strval> LEFT_BRACKET
%token <strval> RIGHT_BRACKET
%token <strval> DOT
%token <strval> UNDERSCORE
%token <subtok> COMPARISON

%type <a> stmt import_stmt select_stmt
%type <a> select_opts from_opts where_opts 
%type <a> formula call primary expr
%type <strval> import_opts   

%start stmt_list

%%

stmt_list: stmt { eval($1); }
  | stmt_list stmt { eval($2); }
  ;

stmt: import_stmt { $$ = $1; }
  |   select_stmt { $$ = $1; }
  ;

import_stmt: IMPORT import_opts { $$ = newast_3(1, $1, NULL, $2); } ;
import_opts: JAVA { $$ = "java"; }
  | GO { $$ = "go"; }
  | CSHARP { $$ = "c#"; }
  | CPP  { $$ = "cpp"; }
  | PYTHON { $$ = "python"; }
  | JAVASCRIPT { $$ = "javscript"; }
  ;

select_stmt: SELECT select_opts { $$ = newast_1(2, NULL, NULL, $2); }
  | FROM from_opts SELECT select_opts  { $$ = newast_1(2, $2, NULL, $4); }
  | FROM from_opts WHERE where_opts SELECT select_opts { $$ = newast_1(2, $2, $4, $6); }
  ;

select_opts: expr { $$ = newast_1(3, $1, NULL, NULL); }
  | expr AS LOWER_ID { $$ = newast_2(3, $3, NULL, NULL);  }
  | select_opts COMMA expr { $$ = newast_1(3, $3, NULL, $1); }
  | select_opts COMMA expr AS LOWER_ID  { $$ = newast_2(3, $5, NULL, $1); }
  ;

from_opts: UPPER_ID LOWER_ID { $$ = newast_2(4, $1, $2, NULL); }
  | from_opts COMMA UPPER_ID LOWER_ID { $$ = newast_2(4, $3, $4, $1); }
  ;

where_opts: formula { $$ = $1; };
formula: LEFT_BRACKET formula RIGHT_BRACKET { $$ = $2; }
  |   formula OR formula { $$ = newast_1(5, $1, NULL, $3); }
  |   formula AND formula { $$ = newast_1(6, $1, NULL, $3); }
  |   formula IMPLIES formula { $$ = newast_1(7, $1, NULL, $3); }
  |   IF formula THEN formula ELSE formula { $$ = newast_1(8, $2, $4, $6); }
  |   NOT formula { $$ = newast_1(9, $2, NULL, NULL); }
  |   primary COMPARISON primary { $$ = newast_1(10, $1, NULL, $3); }
  |   call { $$ = $1; }
  ;

primary: LOWER_ID { $$ = newstringval($1); }
  | STRING_LITERAL { $$ = newstringval($1); }
  | call { $$ = $1; }
  ;
call: LOWER_ID DOT LOWER_ID LEFT_BRACKET RIGHT_BRACKET { $$ = newast_3(11, $1, NULL, $3); }
  | LOWER_ID DOT LOWER_ID LEFT_BRACKET STRING_LITERAL RIGHT_BRACKET { $$ = newast_4(11, $1, $3, $5); }
  ;
expr: UNDERSCORE { $$ = newstringval($1); }
  | primary { $$ = $1; }
  ;
%%

void yyerror(char *s, ...) {
  extern int yylineno;
  va_list ap;
  va_start(ap, s);
  fprintf(stderr, "%d: error: ", yylineno);
  vfprintf(stderr, s, ap);
  fprintf(stderr, "\n");
}

char* concatf(char *s, ...)
{
  va_list args;
  char* buf = NULL;
  va_start(args, s);
  int n = vasprintf(&buf, s, args);
  va_end(args);
  if (n < 0) { free(buf); buf = NULL;  }
  return buf;
}

struct ast* newast_1(int nodetype, struct ast *l, struct ast *m, struct ast *r) {
  struct ast *a = (struct ast *)malloc(sizeof(struct ast));
  if (!a) {
    yyerror("out of space for constructing AST");
    exit(0);
  }
  a->nodetype = nodetype;
  a->l = l;
  a->m = m;
  a->r = r;
  return a;
}

struct ast* newstringval(char *value) {
  struct stringval *a = (struct stringval *)malloc(sizeof(struct stringval));
  if (!a) {
    yyerror("out of space for constructing AST");
    exit(0);
  }
  a->nodetype = 0;
  a->value = value;
  return (struct ast *)a;
}

struct ast* newast_2(int nodetype, char *valueL, char *valueM, struct ast *r) {
  struct ast *l = newstringval(valueL);
  struct ast *m = newstringval(valueM);
  return newast_1(nodetype, l, m, r);
}

struct ast* newast_3(int nodetype, char *valueL, struct ast *m, char *valueR) {
  struct ast *l = newstringval(valueL);
  struct ast *r = newstringval(valueR);
  return newast_1(nodetype, l, m, r);
}

struct ast* newast_4(int nodetype, char *valueL, char *valueM, char *valueR) {
  struct ast *l = newstringval(valueL);
  struct ast *m = newstringval(valueM);
  struct ast *r = newstringval(valueR);
  return newast_1(nodetype, l, m, r);
}

void translateImportStmt(struct ast *a) {
  // No import opts
  if (!a) {
    yyerror("no import language");
    return;
  }

  if (!a->r) {
    yyerror("error in import statement");
    return; 
  } else if (strcmp(((struct stringval *)a->r)->value, "java")) {
    yyerror("only java is supported");
    return; 
  }
}

void translateFrom(struct ast *a) {
  // No fromt opts, accept
  if (!a) {
    return;
  }

  char *result;
  strcpy(result, ".decl ");
  if (a->l) {
    // TODO: Find the .decl in the symbol table
    char *temp = ((struct stringval *)a->l)->value;
    strcat(result, temp);
    strcat(result, "( TO BE FILLED )");
    // TODO: Store the a->m as variables and check in the select opts
  }
  printf("%s\n", result);

  if (!a->r) {
    return;
  } else {
    translateFrom(a->r);
  }
}

void translateWhere(struct ast *a) {
  // No where opts, accept
  if (!a) {
    return;
  }

  // TODO
}

void translateSelect(struct ast *a) {
  // No select opts
  if (!a) {
    yyerror("error in select opts");
    return;
  }

  char *result;
  strcpy(result, ".output ");
  if (a->l) {
    // TODO: Find the .decl in the symbol table
    char *temp = ((struct stringval *)a->l)->value;
    strcat(result, temp);
  }
  printf("%s\n", result);

  if (!a->r) {
    return;
  } else {
    translateSelect(a->r);
  }
}

void eval(struct ast *a) {
  if(!a) {
    yyerror("internal error, null eval");
    return;
  }

  switch(a->nodetype) {
    /* import statement */
    case 1: 
      translateImportStmt(a); 
      break;
    /* select statement */
    case 2: 
      translateFrom(a->l);
      translateSelect(a->r);
      break;
    default: 
      printf("internal error: bad node %c\n", a->nodetype);
  }
  return;
}

int main(int ac, char **av)
{
  extern FILE *yyin;
  if(ac > 1 && (yyin = fopen(av[1], "r")) == NULL) {
    perror(av[1]);
    exit(1);
  }
  if(!yyparse())
    printf("CodeQL parse worked\n");
  else
    printf("CodeQL parse failed\n");
}