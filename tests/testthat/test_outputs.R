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
  
  

  p4 <- runcharter(signals,med_rows = 0, runlength = 9,direction = "above",
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
  
  
  
  # check points on median not plotted
  highlights <-
    structure(
      list(
        reportdate = structure(
          c(
            17532L,
            17539L,
            17546L,
            17553L,
            17560L,
            17567L,
            17574L,
            17581L,
            17588L,
            17595L,
            17602L,
            17609L,
            17616L,
            17623L,
            17630L,
            17637L,
            17644L,
            17651L,
            17658L,
            17665L,
            17672L,
            17679L,
            17686L,
            17693L,
            17700L,
            17707L,
            17714L,
            17721L,
            17728L,
            17735L,
            17742L,
            17749L,
            17756L,
            17763L,
            17770L,
            17777L,
            17784L,
            17791L,
            17798L,
            17805L,
            17812L,
            17819L,
            17826L,
            17833L,
            17840L,
            17847L,
            17854L,
            17861L,
            17868L,
            17875L,
            17882L,
            17889L,
            17896L,
            17903L,
            17910L,
            17917L,
            17924L,
            17931L,
            17938L,
            17945L,
            17952L,
            17959L,
            17966L,
            17973L,
            17980L
          ),
          class = "Date"
        ),
        metric = c(
          100,
          62.5,
          100,
          100,
          100,
          90,
          90,
          85.7,
          87.5,
          100,
          100,
          100,
          100,
          100,
          71.4,
          75,
          83.3,
          75,
          90.9,
          100,
          90.9,
          76.9,
          81.8,
          100,
          100,
          84.6,
          100,
          100,
          100,
          100,
          100,
          80,
          91.7,
          87.5,
          100,
          100,
          87.5,
          85.7,
          80,
          66.7,
          100,
          80,
          100,
          85.7,
          80,
          100,
          100,
          81.8,
          83.3,
          66.7,
          85.7,
          100,
          50,
          100,
          100,
          75,
          100,
          80,
          83.3,
          100,
          100,
          100,
          100,
          100,
          100
        ),
        grp = c(
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1",
          "test_site1"
        )
      ),
      row.names = c(NA,
                    -65L),
      class = "data.frame"
    )
  
  
  checkDT6 <- data.table(grp = c("test_site1","test_site1"),
                         median = c(100.0,81.8),
                         start_date = c("2018-01-01","2018-04-09"),
                         end_date = c("2018-03-26","2018-06-25"),
                         extend_to = c("2018-04-09","2019-03-25"),
                         run_type = c("baseline","sustained"))
  
  checkDT6$start_date <- as.Date(checkDT6$start_date)
  checkDT6$end_date <- as.Date(checkDT6$end_date)
  checkDT6$extend_to <- as.Date(checkDT6$extend_to)
  
p6 <- runcharter(highlights, direction = "both", 
                 datecol = 'reportdate', grpvar = 'grp', yval = 'metric') 
  
expect_equal(p6$sustained$grp,checkDT6$grp)
expect_equal(p6$sustained$start_date,checkDT6$start_date)
expect_equal(p6$sustained$end_date,checkDT6$end_date)
expect_equal(p6$sustained$extend_to,checkDT6$extend_to)
  
})


