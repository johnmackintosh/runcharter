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
    
    
    plot_data <- bind_rows(results[["data"]])
    plot_data[["grp"]] <- as.character(plot_data[["grp"]])
    plot_data <- left_join(plot_data, temp, by = "grp")
    
    
    
    
    filename <- paste0("facet_plot", ".", plot_extension)
    
    
    
    runchart <- ggplot2::ggplot(plot_data, aes(date, y, group = 1)) +
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
    
    runchart <- runchart + 
      ggplot2::geom_line(
        data = median_rows,
        aes(x = date, y = baseline, group = grp),
        colour = "#E87722",
        size = 1.05,
        linetype = 1
      )
    
    
    runchart <-
      runchart + ggplot2::geom_line(
        data = plot_data,
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
      
      
      # summarise sustained dataframe for plotting
      summary_sustained <- sustained %>%
        dplyr::group_by(grp,rungroup, improve,startdate,enddate,lastdate) %>%
        dplyr::summarise() %>%
        dplyr::ungroup() %>%
        dplyr::group_by(grp) %>%
        dplyr::mutate(runend = lead(enddate)) %>%
        dplyr::ungroup() %>%
        dplyr::mutate(runend = case_when
                      (!is.na(runend) ~ runend,
                        TRUE ~ max(plot_data$date)))
      
      runchart <- ggplot2::ggplot(plot_data, aes(date, y, group = 1)) +
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
        runchart + ggplot2::geom_point(
          data = sustained,
          aes(x = date, y = y, group = rungroup),
          shape = 21,
          colour = "#005EB8",
          fill = "#DB1884" ,
          size = 2.7
        )
      
      
      runchart <-
        runchart + ggplot2::ggtitle(label = ct, subtitle = cs)
      
      runchart <-
        runchart + ggplot2::facet_wrap(vars(grp), ncol = n_facets)
      
      # sustained median lines
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
      runchart <-
        runchart +  ggplot2::geom_segment(
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
      
      remaining <- dplyr::anti_join(plot_data,sustained,
                                    by = c("grp", "y", "date"))
      
      #experimental
      remaining <- dplyr::anti_join(remaining,median_rows,
                                    by = c("grp", "y", "date"))
      
      temp_summary_sustained <- summary_sustained %>%
        dplyr::group_by(grp) %>%
        dplyr::filter(startdate == min(startdate)) %>%
        dplyr::select(grp,startdate) %>% 
        ungroup()
      
      finalrows <- dplyr::left_join(remaining, temp_summary_sustained,
                                    by = "grp")
      
      
      
      sus_grps <- temp_summary_sustained %>%
        select(grp) %>%
        pull
      
      non_sus_grps <- finalrows %>%
        filter(!grp %in% sus_grps)
      
      
      runchart <- runchart  + ggplot2::geom_segment(
        data = finalrows,
        na.rm = TRUE,
        aes(x = min(finalrows$date),
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
        aes(x = date,
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
        ggsave(filename)
      }
      
      
      return(results)
    }
  }