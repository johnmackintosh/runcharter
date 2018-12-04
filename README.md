# runcharter
Automated  analysis and re-basing of  runcharts at scale.

Online documentation and vignettes : [runcharter](https://www.johnmackintosh.com/runcharter/)

[![Build Status](https://travis-ci.org/johnmackintosh/runcharter.svg?branch=Master)](https://travis-ci.org/johnmackintosh/runcharter)
[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](https://www.repostatus.org/badges/latest/wip.svg)](https://www.repostatus.org/#wip)

Run charts  and SPC charts are used extensively in quality improvement within the healthcare.

Run charts are simple to construct, and analyse using run chart rules.
However over time, a signal of improvement may require a run-chart median to be rebased. 

Rationale:

The analysis and re-basing of improvement medians quickly becomes labour intensive as the QI programme evolves - and though enterprise level database software can be used to store the raw data, their associated reporting systems are usually ill suited to the task of analysing QI data using run chart rules or SPC rules.


This package automatically creates rebased run charts, based on run chart rules commonly used in healthcare.
The main motivation is to analyse many charts at one time, but will also analyse a single chart. 
All sustained runs of improvement, in the desired direction, will be highlighted and the median re-phased, using the points that contributed to the run. 
Non useful observations (points on the median) are ignored for the purposes of identifying a sustained improvement and are not highlighted. 


 For the time being, the function requires a three column data frame, containing the named variables "grp", "y" and "date".
 "grp" is a grouping variable which will be used for faceting. 
 "y" is the variable on the y axis. 
 You are encouraged to ensure that any doubles have been rounded appropriately.
 "date" is a date column.
 
 The function returns  a runchart and  dataframe of sustained data points, allowing you to perform further analysis or processing. 
 
 ```r
 
 runcharter(signals, faceted = TRUE)

 ```

![runcharter 1 plot facet](https://user-images.githubusercontent.com/3278367/49329156-eb721800-f572-11e8-8c13-91590f40a9c1.png)


```r

runcharter(signals, faceted = TRUE,facet_cols = 2)

```

![runcharter 2 facet plot](https://user-images.githubusercontent.com/3278367/49329166-0cd30400-f573-11e8-8add-1a02ab437266.png)


```r

signals %>%
filter(grp == "WardX") %>%
runcharter(chart_title = "WardX", chart_subtitle = "testing runs below")

```
![wardxbelow](https://user-images.githubusercontent.com/3278367/49329213-8ec32d00-f573-11e8-80e0-5a65734bdb20.png)

Don't try this at home - setting runlength of 3 to show that successive runs are identified:

```r

signals %>% 
  runcharter(med_rows = 3,
             runlength =3, 
             direction = "above",
             faceted = TRUE,
              facet_cols = 2)
```

![successive rebasing](https://user-images.githubusercontent.com/3278367/49333222-ca311c00-f5b2-11e8-8256-4db9dee878d5.png)


