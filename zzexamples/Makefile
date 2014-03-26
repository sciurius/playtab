all:	TOC
	perl ../script/playtab TOC *.ptb > all.ps

separate: TOC
	@for i in TOC *.ptb; \
	do \
	    echo + perl ../script/playtab $$i '>' `basename $$i .ptb`.ps; \
	    perl ../script/playtab $$i > `basename $$i .ptb`.ps; \
	done

TOC :	TOC.pro
	sed -n 's/^\![tT] *\(.*\)$$/- \1/p' *.ptb | \
	  sort -d | cat TOC.pro - > TOC
