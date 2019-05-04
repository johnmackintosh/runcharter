
extractor <- function(df = working_df, enddt = NULL, x ){
  testdata <- df[which(df[["date"]] > enddt), ]
  testdata <- testdata[which(testdata[["y"]] != x), ]
  testdata <- testdata %>%
    dplyr::select(grp,y,date)
  
}

testdata_setup <- function(testdata, targetval,direct, rl, fr) {
  testdata[["flag"]] <- sign(testdata[["y"]] -  targetval)
  testdata[["rungroup"]] <- myrleid(testdata[["flag"]])
  
  if (direct == "below") {
    testdata <- testdata %>%
      dplyr::group_by(grp, rungroup) %>%
      dplyr::mutate(cusum = cumsum_with_reset_neg(flag, rl * -1)) %>%
      dplyr::ungroup()
  } else if (direct == "above") {
    testdata <- testdata %>%
      dplyr::group_by(grp, rungroup) %>%
      dplyr::mutate(cusum = cumsum_with_reset(flag, rl)) %>%
      dplyr::ungroup()
  } else {
    
    testdata <- testdata %>%
      dplyr::group_by(grp, rungroup) %>%
      dplyr::mutate(cusum_lo = cumsum_with_reset_neg(flag, rl * -1),
                    cusum_hi = cumsum_with_reset(flag, abs(fr))) %>%
      dplyr::mutate(cusum = pmax(cusum_hi,abs(cusum_lo))) %>%
      dplyr::ungroup() %>%
      dplyr::select(-cusum_hi,-cusum_lo)
  }
  
  
}



sustained_processing <- function(df,flag,flag_reset) {
  
  df <- df %>%
    dplyr::arrange(date) %>%
    dplyr::mutate(rungroup = cumsum_with_reset_group(abs(flag),
                                                     abs(flag_reset)))
  
  df <- df %>%
    dplyr::group_by(grp, rungroup) %>%
    dplyr::mutate(
      startdate = min(date),
      enddate = max(date),
      lastdate = max(df[["date"]])
    ) %>%
    dplyr::ungroup()
  df
}


cumsum_with_reset <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()
  
  for (i in seq_along(x)) {
    cumsum <- cumsum + x[i]
    
    if (cumsum > threshold) {
      group <- group + 1
      cumsum <- x[i]
    }
    
    #result = c(result, cumsum)
    result <-  c(result, cumsum)
    
  }
  
  return(result)
}


cumsum_with_reset_neg <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()
  
  for (i in seq_along(x)) {
    cumsum <- cumsum + x[i]
    
    if (cumsum < threshold) {
      group <- group + 1
      cumsum <- x[i]
    }
    
    #result = c(result, cumsum)
    result <-  c(result, cumsum)
    
  }
  
  return(result)
}

cumsum_with_reset_group_neg <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()
  
  for (i in 1:seq_along(x)) {
    cumsum <- cumsum + x[i]
    
    if (cumsum < threshold) {
      group <- group + 1
      cumsum <- x[i]
    }
    
    #result = c(result, group)
    result <-  c(result, group)
    
  }
  
  return(result)
}

cumsum_with_reset_group <- function(x, threshold) {
  cumsum <- 0
  group <- 1
  result <- numeric()
  
  for (i in seq_along(x)) {
    cumsum <- cumsum + x[i]
    
    if (cumsum > threshold) {
      group <- group + 1
      cumsum <- x[i]
    }
    
    #result = c(result, group)
    result <-  c(result, group)
    
  }
  
  return(result)
}


getenddate <- function(df, x, y){
  enddate <- df[[x]][y]
  return(enddate)
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


# build_results <- function(item1, item2, item3, item4 = NULL) {
#   results <-
#     list(
#       item1 = runchart,
#       item2 = median_rows,
#       item3 = StartBaseline,
#       item4 = NULL
#     )
#   return(results)
#   }



