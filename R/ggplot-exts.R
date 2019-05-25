# Take in a dataframe containing our x and y values.

#' @export
StatAutoBaselinedRunChartMedians <-
  ggproto("StatAutoBaselinedRunChartMedians",
          Stat,
          compute_group = function(data,
                                   scales,
                                   median_rows = 13,
                                   run_length = 9) {
            
            # This stat will add the baseline and xend parameters
            data$baseline <- NA_real_
            data$xend <- NA_real_
            data$baseline_mark_improved <- NA
            
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
              last_run_length <- min(first_point + run_length,
                                     length(data$y))
              data$baseline[first_point] <-
                median(data$y[first_point:last_point])
              if (first_point != 1) {
                data$baseline_mark_improved[first_point:last_run_length] <- TRUE
              }
              data$xend[first_point] <- data$x[last_point]
              return(list(
                data = data,
                median = data$baseline[first_point],
                last_point = last_point)
              )
            }
            
            # Set the first median
            current_median <- set_median(1)
            data <- current_median$data

            # Start checking the rest of the points from the end of
            # the last median using proj_point as a pointer.
            proj_point <- current_median[["last_point"]]
            
            while (proj_point <= (length(data$y) - run_length)) {

              # If the next point if NA or equals the median,
              # extend the run
              if (is.na(data$y[proj_point]) |
                  (data$y[proj_point] == current_median[["median"]])) {
                proj_point <- proj_point + 1
                next
              }
              
              # If it's greater than the median (and we are looking for >) then check
              if (data$y[proj_point] > current_median[["median"]]) {
                
                # Then check the whole run of medians between the
                # next point and the run length - is the minimum still
                # above our median?
                if (min(data$y[
                  proj_point:(proj_point + run_length - 1)]) > 
                  current_median[["median"]]) {
                    # If so, reset the median
                    current_median <- set_median(proj_point)
                    data <- current_median$data
                    proj_point <- current_median[["last_point"]]
                  next
                }
                
                proj_point <- proj_point + 1
                next
              }

              
              # If it's less than the median (and we are looking for >) then check
              if (data$y[proj_point] < current_median[["median"]]) {
                
                # Then check the whole run of medians between the
                # next point and the run length - is the maximum still
                # below our median?
                if (max(data$y[
                  (proj_point):(proj_point + run_length)]) < 
                  current_median[["median"]]) {
                  # If so, reset the median
                  current_median <- set_median(proj_point)
                  data <- current_median$data
                  proj_point <- current_median[["last_point"]]
                  next
                }
                
                proj_point <- proj_point + 1
                next
              }
              proj_point <- proj_point + 1
            }
            
            return(data)
          },

          required_aes = c("x", "y")
)


GeomChartMedians <- ggproto("GeomChartMedians", Geom,
  required_aes = c("x", "y"),
  default_aes = aes(baseline_colour = "orange"),
                            
  draw_panel = function(data, panel_params, coord) {
                              data <- coord$transform(data, panel_params)
                              improved_points <- dplyr::filter(data,
                                !is.na(baseline_mark_improved))
                              data$baseline_mark_improved <- NULL
                              baseline_coords <- na.omit(data)
                              proj_coords <- baseline_coords
                              proj_coords$x <- c(baseline_coords$xend[-length(baseline_coords$xend)], NA)
                              proj_coords$xend <- c(baseline_coords$x[-1], NA)
                              proj_coords <- proj_coords[-length(proj_coords$x), ]
                              
                              grid::gList(
                                grid::polylineGrob(x = data$x,
                                                   y = data$y),
                                grid::pointsGrob(x = data$x,
                                                 y = data$y,
                                                 pch = 21,
                                                 size = grid::unit(2.5, units="points"),
                                                 gp = grid::gpar()),
                                if (length(improved_points$x) > 0) {
                                  grid::pointsGrob(x = improved_points$x,
                                                   y = improved_points$y,
                                                   pch = 21,
                                                   size = grid::unit(2.5, units="points"),
                                                   gp = grid::gpar(col = "red"))
                                } else {
                                  grid::nullGrob()
                                },
                                grid::segmentsGrob(x0 = baseline_coords$x,
                                                   y0 = baseline_coords$y,
                                                   x1 = baseline_coords$xend,
                                                   y1 = baseline_coords$y,
                                                   gp = grid::gpar(col = baseline_coords$baseline_colour,
                                                                   lty = 1)),
                                
                                grid::segmentsGrob(x0 = proj_coords$xend,
                                                   y0 = proj_coords$y,
                                                   x1 = proj_coords$x,
                                                   y1 = proj_coords$y,
                                                   gp = grid::gpar(col = proj_coords$baseline_colour,
                                                                   lty = 2))
                              )
                            }
)


#' @export
#' @inheritParams ggplot2::stat_identity
#' @param median_rows The number of points used to calculate a new
#' median.
#' @param run_length Number of points above or below a median before a
#' new baseline needs to be calculated.
geom_runchart <- function(mapping = NULL,
                          data = NULL,
                          position = "identity",
                          na.rm = FALSE,
                          show.legend = NA, 
                          inherit.aes = TRUE,
                          median_rows = 13,
                          run_length = 9, ...) {
  layer(stat = StatAutoBaselinedRunChartMedians,
        geom = GeomChartMedians,
        data = data,
        mapping = mapping,
        position = position,
        show.legend = show.legend,
        inherit.aes = inherit.aes,
        params = list(median_rows = median_rows,
                      run_length = run_length,
                      na.rm = na.rm, ...)
  )
}