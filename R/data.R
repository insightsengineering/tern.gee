#' Example dataset for `tern.gee` package.
#'
#' Measurements of FEV1 (forced expired volume in one second) is a measure of
#' how quickly the lungs can be emptied.
#' Low levels of FEV1 may indicate chronic obstructive pulmonary disease (COPD).
#' @format A `tibble` with 800 rows and 7 variables:
#'
#'   - `USUBJID`: price, in US dollars.
#'   - `AVISIT`: visit number.
#'   - `ARMCD`: treatment, `TRT` or `PBO`.
#'   - `RACE`: 3-category race.
#'   - `SEX`: sex.
#'   - `FEV1_BL`: FEV1 at baseline (%).
#'   - `FEV1`: FEV1 at study visits.
"fev_data"
