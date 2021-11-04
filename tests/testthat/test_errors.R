test_that(" more than one direction argument throws error", {
  
  # more than one argument for `direction`
  
  
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above","below","both"),
                         datecol = date,
                         grpvar = grp,
                         yval = y), throws_error())
  
})


test_that(" missing datecol throws errors", {
  
  #  datecol missing
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = ,
                         grpvar = grp,
                         yval = y),
              throws_error())
  
  # datecol and grpvar missing
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = ,
                         grpvar = ,
                         yval = y), throws_error())
  
})

# missing groupvar
test_that(" missing grpvar throws errors", {
  
  #  grpvar missing
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = date,
                         grpvar = ,
                         yval = y),
              throws_error())
  
  
  
})


# missing yval
test_that(" missing yval throws errors", {
  
  #  grpvar missing
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = date,
                         grpvar = grp,
                         yval = ),
              throws_error())
  
})

# multiple missing values throw errors
test_that(" missing grpvar throws errors", {
  
  # grpvar and yval
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = date,
                         grpvar = ,
                         yval = ),
              throws_error())
  
  
  # grpvar and date
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = ,
                         grpvar = ,
                         yval = "y" ),
              throws_error())
  
  
  # missing datecol and yval
  
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = ,
                         grpvar = grp,
                         yval = ),
              throws_error())
  
  

  # wrong date format

  test_that("wrong dateformat causes error",{
    signals2 <- signals
    signals2$date <- as.character(signals2$date)
    expect_that(runcharter(signals2,
                           med_rows = 13,
                           runlength = 9,
                           direction = "both",
                           datecol = as.character("date"),
                           grpvar = "grp",
                           yval = "y"),
                throws_error())
  })
  
  
  
  # date , grpvar and yval all missing
  
  expect_that(runcharter(signals,
                         med_rows = 9,
                         runlength = 9,
                         direction = c("above"),
                         datecol = ,
                         grpvar = ,
                         yval =  ),
              throws_error())
  
  
  
})




# not enough rows remaining
test_that(" there are enough rows beyond the baseline and runlength period", {
  
  expect_that(runcharter(signals,
                         med_rows = 50,
                         runlength = 15,
                         direction = "above",
                         datecol = date,
                         grpvar = grp,
                         yval = y),
              throws_error("None of the groups have enough rows of data beyond the specified baseline period, for the desired runlength.
        Please check the values of the med_rows and runlength arguments.
        Currently they exceed the number of rows for each group"))
  
  
  keeptest <- data.table(grp = c("WardV","WardX","WardY","WardZ"),
                         N = rep_len(55,4),
                         compar = rep_len(59,4),
                         result = rep_len(FALSE,4)
  )
  
  expect_that(runcharter(signals,
                         med_rows = 50,
                         runlength = 15,
                         direction = "above",
                         datecol = date,
                         grpvar = grp,
                         yval = y),
              throws_error("None of the groups have enough rows of data beyond the specified baseline period, for the desired runlength.
        Please check the values of the med_rows and runlength arguments.
        Currently they exceed the number of rows for each group"))  
  
})

# df = NULL
test_that("missing df argument causes error", {
  expect_that(runcharter(df = NULL,
                         med_rows = 13,
                         runlength = 9,
                         direction = "both",
                         datecol = date,
                         grpvar = grp,
                         yval = y),
              throws_error())
  
  
  # df not specified
  expect_that(runcharter(med_rows = 13,
                         runlength = 9,
                         direction = "both",
                         datecol = date,
                         grpvar = grp,
                         yval = y),
              throws_error())
  
  
})




