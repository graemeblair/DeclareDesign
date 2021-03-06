% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/declare_diagnosands.R
\name{diagnosand_handler}
\alias{diagnosand_handler}
\alias{declare_diagnosands}
\title{Declare diagnosands}
\usage{
diagnosand_handler(data, ..., subset = NULL, alpha = 0.05, label)

declare_diagnosands(..., handler = diagnosand_handler, label = NULL)
}
\arguments{
\item{data}{A data.frame.}

\item{...}{A set of new diagnosands.}

\item{subset}{A subset of the simulations data frame within which to calculate diagnosands e.g. \code{subset = p.value < .05}.}

\item{alpha}{Alpha significance level. Defaults to \code{.05}.}

\item{label}{Label for the set of diagnosands.}

\item{handler}{a tidy-in, tidy-out function}
}
\value{
a function that returns a data.frame
}
\description{
Declare diagnosands
}
\details{
If term is TRUE, the names of ... will be returned in a \code{term} column, and \code{estimand_label}
will contain the step label. This can be used as an additional dimension for use in diagnosis.

Diagnosands summarize the simulations generated by \code{\link{diagnose_design}} or \code{\link{simulate_design}}. Typically, the columns of the resulting simulations data.frame include the following variables: estimate, std.error, p.value, conf.low, conf.high, and estimand. Many diagnosands will be a function of these variables.
}
\examples{

my_population <- declare_population(N = 500, noise = rnorm(N))

my_potential_outcomes <- declare_potential_outcomes(
  Y_Z_0 = noise, Y_Z_1 = noise +
  rnorm(N, mean = 2, sd = 2))

my_assignment <- declare_assignment()

my_estimand <- declare_estimand(ATE = mean(Y_Z_1 - Y_Z_0))

my_estimator <- declare_estimator(Y ~ Z, estimand = my_estimand)

my_reveal <- reveal_outcomes()

design <- my_population + my_potential_outcomes + my_estimand +
        my_assignment + my_reveal + my_estimator

\dontrun{
# using built-in defaults:
diagnosis <- diagnose_design(design)
diagnosis
}

# You can choose your own diagnosands instead of the defaults e.g.,

my_diagnosands <-
  declare_diagnosands(median_bias = median(estimate - estimand))
\dontrun{
diagnosis <- diagnose_design(design, diagnosands = my_diagnosands)
diagnosis
}
\dontrun{
design <- set_diagnosands(design, diagnosands = my_diagnosands)
diagnosis <- diagnose_design(design)
diagnosis
}

# Below is the code that makes the default diagnosands.
# You can use these as a model when writing your own diagnosands.

default_diagnosands <- declare_diagnosands(
bias = mean(estimate - estimand),
rmse = sqrt(mean((estimate - estimand) ^ 2)),
power = mean(p.value < alpha),
coverage = mean(estimand <= conf.high & estimand >= conf.low),
mean_estimate = mean(estimate),
sd_estimate = sd(estimate),
mean_se = mean(std.error),
type_s_rate = mean((sign(estimate) != sign(estimand))[p.value < alpha]),
mean_estimand = mean(estimand)
)

}
