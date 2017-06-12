WORK IN PROGRESS: more details will be provided ASAP.

Two experiments are available: exp_ERAI and exp_ASR.
They have the same configuration (Almansi et al., in preparation) but different surface forcings:
- exp_ERAI: forced by the global atmospheric reanalysis ERA-Interim (Donlon et al., 2012).
- exp_ASR:  forced by the regional Arctic System Reanalysis (ASRv2 - 15km; Moore et al., 2016).

Please check [info_exp_ERAI.txt](https://github.com/malmans2/JHU-MITgcm_Tools/blob/master/info/info_exp_ERAI.txt) and [info_exp_ASR.txt](https://github.com/malmans2/JHU-MITgcm_Tools/blob/master/info/info_exp_ASR.txt) for a list of available fields/diagnostics.

## exp_ERAI
- Domain: 47°W-1°E; 57°N-77°N
- Time: snapshots every 6h (@ 00-06-12-18UTC) from 01-Sep-2007 to 31-Aug-2008.
- Exceptions: the following diagnostics are stored every day @ 00UTC: 
  - oceSPDep, oceSPflx, SIarea, SIheff, SIhsalt, SIhsnow, SIuice, SIvice 
                                                                          
## exp_ASR:
- Domain: 47°W-1°E; 57°N-77°N
- Time: snapshots every 6h (@ 00-06-12-18UTC) from 01-Sep-2007 to 31-Aug-2008.
- Exceptions: the following diagnostics are 6h averages and the domain is 13°W-22°W; 69°N-72°N (depth range is 0-700m): 
  - ADVr_TH, ADVx_TH, ADVy_TH 
  - ADVr_SLT, ADVx_SLT, ADVy_SLT
  - DFrI_TH 
  - DFrI_SLT
  - TFLUX
  - SFLUX
  - KPPg_TH
  - KPPg_SLT                                                                    
