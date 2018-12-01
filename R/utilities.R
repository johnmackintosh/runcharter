utils::globalVariables(c("Baseline", "Date", "EndDate", "StartBaseline", "baseline", "chart_title" ,"data","df",
                         "date_format", "enddate", "facet", "flag", "flag_reset", "improve", "lastdate", "median",
                         "med_rows","median_rows","out_group","runcharts", "rungroup", "runlength","tmpdata", "y"))


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

RobustMax <- function(x) {if (length(x) > 0) max(x) else -Inf}

RobustMin <- function(x) {if (length(x) > 0) min(x) else -Inf}

getmax <- function(x, runlength) {
  checkmax <- RobustMax(x)
  runlength <- runlength
  if (checkmax < runlength) {
    try("There are no more runs of the desired length")
  }
  checkmax
}

getmin <- function(x, runlength) {
  checkmin <- RobustMax(x)
  runlength <- runlength * -1
  if (checkmin > runlength) {
    try("There are no more runs of the desired length")
  }
  checkmin
}


build_facet <- function(df, mr, rl,ct,cs,direct, n_facets, ...) {

  by_ward <- df %>%
    mutate(out_group = grp) %>%
    group_by(out_group) %>%
    tidyr::nest()


  by_ward2 <- by_ward %>%
    mutate(runcharts = purrr::map(data,runcharter_facet,
                                  mr,
                                  rl,
                                  ct,
                                  cs,
                                  direct,
                                  n_facets))

  results <- by_ward2 %>% tidyr::unnest(out_group,.preserve = runcharts)

  median_rows <- dplyr::bind_rows(purrr::modify_depth(by_ward2$runcharts, 1, "median_rows"))
  sustained <- dplyr::bind_rows(purrr::modify_depth(by_ward2$runcharts, 1, "sustained"))
  StartBaseline <- unlist(purrr::modify_depth(by_ward2$runcharts, 1, "StartBaseline"))
  grp <- as.character(results$out_group)
  temp <- data.frame(grp,StartBaseline)
  temp$grp <- as.character(temp$grp)


  data <- bind_rows(results$data)
  data$grp <- as.character(data$grp)
  data <- left_join(data,temp, by = "grp")




  runchart <- ggplot2::ggplot(data, aes(date, y, group = 1)) +
    geom_line(colour = "#005EB8", size = 1.3)  +
    geom_point(shape = 21 , colour = "#005EB8", fill = "white", size = 3) +
    theme_minimal(base_size = 10) +
    theme(axis.text.y = element_text(angle = 0)) +
    theme(axis.text.x = element_text(angle = 90)) +
    theme(panel.grid.minor = element_blank(), panel.grid.major = element_blank()) +
    ggtitle(label = NULL,
            subtitle = NULL) +
    labs(x = "", y = "") +
    theme(legend.position = "bottom")

  runchart <- runchart + geom_line(data = median_rows,aes(x = date,y = baseline,group = grp),
                                   colour = "#E87722", size = 1.2,linetype = 1)


  runchart <- runchart + geom_line(data = data,aes(x = date, y = StartBaseline,
                                                   group = grp),
                                   colour = "#E87722", size = 1.2, linetype = 2)

  runchart <- runchart + geom_point(data = sustained, aes(x = date,y = y,group = rungroup),
                                    shape = 21, colour = "#005EB8", fill = "#DB1884" , size = 3.5)

  runchart <- runchart + geom_line(data = sustained,aes(x = date,y = improve,group = rungroup),
                                   colour = "#E87722", linetype = 1, size = 1.2)

  runchart <- runchart +  geom_segment(data = sustained,aes(x = enddate,xend = lastdate,y = improve, yend = improve, group = rungroup),
                                       colour = "#E87722",linetype = 2, size = 1.2)

  runchart <- runchart + ggtitle(label = ct,

                                 subtitle = cs)

  runchart <- runchart + facet_wrap(vars(grp),ncol = n_facets)
  print(runchart)
  results <- list()
  results <- list(runchart = runchart, median_rows = median_rows, sustained = sustained, StartBaseline = StartBaseline)
  return(results)
}
