# library(testthat)

test_that("oddsratio_to_d", {
  expect_equal(oddsratio_to_d(0.2), -0.887, tolerance = 0.01)
  expect_equal(oddsratio_to_d(-1.45, log = TRUE), -0.7994, tolerance = 0.01)
  expect_equal(d_to_oddsratio(-0.887), 0.2, tolerance = 0.01)
  expect_equal(d_to_oddsratio(-0.7994, log = TRUE), -1.45, tolerance = 0.01)
})


test_that("d_to_r", {
  expect_equal(d_to_r(1.1547), 0.5, tolerance = 0.01)
  expect_equal(r_to_d(0.5), 1.1547, tolerance = 0.01)

  expect_equal(oddsratio_to_r(d_to_oddsratio(r_to_d(0.5))), 0.5, tolerance = 0.001)
  expect_equal(oddsratio_to_d(r_to_oddsratio(d_to_r(1), log = TRUE), log = TRUE), 1, tolerance = 0.001)

  r <- cor(mtcars$hp, -mtcars$am)
  d <- cohens_d(hp ~ am, data = mtcars, ci = NULL)[[1]]
  n <- table(mtcars$am)
  expect_gt(r_to_d(r), d)
  expect_lt(d_to_r(d), r)
  expect_equal(r_to_d(r, n[1], n[2]), d, ignore_attr = TRUE)
  expect_equal(d_to_r(d, n[1], n[2]), r, ignore_attr = TRUE)

  expect_identical(d_to_r(0.5, n1 = 10), d_to_r(0.5, 10, 10))
  expect_identical(d_to_r(0.5, n2 = 10), d_to_r(0.5, 10, 10))
})

test_that("oddsratio_to_RR", {
  skip_on_cran()
  p0 <- 0.4
  p1 <- 0.7

  OR <- probs_to_odds(p1) / probs_to_odds(p0)
  RR <- p1 / p0
  ARR <- p1 - p0
  NNT <- 1 / ARR

  expect_equal(nnt_to_arr(NNT), ARR, tolerance = 1e-4)
  expect_equal(arr_to_nnt(ARR), NNT, tolerance = 1e-4)

  expect_equal(riskratio_to_oddsratio(RR, p0 = p0), OR, tolerance = 1e-4)
  expect_equal(oddsratio_to_riskratio(OR, p0 = p0), RR, tolerance = 1e-4)
  expect_equal(oddsratio_to_riskratio(1 / OR, p0 = p1), 1 / RR, tolerance = 1e-4)
  expect_equal(riskratio_to_arr(RR, p0 = p0), ARR, tolerance = 1e-4)
  expect_equal(oddsratio_to_arr(OR, p0 = p0), ARR, tolerance = 1e-4)
  expect_equal(arr_to_oddsratio(ARR, p0 = p0), OR, tolerance = 1e-4)
  expect_equal(arr_to_riskratio(ARR, p0 = p0), RR, tolerance = 1e-4)

  expect_equal(riskratio_to_oddsratio(RR, p0 = p0, log = TRUE), log(OR), tolerance = 1e-4)
  expect_equal(oddsratio_to_riskratio(log(OR), p0 = p0, log = TRUE), RR, tolerance = 1e-4)
  expect_equal(arr_to_oddsratio(ARR, p0 = p0, log = TRUE), log(OR), tolerance = 1e-4)
  expect_equal(oddsratio_to_arr(log(OR), p0 = p0, log = TRUE), ARR, tolerance = 1e-4)

  # -- GLMs --
  data(mtcars)

  m <<- glm(am ~ factor(cyl),
    data = mtcars,
    family = binomial()
  )

  expect_warning(RR <- oddsratio_to_riskratio(m, ci = NULL), "p0") # nolint
  expect_true("(Intercept)" %in% RR$Parameter)
  expect_false("(p0)" %in% RR$Parameter)

  expect_message(RR <- oddsratio_to_riskratio(m, ci_method = "wald", p0 = 0.7272727), "CIs") # nolint
  expect_false("(Intercept)" %in% RR$Parameter)
  expect_true("(p0)" %in% RR$Parameter)
  # these values confirmed from emmeans
  expect_equal(RR$Coefficient, c(0.7272, 0.5892, 0.1964), tolerance = 0.001)
  expect_equal(RR$CI_low, c(NA, 0.1267, 0.0303), tolerance = 0.001)
  expect_equal(RR$CI_high, c(NA, 1.1648, 0.7589), tolerance = 0.001)

  expect_message(RR <- oddsratio_to_riskratio(m, p0 = 0.05), "CIs") # nolint
  expect_true("(p0)" %in% RR$Parameter)
  expect_false("(Intercept)" %in% RR$Parameter)
  # these values confirmed from emmeans
  expect_equal(RR$Coefficient, c(0.05, 0.29173, 0.06557), tolerance = 0.001)

  # -- GLMMs --
  skip_if_not_installed("lme4")
  m <<- lme4::glmer(am ~ factor(cyl) + (1 | gear),
    data = mtcars,
    family = binomial()
  )

  expect_warning(RR <- oddsratio_to_riskratio(m, ci = NULL), "p0") # nolint
  expect_true("(Intercept)" %in% RR$Parameter)
  expect_false("(p0)" %in% RR$Parameter)

  expect_message(RR <- oddsratio_to_riskratio(m, ci_method = "wald", p0 = 0.7047536), "CIs") # nolint
  expect_false("(Intercept)" %in% RR$Parameter)
  expect_true("(p0)" %in% RR$Parameter)
  # these values confirmed from emmeans
  expect_equal(RR$Coefficient, c(0.7048, 0.6042, 0.4475), tolerance = 0.001)
  expect_equal(RR$CI_low, c(NA, 0.08556, 0.0102), tolerance = 0.001)
  expect_equal(RR$CI_high, c(NA, 1.2706, 1.3718), tolerance = 0.001)
})

test_that("odds_to_probs", {
  expect_equal(odds_to_probs(3), 0.75, tolerance = 0.01)
  expect_equal(probs_to_odds(0.75), 3, tolerance = 0.01)
  expect_equal(probs_to_odds(0.75, log = TRUE), 1.098, tolerance = 0.01)
  expect_equal(odds_to_probs(1.098, log = TRUE), 0.75, tolerance = 0.01)

  # Data frames
  df <- odds_to_probs(
    iris,
    select = "Sepal.Length",
    exclude = "Petal.Length",
    log = TRUE
  )

  expect_identical(ncol(df), 5)

  expect_equal(
    probs_to_odds(df,
      select = "Sepal.Length",
      exclude = "Petal.Length",
      log = TRUE
    ), iris,
    tolerance = 1e-4
  )
})

test_that("between anova", {
  expect_equal(eta2_to_f2(0.25), 1 / 3, tolerance = 1e-4)
  expect_equal(eta2_to_f(0.25), sqrt(eta2_to_f2(0.25)), tolerance = 1e-4)

  expect_equal(f2_to_eta2(1 / 3), 0.25)
  expect_equal(f_to_eta2(1 / sqrt(3)), f2_to_eta2(1 / 3), tolerance = 1e-4)
})


test_that("OR and logOR", {
  expect_equal(
    oddsratio_to_d(3),
    logoddsratio_to_d(log(3)),
    tolerance = 1e-4
  )
  expect_equal(
    log(d_to_oddsratio(3)),
    d_to_logoddsratio(3),
    tolerance = 1e-4
  )
  expect_equal(
    oddsratio_to_r(2),
    logoddsratio_to_r(log(2)),
    tolerance = 1e-4
  )
  expect_equal(
    log(r_to_oddsratio(0.5)),
    r_to_logoddsratio(0.5),
    tolerance = 1e-4
  )
  expect_equal(
    log(arr_to_oddsratio(0.2, p0 = 0.3)),
    arr_to_logoddsratio(0.2, p0 = 0.3),
    tolerance = 1e-4
  )
  expect_equal(
    oddsratio_to_arr(2, p0 = 0.3),
    logoddsratio_to_arr(log(2), p0 = 0.3),
    tolerance = 1e-4
  )
})
