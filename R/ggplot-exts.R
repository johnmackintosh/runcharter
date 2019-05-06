# Take in a dataframe containing our x and y values.

#' @export
RunChartMedians <-
  ggproto("RunChartMedians",
          Stat,
          compute_group = function(data,
                                   scales,
                                   median_rows = 13,
                                   run_length = 9) {

            # set_median is a subfunction to create a row of
            # median data in a dataframe for the output. It
            # calculates the median between first_point and
            # last_point, and populates them as x, y, xend and yend
            # respectively. It also sets up xprojected and yprojected
            # as the same values as xend and yend which we then amend
            # on subsequent passes.
            set_median <- function(first_point) {
              last_point <- min(first_point + median_rows,
                                length(data$y))
              new_median = median(data$y[first_point:last_point])

              data.frame(
                x = data$x[first_point],
                y = new_median,
                xend = data$x[last_point],
                yend = new_median,
                last_point = last_point)
            }
            
            # Set the first median
            df_medians <- set_median(1)
            df_medians_last <- 1

            # Start checking the rest of the points from the end of
            # the last median using proj_point as a pointer.
            proj_point <- df_medians$last_point[df_medians_last]
            
            while(proj_point <= (length(data$y) - run_length)) {

              # If the next point if NA or equals the median,
              # extend the run
              if (is.na(data$y[proj_point]) |
                  (data$y[proj_point] == 
                   df_medians$y[df_medians_last])) {
                proj_point <- proj_point + 1
                next
              }
              
              # If it's greater than the median (and we are looking for >) then check
              if (data$y[proj_point] >
                  df_medians$y[df_medians_last]) {
                
                # Then check the whole run of medians between the
                # next point and the run length - is the minimum still
                # above our median?
                if (min(data$y[proj_point:
                              (proj_point + run_length - 1)]) > 
                  df_medians$y[df_medians_last]) {
                    # If so, reset the median
                    df_medians <- rbind(df_medians,
                      set_median(proj_point))
                    df_medians_last <- df_medians_last + 1
                  proj_point <- proj_point + median_rows
                  next
                }
                
                proj_point <- proj_point + 1
                next
              }

              
              # If it's less than the median (and we are looking for >) then check
              if (data$y[proj_point] <
                  df_medians$y[df_medians_last]) {
                
                # Then check the whole run of medians between the
                # next point and the run length - is the maximum still
                # below our median?
                if (max(data$y[(proj_point):
                               (proj_point + run_length)]) < 
                    df_medians$y[df_medians_last]) {
                  # If so, reset the median
                  df_medians <- rbind(df_medians,
                                      set_median(proj_point))
                  df_medians_last <- df_medians_last + 1
                  proj_point <- proj_point + median_rows
                  next
                }
                
                proj_point <- proj_point + 1
                next
              }
              proj_point <- proj_point + 1
            }
            return(df_medians)
          },

          required_aes = c("x", "y")
)

#' @export
#' @inheritParams ggplot2::stat_identity
#' @param median_rows The number of points used to calculate a new
#' median.
#' @param run_length Number of points above or below a median before a
#' new baseline needs to be calculated.
stat_runchart_medians <- function(mapping = NULL, data = NULL, geom = "polygon",
                       position = "identity", na.rm = FALSE,
                       show.legend = NA, 
                       inherit.aes = TRUE,
                       median_rows = 13,
                       run_length = 9, ...) {
  layer(
    stat = RunChartMedians, data = data, mapping = mapping, geom = geom, 
    position = position, show.legend = show.legend, inherit.aes = inherit.aes,
    params = list(median_rows = median_rows,
                  run_length = run_length,
                  na.rm = na.rm, ...)
  )
}