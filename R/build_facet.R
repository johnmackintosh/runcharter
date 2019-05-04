build_facet <-
  function(df,
           mr,
           rl,
           ct,
           cs,
           direct,
           n_facets,
           sp,
           pe,
           ...) {
    df[["grp"]] <-  as.character(df[["grp"]])
    
    keep_df <- df %>% dplyr::group_by(grp) %>% dplyr::count()
    keep_df <- keep_df %>% dplyr::filter(n > (mr + rl))
    keep_df <- keep_df %>% dplyr::pull(grp)
    
    working_df <- df %>% dplyr::filter(grp %in% keep_df)
    
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
          pe
        )
      )
    
    
    results <-
      by_grp2 %>% tidyr::unnest(out_group, .preserve = runcharts)
    
    median_rows <-
      dplyr::bind_rows(purrr::modify_depth(by_grp2[["runcharts"]], 
                                           1, "median_rows"))
    sustained <-
      dplyr::bind_rows(purrr::modify_depth(by_grp2[["runcharts"]], 1,
                                        .f = ~ as.data.frame(.["sustained"])))
    StartBaseline <-
      unlist(purrr::modify_depth(by_grp2[["runcharts"]], 1, "StartBaseline"))
    grp <- as.character(results[["out_group"]])
    temp <- data.frame(grp, StartBaseline)
    temp[["grp"]] <- as.character(temp[["grp"]])
    
    plot_data <- dplyr::bind_rows(results[["data"]])
    plot_data[["grp"]] <- as.character(plot_data[["grp"]])
    plot_data <- dplyr::left_join(plot_data, temp, by = "grp")
    
    
    
    
    filename <- paste0("facet_plot", ".", pe)
    
    
    runchart <- ggplot2::ggplot(plot_data, ggplot2::aes(date, y, group = 1)) +
      ggplot2::geom_line(colour = "#005EB8", size = 1.1)  +
      ggplot2::geom_point(
        shape = 21 ,
        colour = "#005EB8",
        fill = "#005EB8",
        size = 2.5
      ) +
      ggplot2::theme_minimal(base_size = 10) +
      ggplot2::theme(axis.text.y = ggplot2::element_text(angle = 0)) +
      ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90)) +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                     panel.grid.major = ggplot2::element_blank()) +
      ggplot2::labs(x = "", y = "") +
      ggplot2::theme(legend.position = "bottom")
    
    runchart <- runchart + 
      ggplot2::geom_line(
        data = median_rows,
        ggplot2::aes(x = date, y = baseline, group = grp),
        colour = "#E87722",
        size = 1.05,
        linetype = 1
      )
    
    
    runchart <-
      runchart + ggplot2::geom_line(
        data = plot_data,
        ggplot2::aes(x = date, y = StartBaseline,
            group = grp),
        colour = "#E87722",
        size = 1.05,
        linetype = 2
      )
    
    
    # if there are no sustained runs, plot now
    
    if (dim(sustained)[1] == 0) {
      runchart <- runchart + ggplot2::ggtitle(label = ct, subtitle = cs)
      
      runchart <-
        runchart + ggplot2::facet_wrap(ggplot2::vars(grp), ncol = n_facets)
      results <-
        list(
          runchart = runchart,
          median_rows = median_rows,
          StartBaseline = StartBaseline
        )
      
      if (sp) {
        ggplot2::ggsave(filename)
      }
      
      return(results)
    } else {
      
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
      
      # summarise sustained dataframe for plotting
      summary_sustained <- sustained %>%
        dplyr::group_by(grp,rungroup, improve,startdate,enddate,lastdate) %>%
        dplyr::summarise() %>%
        dplyr::ungroup() %>%
        dplyr::group_by(grp) %>%
        dplyr::mutate(runend = dplyr::lead(enddate)) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(runend = dplyr::case_when
                      (!is.na(runend) ~ runend,
                        TRUE ~ max(plot_data$date)))
      
      runchart <- ggplot2::ggplot(plot_data, ggplot2::aes(date, y, group = 1)) +
        ggplot2::geom_line(colour = "#005EB8", size = 1.1)  +
        ggplot2::geom_point(
          shape = 21 ,
          colour = "#005EB8",
          fill = "#005EB8",
          size = 2.5
        ) +
        ggplot2::theme_minimal(base_size = 10) +
        ggplot2::theme(axis.text.y = ggplot2::element_text(angle = 0)) +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90)) +
        ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                       panel.grid.major = ggplot2::element_blank()) +
        ggplot2::labs(x = "", y = "") +
        ggplot2::theme(legend.position = "bottom")
      
      runchart <-
        runchart + ggplot2::geom_line(
          data = median_rows,
          ggplot2::aes(x = date, y = baseline, group = grp),
          colour = "#E87722",
          size = 1.05,
          linetype = 1
        )
      
      
      runchart <-
        runchart + ggplot2::geom_point(
          data = sustained,
          ggplot2::aes(x = date, y = y, group = rungroup),
          shape = 21,
          colour = "#005EB8",
          fill = "#DB1884" ,
          size = 2.7
        )
      
      
      runchart <-
        runchart + ggplot2::ggtitle(label = ct, subtitle = cs)
      
      runchart <-
        runchart + ggplot2::facet_wrap(ggplot2::vars(grp), ncol = n_facets)
      
      # sustained median lines
      runchart <-
        runchart + ggplot2::geom_segment(
          data = summary_sustained,
          na.rm = TRUE,
          ggplot2::aes(x = startdate,
              xend = enddate,
              y = improve,
              yend = improve,
              group = rungroup),
          colour = "#E87722",
          linetype = 1,
          size = 1.05
        )
      
      # extended baseline from last improvement to end
      runchart <-
        runchart +  ggplot2::geom_segment(
          data = summary_sustained,
          na.rm = TRUE,
          ggplot2::aes(
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
      
      remaining <- dplyr::anti_join(plot_data,sustained,
                                    by = c("grp", "y", "date"))
      
      #experimental
      remaining <- dplyr::anti_join(remaining,median_rows,
                                    by = c("grp", "y", "date"))
      
      temp_summary_sustained <- summary_sustained %>%
        dplyr::group_by(grp) %>%
        dplyr::filter(startdate == min(startdate)) %>%
        dplyr::select(grp,startdate) %>% 
        dplyr::ungroup()
      
      finalrows <- dplyr::left_join(remaining, temp_summary_sustained,
                                    by = "grp")
      
      
      
      sus_grps <- temp_summary_sustained %>%
        dplyr::select(grp) %>%
        dplyr::pull()
      
      non_sus_grps <- finalrows %>%
        dplyr::filter(!grp %in% sus_grps)
      
      
      runchart <- runchart  + ggplot2::geom_segment(
        data = finalrows,
        na.rm = TRUE,
        ggplot2::aes(x = min(finalrows$date),
            xend = startdate,
            y = StartBaseline,
            yend = StartBaseline,
            group = grp),
        colour = "#E87722",
        linetype = 2,
        size = 1.05
      )
      
      runchart <- runchart  + ggplot2::geom_line(
        data = non_sus_grps,
        ggplot2::aes(x = date,
            y = StartBaseline,
            group = grp),
        colour = "#E87722",
        linetype = 2,
        size = 1.05
      )
      
      
      
      results <-
        list(
          runchart = runchart,
          median_rows = median_rows,
          sustained = sustained,
          StartBaseline = StartBaseline
        )
      
      
      if (sp) {
        ggplot2::ggsave(filename)
      }
      
      
      return(results)
    }
  }
