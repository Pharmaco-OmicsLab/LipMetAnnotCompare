#' ---
#' title: "Annotation matching"
#' ---
#' 
#' # NOTE: Please close the whole Rstudio and open the provided code directly.
#' # Or set your working dir via setwd("your_wd_path")
#' 
#' # Install package if not already installed. If yes, move to package call step.
## ----eval=FALSE---------------------------------------------------------------------------------------------------------------------------------------------------------
## # If need to install pacakge, remove the "##" before each line of code in 3 install.packages here and run, because it was comment now.
## install.packages("fuzzyjoin")
## install.packages("tidyverse")
## install.packages("openxlsx", dependencies = TRUE)

#' 
#' # Call library
## ----warning=FALSE, message=FALSE---------------------------------------------------------------------------------------------------------------------------------------
library(fuzzyjoin)
library(tidyverse)
library(openxlsx)

#' 
#' # Read data and transform

#' #' 
#' ## Modify the input name
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
## Version1 data name. Here it is data from MS-DIAL ver. 4.9
Version1_data_name = "Input_version49.csv"
## Version2 data name. Here it is data from MS-DIAL ver. 5.2
Version2_data_name = "Input_version52.csv"

#' ## Read version1 data
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Version1_data <- read.csv(Version1_data_name, 
                          check.names = FALSE) %>% 
  mutate(RT_MZ = paste(RT, mz, sep = "__")) %>% 
  mutate(Annotation_in_Version1Data = ifelse(grepl("Unknown|w/o", name), "No", "Yes" )) %>%
  dplyr::select(Annotation_in_Version1Data, `name`, RT, mz, RT_MZ, adduct, SN_ratio, fill_perc)

#' 
#' ## Read version2 data
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Version2_data <- read.csv(Version2_data_name, 
                          check.names = FALSE) %>%  
  mutate(RT_MZ = paste(RT, mz, sep = "__")) %>% 
  dplyr::select(`name`, RT, mz, RT_MZ, adduct, SN_ratio, fill_perc) %>% 
  # Remove sodium adduct
  filter(!adduct == "[M+Na]+")

#' 
#' # ID matching with full data
#' ## fuzzy search 
#' - First, using fuzzy search with `RT__mz` to avoid missing
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Version1_data %>% 
  stringdist_join(Version2_data, 
                  by = "RT_MZ",
                  mode = "left",
                  ignore_case = FALSE, 
                  method = "jw", 
                  max_dist = 99, # set very high distance threshold, or can use `Inf`
                  distance_col = "dist") %>% 
  group_by(RT_MZ.x) %>%
  # Then filter the lowest distance, i.e., best match
  slice_min(order_by = dist, n = 1) %>% 
  ungroup() -> fuzzy_match_full

#' 
#' - Next, avoid redundancy by using RT and m/z cut-offs
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
check_match_full <-  fuzzy_match_full %>% 
  mutate(mz_diff =  abs(mz.y - mz.x),
         RT_diff = abs(RT.y - RT.x),
         RT_diff_percentage = abs(RT.y - RT.x)/RT.x*100) %>% 
  arrange(dist)

#' Define cut-offs for RT and m/z. The RT cut off should be set based on empirical RT differences.
RT_cut_off = 1.5      # %
mz_cut_off = 0.015    # Da

#' Filter
check_match_full_fil_mz_rt <- check_match_full %>% 
  filter(RT_diff_percentage <= RT_cut_off) %>% 
  filter(mz_diff <= mz_cut_off)

#' 
#' # Export
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
#' 
#' ## Standardize variable name before exporting
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
Version1_variable_name = "49"
Version2_variable_name = "52"

c(
  "Annotation_in_Version1Data",
  
  paste("name_", Version1_variable_name, sep = ""),
  paste("RT_", Version1_variable_name, sep = ""),
  paste("mz_", Version1_variable_name, sep = ""),
  paste("RT_mz_", Version1_variable_name, sep = ""),
  paste("adduct_", Version1_variable_name, sep = ""),
  paste("SN_ratio_", Version1_variable_name, sep = ""),
  paste("fill_perc_", Version1_variable_name, sep = ""),
  
  paste("name_", Version2_variable_name, sep = ""),
  paste("RT_", Version2_variable_name, sep = ""),
  paste("mz_", Version2_variable_name, sep = ""),
  paste("RT_mz_", Version2_variable_name, sep = ""),
  paste("adduct_", Version2_variable_name, sep = ""),
  paste("SN_ratio_", Version2_variable_name, sep = ""),
  paste("fill_perc_", Version2_variable_name, sep = ""),
  
  "dist",
  "mz_diff",
  "RT_diff",
  "RT_diff_percentage"
) -> names(check_match_full) 

names(check_match_full_fil_mz_rt) = names(check_match_full)


#' ## Create a new workbook and add a worksheet
## -----------------------------------------------------------------------------------------------------------------------------------------------------------------------
wb <- createWorkbook()
sheet1 = "full_raw"
sheet2 = paste("filter_" ,"RT", gsub("\\.", "", RT_cut_off), "_", "mz", gsub("\\.", "", mz_cut_off), sep = "")
addWorksheet(wb, sheet1)
addWorksheet(wb, sheet2)

# Write the data frame to the worksheet, including row names
writeData(wb, 
          sheet = sheet1, 
          x = check_match_full %>% arrange(RT_diff_percentage), # Sort by RT differences before export
          rowNames = TRUE)

# Write the data frame to the worksheet, including row names
writeData(wb, 
          sheet = sheet2, 
          x = check_match_full_fil_mz_rt %>% arrange(RT_diff_percentage), # Sort by RT differences before export
          rowNames = TRUE)

# Save the workbook to a file
saveWorkbook(wb, "Output_ID_match.xlsx", overwrite = TRUE)

#' 
#' # sessionInfo
## ---------------------------------------------------------------------------------------------------------------------------------------------------------------
sessionInfo
# Export sessionInfo
writeLines(capture.output(sessionInfo()), "Output_sessionInfo.txt")


