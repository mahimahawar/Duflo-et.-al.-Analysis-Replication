# Replication of Table 2 (Child Survival) in R

An independent replication of Table 2 from:

> Duflo, Esther, Pascaline Dupas, Elizabeth Spelke, and Mark Walsh. 2026. "Intergenerational Impacts of Secondary Education: Experimental Evidence from Ghana." American Economic Review 116 (9): 3586–3621. [https://www.aeaweb.org/articles?id=10.1257/aer.20241001]
> Data compared against the 2024 NBER Working Paper [https://www.nber.org/papers/w32742] as the AER article cannot be accessed.

The authors' own code is written in Stata. I have translated their Table 2 regressions into R, owing to lack of access to Stata. This is an attempt to replicate their analysis. The research and data belongs to them.

# Table 2 Captures:

The study follows people who took part in a scholarship lottery for secondary school in Ghana. Table 2 asks whether winning a scholarship changed the survival of the participants' children, reported separately for female and male participants:

- **Panel A:** children of female participants
- **Panel B:** children of male participants
- **Columns 1 and 3:** survived to one year. **Columns 2 and 4:** survived to three years.
- **Columns 1 and 2** control for birth year as a linear trend. **Columns 3 and 4** use a separate dummy for each birth year.
- The last row tests whether the effect for male participants equals the effect for female participants.

# Repository

```
.
├── README.md
├── code/
│   └── table2_replication.R             # the full replication script
├── data/
│   └── README.md                        # where to download the data (not included here)
└── output/
    ├── table2_replication.md            # replicated table
    └── table2_replication_comparison.xlsx   # comparison with the paper
```

# How to run

1. **Get the data.** Download the replication package from openICPSR [https://doi.org/10.3886/E241205V1] and save `mortality_surveys_u5.dta` into this repository's `data/` folder.
2. **Install R and RStudio.** The script needs R version 4.1 or newer.
3. **Install the packages once**:
   ```r
   install.packages(c("haven", "dplyr", "fixest", "knitr"))
   ```
4. **Open the project folder in RStudio**
5. **Open `code/table2_replication.R` and click Source.**

# Method

For each column, I run an OLS regression of child survival on the scholarship-treatment indicator. The controls are birth-order dummies, birth year (linear or as dummies), region dummies, a parent exam-score control, and flags for filled-in missing values. Standard errors are clustered by parent ID, because one parent can have several children. Samples use the authors' own sample indicators (`samplemort_one` and `samplemort_three`). Significance stars follow the paper's convention (* p<0.1, ** p<0.05, *** p<0.01).

The specification was pieced together from the paper's description and the variable names in the data.

# Results: Paper vs. My R Output

**Panel A: children of female scholarship-lottery participants**

| | (1) Survived to 1 yr | (2) Survived to 3 yrs | (3) Survived to 1 yr, year FE | (4) Survived to 3 yrs, year FE |
|---|---|---|---|---|
| Treatment, paper | 0.018** (0.008) | 0.018* (0.010) | 0.017** (0.008) | 0.018* (0.010) |
| Treatment, my R | 0.018** (0.008) | 0.020** (0.010) | 0.017** (0.008) | 0.021** (0.010) |
| P-value, paper | 0.028 | 0.065 | 0.032 | 0.065 |
| P-value, my R | 0.032 | 0.041 | 0.037 | 0.041 |
| Comparison mean, paper / my R | 0.965 / 0.965 | 0.960 / 0.958 | 0.965 / 0.965 | 0.960 / 0.958 |
| N, paper / my R | 1,707 / 1,707 | 1,395 / 1,395 | 1,707 / 1,707 | 1,395 / 1,395 |

**Panel B: children of male scholarship-lottery participants**

| | (1) Survived to 1 yr | (2) Survived to 3 yrs | (3) Survived to 1 yr, year FE | (4) Survived to 3 yrs, year FE |
|---|---|---|---|---|
| Treatment, paper | 0.014 (0.010) | 0.007 (0.012) | 0.014 (0.010) | 0.009 (0.012) |
| Treatment, my R | 0.014 (0.010) | 0.007 (0.012) | 0.014 (0.010) | 0.009 (0.012) |
| P-value, paper | 0.161 | 0.549 | 0.147 | 0.477 |
| P-value, my R | 0.161 | 0.548 | 0.148 | 0.474 |
| Comparison mean, paper / my R | 0.970 / 0.970 | 0.971 / 0.970 | 0.970 / 0.970 | 0.971 / 0.970 |
| N, paper / my R | 1,016 / 1,009 | 772 / 765 | 1,016 / 1,009 | 772 / 765 |

**Test that the effect is equal for male and female participants (p-value)**

| | (1) | (2) | (3) | (4) |
|---|---|---|---|---|
| Paper | 0.706 | 0.532 | 0.612 | 0.473 |
| My R | 0.716 | 0.448 | 0.634 | 0.403 |

# Differences from the paper

Counting each statistic in each column (44 in total), **23 match the paper exactly, and 21 do not**. The standard errors match in all 8 cells, the coefficients in 6 of 8, the p-values in 1 of 8, and none of the four male-vs-female p-values match. Many of the gaps are small (often 0.001 to 0.005). The full cell-by-cell comparison is in `output/table2_replication_comparison.xlsx`.

The differences cluster in three places:

1. **Panel A, columns 2 and 4 (survived to three years).** Replicated coefficient is about 0.020 against the paper's 0.018, and replicated p-value is about 0.04 against 0.065. This changes the significance from * to **.
2. **Male sample sizes.** The data file provided for replication includes 1,009 and 765 male-parent children under the authors' sample indicators, while the working paper from 2024 reports 1,016 and 772.
3. **The male-vs-female test.** The replicated version is an approximation: one regression on both groups with separate treatment effects for each, then a test that the two are equal.

Two hypotheses: The paper I compared against is the July 2024 working paper, while the replication package I downloaded may reflect a later data version or the authors' exact specification differs from the one I inferred.

# Other notes

- In some columns, `fixest` drops the control `m_birth_year_lin` because it is redundant (for example, no child in the three-year sample has a missing birth year). This does not change the results. The script hides that notice with `notes = FALSE`.
- The script stops with a clear message if the data file is missing from `data/`.

# Author

Mahi Mahawar. [mahijaipur94@gmail.com, November 2026]
