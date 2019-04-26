
<!-- README.md is generated from README.Rmd. Please edit that file -->
runcharter <img src="man/figures/logo.png" width="160px" align="right" />
=========================================================================

Automated analysis and re-basing of run charts at scale.

Online documentation and vignettes : [runcharter](https://www.johnmackintosh.com/runcharter/)

[![Build Status](https://travis-ci.org/johnmackintosh/runcharter.svg?branch=Master)](https://travis-ci.org/johnmackintosh/runcharter) [![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip) [![Coverage status](https://codecov.io/gh/johnmackintosh/runcharter/branch/master/graph/badge.svg)](https://codecov.io/github/johnmackintosh/runcharter?branch=master)

Installation
------------

You can install runcharter from github with:

``` r
# install.packages("devtools")
devtools::install_github("johnmackintosh/runcharter")

# to ensure the vignettes are built or ensure latest version is installed:

devtools::install_github("johnmackintosh/runcharter", 
                         build_vignettes = TRUE, force = TRUE)
```

Rationale
---------

Run charts are easy to create and analyse on an individual basis, hence they are widely used in healthcare quality improvement.

A run chart is a regular line chart, with a central reference line.

This central line, calculated using the median of a number of values over a baseline period, allows the QI team to assess if any statistically significant improvement is taking place, as a result of their improvement initiatives.

These improvements are denoted by certain patterns, or signals, within the plotted data points, in relation to the median line. The main signal is a run of 9 or more consecutive values on the desired side of the median line.

If this signal occurs as a result of improvement activities, but performance is not yet at the target level, a new median line can be plotted.

This is calculated using the median of the points that contributed to the signal. The aim is to then continue to work on improvement, measure and plot data, and look for the next sustained signal, until the improvement initiative is operating at its target level.

While this 'rebasing' (calculating new medians) is manageable for a few charts, it quickly becomes labour intensive as QI initiatives expand or further QI programmes are launched.

While enterprise level database software can be used to store the raw data, their associated reporting systems are usually ill suited to the task of analysing QI data using run chart rules.

This package automatically creates rebased run charts, based on the run chart rule for sustained improvement commonly used in healthcare ( 9 consecutive points on the desired side of the median).

All sustained runs of improvement, in the desired direction, will be highlighted and the median re-phased, using the points that contributed to the run.

Non useful observations (points on the median) are ignored and are not highlighted.

The main motivation is to analyse many charts at once, but you can also create and analyse a single run chart, or iterate, plot and save many individual charts.

The runcharter function - input
-------------------------------

The function requires a simple three column dataframe, with the following column names

-   grp : a character column indicating a grouping variable to identify each individual run chart and for faceted plots
-   date : a column of type 'date'.
-   y : the variable / value to plot.

runcharter function arguments
-----------------------------

-   df : a three column dataframe with columns named 'grp', 'date' and 'y' as specified above
-   med\_rows : How many rows / data points should the initial baseline median be calculated over?
-   runlength : How long a run of consecutive points do you want to find, before you rebase the median? The median will be rebased using all useful observations (points on the median are not useful, and are ignored).
-   chart\_title : The main title for the chart
-   chart\_subtitle : A subtitle for the chart
-   direction : "above" or "below" the median, or "both". The function can nowlook for alternating runs in both directions,using "both".
-   faceted : defaults to TRUE. Set to FALSE if you only need to plot a single run chart. This will ensure the chart plots correctly
-   facet\_cols : the number of columns in a faceted plot - only required if faceted is set to TRUE, otherwise ignored
-   save\_plot : Calls ggsave if TRUE, saving in the current working directory
-   plot\_extension : one of "png","pdf" or other valid extension for saving ggplot2 plots. Used in the call to ggsave.

example plot
------------

``` r
library(runcharter)
library(dplyr)
#> Warning: package 'dplyr' was built under R version 3.5.2
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union

single <- signals %>%
dplyr::filter(grp == "WardX") %>%
runcharter(med_rows = 13,
runlength = 9,
chart_title = "Analysis of runs below median",
chart_subtitle = "Ward X",
direction = "below",
faceted =  FALSE)
#> Joining, by = c("grp", "y", "date")
#> Joining, by = "grp"
#> all sustained runs found, not enough rows remaining for analysis
```

![One plot, one run below the median](man/figures/unnamed-chunk-2-1.png)

Plot explanation
----------------

-   `med_rows` defines the initial baseline period. In the example below, the first 13 points are used to calculate the initial median. This is represented with a solid orange horizontal line. This median is then used as a reference for the remaining values, denoted by the extending orange dashed line

-   `runlength` specifies the length of run to be identified. Along with `direction`, which specifies which side of median represents improvement, the runlength is your target number of successive points on the desired side of the median (points on the median are ignored as they do not make or break a run).You can currently set the `direction` as either "above" or "below" the line. Searching for runs in "both" directions at once is also possible.

If a run is identified, the points are highlighted (the purple coloured points), and a new median is calculated using them. The median is also plotted and extended into the future for further run chart rules analysis, with a new set of solid and dashed horizontal lines.

The analysis continues, rebasing any further runs, until no more runs are found or there are not enough data points remaining.

Example
-------

By default the function returns a faceted plot, highlighting successive runs below the median:

``` r
library(runcharter)
runcharter(signals, direction = "below",facet_cols = 2)
#> $runchart
#> Warning: Removed 110 rows containing missing values (geom_segment).
```

![](man/figures/unnamed-chunk-3-1.png)

    #> 
    #> $median_rows
    #> # A tibble: 52 x 4
    #>    grp       y date       baseline
    #>    <chr> <int> <date>        <int>
    #>  1 WardX     9 2014-01-01       11
    #>  2 WardX    22 2014-02-01       11
    #>  3 WardX    19 2014-03-01       11
    #>  4 WardX    18 2014-04-01       11
    #>  5 WardX     8 2014-05-01       11
    #>  6 WardX     7 2014-06-01       11
    #>  7 WardX    11 2014-07-01       11
    #>  8 WardX    11 2014-08-01       11
    #>  9 WardX    11 2014-09-01       11
    #> 10 WardX    12 2014-10-01       11
    #> # ... with 42 more rows
    #> 
    #> $sustained
    #>      grp  y       date flag rungroup cusum improve  startdate    enddate
    #> 1  WardX  7 2016-12-01   -1        1    -1       6 2016-12-01 2017-08-01
    #> 2  WardX  5 2017-01-01   -1        1    -2       6 2016-12-01 2017-08-01
    #> 3  WardX  4 2017-02-01   -1        1    -3       6 2016-12-01 2017-08-01
    #> 4  WardX 10 2017-03-01   -1        1    -4       6 2016-12-01 2017-08-01
    #> 5  WardX  4 2017-04-01   -1        1    -5       6 2016-12-01 2017-08-01
    #> 6  WardX  9 2017-05-01   -1        1    -6       6 2016-12-01 2017-08-01
    #> 7  WardX  4 2017-06-01   -1        1    -7       6 2016-12-01 2017-08-01
    #> 8  WardX  8 2017-07-01   -1        1    -8       6 2016-12-01 2017-08-01
    #> 9  WardX  6 2017-08-01   -1        1    -9       6 2016-12-01 2017-08-01
    #> 10 WardY  7 2017-10-01   -1        1    -1       8 2017-10-01 2018-06-01
    #> 11 WardY  3 2017-11-01   -1        1    -2       8 2017-10-01 2018-06-01
    #> 12 WardY  8 2017-12-01   -1        1    -3       8 2017-10-01 2018-06-01
    #> 13 WardY 11 2018-01-01   -1        1    -4       8 2017-10-01 2018-06-01
    #> 14 WardY  7 2018-02-01   -1        1    -5       8 2017-10-01 2018-06-01
    #> 15 WardY  9 2018-03-01   -1        1    -6       8 2017-10-01 2018-06-01
    #> 16 WardY  8 2018-04-01   -1        1    -7       8 2017-10-01 2018-06-01
    #> 17 WardY  8 2018-05-01   -1        1    -8       8 2017-10-01 2018-06-01
    #> 18 WardY  7 2018-06-01   -1        1    -9       8 2017-10-01 2018-06-01
    #>      lastdate
    #> 1  2018-07-01
    #> 2  2018-07-01
    #> 3  2018-07-01
    #> 4  2018-07-01
    #> 5  2018-07-01
    #> 6  2018-07-01
    #> 7  2018-07-01
    #> 8  2018-07-01
    #> 9  2018-07-01
    #> 10 2018-07-01
    #> 11 2018-07-01
    #> 12 2018-07-01
    #> 13 2018-07-01
    #> 14 2018-07-01
    #> 15 2018-07-01
    #> 16 2018-07-01
    #> 17 2018-07-01
    #> 18 2018-07-01
    #> 
    #> $StartBaseline
    #> [1] 11 13  4  7

The function will print the plot, and return a list, containing:

-   a ggplot2 object,
-   a dataframe / tibble containing the rows of data used to calculate the baseline median
-   if applicable, a dataframe / tibble showing the points in each sustained period of improvement.
-   the initial baseline median value

The latter 3 items can be retrieved from the list and used to create new plots (if, for example, you would like different plot themes or colours from the package defaults)

Don't try this at home - setting runlength of 3 to show that successive runs are identified:

``` r
library(dplyr)
signals %>% 
  dplyr::filter(date <= '2015-12-01',grp == "WardX") %>% 
  runcharter(med_rows = 3,
             runlength = 3, 
             direction = "both",
             faceted = FALSE)
#> Joining, by = c("grp", "y", "date")
#> Joining, by = "grp"
#> all sustained runs found, not enough rows remaining for analysis
```

![](man/figures/unnamed-chunk-4-1.png)

    #> $runchart

![](man/figures/unnamed-chunk-4-2.png)

    #> 
    #> $sustained
    #> # A tibble: 15 x 10
    #>    grp       y date        flag rungroup cusum improve startdate 
    #>    <chr> <int> <date>     <dbl>    <dbl> <dbl>   <int> <date>    
    #>  1 WardX    18 2014-04-01    -1        1     1       8 2014-04-01
    #>  2 WardX     8 2014-05-01    -1        1     2       8 2014-04-01
    #>  3 WardX     7 2014-06-01    -1        1     3       8 2014-04-01
    #>  4 WardX    11 2014-07-01     1        2     1      11 2014-07-01
    #>  5 WardX    11 2014-08-01     1        2     2      11 2014-07-01
    #>  6 WardX    11 2014-09-01     1        2     3      11 2014-07-01
    #>  7 WardX     2 2014-11-01    -1        3     1       8 2014-11-01
    #>  8 WardX     8 2014-12-01    -1        3     2       8 2014-11-01
    #>  9 WardX     9 2015-01-01    -1        3     3       8 2014-11-01
    #> 10 WardX    11 2015-04-01     1        4     1      11 2015-04-01
    #> 11 WardX    11 2015-05-01     1        4     2      11 2015-04-01
    #> 12 WardX    11 2015-06-01     1        4     3      11 2015-04-01
    #> 13 WardX    21 2015-07-01     1        5     1      21 2015-07-01
    #> 14 WardX    12 2015-08-01     1        5     2      21 2015-07-01
    #> 15 WardX    21 2015-09-01     1        5     3      21 2015-07-01
    #> # ... with 2 more variables: enddate <date>, lastdate <date>
    #> 
    #> $median_rows
    #> # A tibble: 3 x 4
    #>   grp       y date       baseline
    #>   <chr> <int> <date>        <int>
    #> 1 WardX     9 2014-01-01       19
    #> 2 WardX    22 2014-02-01       19
    #> 3 WardX    19 2014-03-01       19
    #> 
    #> $StartBaseline
    #> [1] 19
