context("Simulate Design")

my_population <- declare_population(N = 50, noise = rnorm(N))
my_potential_outcomes <-
  declare_potential_outcomes(Y_Z_0 = noise, Y_Z_1 = noise + rnorm(N, mean = 2, sd = 2))
my_assignment <- declare_assignment(m = 25)
my_estimand <- declare_estimand(ATE = mean(Y_Z_1 - Y_Z_0))
my_estimator <- declare_estimator(Y ~ Z, estimand = my_estimand)
my_reveal <- reveal_outcomes()

my_design_1 <- my_population + my_potential_outcomes + my_estimand + my_assignment + my_reveal + my_estimator

my_design_2 <- my_design_1

test_that("Simulate Design works", {
  sims <- simulate_design(my_design_1, sims = 5)
  expect_equal(nrow(sims), 5)

  sims <- simulate_design(my_design_1, my_design_2, sims = 5)
  expect_equal(nrow(sims), 10)
  expect_true(all(sims$design_label %in% c("my_design_1", "my_design_2")))

  sims <- simulate_design(list(my_design_1, my_design_2), sims = 5)
  expect_equal(nrow(sims), 10)

  expect_true(all(sims$design_label %in% c("design_1", "design_2")))

  sims <-
    simulate_design(a = my_design_1, b = my_design_2, sims = 5)
  expect_true(all(sims$design_label %in% c("a", "b")))
})



test_that("Simulate Design works x2", {

  f1 <- local({i <- 0; function(){i<<- i+1; i} })
  f2 <- local({i <- 0; function(){i<<- i+1; i} })
  f3 <- local({i <- 0; function(){i<<- i+1; i} })
  e1 <- declare_estimand(a=f1())
  e2 <- declare_estimand(b=f2())
  e3 <- declare_estimand(c=f3())
  out <- simulate_design(declare_population(sleep) + e1 + e2 + e3, sims=c(1,1,5,2))
  expect_equal(out$estimand, 
                    as.vector(t(out[(1:10)*3, c("step_1_draw", "step_3_draw", "step_4_draw")])))
})



my_designer <- function(N, tau) {
  pop <- declare_population(N = N)
  pos <-
    declare_potential_outcomes(Y_Z_0 = rnorm(N), Y_Z_1 = Y_Z_0 + tau)
  my_assignment <- declare_assignment(m = floor(N / 2))
  my_estimand <- declare_estimand(ATE = mean(Y_Z_1 - Y_Z_0))
  my_estimator <- declare_estimator(Y ~ Z, estimand = my_estimand)
  my_reveal <- reveal_outcomes()
  my_design_1 <- pop + pos + my_estimand + my_assignment + my_reveal + my_estimator
  my_design_1
}

test_that("expand and simulate", {
  my_designs <-
    expand_design(my_designer,
      N = c(10, 50),
      tau = c(5, 1), prefix = "custom_prefix"
    )
  sims <- simulate_design(my_designs, sims = 5)
  expect_equal(nrow(sims), 20)
  expect_true(all(sims$design_label %in% c("custom_prefix_1", "custom_prefix_2", "custom_prefix_3", "custom_prefix_4")))
  expect_true(all(c("N", "tau") %in% colnames(sims)))
})

test_that("wrong number of sims yields error", {
  expect_error(simulate_design(my_design_1, sims = rep(5, 3)), "Please provide sims a scalar or a numeric vector of length the number of steps in designs.")
})

test_that("zero sims yields error", {
  expect_error(simulate_design(my_design_1, sims = -1), "Sims should be >= 1")
})

test_that("dupe designs give error", {
  expect_error(simulate_design(my_design_1, my_design_1), "You have more than one design named my_design_1")
})



test_that("no estimates estimands declared", {
  my_design_noestmand <- delete_step(my_design_1, my_estimand)
  my_design_noestmand <- delete_step(my_design_noestmand, my_estimator)

  expect_error(simulate_design(my_design_noestmand, sims = 2), "No estimates or estimands were declared, so design cannot be simulated.")
})


test_that("designs with some estimators that don't have p.values return the p.values for the estimators that do have them", {
  my_custom_estimator <- function(data) return(data.frame(estimate = 5))
  
  des <- declare_population(N = 100) +
    declare_potential_outcomes(Y ~ .25 * Z + rnorm(N)) +
    declare_estimand(ATE = mean(Y_Z_1 - Y_Z_0)) +
    declare_assignment() +
    reveal_outcomes(Y, Z) +
    declare_estimator(Y ~ Z, estimand = "ATE", label = "blah") +
    declare_estimator(handler = label_estimator(my_custom_estimator), estimand = "ATE")
  
  expect_equivalent(names(simulate_design(des, sims = 1)), c("design_label", "sim_ID", "estimand_label", "estimand", "estimator_label", 
                                                        "term", "estimate", "std.error", "statistic", "p.value", "conf.low", 
                                                        "conf.high", "df", "outcome"))
  
  expect_equal(nrow(get_diagnosands(diagnose_design(des, sims = 2, diagnosands = declare_diagnosands(power = mean(p.value <= 0.05))))), 2)
  
})
