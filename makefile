install:
	bison -d sap.y
	flex --header-file=lex.yy.h sap.l
	g++ -std=c++11 -o sap sap.tab.c lex.yy.c
	cp sap ~/bin/
