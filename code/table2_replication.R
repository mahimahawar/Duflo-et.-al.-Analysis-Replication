# Replication of Table 2 (Child Survival)
#
# Paper:   "Intergenerational Impacts of Secondary Education:
#           Experimental Evidence from Ghana"
#           Esther Duflo, Pascaline Dupas, Elizabeth Spelke, Mark Walsh
# Author:  Mahi Mahawar (independent replication, in R)
# Date:    November 2026
#
# What this does:
# Reproduces Table 2, the effect of winning a secondary-school
# scholarship on the survival of participants' children to ages
# 1 and 3, separately for female and male participants.
#
# Data: mortality_surveys_u5.dta from the authors' replication
#       package on openICPSR. Save it in the folder data/ before
#       running. Not included in this repository.
#
# Note: The authors' original code is in Stata. This is my own
#       translation of the Table 2 regressions into R owing 
#       to lack of access to Stata.
#       Results differ slightly from the published table; see README.
#
# How to run:
#   1. Open the .Rproj file (or the project folder) in RStudio.
#   2. Install packages:
#        install.packages(c("haven", "dplyr", "fixest", "knitr"))
#   3. Open this script and click "Source".
#   Output is written to output/table2_replication.md
# ==============================================================

# 1. Load packages
library(haven)    # read_dta(): reads Stata files
library(dplyr)    # filter(): selects rows
library(fixest)   # feols(): regressions with clustered standard errors
library(knitr)    # kable(): formats the final table

# 2. Load and prepare the data
data_path <- "data/mortality_surveys_u5.dta"

# Stop with a clear message if the data file is missing
if (!file.exists(data_path)) {
  stop("Data file not found. Save mortality_surveys_u5.dta in the data/ folder.")
}

# zap_labels() strips Stata value labels so columns behave as plain numbers
d <- read_dta(data_path) |> zap_labels()

# 3. Define the four table columns
# y = outcome variable (survival to age 1 or age 3)
# flag = sample indicator the authors use (1 = child is in sample)
# yearfe = FALSE: birth year enters as a linear trend (columns 1-2)
#          TRUE : separate dummy for each birth year (columns 3-4)
cols <- data.frame(y = c("an_survive_1_23", "an_survive_3_23", "an_survive_1_23", "an_survive_3_23"),
  flag = c("samplemort_one", "samplemort_three", "samplemort_one", "samplemort_three"),
  yearfe = c(FALSE, FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE)

# 4. Control variables
# c_ variables are versions with missing values filled in;
# m_ variables flag which rows were filled in.
rhs <- function(yearfe) {yr <- if (yearfe) "factor(c_birth_year)" else "c_birth_year_lin"
  paste("factor(c_birth_order) +", yr,
        "+ factor(c_region_code) + c_an_bece_mean_score_0_1",
        "+ m_an_bece_mean_score_0_1 + m_birth_year_lin")}

# 5. Significance stars (paper's convention)
# * p < 0.1,  ** p < 0.05,  *** p < 0.01
stars <- function(p) ifelse(p < 0.01, "***", ifelse(p < 0.05, "**", ifelse(p < 0.1, "*", "")))

# 6. One column of one panel
# Runs the regression for one outcome and one sex of participant, then
# returns the five numbers shown in the paper as formatted text.
# Standard errors are clustered by parent ID (studentcode), because
# one parent can have several children.
panel_col <- function(y, flag, yearfe, female) {
  dd <- d |> filter(.data[[flag]] == 1, female_all == female, !is.na(.data[[y]]))
  m  <- feols(as.formula(paste(y, "~ treat +", rhs(yearfe))),
              data = dd, cluster = ~studentcode, notes = FALSE)
  p  <- unname(pvalue(m)["treat"])
  c(paste0(sprintf("%.3f", unname(coef(m)["treat"])), stars(p)),  # treatment effect
    sprintf("(%.3f)", unname(se(m)["treat"])),                    # standard error
    sprintf("%.3f", p),                                           # p-value
    sprintf("%.3f", mean(dd[[y]][dd$treat == 0])),                # comparison mean (control group)
    format(nobs(m), big.mark = ","))                              # number of children
}

# Builds all four columns for one panel (female = 1, male = 0)
make_panel <- function(female) {out <- sapply(1:4, function(i) panel_col(cols$y[i], cols$flag[i], cols$yearfe[i], female))
  rownames(out) <- c("Treatment", "", "P-value", "Comparison mean", "N")
  out}

# 7. Test: is the effect the same for male and female scholarship recipients?
# One regression on both groups together, with separate treatment
# effects for each (treatXfemale_all, treatXmale_all, built by the
# authors), then a test that the two effects are equal.
# NOTE: the paper's exact method was not available to me, so this row is an approximation.
gender_p <- function(y, flag, yearfe) {
  dd <- d |> filter(.data[[flag]] == 1, !is.na(.data[[y]]))
  m  <- feols(as.formula(paste(y, "~ treatXfemale_all + treatXmale_all + female_all +", rhs(yearfe))),
              data = dd, cluster = ~studentcode, notes = FALSE)
  b <- coef(m); V <- vcov(m)
  diff <- b["treatXfemale_all"] - b["treatXmale_all"]
  se_d <- sqrt(V["treatXfemale_all", "treatXfemale_all"] + V["treatXmale_all", "treatXmale_all"] -
                 2 * V["treatXfemale_all", "treatXmale_all"])
  sprintf("%.3f", 2 * pt(-abs(diff / se_d), df = degrees_freedom(m, type = "t")))
}

# 8. Run everything and assemble the table
panelA <- make_panel(female = 1)   # Panel A: children of female participants
panelB <- make_panel(female = 0)   # Panel B: children of male participants
gp <- matrix(sapply(1:4, function(i) gender_p(cols$y[i], cols$flag[i], cols$yearfe[i])),
             nrow = 1, dimnames = list("P-val male=fem", NULL))

hdrA <- matrix("", 1, 4, dimnames = list("Panel A: Children of Female Scholarship-lottery participants", NULL))
hdrB <- matrix("", 1, 4, dimnames = list("Panel B: Children of Male Scholarship-lottery participants", NULL))

tab <- rbind(hdrA, panelA, hdrB, panelB, gp)
tab <- data.frame(" " = rownames(tab), tab, row.names = NULL, check.names = FALSE)
names(tab)[2:5] <- c("(1) Survived to one yr (2023)", "(2) Survived to three yrs (2023)",
                     "(3) Survived to one yr (2023)", "(4) Survived to three yrs (2023)")

# 9. Show and save the result
print(tab)
dir.create("output", showWarnings = FALSE)   # make output/ if it doesn't exist
writeLines(kable(tab, format = "markdown"), "output/table2_replication.md")