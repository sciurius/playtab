all:	TOC
	perl ../script/playtab TOC *.dat > all.ps

separate: TOC
	@for i in TOC *.dat; \
	do \
	    echo + perl ../script/playtab $$i '>' `basename $$i .dat`.ps; \
	    perl ../script/playtab $$i > `basename $$i .dat`.ps; \
	done

TOC :	TOC.pro
	sed -n 's/^\![tT] *\(.*\)$$/- \1/p' *.dat | \
	  sort -d | cat TOC.pro - > TOC
