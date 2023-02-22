# Last updated: Feb 21, 2023

library(tidyverse)
library(reshape2)
library(readxl)

# ddir_cedric <- "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"
ddir_matt <- './data/'
ddir <- ddir_matt

##----------##
# FRED PPI data
##----------##

# Note: the full sample is bituminous coal mines, and PPI are for just coal mining OR underground bituminous coal mining
# => should probably use total coal mining PPI?

ppi_coalmining_df <- read_excel(file.path(ddir, "FRED", "PCU21212121.xls"), skip = 10, col_types = c("date","numeric")) %>%
  rename(date = observation_date,
         ppi_coalmining = PCU21212121) %>%
  mutate(date = ymd(date), 
         year = year(date),
         month = month(date)) %>%
  dplyr::select(!date)

ppi_undergroundbituminous_coalmining_df <- read_excel(file.path(ddir, "FRED", "PCU212112212112.xls"), skip = 10, col_types = c("date","numeric")) %>%
  rename(date = observation_date,
         ppi_undergroundbituminous_coalmining = PCU212112212112) %>%
  mutate(date = ymd(date), 
         year = year(date),
         month = month(date)) %>%
  dplyr::select(!date)

##----------##
# S&P Capital IQ coal mine-power plant contract data
##----------##

contract_col_types <- c("text","text","text","text","text","text","text","date","text","text","text","text","text","text","text","text","text","text","text")
contracts <- read_excel(file.path(ddir, "capiq", "SPGlobal_Export_2002_2003.xls"), skip = 3, col_types = contract_col_types)

years_list <- c("2003_2004", "2005_2006", "2007_2008", "2009_2010", "2011_2013", "2014_2017", "2018_2022")
for (years in years_list) {
  print(years)
  temp <- read_excel(file.path(ddir, "capiq", paste0("SPGlobal_Export_", years, ".xls")), skip = 3, col_types = contract_col_types)
  
  
  contracts <- contracts %>%
    bind_rows(temp) %>%
    filter(!is.na(KEY_MINE_ID),
           FUEL_TYPE_DETAIL == "Bituminous Coal") %>%
    distinct()
  
  rm(temp)
}

# Can only use contracts with both price and coal quantity data
contracts_semi_cleaned <- contracts %>%
  mutate(DLVY_DATE = ymd(DLVY_DATE),
         year = year(DLVY_DATE), 
         month = month(DLVY_DATE)) %>%
  left_join(ppi_coalmining_df, by = c("year", "month")) %>%
  left_join(ppi_undergroundbituminous_coalmining_df, by = c("year", "month")) %>%
  mutate(QTY_COAL_PURCH = as.numeric(QTY_COAL_PURCH),
         PRICE_PER_TON = as.numeric(PRICE_PER_TON),
         KEY_MINE_ID = as.numeric(KEY_MINE_ID)) %>%
  filter(!is.na(QTY_COAL_PURCH),
         !is.na(PRICE_PER_TON)) %>%
  rename(contract_type = FUEL_CONTRACT_TYPE)

##----------##
# S&P Capital IQ coal mine seam height data
##----------##

seamheight <- read_excel(file.path(ddir, "capiq", "SPGlobal_Export_seam_height.xls"), skip = 3, col_types = "text", na = "NA") %>%
  filter(!is.na(MSHA_MINE_ID))

for (i in 4:24) {
  year <- 2026-i
  colnames(seamheight)[i] <- as.character(year)
}

seamheight_long <- seamheight %>%
  dplyr::select(-NAME, -MSHA_MINE_ID) %>%
  melt(id = "MINE_UNIQUE_IDENTIFIER", variable.name = "year", value.name = "seam_height_in") %>%
  mutate(na_indicator = ifelse(is.na(seam_height_in), 1, 0),
         ones = 1, 
         seam_height_in = as.numeric(seam_height_in),
         year = 2023-as.numeric(year),
         KEY_MINE_ID = as.numeric(MINE_UNIQUE_IDENTIFIER)) %>%
  dplyr::select(-MINE_UNIQUE_IDENTIFIER)

# Percentage of mine-years missing data: 79 percent
# sum(seamheight_long$na_indicator)/sum(seamheight_long$ones)
# hist(seamheight_long$seam_height_in)

seamheight_long <- seamheight_long %>%
  filter(na_indicator == 0) %>%
  dplyr::select(-na_indicator, -ones)

msha_capiq_crosswalk <- seamheight %>%
  mutate(KEY_MINE_ID = as.numeric(MINE_UNIQUE_IDENTIFIER)) %>%
  dplyr::select(KEY_MINE_ID, MSHA_MINE_ID) %>%
  distinct()

contracts_full <- contracts_semi_cleaned %>%
  left_join(seamheight_long, by = c("KEY_MINE_ID", "year")) %>%
  left_join(msha_capiq_crosswalk, by = c("KEY_MINE_ID")) %>%
  rename(CAPIQ_MINE_ID = KEY_MINE_ID)
  
##----------##
# BEA state real GDP data
##----------##

bea_df <- read.csv(paste0(ddir,'BEA','/SAGDP1__ALL_AREAS_1997_2021.csv'))

bea_gdp <- bea_df %>%
  filter((GeoName != 'United States') & (LineCode == 1)) %>%
  mutate(STATE = state.abb[match(GeoName,state.name)]) %>%
  pivot_longer(cols = starts_with('X'),names_to = 'year',values_to = 'rgdp') %>%
  mutate(year = as.numeric(str_sub(year,start = 2))) %>%
  select(STATE,year,rgdp)
  
contracts_full <- contracts_full %>%
  left_join(bea_gdp, by = c("STATE", "year")) %>%
  filter(year != 2022)

write_csv(contracts_full, file.path(ddir, "cleaned", "contracts_cleaned.csv"))

