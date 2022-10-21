library(r2stream)

test_data <- fev_data
test_vars <- fev_vars

model <- fit_gee(
  vars = test_vars,
  data = test_data,
  regression = "logistic",
  cor_struct = "unstructured"
)

sascode <- list(
  "test" = "
      proc genmod data=ana.dat descending;
      class RACE(ref = 'Asian') USUBJID ARMCD(ref = 'PBO') AVISIT;
      model FEV1_BIN = ARMCD RACE / dist=bin link=logit ;
      repeated subject=USUBJID / within=AVISIT type=UN CORRW;
      run;
  "
)

sas_data <- test_data
sas_data$FEV1_BIN <- sas_data$FEV1_BINARY
sas_data$FEV1_BINARY <- NULL

result <- r2stream::bee_sas(dat = list("dat" = sas_data), sascode = sascode)
result$test$sas_log
writeLines(result$test$sas_out, con = "sas_log.txt")

QIC(model)
VarCorr(model)
