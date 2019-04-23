utils::globalVariables(
  c(
    "Baseline",
    "Date",
    "EndDate",
    "StartBaseline",
    "baseline",
    "chart_title" ,
    "data",
    "df",
    "date_format",
    "enddate",
    "facet",
    "flag",
    "flag_reset",
    "improve",
    "lastdate",
    "median",
    "med_rows",
    "median_rows",
    "out_group",
    "runcharts",
    "rungroup",
    "runlength",
    "sp",
    "plot_ext",
    "tmpdata",
    "y"
  )
)


cumsum_with_reset <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()

  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]

    if (cumsum > threshold) {
      group <- group + 1
      cumsum <- x[i]
    }

    result = c(result, cumsum)

  }

  return(result)
}


cumsum_with_reset_neg <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()

  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]

    if (cumsum < threshold) {
      group <- group + 1
      cumsum <- x[i]
    }

    result = c(result, cumsum)

  }

  return(result)
}

cumsum_with_reset_group_neg <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()

  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]

    if (cumsum < threshold) {
      group <- group + 1
      cumsum <- x[i]
    }

    result = c(result, group)

  }

  return(result)
}

cumsum_with_reset_group <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()

  for (i in 1:length(x)) {
    cumsum <- cumsum + x[i]

    if (cumsum > threshold) {
      group <- group + 1
      cumsum <- x[i]
    }

    result = c(result, group)

  }

  return(result)
}




myrleid <- function(x) {
  x <- rle(x)$lengths
  rep(seq_along(x), times = x)
}

RobustMax <- function(x) {
  if (length(x) > 0)
    max(x)
  else-Inf
}

RobustMin <- function(x) {
  if (length(x) > 0)
    min(x)
  else-Inf
}




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
    df <- df %>% arrange(date)

    keep <- df %>% group_by(grp) %>% dplyr::count()
    keep <- keep %>% filter(n > (med_rows + runlength))
    keep <- keep %>% pull(grp)

    working_df <- df %>% filter(grp %in% keep)

    enddate <- working_df[["date"]][med_rows]

    median_rows <- head(working_df, med_rows)
    median_rows[["baseline"]] <- median(median_rows[["y"]])

    Baseline <- median(head(working_df[["y"]], med_rows))
    StartBaseline <- Baseline

    flag_reset <-
      ifelse(direction != "above", flag_reset <-
               runlength * -1, runlength)
    remaining_rows <- dim(working_df)[1] - med_rows
    saved_sustained <- list()
    results <- list()
    i <- 1



    ### first pass##

    if (!remaining_rows > runlength)
      stop("Not enough rows remaining beyond the baseline period")


    testdata <- df[which(working_df[["date"]] > enddate), ]
    testdata <- testdata[which(testdata[["y"]] != Baseline), ]

    if (dim(testdata)[1] < 1) {
      results <-
        list(median_rows = median_rows, StartBaseline = StartBaseline)
      return(results)
    }

    testdata[["flag"]] <- sign(testdata[["y"]] -  Baseline)
    testdata[["rungroup"]] <- myrleid(testdata[["flag"]])

    if (direction == "below") {
      testdata <- testdata %>%
        dplyr::group_by(grp, rungroup) %>%
        dplyr::mutate(cusum = cumsum_with_reset_neg(flag, flag_reset)) %>%
        dplyr::ungroup()
    } else {
      testdata <- testdata %>%
        dplyr::group_by(grp, rungroup) %>%
        dplyr::mutate(cusum = cumsum_with_reset(flag, flag_reset)) %>%
        dplyr::ungroup()
    }

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
    enddate <-  testdata[["date"]][breakrow]
    tempdata <- testdata[startrow:breakrow, ]
    tempdata[["improve"]] <- median(tempdata[["y"]])
    saved_sustained[[i]] <- tempdata

    Baseline <- median(tempdata[["y"]])
    testdata <- df[which(working_df[["date"]] > enddate), ]
    remaining_rows <- dim(testdata)[1]

    # if not enough rows remaining, print the sustained run chart
    # return the run chart object
    # return the sustained dataframe

    if (remaining_rows < abs(runlength)) {
      sustained <- bind_rows(saved_sustained)

      ### make sure each rungroup is unique#####

      sustained <- sustained %>%
        dplyr::arrange(date) %>%
        dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag), abs(flag_reset)))
      ################################################

      sustained <- sustained %>%
        dplyr::group_by(grp, rungroup) %>%
        dplyr::mutate(
          startdate = min(date),
          enddate = max(date),
          lastdate = max(df[["date"]])
        ) %>%
        dplyr::ungroup()


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
        # return rows beyond the current end date

        testdata <- working_df[which(working_df[["date"]] > enddate), ]
        testdata <- testdata[which(testdata[["y"]] != Baseline), ]

        #check that are still rows remaining in case all rows are equal to the baseline value

        if (dim(testdata)[1] < 1) {
          sustained <- bind_rows(saved_sustained)

          ### make sure each rungroup is unique#####

          sustained <- sustained %>%
            dplyr::arrange(date) %>%
            dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag), abs(flag_reset)))
          ################################################

          sustained <- sustained %>%
            dplyr::group_by(grp, rungroup) %>%
            dplyr::mutate(
              startdate = min(date),
              enddate = max(date),
              lastdate = max(df[["date"]])
            ) %>%
            dplyr::ungroup()

          results <- list(
            sustained = sustained,
            median_rows = median_rows,
            StartBaseline = StartBaseline
          )
          return(results)
        }


        testdata[["flag"]] <- sign(testdata[["y"]] -  Baseline)
        testdata[["rungroup"]] <- myrleid(testdata[["flag"]])

        if (direction == "below") {
          testdata <- testdata %>%
            dplyr::group_by(grp, rungroup) %>%
            dplyr::mutate(cusum = cumsum_with_reset_neg(flag, flag_reset)) %>%
            dplyr::ungroup()
        } else {
          testdata <- testdata %>%
            dplyr::group_by(grp, rungroup) %>%
            dplyr::mutate(cusum = cumsum_with_reset(flag, flag_reset)) %>%
            dplyr::ungroup()
        }


        breakrow <- which.max(testdata[["cusum"]] == flag_reset)
        startrow <- breakrow - (abs(runlength) - 1)

        # if we get to this point, there is at least one sustained run
        #if there are no more runs of the required length, print sustained chart and quit

        if (startrow < 1) {
          #need to unlist the sustained rows
          sustained <- dplyr::bind_rows(saved_sustained)

          ### make sure each rungroup is unique#####

          sustained <- sustained %>%
            dplyr::arrange(date) %>%
            dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag), abs(flag_reset)))
          ################################################


          sustained <- sustained %>%
            dplyr::group_by(grp, rungroup) %>%
            dplyr::mutate(
              startdate = min(date),
              enddate = max(date),
              lastdate = max(df[["date"]])
            ) %>%
            dplyr::ungroup()


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
          enddate <-  testdata[["date"]][breakrow]
          tempdata <- testdata[startrow:breakrow, ]
          tempdata[["improve"]] <- median(tempdata[["y"]])
          saved_sustained[[i]] <- tempdata

          Baseline <- median(tempdata[["y"]])
          testdata <-
            working_df[which(working_df[["date"]] > enddate), ]
          remaining_rows <- dim(testdata)[1]
          i <- i + 1
        }

        # if not enough rows remaining now,  no need to analyse further
        # print the current sustained chart

        if (remaining_rows < abs(runlength)) {
          sustained <- bind_rows(saved_sustained)

          ### make sure each rungroup is unique#####

          sustained <- sustained %>%
            dplyr::arrange(date) %>%
            dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag), abs(flag_reset)))
          ################################################

          sustained <- sustained %>%
            dplyr::group_by(grp, rungroup) %>%
            dplyr::mutate(
              startdate = min(date),
              enddate = max(date),
              lastdate = max(df[["date"]])
            ) %>%
            dplyr::ungroup()


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









build_facet <-
  function(df,
           mr,
           rl,
           ct,
           cs,
           direct,
           n_facets,
           sp,
           plot_extension,
           ...) {
    df[["grp"]] <-  as.character(df[["grp"]])

    keep <- df %>% group_by(grp) %>% dplyr::count()
    keep <- keep %>% filter(n > (mr + rl))
    keep <- keep %>% pull(grp)

    working_df <- df %>% filter(grp %in% keep)

    by_grp <- working_df %>%
      dplyr::mutate(out_group = grp) %>%
      dplyr::group_by(out_group) %>%
      tidyr::nest()


    by_grp2 <- by_grp %>%
      dplyr::mutate(
        runcharts = purrr::map(
          data,
          runcharter_facet,
          mr,
          rl,
          ct,
          cs,
          direct,
          n_facets,
          sp,
          plot_extension
        )
      )


    results <-
      by_grp2 %>% tidyr::unnest(out_group, .preserve = runcharts)

    median_rows <-
      dplyr::bind_rows(purrr::modify_depth(by_grp2[["runcharts"]], 1, "median_rows"))
    sustained <-
      dplyr::bind_rows(purrr::modify_depth(by_grp2[["runcharts"]], 1,
                                           .f = ~ as.data.frame(.["sustained"])))

    colnames(sustained) <-
      c(
        'grp',
        'y',
        'date',
        'flag',
        'rungroup',
        'cusum',
        'improve',
        'startdate',
        'enddate',
        'lastdate'
      )

    StartBaseline <-
      unlist(purrr::modify_depth(by_grp2[["runcharts"]], 1, "StartBaseline"))
    grp <- as.character(results[["out_group"]])
    temp <- data.frame(grp, StartBaseline)
    temp[["grp"]] <- as.character(temp[["grp"]])


    data <- bind_rows(results[["data"]])
    data[["grp"]] <- as.character(data[["grp"]])
    data <- left_join(data, temp, by = "grp")




    filename <- paste0("facet_plot", ".", plot_extension)



    runchart <- ggplot2::ggplot(data, aes(date, y, group = 1)) +
      ggplot2::geom_line(colour = "#005EB8", size = 1.1)  +
      ggplot2::geom_point(
        shape = 21 ,
        colour = "#005EB8",
        fill = "#005EB8",
        size = 2.5
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::theme(axis.text.y = element_text(angle = 0)) +
      ggplot2::theme(axis.text.x = element_text(angle = 90)) +
      ggplot2::theme(panel.grid.minor = element_blank(),
                     panel.grid.major = element_blank()) +
      ggplot2::labs(x = "", y = "") +
      ggplot2::theme(legend.position = "bottom")

    runchart <-
      runchart + ggplot2::geom_line(
        data = median_rows,
        aes(x = date, y = baseline, group = grp),
        colour = "#E87722",
        size = 1.05,
        linetype = 1
      )


    runchart <-
      runchart + ggplot2::geom_line(
        data = data,
        aes(x = date, y = StartBaseline,
            group = grp),
        colour = "#E87722",
        size = 1.05,
        linetype = 2
      )


    # if there are no sustained runs, plot now

    if (dim(sustained)[1] == 0) {
      runchart <- runchart + ggplot2::ggtitle(label = ct, subtitle = cs)

      runchart <-
        runchart + ggplot2::facet_wrap(vars(grp), ncol = n_facets)
      results <-
        list(
          runchart = runchart,
          median_rows = median_rows,
          StartBaseline = StartBaseline
        )

      if (sp) {
        ggsave(filename)
      }

      return(results)
    } else {
      runchart <-
        runchart + ggplot2::geom_point(
          data = sustained,
          aes(x = date, y = y, group = rungroup),
          shape = 21,
          colour = "#005EB8",
          fill = "#DB1884" ,
          size = 2.7
        )

      runchart <-
        runchart + ggplot2::geom_line(
          data = sustained,
          aes(x = date, y = improve, group = rungroup),
          colour = "#E87722",
          linetype = 1,
          size = 1.05
        )

      runchart <-
        runchart +  ggplot2::geom_segment(
          data = sustained,
          aes(
            x = enddate,
            xend = lastdate,
            y = improve,
            yend = improve,
            group = rungroup
          ),
          colour = "#E87722",
          linetype = 2,
          size = 1.05
        )

      runchart <-
        runchart + ggplot2::ggtitle(label = ct, subtitle = cs)

      runchart <-
        runchart + ggplot2::facet_wrap(vars(grp), ncol = n_facets)

      results <-
        list(
          runchart = runchart,
          median_rows = median_rows,
          sustained = sustained,
          StartBaseline = StartBaseline
        )


      if (sp) {
        ggsave(filename)
      }


      return(results)
    }
  }
