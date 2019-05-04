runcharter_facet <-
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
    
    df <- df %>% dplyr::arrange(date) %>%
      dplyr::select(grp,y,date)


    keep_df <- df %>% dplyr::group_by(grp) %>% dplyr::count()
    keep_df <- keep_df %>% dplyr::filter(n > (med_rows + runlength))
    keep_df <- keep_df %>% dplyr::pull(grp)

    working_df <- df %>% dplyr::filter(grp %in% keep_df)

    
    enddate <- getenddate(working_df,x = "date",
                          y = med_rows)
    
    median_rows <- utils::head(working_df, med_rows)
    median_rows[["baseline"]] <- stats::median(median_rows[["y"]], 
                                               na.rm = TRUE)
    
    Baseline <- stats::median(utils::head(working_df[["y"]],med_rows),
                              na.rm = TRUE)
    StartBaseline <- Baseline
    
    flag_reset <- ifelse(direction == "below",
                         runlength * -1, runlength)
    
    remaining_rows <- dim(working_df)[1] - med_rows
    saved_sustained <- list()
    results <- list()
    i <- 1
    
    
    
    
    ### first pass##
    
    if (!remaining_rows > runlength)
      stop("Not enough rows remaining beyond the baseline period")
    
    testdata <- extractor(working_df, enddt = enddate, x = Baseline)
    
    if (dim(testdata)[1] < 1) {
      results <-
        list(median_rows = median_rows, StartBaseline = StartBaseline)
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
      results <-
        list(median_rows = median_rows, StartBaseline = StartBaseline)
      return(results)
    }
    
    
    #   if  we get to this point there is at least one run
    #   save the current sustained run, and the end date for future subsetting
    #   return the chart object  so it can be modified by the user
    #   return the sustained dataframe also
    
    
    startdate <- testdata[["date"]][startrow]
    enddate <-   getenddate(testdata,x = "date", y = breakrow)
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
      sustained <- dplyr::bind_rows(saved_sustained)
      sustained <- sustained_processing(sustained, flag,flag_reset)
      
      
      results <- list(
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
        
        testdata <- extractor(working_df, enddt = enddate, x = Baseline)
        
        #check that are still rows remaining in case
        # all rows are equal to the baseline value
        
        if (dim(testdata)[1] < 1) {
          sustained <- dplyr::bind_rows(saved_sustained)
          sustained <- sustained_processing(sustained, flag, flag_reset)
          
          
          results <- list(
            sustained = sustained,
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
        
        # if we get to this point, there is at least one sustained run
        #if there are no more runs of the required length, 
        # print sustained chart and quit
        
        if (startrow < 1) {
          #need to unlist the sustained rows
          sustained <- dplyr::bind_rows(saved_sustained)
          sustained <- sustained_processing(sustained, flag, flag_reset)
          
          results <- list(
            sustained = sustained,
            median_rows = median_rows,
            StartBaseline = StartBaseline
          )
          return(results)
          #break
        } else {
          # else, carry on with processing the latest sustained run
          
          startdate <- testdata[["date"]][startrow]
          enddate <-  getenddate(testdata,x = "date", y = breakrow)
          tempdata <- testdata[startrow:breakrow, ]
          tempdata[["improve"]] <- median(tempdata[["y"]], na.rm = TRUE)
          saved_sustained[[i]] <- tempdata
          
          Baseline <- median(tempdata[["y"]],na.rm = TRUE)
          testdata <- extractor(working_df, enddt = enddate, x = Baseline)
          remaining_rows <- dim(testdata)[1]
          i <- i + 1
        }
        
        # if not enough rows remaining now,  no need to analyse further
        # print the current sustained chart
        
        if (remaining_rows < abs(runlength)) {
          sustained <- dplyr::bind_rows(saved_sustained)
          sustained <- sustained_processing(sustained, flag, flag_reset)
          
          results <- list(
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


