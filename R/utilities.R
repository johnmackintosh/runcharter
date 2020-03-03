
get_run_dates <- function(direct = direction,
                          DT = NULL,
                          target_vec = c("cusum_shift","cusum"),
                          compar_vec = flag_reset,
                          runlength = runlength,
                          ...) {
  flag_reset <- if (direct == "below") {
    runlength * -1
  } else {
    runlength
  }
  
  if (direct == "both") {
    res <- DT[abs(get(target_vec)) == abs(compar_vec),]
  } else {
    res <-  DT[get(target_vec) == compar_vec,]
    res[, .SD[1], by = grp]
  }
}


basic_processing <- function(DT = NULL,
                             kg = keepgroup,
                             runlength = runlength,
                             ...) {
  lookback <- (runlength - 1)
  
  DT[grp %chin% kg,flag := sign(y - median)]
  DT[flag != 0, rungroup := rleidv(flag), by = grp
     ][flag != 0, cusum := cumsum(flag), by = list(grp,rungroup)
       ][flag != 0, cusum_shift := shift(cusum, n = lookback, type = "lead")
         ][flag != 0, roll_median := zoo::rollapply(y, width = runlength,
                                                    FUN = median,
                                                    partial = TRUE,
                                                    align = "right"),
           by = list(grp,rungroup)]
}


get_runs_DT <- function(DT1 = NULL, #run_start
                        DT2 = NULL, # run_end
                        joinvar = "grp",
                        instance = "first",
                        sdcols = c("grp","date","i.date","i.roll_median"),
                        ... ){
  
  runs <- DT1[DT2, on = joinvar, mult = instance
              ][,.SD, .SDcols = sdcols
                ][,.SD[1], by = joinvar]
  setnames(runs,
           old = c("date","i.date","i.roll_median"),
           new = c("start_date","end_date","median"))

}

update_tempDT <- function(DT1 = NULL, # sustained
                          DT2 = NULL, # tempDT
                          joinvar ="grp",
                          sdcols = c("grp","y","date","median")) {
  res <- DT1[DT2, on = joinvar
             ][date > end_date,
               ][,.SD, .SDcols = sdcols][]
  res
}



get_sustained <- function(DT1 = NULL,
                          DT2 = NULL, ...){

  sus <- get_runs_DT(DT1, DT2)
  sus <- sus[,c("grp","median","start_date","end_date"),]
  sus[,`:=`(run_type = 'sustained',
            rungroup = 1)][]
  return(sus)

}
