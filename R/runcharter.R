#' runcharter
#'
#' Finds all runs of desired  length occurring on desired side of median line.
#' Can also find runs occurring on both sides of the line, though this is of
#' limited use in terms of quality improvement.
#' Re-bases median each time a run is discovered.
#'
#' Facets and axis limits are handled by ggplot, though x-axis breaks can be
#' specified using the appropriate character string e.g. "3 months" if they are
#' either of class dates or datetime
#'
#'
#' @param df  data.frame or data table
#' @param med_rows number of points to calculate initial baseline median
#' @param runlength length of run that will trigger re-phased median
#' @param direction should run occur "above", "below" or on "both" sides of median
#' @param datecol name of date column
#' @param grpvar character vector of grouping variable
#' @param yval numeric y value
#' @param facet_cols how many columns are required in the plot facets
#' @param facet_scales defaults to "fixed". Alternatively, "free_y" 
#' @param chart_title title for the  final chart
#' @param chart_subtitle subtitle for chart
#' @param chart_caption caption for chart
#' @param chart_breaks character string defining desired x-axis date / datetime breaks.
#' If the x axis is not a Date or datetime, then this argument is ignored, 
#' and ggplot2 will provide default breaks
#' @param line_colr colour for run chart lines
#' @param line_size thickness of connecting lines between run chart points
#' @param point_colr colour for run chart points
#' @param point_size size of normal run chart points
#' @param median_colr colour for solid and extended median lines
#' @param median_line_size thickness of solid and extended median lines
#' @param highlight_fill fill colour for highlighting points in a sustained run
#' @param highlight_point_size size of highlighted points in a sustained run
#'
#' @return list - faceted plot and data.table showing all identified runs
#'
#' @import data.table
#' @importFrom stats median
#' @importFrom zoo rollapply
#' @importFrom ggplot2 aes ggplot geom_line geom_point geom_segment
#' @importFrom ggplot2 theme element_text element_blank labs
#' @importFrom ggplot2 ggtitle facet_wrap vars scale_x_date
#' @export
#'
#' @examples
#' \donttest{
#'runcharter(signals, med_rows = 13, runlength = 9,
#'direction = "above", datecol = date, grpvar = grp, yval = y,
#' facet_cols = 2,chart_title = "Automated runs analysis",
#'chart_subtitle = " some runs found", chart_caption = "powered by R",
#'chart_breaks = "6 months")
#' }
#'
#'
#'
runcharter <- function(df,
                       med_rows = 13,
                       runlength = 9,
                       direction = c("above","below","both"),
                       datecol = NULL,
                       grpvar = NULL,
                       yval = NULL,
                       facet_cols = NULL,
                       facet_scales = "fixed",
                       chart_title = NULL,
                       chart_subtitle = NULL,
                       chart_caption = NULL,
                       chart_breaks = NULL,
                       line_colr = "#005EB8",
                       line_size = 1.1,
                       point_colr ="#005EB8",
                       point_size = 2.5,
                       median_colr = "#E87722",
                       median_line_size = 1.05,
                       highlight_fill = "#DB1884",
                       highlight_point_size = 2.7) {
  

  datecol <- deparse1(substitute(datecol))
  grpvar <- deparse1(substitute(grpvar))
  yval <- deparse1(substitute(yval))
  
  stopifnot(!is.null(datecol),
            !is.null(grpvar),
            !is.null(df),
            !is.null(yval),
            length(direction) == 1
  )
  
  
  # mising arguments
  # df
  if (!length(df)) {
    stop('"Please provide the dataframe / tibble / data.table name"')
  }
  
  # datecol , grpvar and yval
  if (datecol == 'NULL' | grpvar == 'NULL' | yval == 'NULL') {
    stop('"Please check and provide values for the "datecol", "grpvar"  and "yval" arguments"')
  }
  
  
  
  
  # direction
  if (length(direction) > 1) {
    stop('"Too many values passed to "direction" argument.
         Please set direction to one of "above", "below", or "both"',
         call. = FALSE)
  }
  

  start_date <- NULL
  end_date <- NULL
  keepgroup <- character()
  
  
  flag_reset <- if (direction == "below") {
    runlength * -1
  } else {
    runlength
  }
  
  
  
  masterDT <- copy(df)
  setDT(masterDT)
  
  
  
  
  
  masterDT <- setnames(masterDT, old = c(datecol,grpvar,yval),
                                   new = c("date","grp","y"))
  
  
  # is grpvar a factor
  factorcheck <- is.factor(masterDT[["grp"]])
  
  if (factorcheck) {
    keeplevels <- levels(masterDT[["grp"]])
  }
  
  # then change to character for now
  masterDT[["grp"]] <- as.character(masterDT[["grp"]])
  
  # is datecol in wrong format?
  charactercheck <- is.character(masterDT[["date"]])
  
  if (charactercheck) {
    stop("The date column is a character  or factor vector.
     Please ensure this is in a Date, PosixCT, numeric or integer format")
  }
  
  
  masterDT[["y"]] <- as.numeric(masterDT[["y"]])
  
  setkey(masterDT, grp, date)
  
  masterDT <- masterDT[!is.na(date),]
  
  keepgroup <- masterDT[,.N, by = .(grp)]
  
  lines_only <- keepgroup[N > 1, .SD, by = .(grp)][, unique(grp)]
  lines_only <- masterDT[grp %chin% lines_only, ]
  
  
  keeptest <- keepgroup[]
  keeptest[, compar := (med_rows + runlength)][]
  keeptest[, result := (N >= compar)][]
  
  
  if (all(keeptest[["result"]] == FALSE)) {
    stop("None of the groups have enough rows of data beyond the specified baseline period, for the desired runlength.
        Please check the values of the med_rows and runlength arguments.
        Currently they exceed the number of rows for each group")
  } else {
    keepgroup <-  masterDT[,.N, by = .(grp)
                           ][N >= (med_rows + runlength),.SD,
                             .SDcols = "N", by = list(grp)
                             ][,unique(grp)] }
  
  if (length(keepgroup) == 0) {
    stop("None of the groups have enough rows of data beyond the specified baseline period, for the desired runlength.
        Please check the values of the med_rows and runlength arguments.
        Currently they exceed the number of rows for each group")
  }
  
  # every grp should appear in med rows
  median_rows <- masterDT[,.SD[1:med_rows], by = grp
                          ][, median := stats::median(utils::head(y,med_rows),na.rm = TRUE), by = grp
                            ][, start_date := min(date), by = grp
                              ][,end_date := max(date), by = grp]
  
  medians <- median_rows[,utils::head(.SD,1), by = grp,
                         .SDcols = c("median","start_date","end_date")
                         ][,`:=`(run_type = "baseline", rungroup = 1)]
  
  med_lookup <- medians[,c("grp","median","end_date")]
  
  
  
  tempDT <- med_lookup[masterDT,.(grp,y,date, median, end_date), on = "grp"
                       ][date > end_date,][]
  
  tempDT <- tempDT[,end_date := NULL][]
  
  
  # function begins from here
  tempDT <- basic_processing(DT = tempDT, kg = keepgroup,runlength)
  run_start <- get_run_dates(direction,DT = tempDT, target_vec = "cusum_shift",
                             compar_vec = flag_reset, runlength)
  keepgroup <- run_start[,.N,.(grp)][,unique(grp)]
  run_end <- get_run_dates(direction,DT = tempDT, target_vec = "cusum",
                           compar_vec = flag_reset, runlength)
  
  sustained <- get_sustained(DT1 = run_start, DT2 = run_end)
  
  tempDT <- update_tempDT(sustained,tempDT)
  
  bindlist <- if (!exists("bindlist")) {
    bindlist <- list(medians, sustained)
  } else {
    bindlist <- c(bindlist,sustained)
  }
  
  medians <- rbindlist(bindlist, use.names = TRUE, fill = TRUE)
  
  keepgroup <- tempDT[,.N,.(grp)
                      ][N >= (runlength),.SD,.SDcols = "N",by = list(grp)
                        ][,unique(grp)]
  
  # if keepgroup > 0 , repeat, else
  
  while (length(keepgroup)) {
    tempDT <- basic_processing(DT = tempDT, kg = keepgroup, runlength)
    run_start <- get_run_dates(direction, DT = tempDT, target_vec = "cusum_shift",
                               compar_vec = flag_reset, runlength)
    keepgroup <- run_start[,.N,.(grp)][,unique(grp)]
    run_end <- get_run_dates(direction,DT = tempDT, target_vec = "cusum",
                             compar_vec = flag_reset, runlength)
    
    sustained <- get_sustained(DT1 = run_start, DT2 = run_end)
    tempDT <- update_tempDT(sustained,tempDT)
    bindlist <- list(medians,sustained)
    medians <- rbindlist(bindlist, use.names = TRUE, fill = TRUE)
  }
  
  # modify the final medians DT for plotting purposes
  
  medians[,prev_median := shift(median, type = "lag"), by = "grp"]
  
  medians[,extend_to := shift(start_date,type = "lead"), by = "grp"]
  medians[,extend_to := ifelse(is.na(extend_to),
                               max(masterDT[["date"]]),extend_to), by = "grp"]
  median_rows <- medians[!is.na(end_date) & run_type == "baseline",]
  
  sustained_rows <- medians[!is.na(end_date) & run_type == "sustained",]
 
  sustained_rows <- sustained_rows[order(grp,start_date)
                                   ][,rungroup := NULL
                                     ][,rungroup := .GRP, by = list(grp,start_date)]

  setkey(sustained_rows,grp,start_date,end_date)
  
  highlights <- merge(masterDT, sustained_rows, by = "grp",
                     allow.cartesian = TRUE)
  
  highlights <- highlights[between(date,start_date,end_date),]
  
  highlights <- highlights[y != prev_median,.SD, by = "grp"][]
  

  if (factorcheck) {
    masterDT[,grp := factor(grp,levels = keeplevels,ordered = TRUE)]
    medians[,grp := factor(grp,levels = keeplevels,ordered = TRUE)]
    sustained_rows[,grp := factor(grp,levels = keeplevels,ordered = TRUE)]
    highlights[,grp := factor(grp,levels = keeplevels,ordered = TRUE)]
  }
  
  # base plot - lines and points
  
  runchart <- ggplot2::ggplot(masterDT, ggplot2::aes(date, y, group = grp)) 
  
  
  
  if (factorcheck) {
    runchart <- runchart + ggplot2::facet_wrap(ggplot2::vars(factor(grp)), 
                                               ncol = facet_cols,
                                               scales = facet_scales)
  } else {
    runchart <- runchart + ggplot2::facet_wrap(ggplot2::vars(grp), 
                                               ncol = facet_cols,
                                               scales = facet_scales)
  }
  
  # plot all points for all groups
  runchart <- runchart +
    ggplot2::geom_point(shape = 21 ,colour = point_colr, 
                        fill = point_colr, size = point_size) +
    ggplot2::theme_minimal(base_size = 10) +
    ggplot2::theme(axis.text.y = ggplot2::element_text(angle = 0)) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90)) +
    ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                   panel.grid.major = ggplot2::element_blank()) +
    ggplot2::labs(x = "", y = "", caption = chart_caption) +
    ggplot2::theme(legend.position = "bottom")
  
  
  # only plot lines for groups  with N > 1
  
  runchart <-
    runchart + ggplot2::geom_line(
      data = lines_only,
      na.rm = TRUE,
      ggplot2::aes(x = date,
                   y = y,
                   group = grp),
      colour = line_colr,
      size = line_size
    ) 
  
  # solid original median line
  
  runchart <- runchart +
    ggplot2::geom_segment(
      data = median_rows,
      na.rm = TRUE,
      ggplot2::aes(
        x = start_date,
        xend = end_date,
        y = median,
        yend = median,
        group = rungroup
      ),
      colour = median_colr,
      size = median_line_size,
      linetype = 1
    )
  
  
  #  highlight sustained points
  
  runchart <- runchart +
    ggplot2::geom_point(data = highlights, 
                        ggplot2::aes(x = date, y = y, group = rungroup),
                        shape = 21, 
                        colour = point_colr, 
                        fill = highlight_fill,
                        size = highlight_point_size)
  
  
  # sustained median lines
  runchart <- runchart +
    ggplot2::geom_segment(data = sustained_rows, na.rm = TRUE,
                          ggplot2::aes(x = start_date, 
                                       xend = end_date, 
                                       y = median, 
                                       yend = median,group = rungroup),
                          colour = median_colr, 
                          linetype = 1, 
                          size = median_line_size)
  
  
  runchart <- runchart + ggplot2::ggtitle(label = chart_title, 
                                          subtitle = chart_subtitle)
  
  
  
  
  
  
  # extended baseline from last improvement date to next run or end
  runchart <- runchart +
    ggplot2::geom_segment(data = medians, na.rm = TRUE,
                          ggplot2::aes(x = end_date,
                                       xend = extend_to,
                                       y = median,
                                       yend = median,
                                       group = rungroup),
                          colour = median_colr,
                          linetype = 2,
                          size = median_line_size)
  
  # date breaks
  
  if (inherits(masterDT[["date"]],"Date") & !is.null(chart_breaks)) {
    runchart <- runchart + ggplot2::scale_x_date(date_breaks = chart_breaks)
  }
  
  if (inherits(masterDT[["date"]],"Date") & is.null(chart_breaks)) {
    runchart <- runchart + ggplot2::scale_x_date()
  }
  
  
  if (inherits(masterDT[["date"]],"PosixCT") & !is.null(chart_breaks)) {
    runchart <- runchart + ggplot2::scale_x_datetime(date_breaks = chart_breaks)
  }
  
  if (inherits(masterDT[["date"]],"PosixCT") & is.null(chart_breaks)) {
    runchart <- runchart + ggplot2::scale_x_datetime()
  }
  
  # tidy up the medians DT and reapply original column names
  
  medians <- medians[,.SD,.SDcols = c("grp","median","start_date","end_date",
                                      "extend_to","run_type")]
  
  setnames(medians, old = "grp",new = grpvar)
  
  results <- list( runchart = runchart, sustained = medians[!is.na(end_date),])
  
  return(results)
  
}