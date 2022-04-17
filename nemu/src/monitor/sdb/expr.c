#include <isa.h>

/* We use the POSIX regex functions to process regular expressions.
 * Type 'man regex' for more information about POSIX regex functions.
 */
#include <regex.h>
word_t vaddr_read(vaddr_t addr, int len);

enum {
  TK_NOTYPE = 256,
  TK_REG    = 257,
  TK_DEC    = 258,
  TK_HEX    = 259,
  TK_DEREF  = 260,
  TK_POS    = 261,
  TK_NEG    = 262,
  TK_EQ     = 263,

  /* TODO: Add more token types */

};

static struct rule {
  const char *regex;
  int token_type;
} rules[] = {

  /* TODO: Add more rules.
   * Pay attention to the precedence level of different rules.
   */

  {"^0x[0-9abcdefABCDEF][0-9abcdefABCDEF]*", TK_HEX}, //hex_number
  {"^[0-9][0-9]*", TK_DEC}, // dec_number
  {"^\\$[\\$0-9a-zA-Z][0-9a-zA-Z]*", TK_REG}, //reg
  {"^ +" , TK_NOTYPE},      // spaces
  {"^\\+", '+'},            // plus
  {"^-"  , '-'},            // minus
  {"^\\*", '*'},            // multiply
  {"^/"  , '/'},            // divide
  {"^\\(", '('},            // leftbracket
  {"^\\)", ')'},            // rightbracket
  {"^==" , TK_EQ},          // equal
};

#define NR_REGEX ARRLEN(rules)

static regex_t re[NR_REGEX] = {};

/* Rules are used for many times.
 * Therefore we compile them only once before any usage.
 */
void init_regex() {
  int i;
  char error_msg[128];
  int ret;

  for (i = 0; i < NR_REGEX; i ++) {
    ret = regcomp(&re[i], rules[i].regex, REG_EXTENDED);
    if (ret != 0) {
      regerror(ret, &re[i], error_msg, 128);
      panic("regex compilation failed: %s\n%s", error_msg, rules[i].regex);
    }
  }
}

typedef struct token {
  int type;
  char str[32];
} Token;

static Token tokens[32] __attribute__((used)) = {};
static int nr_token __attribute__((used))  = 0;

static bool make_token(char *e) {
  int position = 0;
  int i;
  regmatch_t pmatch;

  nr_token = 0;

  while (e[position] != '\0') {
    /* Try all rules one by one. */
    for (i = 0; i < NR_REGEX; i ++) {
      if (regexec(&re[i], e + position, 1, &pmatch, 0) == 0 && pmatch.rm_so == 0) {
        char *substr_start = e + position;
        int substr_len = pmatch.rm_eo;

        //Log("match rules[%d] = \"%s\" at position %d with len %d: %.*s",i, rules[i].regex, position, substr_len, substr_len, substr_start);

        position += substr_len;

        /* TODO: Now a new token is recognized with rules[i]. Add codes
         * to record the token in the array `tokens'. For certain types
         * of tokens, some extra actions should be performed.
         */

        switch (rules[i].token_type) {
          case TK_NOTYPE: break;
          case TK_DEC:
          case TK_HEX:
          case TK_REG:
               sprintf(tokens[nr_token].str, "%.*s", substr_len, substr_start);
          case '+':
          case '-':
          case '*':
          case '/':
          case '(':
          case ')':
          case TK_EQ:
               tokens[nr_token++].type = rules[i].token_type;
               break;
          default: TODO();
        }
        break;
      }
    }

    if (i == NR_REGEX) {
      printf("no match at position %d\n%s\n%*.s^\n", position, e, position, "");
      return false;
    }
  }

  return true;
}

static bool check_parentheses(int p, int q){
  assert(p<q);
  if(tokens[p].type != '(' || tokens[q].type != ')'){
    return false;
  }
  else{
    int bracket_ptr = 0;
    bool check_match = true;
    for(int i=p+1; i<q; i++){
      if(tokens[i].type == '('){
        bracket_ptr++;
      }
      else if(tokens[i].type == ')'){
        bracket_ptr--;
        if(bracket_ptr==-1)
          check_match=false;
      }
    }
    if (bracket_ptr==0){
      return check_match;
    }
    else{
      panic("parentheses not match!");
      return false;
    }
  }
}

static int position_mop(int p, int q){
  assert(p<q);
  int bracket_ptr = 0;
  int pst = -1;
  char lvl = 127;
  for(int i=q; i>=p; i--){
    switch(tokens[i].type){
      case ')':bracket_ptr--;break;
      case '(':bracket_ptr++;break;
      default :break;
    }
    if(bracket_ptr != 0){
      continue;
    }
    else{
      switch(tokens[i].type){
        case TK_EQ: return i;
        case '+': case '-':
          if(lvl>1){
            pst=i;
            lvl=1;
          }break;
        case '*': case '/': 
          if(lvl>2){
            pst=i;
            lvl=2;
          }break;
        case TK_POS: case TK_NEG: case TK_DEREF:
          if(lvl>=3){
            pst=i;
            lvl=3;
          }break;
        default:break;
      }
    }
  }
  return pst;
}

static word_t eval(int p, int q) {
  if (p>q){
    /* Bad expression */
    assert(0);
    return -1;
  }
  else if (p==q){
    /* Single token.
    * For now this token should be a number.
    * Return the value of the number.
    */
    word_t value;
    bool success = true;
    switch(tokens[p].type){
      case TK_DEC:
           sscanf(tokens[p].str, "%ld", &value);
           break;
      case TK_HEX:
           sscanf(tokens[p].str, "0x%lx", &value);
           break;
      case TK_REG:
           value=isa_reg_str2val(tokens[p].str+1,&success);
           if(success)
             return value;
           else
             panic("Not found the reg!");
           break;
      default:assert(0);
    }
    return value;
  }
  else if (check_parentheses(p, q) == true) {
    /* The expression is surrounded by a matched pair of parentheses.
    * If that is the case, just throw away the parentheses.
    */
    return eval(p + 1, q - 1);
  }
  else {
    /* We should do more things here. */
    int op = position_mop(p,q);
    assert(op>=0);

    switch (tokens[op].type) {
      case '+': return eval(p, op - 1) + eval(op + 1, q);
      case '-': return eval(p, op - 1) - eval(op + 1, q);
      case '*': return eval(p, op - 1) * eval(op + 1, q);
      case '/': return eval(p, op - 1) / eval(op + 1, q);
      case TK_POS: assert(p==op); return eval(op + 1, q);
      case TK_NEG: assert(p==op); return -eval(op + 1, q);
      case TK_DEREF: assert(p==op); return vaddr_read(eval(op + 1, q),8);
      case TK_EQ: return eval(p , op - 1)==eval( op + 1,q);
      default: TODO();
    }
    return 0;
  }
}

word_t expr(char *e, bool *success) {
  if (!make_token(e)) {
    *success = false;
    return 0;
  }

  for (int i = 0; i < nr_token; i ++) {
    if(i == 0){
      switch(tokens[0].type){
        case '+': tokens[0].type=TK_POS;break;
        case '-': tokens[0].type=TK_NEG;break;
        case '*': tokens[0].type=TK_DEREF;break;
        default : break;
      }
    }
    else{
      switch(tokens[i-1].type){
        case TK_EQ:
        case TK_POS:
        case TK_NEG:
        case '+':
        case '-':
        case '*':
        case '/': 
        case '(':
          switch(tokens[i].type){
            case '+': tokens[i].type=TK_POS;break;
            case '-': tokens[i].type=TK_NEG;break;
            case '*': tokens[i].type=TK_DEREF;break;
            default: break;
          }break;
        default : break;
      }
    }
  }
  /* TODO: Insert codes to evaluate the expression. */
  return eval(0, nr_token-1);
}
