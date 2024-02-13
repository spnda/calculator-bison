%language "Java"

%define api.parser.class {Calc}
%define api.parser.public

%define parse.error verbose
%locations

%code imports {
  import java.io.IOException;
  import java.io.InputStream;
  import java.io.InputStreamReader;
  import java.io.Reader;
  import java.io.StreamTokenizer;

  import java.util.Map;
  import java.util.HashMap;

  import java.lang.Math;
  import java.math.MathContext;
  import java.math.BigDecimal;
}

%code {
  public static void main (String args[]) throws IOException
  {
    CalcLexer l = new CalcLexer (System.in);
    Calc p = new Calc (l);

    p.set_default_variables();

    p.parse ();
  }

  // Hiermit ermöglichen wir das abspeichern von beliebig vielen Werten als Variablen
  Map<String, BigDecimal> variables = new HashMap<>();

  BigDecimal get_variable(String str) {
    if (!variables.containsKey(str))
      return BigDecimal.ZERO;
    else
      return variables.get(str);
  }

  static final double PI = 3.14159265358979311599796346854D;

  void set_default_variables() {
    variables.put("π", new BigDecimal(PI));
    variables.put("pi", new BigDecimal(PI));
    variables.put("e", new BigDecimal(Math.E));
  }

  BigDecimal evaluate_function(BigDecimal input, String name) {
    return switch (name) {
      case "sqrt" -> input.sqrt(MathContext.DECIMAL128);
      case "sin" -> new BigDecimal(Math.sin(input.doubleValue()));
      case "cos" -> new BigDecimal(Math.cos(input.doubleValue()));
      case "ln" -> new BigDecimal(Math.log(input.doubleValue()));
      case "log" -> new BigDecimal(Math.log10(input.doubleValue()));
      default -> BigDecimal.ZERO;
    };
  }
}

%define api.value.type {Object}

/* Bison Declarations */
%token <BigDecimal> NUM
%token <String> IDENTIFIER
%token EOL "\n"
%token CMP "=="
%token ASSIGN "="

%type <BigDecimal> exp

// Hier geht es darum zu definieren, ob der linke oder der rechte Ausdruck zuerst evaluiert werden soll.
// Siehe https://en.wikipedia.org/wiki/Operator_associativity
%left '-' '+'
%left '*' '/'
%left CMP
%precedence NEG     /* unary minus */
%right '^'          /* exponentiation */
%right ASSIGN

/* Grammar follows */
%%
input:
  line
| input line
;

line:
  EOL
| exp CMP exp EOL {
    if ($1.equals($3))
      //System.out.println("" + $1 + " = " + $3);
      System.out.println("> true");
    else
      //System.out.println("" + $1 + " != " + $3);
      System.out.println("> false");
  }
| IDENTIFIER ASSIGN exp EOL {
    variables.put($1, $3);
    System.out.println("> " + $1 + " = " + $3);
  }
| exp EOL           { System.out.println("> " + $exp); }
| error EOL
;

// Weiter unten stehende Gruppen werden zuerst ausgeführt.
// Punkt vor Strich, weshalb * und / weiter unten stehen als + und -.
exp:
  NUM
| IDENTIFIER         { $$ = get_variable($1); } // Wir interpretieren hier einen IDENTIFIER als einen Variablenname
| exp '+' exp        { $$ = $1.add($3); }
| exp '-' exp        { $$ = $1.subtract($3); }
| exp '*' exp        { $$ = $1.multiply($3); }
| exp '/' exp        { $$ = $1.divide($3); }
| '-' exp  %prec NEG { $$ = $2.negate(); }
| exp '^' exp        { $$ = $1.pow($3.intValue()); }
| '|' exp '|'        { $$ = $2.abs(); }
| '(' exp ')'        { $$ = $2; }
| IDENTIFIER '(' exp ')'  { $$ = evaluate_function($3, $1); } // Wir interpretieren hier einen IDENTIFIER als einen Funktionsname
| '(' error ')'      { $$ = new BigDecimal (0); return YYERROR; }
| '!'                { $$ = new BigDecimal (0); return YYERROR; }
| '-' error          { $$ = new BigDecimal (0); return YYERROR; }
;

%%

class CalcLexer implements Calc.Lexer {
  StreamTokenizer st;

  public CalcLexer (InputStream is) throws IOException {
    st = new StreamTokenizer (new InputStreamReader (is, "UTF-8"));
    st.resetSyntax ();
    st.eolIsSignificant (true);
    st.whitespaceChars ('\t', '\t');
    st.whitespaceChars (' ', ' ');

    st.parseNumbers();
    st.wordChars('a', 'z');
    st.wordChars('A', 'Z');
    st.wordChars('π', 'π');
  }

  Position yypos = new Position (1, 0);

  public Position getStartPos () {
    return yypos;
  }

  public Position getEndPos () {
    return yypos;
  }

  public void yyerror (Calc.Location l, String s)
  {
    if (l == null)
      System.err.println (s);
    else
      System.err.println (l + ": " + s);
  }

  Object yylval;
  // Gibt den semantischen Wert des zuletzt geparsten Tokens zurück
  public Object getLVal() {
    return yylval;
  }

  public int yylex () throws IOException {
    int ttype = st.nextToken ();
    yypos = new Position (yypos.lineno (), yypos.token () + 1);

    switch (ttype) {
      case StreamTokenizer.TT_EOF:
        return EOF;
      case StreamTokenizer.TT_EOL:
        yypos = new Position(yypos.lineno() + 1, 0);
        return EOL;
      case StreamTokenizer.TT_NUMBER:
        // Siehe StreamTokenizer.parseNumbers im ctor
        yylval = new BigDecimal(st.nval);
        return NUM;
      case StreamTokenizer.TT_WORD:
        yylval = st.sval;
        return IDENTIFIER;
      case '=':
        int next = st.nextToken();
        if (next == '=') {
          yylval = "==";
          return CMP;
        }
        // Wir sind ein Token weiter gegangen, und setzten dies hiermit wieder zurück.
        st.pushBack();
        return ASSIGN;
      default:
        return st.ttype;
    }
  }
}

class Position {
  public int line;
  public int token;

  public Position ()
  {
    line = 0;
    token = 0;
  }

  public Position (int l, int t)
  {
    line = l;
    token = t;
  }

  public boolean equals (Position l)
  {
    return l.line == line && l.token == token;
  }

  public String toString ()
  {
    return Integer.toString (line) + "." + Integer.toString(token);
  }

  public int lineno ()
  {
    return line;
  }

  public int token ()
  {
    return token;
  }
}
