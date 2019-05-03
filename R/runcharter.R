
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
#' @import ggplot2
#' @import dplyr
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
    
    
    group_count <-  df %>%
      dplyr::select(grp) %>%
      dplyr::n_distinct()
    
    if (faceted == TRUE & group_count > 1) {
      build_facet(
        df,
        mr = med_rows,
        rl = runlength,
        ct = chart_title,
        cs = chart_subtitle,
        direct = direction,
        faceted = TRUE,
        n_facets = facet_cols,
        sp = save_plot,
        plot_extension
      )
    } else {
      # setup
      df <- df %>% dplyr::arrange(date)
      df[["grp"]] <-  as.character(df[["grp"]])
      
      keep <- df %>% group_by(grp) %>% dplyr::count()
      keep <- keep %>% filter(n >= (med_rows + runlength))
      keep <- keep %>% pull(grp)
      
      working_df <- df %>% filter(grp %in% keep)
      
      enddate <- getenddate(working_df,x = "date",
                            y = med_rows)
      
      median_rows <- head(working_df, med_rows)
      median_rows[["baseline"]] <- median(median_rows[["y"]], na.rm = TRUE)
      
      Baseline <- median(head(working_df[["y"]],med_rows),na.rm = TRUE)
      
      StartBaseline <- Baseline
      
      flag_reset <-
        ifelse(direction == "below", runlength * -1, runlength)
      remaining_rows <- dim(working_df)[1] - med_rows
      saved_sustained <- list()
      results <- list()
      i <- 1
      
      current_grp <- unique(df[["grp"]])
      filename <- paste0(current_grp, ".", plot_extension)
      
      
      ### first pass##
      
      if (!remaining_rows > runlength)
        stop("Not enough rows remaining beyond the baseline period")
      
      
      testdata <- extractor(working_df, enddt = enddate,  x = Baseline)
      
      if (dim(testdata)[1] < 1) {
        runchart <- baseplot(df,
                             x = date,
                             y = y,
                             med_df = median_rows,
                             #baseval = baseline,
                             ct = chart_title,
                             cs = chart_subtitle,
                             sb = StartBaseline)
        if (!faceted) {
          #print(runchart)
          if (save_plot) {
            ggsave(filename)
          }
          message("no sustained runs found")
        }
        results <-
          list(
            runchart = runchart,
            median_rows = median_rows,
            StartBaseline = StartBaseline
          )
        return(results)
      }
      
      testdata <- testdata_setup(testdata,
                                 targetval = Baseline, 
                                 direct = direction,
                                 rl = runlength, 
                                 fr = flag_reset)
      
      breakrow <- which.max(testdata[["cusum"]] == flag_reset)
      startrow <- breakrow - (abs(runlength) - 1)
      
      #  if no runs at all - print the chart
      #   return the chart object  so it can be modified by the user
      
      
      if (startrow < 1) {
        runchart <- baseplot(df,
                             x = date,
                             y = y,
                             med_df = median_rows,
                             #baseval = baseline,
                             ct = chart_title,
                             cs = chart_subtitle,
                             sb = StartBaseline)
        if (!faceted) {
          #print(runchart)
          if (save_plot) {
            ggsave(filename)
          }
          message("no sustained runs found")
        }
        
        # results <- build_results(rc = runchart, 
        #                          mr = median_rows,
        #                          sb = StartBaseline)  
        
        results <- list(
          runchart = runchart,
          median_rows = median_rows,
          StartBaseline = StartBaseline
        )
        return(results)
      }
      
      
      #   if  we get to this point there is at least one run
      #   save the current sustained run, and the end date for future subsetting
      #   return the chart object  so it can be modified by the user
      #   return the sustained dataframe also
      
      
      startdate <- testdata[["date"]][startrow]
      enddate <- getenddate(testdata,x = "date", y = breakrow)
      tempdata <- testdata[startrow:breakrow, ]
      tempdata[["improve"]] <- median(tempdata[["y"]], na.rm = TRUE)
      saved_sustained[[i]] <- tempdata
      
      Baseline <- median(tempdata[["y"]],na.rm = TRUE)
      
      testdata <- extractor(working_df, enddt = enddate, x = Baseline)
      
      remaining_rows <- dim(testdata)[1]
      
      # if not enough rows remaining, print the sustained run chart
      # return the run chart object
      # return the sustained dataframe
      
      if (remaining_rows < abs(runlength)) {
        sustained <- bind_rows(saved_sustained)
        
        sustained <- sustained_processing(sustained,flag,
                                          flag_reset)
        
        runchart <- susplot(df,
                            med_df = median_rows,
                            #baseval = baseline,
                            susdf = sustained,
                            ct = chart_title,
                            cs = chart_subtitle,
                            sb = StartBaseline)
        if (!faceted) {
          #print(runchart)
          if (save_plot) {
            ggsave(filename)
          }
          
          message("Improvements noted, not enough rows remaining for further analysis")
        }
        
        results <- list(
          runchart = runchart,
          sustained = sustained,
          median_rows = median_rows,
          StartBaseline = StartBaseline
        )
        return(results)
        
      }
      i <- i + 1
      
      remaining_rows <- dim(testdata)[1]
      while (remaining_rows >= runlength) {
        # if we still have enough rows remaining then we look for the next run
        
        {
          # return rows beyond the current end date
          testdata <- extractor(working_df, enddt = enddate, x = Baseline)
          
          # check that are still rows remaining in case all
          # rows are equal to the baseline value
          
          
          
          if (dim(testdata)[1] < 1) {
            sustained <- bind_rows(saved_sustained)
            
            sustained <- sustained_processing(sustained,flag,
                                              flag_reset)
            
            runchart <- susplot(df,
                                med_df = median_rows,
                                #baseval = baseline,
                                susdf = sustained,
                                ct = chart_title,
                                cs = chart_subtitle,
                                sb = StartBaseline)
            if (!facet_cols) {
              # print(runchart)
              if (save_plot) {
                ggsave(filename)
              }
              message("Improvements noted, not enough rows remaining for further analysis")
            }
            results <-
              list(
                runchart = runchart,
                sustained = sustained,
                median_rows = median_rows,
                StartBaseline = StartBaseline
              )
            return(results)
          }
          
          
          # repeat the set up and check for runs of correct length
          
          testdata <- testdata_setup(testdata,
                                     targetval = Baseline, 
                                     direct = direction,
                                     rl = runlength, 
                                     fr = flag_reset)
          
          breakrow <- which.max(testdata[["cusum"]] == flag_reset)
          startrow <- breakrow - (abs(runlength) - 1)
          
          # if there are no more runs of the required length,
          # print sustained chart and quit
          
          if (startrow < 1) {
            #need to unlist the sustained rows
            sustained <- dplyr::bind_rows(saved_sustained)
            
            sustained <- sustained_processing(sustained,flag,
                                              flag_reset)
            
            #now do sustained plot
            runchart <- susplot(df,
                                med_df = median_rows,
                                #baseval = median_rows[["baseline"]],
                                susdf = sustained,
                                ct = chart_title,
                                cs = chart_subtitle,
                                sb = StartBaseline)
            if (!faceted) {
              #print(runchart)
              if (save_plot) {
                ggsave(filename)
              }
              
              message("all sustained runs found, not enough rows remaining for analysis")
            }
            results <-
              list(
                runchart = runchart,
                sustained = sustained,
                median_rows = median_rows,
                StartBaseline = StartBaseline
              )
            return(results)
            break
          }
          
          # else, carry on with processing the latest sustained run
          
          startdate <- testdata[["date"]][startrow]
          enddate <-   getenddate(testdata,x = "date", y = breakrow)
          tempdata <- testdata[startrow:breakrow, ]
          tempdata[["improve"]] <- median(tempdata[["y"]], na.rm = TRUE)
          saved_sustained[[i]] <- tempdata
          
          Baseline <- median(tempdata[["y"]],na.rm = TRUE)
          testdata <- extractor(working_df, enddt = enddate, x = Baseline)
          
          remaining_rows <- dim(testdata)[1]
          i <- i + 1
          
          # if not enough rows remaining now,  no need to analyse further
          # print the current sustained chart
          
          if (remaining_rows < abs(runlength)) {
            sustained <- bind_rows(saved_sustained)
            
            sustained <- sustained_processing(sustained,flag,
                                              flag_reset)
            
            
            runchart <- susplot(df,
                                med_df = median_rows,
                                #baseval = baseline,
                                susdf = sustained,
                                ct = chart_title,
                                cs = chart_subtitle,
                                sb = StartBaseline)
            
            if (!faceted) {
              #print(runchart)
              
              if (save_plot) {
                ggsave(filename)
              }
              
              message("all sustained runs found, not enough rows remaining for analysis")
            }
            results <-
              list(
                runchart = runchart,
                sustained = sustained,
                median_rows = median_rows,
                StartBaseline = StartBaseline
              )
            return(results)
            break
            
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