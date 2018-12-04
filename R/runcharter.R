utils::globalVariables(c("Baseline", "Date", "EndDate", "StartBaseline", "baseline", "chart_title","df",
                         "date_format", "enddate","EndDate", "grp", "flag", "runlength", "improve", "lastdate", "median",
                         "med_rows","median_rows","out_group","runcharts","runchart", "rungroup", "runlength","sustained","tmpdata", "y"))

#' Create run chart with highlighted improvements where applicable
#'
#'This will plot the original dataframe, with highlighted runs of improvement.
#'It will also return a dataframe showing the improvment data
#'
#'
#' @param df  dataframe containing columns "date", "y", "grp"
#' @param med_rows   the number of rows you wish to base the initial median calculation over
#' @param runlength how long a run of consecutive points should be before re-basing the median
#' @param chart_title title for the  final chart
#' @param chart_subtitle subtitle for chart
#' @param direction look for runs "below" or "above" the median
#' @param faceted if you  dont need a faceted / trellis display set this to FALSE
#' @param facet_cols the number of columns required for a faceted plot. Ignored if faceted is set to FALSE
#' @param ... further arguments passed on to function
#'
#' @return runchart and a dataframe showing sustained run data if appropriate
#'
#' @import ggplot2
#' @import dplyr
#' @importFrom utils head
#' @export
#'
#'@examples
#'\donttest{
#'runcharter(data, med_rows = 13, runlength = 9, chart_title = "Automated runs analysis",
#'direction = "above", faceted = FALSE)
#'}
#'
#'
#
runcharter <- function(df, med_rows = 13, runlength = 9, chart_title = NULL,
                       chart_subtitle = NULL, direction ="below",
                       faceted = TRUE, facet_cols = NULL, ...) {

  baseplot <- function(df, chart_title, chart_subtitle, ...) {
    runchart <- ggplot2::ggplot(df, aes(date, y, group = 1)) +
      ggplot2::geom_line(colour = "#005EB8", size = 1.3)  +
      ggplot2::geom_point(shape = 21 , colour = "#005EB8", fill = "white", size = 3) +
      ggplot2::theme_minimal(base_size = 10) +
      theme(axis.text.y = element_text(angle = 0)) +
      theme(axis.text.x = element_text(angle = 90)) +
      theme(panel.grid.minor = element_blank(), panel.grid.major = element_blank()) +
      ggplot2::ggtitle(label = chart_title,
                       subtitle = chart_subtitle) +
      ggplot2::labs(x = "", y = "") +
      theme(legend.position = "bottom")


    #runchart <- runchart + ggplot2::facet_wrap(vars(grp))

    runchart <- runchart + ggplot2::geom_line(data = median_rows,aes(x = date,y = baseline,group = 1),
                                              colour = "#E87722", size = 1.2,linetype = 1)
    runchart <- runchart + ggplot2::geom_line(data = df,aes(x = date, y = StartBaseline, group = 1),
                                              colour = "#E87722", size = 1.2, linetype = 2)


    return(runchart)
  }

  susplot <- function(df,susdf, ...) {

    runchart <- baseplot(df,chart_title, chart_subtitle,...)

    runchart <- runchart + ggplot2::geom_point(data = susdf, aes(x = date,y = y,group = rungroup),
                                               shape = 21, colour = "#005EB8", fill = "#DB1884" , size = 3.5)

    runchart <- runchart + ggplot2::geom_line(data = susdf,aes(x = date,y = improve,group = rungroup),
                                              colour = "#E87722", linetype = 1, size = 1.2)

    runchart <- runchart +  ggplot2::geom_segment(data = susdf,
                                                  aes(x = enddate, xend = lastdate, y = improve,  yend = improve, group = rungroup),
                                                  colour = "#E87722",linetype = 2, size = 1.2)

    runchart <- runchart + ggplot2::ggtitle(label = chart_title, subtitle = chart_subtitle)
    #print(runchart)
    return(runchart)
  }


  if (faceted == TRUE) {
    build_facet(df, mr = med_rows,rl = runlength, ct = chart_title,
                cs = chart_subtitle, direct = direction, faceted = TRUE, n_facets = facet_cols)
  } else {
    ### first pass##
    df <- df %>% dplyr::arrange(date)
    enddate <- df[["date"]][med_rows]

    median_rows <- head(df,med_rows)
    median_rows[["baseline"]] <- median(median_rows[["y"]])

    Baseline <- median(head(df[["y"]],med_rows))

    StartBaseline <- Baseline

    flag_reset <- ifelse(direction != "above", flag_reset <- runlength * -1, runlength)
    remaining_rows <- dim(df)[1] - med_rows
    saved_sustained <- list()
    results <- list()
    i <- 1

    stopifnot(remaining_rows > runlength)


    testdata <- df[which(df[["date"]] > enddate),]
    testdata <- testdata[which(testdata[["y"]] != Baseline),]
    testdata[["flag"]] <- sign(testdata[["y"]] -  Baseline)
    testdata[["rungroup"]] <- myrleid(testdata[["flag"]])

    if (direction == "below") {
      testdata <- testdata %>%
        dplyr::group_by(grp,rungroup) %>%
        dplyr::mutate(cusum = cumsum_with_reset_neg(flag, flag_reset)) %>%
        dplyr::ungroup()
    } else {
      testdata <- testdata %>%
        dplyr::group_by(grp,rungroup) %>%
        dplyr::mutate(cusum = cumsum_with_reset(flag, flag_reset)) %>%
        dplyr::ungroup()
    }

    breakrow <- which.max(testdata[["cusum"]] == flag_reset)
    startrow <- breakrow - (abs(runlength) - 1)

    #  if no runs at all - print the chart
    #   return the chart object  so it can be modified by the user


    if (startrow < 0) {
      runchart <- baseplot(df, chart_title, chart_subtitle)
      print(runchart)
      message("no sustained runs found")
      results <- list(runchart = runchart, median_rows = median_rows, StartBaseline = StartBaseline)
      return(results)
    }


    #   if  we get to this point there is at least one run
    #   save the current sustained run, and the end date for future subsetting
    #   return the chart object  so it can be modified by the user
    #   return the sustained dataframe also


    startdate <- testdata[["date"]][startrow]
    enddate <-  testdata[["date"]][breakrow]
    tempdata <- testdata[startrow:breakrow,]
    tempdata[["improve"]] <- median(tempdata[["y"]])
    saved_sustained[[i]] <- tempdata

    Baseline <- median(tempdata[["y"]])
    testdata <- df[which(df[["date"]] > enddate),]
    remaining_rows <- dim(testdata)[1]

    # if not enough rows remaining, print the sustained run chart
    # return the run chart object
    # return the sustained dataframe

    if (remaining_rows < abs(runlength)) {

      sustained <- bind_rows(saved_sustained)

      ### make sure each rungroup is unique#####

      sustained <- sustained %>%
        dplyr::arrange(date) %>%
        dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag),abs(flag_reset)))
      ################################################

      sustained <- sustained %>%
        dplyr::group_by(grp,rungroup) %>%
        dplyr::mutate(startdate = min(date),
                      enddate = max(date),
                      lastdate = max(df[["date"]])) %>%
        dplyr::ungroup()


      runchart <- susplot(df, sustained)
      print(runchart)

      results <- list(runchart = runchart, sustained = sustained,
                      median_rows = median_rows, StartBaseline = StartBaseline)

      message("Improvements noted, not enough rows remaining for further analysis")
      return(results)

    }
    i <- i + 1

    remaining_rows <- dim(testdata)[1]
    while (remaining_rows >= runlength) {
      # if we still have enough rows remaining then we look for the next run

      {

        # return rows beyond the current end date

        testdata <- df[which(df[["date"]] > enddate),]
        testdata <- testdata[which(testdata[["y"]] != Baseline),]
        testdata[["flag"]] <- sign(testdata[["y"]] -  Baseline)
        testdata[["rungroup"]] <- myrleid(testdata[["flag"]])

        if (direction == "below") {
          testdata <- testdata %>%
            dplyr::group_by(grp,rungroup) %>%
            dplyr::mutate(cusum = cumsum_with_reset_neg(flag, flag_reset)) %>%
            dplyr::ungroup()
        } else {
          testdata <- testdata %>%
            dplyr::group_by(grp,rungroup) %>%
            dplyr::mutate(cusum = cumsum_with_reset(flag, flag_reset)) %>%
            dplyr::ungroup()
        }


        breakrow <- which.max(testdata[["cusum"]] == flag_reset)
        startrow <- breakrow - (abs(runlength) - 1)

        # if we get to this point, there is at least one sustained run
        #if there are no more runs of the required length, print sustained chart and quit

        if (startrow < 0) {

          #need to unlist the sustained rows
          sustained <- dplyr::bind_rows(saved_sustained)

          ### make sure each rungroup is unique#####

          sustained <- sustained %>%
            dplyr::arrange(date) %>%
            dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag),abs(flag_reset)))
          ################################################


          sustained <- sustained %>%
            dplyr::group_by(grp,rungroup) %>%
            dplyr::mutate(startdate = min(date),
                          enddate = max(date),
                          lastdate = max(df[["date"]])) %>%
            dplyr::ungroup()


          #now do sustained plot
          runchart <- susplot(df, sustained, chart_title,chart_subtitle)
          print(runchart)


          message("all sustained runs found, not enough rows remaining for further analysis")
          results <- list(runchart = runchart, sustained = sustained,
                          median_rows = median_rows, StartBaseline = StartBaseline)
          return(results)
          break
        }

        # else, carry on with processing the latest sustained run

        startdate <- testdata[["date"]][startrow]
        enddate <-  testdata[["date"]][breakrow]
        tempdata <- testdata[startrow:breakrow,]
        tempdata[["improve"]] <- median(tempdata[["y"]])
        saved_sustained[[i]] <- tempdata

        Baseline <- median(tempdata[["y"]])
        testdata <- df[which(df[["date"]] > enddate),]
        remaining_rows <- dim(testdata)[1]
        i <- i + 1

        # if not enough rows remaining now,  no need to analyse further
        # print the current sustained chart

        if (remaining_rows < abs(runlength)) {
          sustained <- bind_rows(saved_sustained)

          ### make sure each rungroup is unique#####

          sustained <- sustained %>%
            dplyr::arrange(date) %>%
            dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag),abs(flag_reset)))
          ################################################

          sustained <- sustained %>%
            dplyr::group_by(grp,rungroup) %>%
            dplyr::mutate(startdate = min(date),
                          enddate = max(date),
                          lastdate = max(df[["date"]])) %>%
            dplyr::ungroup()


          runchart <- susplot(df, sustained, chart_title,chart_subtitle)
          print(runchart)
          ##runchart <<- runchart
          ## sustained <<- sustained
          results <- list(runchart = runchart, sustained = sustained)
          message("all sustained runs found, not enough rows remaining for further analysis")
          return(results)
          break

          #stop("all sustained runs found, not enough remaining rows")
        }
        remaining_rows <- dim(testdata)[1]
      }
      remaining_rows <- dim(testdata)[1]
      if (remaining_rows < runlength) {
        break
      }
    }


  }

}



