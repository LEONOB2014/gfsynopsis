# gfsynopsis: An R package for generating an annual data synopsis report for groundfish

<img src="report/silvergray.jpg" alt="Silver Gray Rockfish Example" width="750" height="478.5">

This package uses the data extraction, data tidying, model fitting, and plotting functions from [gfplot](https://github.com/pbs-assess/gfplot).

# Building the document

1. Install gfsynopsis and csasdown:

```r
# install.packages("devtools")
devtools::install_github("pbs-assess/gfsynopsis", dependencies = TRUE)
devtools::install_github("pbs-assess/csasdown")
```

2. Clone or download the gfsynopsis GitHub repository.

3. With the R working directory set to the root folder of the project (e.g. open the RStudio `gfsynopsis.Rproj` file), run:

```r
source("report/make.R")
```

4. Wait for a long time for all the data to download, all the models to fit, and all the plots to generate. If you are starting from scratch then it may take a day or so to fit all the commercial CPUE index standardization models. If you already have these results cached, then it could take anywhere from ~10 minutes to a couple hours depending what needs to be built.

5. In RStudio, open `gfsynopsis/report/report-rmd/index.Rmd` and click the "Knit" button, or in any R console run:

```r
setwd("report/report-rmd")
bookdown::render_book("index.Rmd")
setwd("../../")
```

Problems? Sorry! File an [issue](https://github.com/pbs-assess/gfsynopsis/issues).
