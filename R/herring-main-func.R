
baseline_path <- "./inst/data_files/alewife-baseline.csv"
lat_long_path <- "./inst/data_files/alewife-lat-long.txt"
rep_unit_path <- "./inst/data_files/alewife-3-grps.txt"
locus_columns <-  14:35


baseline_path <- "./inst/data_files/blueback-baseline.csv"
lat_long_path <- "./inst/data_files/blueback-lat-long.txt"
rep_unit_path <- "./inst/data_files/blueback-4-grps.txt"
locus_columns <-  14:39


#' main wrapper function that does all the steps of a full analysis
#' 
#' @inheritParams herring_csv2gpiper
#' 
herring_main_func <- function(
  baseline_path,
  lat_long_path, 
  rep_unit_path,
  locus_columns
  ) {
  
  # read in data
  baseline.df <- herring_csv2gpiper(baseline_path, lat_long_path, locus_columns)
  
  # make a gsi_sim file of it
  the.pops.f <- make_baseline_file(baseline.df)
  
  # run gsi_sim for self assignments.  the result is a list with $from_pop_to_pop, $from_pop_to_rg, and $from_rg_to_rg
  self_ass <- gsi_self_assignment(the.pops.f, rep_unit_path)
  
  # make some barplots.  Currently these does not save them.  But I will add that later.
  # simple barplot to rep unit:
  simple_barplot(self_ass$from_pop_to_rg$Cutoff_0$AssTable)
  
  # shade gradient barplot to pops
  to_pops_barplot(self_ass$from_pop_to_pop$Cutoff_0$AssTable, self_ass$rep_units)
  
  
}