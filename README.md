# runcharter
Automated  analysis and re-basing of  runcharts at scale.


Run charts  and SPC charts are used extensively in quality improvement within the healthcare.

Run charts are simple to construct, and analyse using run chart rules.
However over time, a signal of improvement may require a run-chart median to be rebased.

Rationale:

The analysis and re-basing of improvement medians quickly becomes labour intensive as the QI programme evolves - and though enterprise level database software can be used to store the raw data, their associated reporting systems are usually ill suited to the task of analysing QI data using run chart rules or SPC rules.


This package automatically creates rebased run charts, based on run chart rules commonly used in healthcare.
This can be a single chart, and will eventually also create faceted small multiples.
All sustained runs of improvement, in the desired direction, will be highlighted and the median re-phased, using the points that contributed to the run.
Non useful observations (points on the median) are ignored for the purposes of identifying a sustained improvement and are not highlighted.


 For the time being, the function requires a three column data frame, containing the named variables "grp", "y" and "date".
 "grp" is a grouping variable which will be used for faceting.
 "y" is the variable on the y axis. You are encouraged to ensure that any doubles have been rounded appropriately.
 "date" is a date column.

 The function returns  a runchart and  dataframe of sustained data points, allowing you to perform further analysis or processing.

 ```r
 runcharter(signals, med_rows = 13, runlength = 9, chart_title = unique(newtest$grp),
                      chart_subtitle = "test runs above", direction = "below", faceted = FALSE)

 ```

 ![runcharter](https://user-images.githubusercontent.com/3278367/49257408-2157b500-f42a-11e8-8d05-96cf8ba8b8f6.gif)


