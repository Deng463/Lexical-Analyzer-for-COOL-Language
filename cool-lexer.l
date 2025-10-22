%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

typedef enum {
    KEYWORD_CLASS, KEYWORD_ELSE, KEYWORD_IF, KEYWORD_FI,
    KEYWORD_IN, KEYWORD_INHERITS, KEYWORD_LET, KEYWORD_LOOP,
    KEYWORD_POOL, KEYWORD_THEN, KEYWORD_WHILE, KEYWORD_CASE,
    KEYWORD_ESAC, KEYWORD_NEW, KEYWORD_ISVOID, KEYWORD_NOT,
    KEYWORD_OF,
    IDENTIFIER, TYPE_IDENTIFIER,
    INTEGER, STRING,
    OP_PLUS, OP_MINUS, OP_MUL, OP_DIV, OP_EQ, OP_LT, OP_LE,
    OP_ASSIGN, OP_NEG,
    DELIM_LBRACE, DELIM_RBRACE, DELIM_LPAREN, DELIM_RPAREN,
    DELIM_SEMICOLON, DELIM_COLON, DELIM_COMMA, DELIM_DOT, DELIM_ARROW,
    UNKNOWN_TOKEN
} TokenType;

int current_line = 1;

void error_report(const char* message) {
    fprintf(stderr, "错误 (行 %d): %s\n", current_line, message);
}

void print_token(TokenType type, const char* value) {
    printf("[TOKEN] ");
    switch(type) {
        case KEYWORD_CLASS:      printf("CLASS"); break;
        case KEYWORD_ELSE:       printf("ELSE"); break;
        case KEYWORD_IF:         printf("IF"); break;
        case KEYWORD_FI:         printf("FI"); break;
        case KEYWORD_IN:         printf("IN"); break;
        case KEYWORD_INHERITS:   printf("INHERITS"); break;
        case KEYWORD_LET:        printf("LET"); break;
        case KEYWORD_LOOP:       printf("LOOP"); break;
        case KEYWORD_POOL:       printf("POOL"); break;
        case KEYWORD_THEN:       printf("THEN"); break;
        case KEYWORD_WHILE:      printf("WHILE"); break;
        case KEYWORD_CASE:       printf("CASE"); break;
        case KEYWORD_ESAC:       printf("ESAC"); break;
        case KEYWORD_NEW:        printf("NEW"); break;
        case KEYWORD_ISVOID:     printf("ISVOID"); break;
        case KEYWORD_NOT:        printf("NOT"); break;
        case KEYWORD_OF:         printf("OF"); break;
        case IDENTIFIER:         printf("IDENTIFIER"); break;
        case TYPE_IDENTIFIER:    printf("TYPE_IDENTIFIER"); break;
        case INTEGER:            printf("INTEGER"); break;
        case STRING:             printf("STRING"); break;
        case OP_PLUS:            printf("PLUS"); break;
        case OP_MINUS:           printf("MINUS"); break;
        case OP_MUL:             printf("MUL"); break;
        case OP_DIV:             printf("DIV"); break;
        case OP_EQ:              printf("EQ"); break;
        case OP_LT:              printf("LT"); break;
        case OP_LE:              printf("LE"); break;
        case OP_ASSIGN:          printf("ASSIGN"); break;
        case OP_NEG:             printf("NEG"); break;
        case DELIM_LBRACE:       printf("LBRACE"); break;
        case DELIM_RBRACE:       printf("RBRACE"); break;
        case DELIM_LPAREN:       printf("LPAREN"); break;
        case DELIM_RPAREN:       printf("RPAREN"); break;
        case DELIM_SEMICOLON:    printf("SEMICOLON"); break;
        case DELIM_COLON:        printf("COLON"); break;
        case DELIM_COMMA:        printf("COMMA"); break;
        case DELIM_DOT:          printf("DOT"); break;
        case DELIM_ARROW:        printf("ARROW"); break;
        default:                 printf("UNKNOWN");
    }
    printf(" -> %s\n", value);
}

const char *keywords[] = {"class", "else", "if", "fi", "in", "inherits", "let", "loop", "pool", "then", "while", "case", "esac", "new", "isvoid", "not", "of"};
const TokenType keyword_types[] = {KEYWORD_CLASS, KEYWORD_ELSE, KEYWORD_IF, KEYWORD_FI, KEYWORD_IN, KEYWORD_INHERITS, KEYWORD_LET, KEYWORD_LOOP, KEYWORD_POOL, KEYWORD_THEN, KEYWORD_WHILE, KEYWORD_CASE, KEYWORD_ESAC, KEYWORD_NEW, KEYWORD_ISVOID, KEYWORD_NOT, KEYWORD_OF};
const int NUM_KEYWORDS = 17;

int istrcmp(const char *s1, const char *s2) {
    while (*s1 && *s2) {
        if (tolower((unsigned char)*s1) != tolower((unsigned char)*s2)) return tolower((unsigned char)*s1) - tolower((unsigned char)*s2);
        s1++; s2++;
    }
    return tolower((unsigned char)*s1) - tolower((unsigned char)*s2);
}

TokenType check_keyword(const char *text) {
    for (int i = 0; i < NUM_KEYWORDS; i++) {
        if (istrcmp(text, keywords[i]) == 0) return keyword_types[i];
    }
    return UNKNOWN_TOKEN;
}

int comment_depth = 0;
char string_buf[1025];
int string_len = 0;
%}

digit            [0-9]
esc_char         \\[btnfr"\\]
space_char       [ \t\r]+

%x COMMENT_NESTED
%x COMMENT_SINGLE
%x STRING_MODE

%%

"<="             { print_token(OP_LE, yytext); return 1; }
"<-"             { print_token(OP_ASSIGN, yytext); return 1; }
"=>"             { print_token(DELIM_ARROW, yytext); return 1; }

\"               { string_len=0; memset(string_buf,0,sizeof(string_buf)); BEGIN(STRING_MODE); return 1; }
<STRING_MODE>\"  { 
    if (string_len > 1024) error_report("字符串长度超过1024字符限制");
    else print_token(STRING, string_buf); 
    BEGIN(INITIAL); 
    return 1; 
}
<STRING_MODE>\n  { error_report("字符串未闭合（包含换行）"); current_line++; BEGIN(INITIAL); return 1; }
<STRING_MODE>{esc_char} { 
    if (string_len < 1024) {
        string_buf[string_len++] = '\\';
        string_buf[string_len++] = yytext[1];
    }
    return 1; 
}
<STRING_MODE>[^"\\\n] { 
    if (string_len < 1024) string_buf[string_len++] = yytext[0]; 
    return 1; 
}
<STRING_MODE><<EOF>> { error_report("文件结束时字符串未闭合"); BEGIN(INITIAL); return 1; }

[a-zA-Z_][a-zA-Z0-9_]* {
    TokenType type = check_keyword(yytext);
    if (type != UNKNOWN_TOKEN) {
        print_token(type, yytext);
    } else {
        if (isupper((unsigned char)yytext[0])) {
            print_token(TYPE_IDENTIFIER, yytext);
        } else {
            print_token(IDENTIFIER, yytext);
        }
    }
    return 1;
}

{digit}+         { print_token(INTEGER, yytext); return 1; }

"+"              { print_token(OP_PLUS, yytext); return 1; }
"-"              { print_token(OP_MINUS, yytext); return 1; }
"*"              { print_token(OP_MUL, yytext); return 1; }
"/"              { print_token(OP_DIV, yytext); return 1; }
"="              { print_token(OP_EQ, yytext); return 1; }
"<"              { print_token(OP_LT, yytext); return 1; }
"~"              { print_token(OP_NEG, yytext); return 1; }

"{"              { print_token(DELIM_LBRACE, yytext); return 1; }
"}"              { print_token(DELIM_RBRACE, yytext); return 1; }
"("              { print_token(DELIM_LPAREN, yytext); return 1; }
")"              { print_token(DELIM_RPAREN, yytext); return 1; }
";"              { print_token(DELIM_SEMICOLON, yytext); return 1; }
":"              { print_token(DELIM_COLON, yytext); return 1; }
","              { print_token(DELIM_COMMA, yytext); return 1; }
"."              { print_token(DELIM_DOT, yytext); return 1; }

"--"             { BEGIN(COMMENT_SINGLE); return 1; }
<COMMENT_SINGLE>[^\n]* { return 1; }
<COMMENT_SINGLE>\n     { current_line++; BEGIN(INITIAL); return 1; }
<COMMENT_SINGLE><<EOF>> { BEGIN(INITIAL); return 1; }

"(*"             { comment_depth = 1; BEGIN(COMMENT_NESTED); return 1; }
<COMMENT_NESTED>"(*"    { comment_depth++; return 1; }
<COMMENT_NESTED>"*)"    { 
    comment_depth--; 
    if (comment_depth == 0) BEGIN(INITIAL); 
    return 1; 
}
<COMMENT_NESTED>.       { return 1; }
<COMMENT_NESTED>\n       { current_line++; return 1; }
<COMMENT_NESTED><<EOF>> { error_report("文件结束时注释未闭合"); BEGIN(INITIAL); return 1; }

"*)"             { error_report("未匹配的注释结束符"); print_token(UNKNOWN_TOKEN, yytext); return 1; }

{space_char}     { return 1; }

\n               { current_line++; return 1; }

.                { error_report("非法字符"); print_token(UNKNOWN_TOKEN, yytext); return 1; }

%%

int yywrap() {
    return 1;
}

int main(int argc, char *argv[]) {
    printf("COOL 词法分析器启动...\n");
    printf("(输入 'exit' 或 EOF 结束)\n");

    if (argc > 1) {
        FILE *file = fopen(argv[1], "r");
        if (file == NULL) {
            perror("无法打开文件");
            return 1;
        }
        yyin = file;
    }

    while (yylex() != 0);

    if (argc > 1) {
        fclose(yyin);
    }

    printf("词法分析结束\n");
    return 0;
}