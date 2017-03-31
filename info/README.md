WORK IN PROGRESS: more details will be provided ASAP.

Two experiments are available: exp_ERAI and exp_ASR.
They have the same configuration (Almansi et al., in progress) but different surface forcings.
exp_ERAI: forced by the global atmospheric reanalysis ERA-Interim (Donlon et al., 2012).
exp_ASR:  forced by the regioanal Arctic System Reanalysis (ASRv2 - 15km; Moore et al., 2016).

Please check info_exp_ASR.txt and info_exp_ERAI.txt for a list of available fields/diagnostics.

## exp_ERAI
- Domain: 47°W-1°E; 57°N-77°N
- Time: snapshots every 6h from 01-Sep-2007 to 31-Aug-2008.
- Exceptions: the following diagnostics are stored every day @ 00:00:00: 
  - oceSPDep, oceSPflx, SIarea, SIheff, SIhsalt, SIhsnow, SIuice, SIvice 
                                                                          
## exp_ASR:
- Domain: 47°W-1°E; 57°N-77°N
- Time: snapshots every 6h from 01-Sep-2007 to 31-Aug-2008.
- Exceptions: the domain of the following diagnostics is 13°W-22°W; 69°N-72°N: 
  - UVELTH, VVELTH, WVELTH, 
  - UVELSLT, VVELSLT, WVELSLT, 
  - TOTTTEND, TOTSTEND, 
  - DFrE_TH, DFxE_TH, DFyE_TH, DFrI_TH, DFrE_SLT, DFxE_SLT, DFyE_SLT, DFrI_SLT                                                                     
