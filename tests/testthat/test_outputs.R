test_that("`runcharter function` works with input and returns expected data.frame", {
  
  #runs in both directions
  
  checkDT <- data.table(grp = c("WardV","WardX","WardY","WardZ","WardX","WardY","WardZ"),
                        median = c(7,11,12,4,6,8,9),
                        start_date = c("2014-01-01","2014-01-01","2014-01-01",
                                       "2014-01-01","2016-12-01","2017-10-01",
                                       "2017-06-01"),
                        end_date = c("2014-09-01","2014-09-01","2014-09-01",
                                     "2014-09-01","2017-08-01","2018-06-01",
                                     "2018-03-01"),
                        extend_to = c("2018-07-01","2016-12-01","2017-10-01",
                                      "2017-06-01","2018-07-01","2018-07-01",
                                      "2018-07-01"),
                        run_type = c("baseline","baseline","baseline","baseline",
                                     "sustained","sustained","sustained"))
  
  checkDT$start_date <- as.Date(checkDT$start_date)
  checkDT$end_date <- as.Date(checkDT$end_date)
  checkDT$extend_to <- as.Date(checkDT$extend_to)
  
  p <- runcharter(signals,med_rows = 9, runlength = 9, direction = "both",
                  datecol = "date",grpvar = "grp",yval = "y")
  
  
  expect_equal(p$sustained,checkDT)
  expect_identical(p$sustained,checkDT)
  
  
  #runs above the median
  
  checkDT1 <- data.table(grp = c("WardV","WardX","WardY","WardZ","WardZ"),
                         median = c(7,11,12,4,9),
                         start_date = c("2014-01-01","2014-01-01","2014-01-01",
                                        "2014-01-01","2017-06-01"),
                         end_date = c("2014-09-01","2014-09-01","2014-09-01",
                                      "2014-09-01","2018-03-01"),
                         extend_to = c("2018-07-01","2018-07-01","2018-07-01",
                                       "2017-06-01","2018-07-01"),
                         run_type = c("baseline","baseline","baseline","baseline",
                                      "sustained"))
  
  checkDT1$start_date <- as.Date(checkDT1$start_date)
  checkDT1$end_date <- as.Date(checkDT1$end_date)
  checkDT1$extend_to <- as.Date(checkDT1$extend_to)
  
  p1 <- runcharter(signals,med_rows = 9, runlength = 9, direction = "above",
                   datecol = "date",grpvar = "grp",yval = "y")
  
  expect_equal(p1$sustained,checkDT1)
  expect_identical(p1$sustained,checkDT1)
  
  
  # runs below the median
  checkDT2 <- data.table(grp = c("WardV","WardX","WardY","WardZ","WardX","WardY"),
                         median = c(7,11,12,4,6,8),
                         start_date = c("2014-01-01","2014-01-01","2014-01-01",
                                        "2014-01-01","2016-12-01","2017-10-01"),
                         end_date = c("2014-09-01","2014-09-01","2014-09-01",
                                      "2014-09-01","2017-08-01","2018-06-01"),
                         extend_to = c("2018-07-01","2016-12-01","2017-10-01",
                                       "2018-07-01","2018-07-01",
                                       "2018-07-01"),
                         run_type = c("baseline","baseline","baseline","baseline",
                                      "sustained","sustained"))
  
  checkDT2$start_date <- as.Date(checkDT2$start_date)
  checkDT2$end_date <- as.Date(checkDT2$end_date)
  checkDT2$extend_to <- as.Date(checkDT2$extend_to)
  
  p2 <- runcharter(signals,med_rows = 9, runlength = 9, direction = "below",
                   datecol = "date",grpvar = "grp",yval = "y")
  
  expect_equal(p2$sustained,checkDT2)
  expect_identical(p2$sustained,checkDT2)
  
  
  # runlength set to 0 (zero)
  
  checkDT3 <- data.table(grp = c("WardV","WardX","WardY","WardZ"),
                         median = c(7,11,12,4),
                         start_date = c("2014-01-01","2014-01-01","2014-01-01",
                                        "2014-01-01"),
                         end_date = c("2014-09-01","2014-09-01","2014-09-01",
                                      "2014-09-01"),
                         extend_to = c("2018-07-01","2018-07-01","2018-07-01",
                                       "2018-07-01"),
                         run_type = c("baseline","baseline","baseline","baseline"))
  
  checkDT3$start_date <- as.Date(checkDT3$start_date)
  checkDT3$end_date <- as.Date(checkDT3$end_date)
  checkDT3$extend_to <- as.Date(checkDT3$extend_to)
  
  
  p3 <- runcharter(signals,med_rows = 9, runlength = 0, direction = "above",
                   datecol = "date",grpvar = "grp",yval = "y")
  
  expect_equal(p3$sustained,checkDT3)
  expect_identical(p3$sustained,checkDT3)
  
  
  # med_rows set to 0 (zero)
  
  checkDT4 <- data.table(grp = c("WardV","WardX","WardY","WardZ"),
                         median = c(NA,NA,NA,NA),
                         start_date = c("2014-01-01","2014-01-01","2014-01-01",
                                        "2014-01-01"),
                         end_date = c("2014-01-01","2014-01-01","2014-01-01",
                                      "2014-01-01"),
                         extend_to = c("2018-07-01","2018-07-01","2018-07-01",
                                       "2018-07-01"),
                         run_type = c("baseline","baseline","baseline","baseline"))
  
  checkDT4$start_date <- as.Date(checkDT4$start_date)
  checkDT4$end_date <- as.Date(checkDT4$end_date)
  checkDT4$extend_to <- as.Date(checkDT4$extend_to)
  
  
  
  p4 <- runcharter(signals,med_rows = 0, runlength = 0,direction = "above",
                   datecol = "date",grpvar = "grp",yval = "y")
  
  
  expect_equal(p4$sustained$grp,checkDT4$grp)
  expect_equal(p4$sustained$start_date,checkDT4$start_date)
  expect_equal(p4$sustained$end_date,checkDT4$end_date)
  expect_equal(p4$sustained$extend_to,checkDT4$extend_to)
  
  
  
  expect_equal(p4$sustained$median,as.numeric(c(NA,NA,NA,NA)))
  
  
  # check factors converted to character and back
  
  signals[["grp"]] <- as.factor(signals[["grp"]])
  
  p5 <- runcharter(signals,med_rows = 9, runlength = 9, direction = "both",
                   datecol = "date",grpvar = "grp",yval = "y")
  
  expect_true(is.factor(p5$sustained$grp))
  
})
