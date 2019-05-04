
#' Create run chart with highlighted improvements where applicable
#'
#'This will plot the original dataframe, with highlighted runs of improvement.
#'It will also return a dataframe showing the improvment data
#'
#'
#' @param df  dataframe containing columns "date", "y", "grp"
#' @param med_rows   number of rows to base the initial median calculation over
#' @param runlength how long a run of consecutive points should be before re-basing the median
#' @param chart_title title for the  final chart
#' @param chart_subtitle subtitle for chart
#' @param direction look for runs "below" or "above" the median, or "both"
#' @param faceted if you  dont need a faceted / trellis display set this to FALSE
#' @param facet_cols the number of columns required for a faceted plot. Ignored if faceted is set to FALSE
#' @param save_plot should the plot be saved?  Calls ggsave on the last plot, saving in the current directory, if TRUE.
#' @param plot_extension one of "png","pdf" or other valid extension for saving ggplot2 plots. Used in the call to ggsave.
#' @param ... further arguments passed on to function
#'
#' @return run chart(s) and a dataframe showing sustained run data if appropriate
#'
#' 
#' @importFrom utils head
#' @importFrom stats median
#' @export
#'
#'@examples
#'\donttest{
#'runcharter(signals, med_rows = 13, runlength = 9,
#'chart_title = "Automated runs analysis",
#'direction = "above", faceted = TRUE,
#'facet_cols = 2, save_plot = TRUE, plot_extension = "png")
#'}
#'
#'
#
runcharter <-
  function(df,
           med_rows = 13,
           runlength = 9,
           chart_title = NULL,
           chart_subtitle = NULL,
           direction = "below",
           faceted = TRUE,
           facet_cols = NULL,
           save_plot = FALSE,
           plot_extension = "png",
           ...) {
    
      build_facet(df,
        mr = med_rows,
        rl = runlength,
        ct = chart_title,
        cs = chart_subtitle,
        direct = direction,
        faceted = TRUE,
        n_facets = facet_cols,
        sp = save_plot,
        pe = plot_extension
      )
  }
