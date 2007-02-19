all:
	sed -n 's/^\![tT] *\(.*\)$$/- \1/p' *.dat | \
	  sort -d | cat TOC.pro - > TOC
