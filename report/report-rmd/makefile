all:pdf

pdf:
	Rscript -e "bookdown::render_book('index.Rmd')"

compressfigs:
	cd knitr-figs
	find -X . -name '*.png' -print0 | xargs -0 -n 7 -P 4 optipng -strip all
	
compresslogos:
	cd csas-style/images/
	find -X . -name '*.png' -print0 | xargs -0 optipng -strip all
