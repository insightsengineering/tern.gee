# h_gee_cov works as expected

    Code
      result
    Output
              VIS1      VIS2      VIS3      VIS4  
      ————————————————————————————————————————————
      VIS1   1.0000    -0.0565   -0.1257   0.0678 
      VIS2   -0.0565   1.0000    -0.0836   -0.0578
      VIS3   -0.1257   -0.0836   1.0000    0.0092 
      VIS4   0.0678    -0.0578   0.0092    1.0000 

# summarize_gee_logistic works as expected with covariates in the model

    Code
      result
    Output
                                          PBO            TRT     
                                        (N=105)         (N=95)   
      ———————————————————————————————————————————————————————————
      n                                   420            380     
      Adjusted Mean Proportion (SE)   0.90 (0.02)    0.95 (0.01) 
        95% CI                        (0.85, 0.93)   (0.91, 0.97)
      Odds Ratio                                         1.97    
        95% CI                                       (1.03, 3.77)
      Log Odds Ratio                                     0.68    
        95% CI                                       (0.03, 1.33)

# summarize_gee_logistic works as expected with no covariates in the model

    Code
      result
    Output
                                          PBO            TRT     
                                        (N=105)         (N=95)   
      ———————————————————————————————————————————————————————————
      n                                   420            380     
      Adjusted Mean Proportion (SE)   0.88 (0.02)    0.94 (0.01) 
        95% CI                        (0.84, 0.92)   (0.91, 0.97)
      Odds Ratio                                         2.18    
        95% CI                                       (1.16, 4.10)
      Log Odds Ratio                                     0.78    
        95% CI                                       (0.15, 1.41)

