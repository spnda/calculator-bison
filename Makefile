UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    BISON = $(shell brew --prefix bison)/bin/bison
else
	BISON = bison
endif

JAVAC = javac
JAVA = java
XSLTPROC = xsltproc
JAVACFLAGS = -Xlint:none

all: Calc.class

%.java %.xml %.gv: %.y
	$(BISON) $(BISONFLAGS) --xml --graph=$*.gv -o $*.java $<

%.class: %.java
	$(JAVAC) $(JAVACFLAGS) $<

run: Calc.class
	@echo "Type arithmetic expressions.  Quit with ctrl-d."
	$(JAVA) $(JAVAFLAGS) Calc

html: Calc.html
%.html: %.xml
	$(XSLTPROC) $(XSLTPROCFLAGS) -o $@ $$($(BISON) --print-datadir)/xslt/xml2xhtml.xsl $<

clean:
	rm -f *.class Calc.java Calc.html Calc.xml Calc.gv
