baseplot <- function(df,med_df, x, y, ct, cs, sb,  ...) {
  
  runchart <- ggplot2::ggplot(df, aes(x = date, y = df[["y"]], group = 1)) +
    ggplot2::geom_line(colour = "#005EB8", size = 1.1)  +
    ggplot2::geom_point(
      shape = 21 ,
      colour = "#005EB8",
      fill = "#005EB8",
      size = 2.5
    ) +
    ggplot2::theme_minimal(base_size = 10) +
    theme(axis.text.y = element_text(angle = 0)) +
    theme(axis.text.x = element_text(angle = 90)) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_blank()) +
    ggplot2::ggtitle(label = ct,
                     subtitle = cs) +
    ggplot2::labs(x = "", y = "") +
    theme(legend.position = "bottom")
  
  runchart <- runchart + ggplot2::geom_line(
    data = med_df,
    aes(x = date, y = med_df[["baseline"]], group = 1),
    colour = "#E87722",
    size = 1.05,
    linetype = 1
  )
  
  runchart <- runchart + ggplot2::geom_line(
    data = df,
    aes(x = date, y = sb, group = 1),
    colour = "#E87722",
    size = 1.05,
    linetype = 2
  )
  
  
  return(runchart)
}


baseplot2 <- function(df, med_df, x, y, ct, cs,  ...) {
  
  runchart <- ggplot2::ggplot(df, aes(x = date, y = df[["y"]], group = 1)) +
    ggplot2::geom_line(colour = "#005EB8", size = 1.1)  +
    ggplot2::geom_point(
      shape = 21 ,
      colour = "#005EB8",
      fill = "#005EB8",
      size = 2.5) +
    ggplot2::theme_minimal(base_size = 10) +
    theme(axis.text.y = element_text(angle = 0)) +
    theme(axis.text.x = element_text(angle = 90)) +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_blank()) +
    ggplot2::ggtitle(label = ct,
                     subtitle = cs) +
    ggplot2::labs(x = "", y = "") +
    theme(legend.position = "bottom")
  
  runchart <- runchart + ggplot2::geom_line(
    data = med_df,
    aes(x = date, y = med_df[["baseline"]], group = 1),
    colour = "#E87722",
    size = 1.05,
    linetype = 1
  )
  
  return(runchart)
}


susplot <- function(df, 
                    med_df, 
                    susdf, 
                    grp1 = grp,
                    rungrp = rungroup,
                    imprv = improve,
                    strtdt = startdate,
                    enddt = enddate,
                    lstdt = lastdate,
                    y = y,
                    ct, 
                    cs, 
                    sb = StartBaseline,
                    ...) {
  
  summary_sustained <- susdf %>%
    dplyr::group_by(grp,
                    rungroup, 
                    improve,
                    startdate,
                    enddate,
                    lastdate) %>%
    dplyr::summarise() %>%
    dplyr::ungroup() %>%
    dplyr::group_by(grp) %>%
    dplyr::mutate(runend = dplyr::lead(enddate)) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(runend = case_when
                  (!is.na(runend) ~ runend,
                    TRUE ~ max(df$date)))
  
  
  
  runchart <- baseplot2(df, med_df,
                        x = date,  y = df[["y"]],
                        ct, cs, ...)
  
  
  # sustained points
  runchart <-
    runchart + ggplot2::geom_point(
      data = susdf,
      aes(x = date, y = y, group = rungroup),
      shape = 21,
      colour = "#005EB8",
      fill = "#DB1884" ,
      size = 2.7
    )
  
  
  # new sustained baseline
  runchart <-
    runchart + ggplot2::geom_segment(
      data = summary_sustained,
      na.rm = TRUE,
      aes(x = startdate,
          xend = enddate,
          y = improve,
          yend = improve,
          group = rungroup),
      colour = "#E87722",
      linetype = 1,
      size = 1.05
    )
  
  # extended baseline from last improvement to end
  runchart <- runchart +  ggplot2::geom_segment(
    data = summary_sustained,
    na.rm = TRUE,
    aes(
      x = enddate,
      xend = runend,
      y = improve,
      yend = improve,
      group = rungroup
    ),
    colour = "#E87722",
    linetype = 2,
    size = 1.05
  )
  
  remaining <- dplyr::anti_join(df,susdf,
                                by = c("grp", "y", "date"))
  
  remaining <- dplyr::anti_join(remaining,med_df,
                                by = c("grp", "y", "date"))
  
  temp_summary_sustained <- summary_sustained %>%
    group_by(grp) %>%
    filter(startdate == min(startdate)) %>%
    select(grp,startdate)
  
  finalrows <- dplyr::left_join(remaining, temp_summary_sustained,
                                by = "grp")
  
  
  finalstartx <- finalrows %>%
    select(date) %>%
    summarise(mindate = min(date)) %>%
    pull()
  
  # intervening rows from original baseline to new baseline
  runchart <- runchart  + ggplot2::geom_segment(
    data = finalrows,
    na.rm = TRUE,
    aes(x = finalstartx,
        xend = startdate,
        y = sb,
        yend = sb,
        group = grp),
    colour = "#E87722",
    linetype = 2,
    size = 1.05
  )
  
  runchart <-
    runchart + ggplot2::ggtitle(label = ct,
                                subtitle = cs)
  return(runchart)
}