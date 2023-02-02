# Last updated: Feb 1, 2023

library(tidyverse)
library(reshape2)
library(readxl)

ddir <- "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"

# S&P Capital IQ mine data

##-----##
# Monthly Fuel Deliveries
##-----##

# Import data
contracts <- read_excel(file.path(ddir, "capiq", "SPGlobal_Export_2002_2003.xls"), skip = 3, col_types = "text")

years_list <- c("2003_2004", "2005_2006", "2007_2008", "2009_2010", "2011_2013", "2014_2017", "2018_2022")
for (years in years_list) {
  print(years)
  temp <- read_excel(file.path(ddir, "capiq", paste0("SPGlobal_Export_", years, ".xls")), skip = 3, col_types = "text")
    
  
  contracts <- contracts %>%
    bind_rows(temp) %>%
    filter(!is.na(KEY_MINE_ID),
           FUEL_TYPE_DETAIL == "Bituminous Coal") %>%
    distinct()
  
  rm(temp)
}

# Can only use contracts with both price and coal quantity data: 188,219 contracts
contracts <- contracts %>%
  filter(!is.na(QTY_COAL_PURCH), 
         QTY_COAL_PURCH != "NA",
         !is.na(PRICE_PER_TON),
         PRICE_PER_TON != "NA") %>%
  mutate(QTY_COAL_PURCH = as.numeric(QTY_COAL_PURCH), 
         PRICE_PER_TON = as.numeric(PRICE_PER_TON), 
         QTY_COAL_PURCH_x_PRICE_PER_TON = QTY_COAL_PURCH*PRICE_PER_TON,
         ln_PRICE_PER_TON = log(PRICE_PER_TON), 
         ln_QTY_COAL_PURCH = log(QTY_COAL_PURCH))

lm1 <- lm(ln_QTY_COAL_PURCH ~ ln_PRICE_PER_TON, data = contracts)
summary(lm1)
  
# Aggregate by mine 
contracts_year_mine <- contracts %>%
  group_by(DLVY_YR, KEY_MINE_ID, FUEL_CONTRACT_TYPE) %>%
  summarise(QTY_COAL_PURCH_sum = sum(QTY_COAL_PURCH), 
            QTY_COAL_PURCH_x_PRICE_PER_TON_sum = sum(QTY_COAL_PURCH_x_PRICE_PER_TON)) %>%
  mutate(PRICE_PER_TON_avg_weighted = QTY_COAL_PURCH_x_PRICE_PER_TON_sum/QTY_COAL_PURCH_sum,
         ln_PRICE_PER_TON_avg_weighted = log(PRICE_PER_TON_avg_weighted),
         ln_QTY_COAL_PURCH_sum = log(QTY_COAL_PURCH_sum))

lm2i <- lm(ln_PRICE_PER_TON_avg_weighted ~ ln_QTY_COAL_PURCH_sum, data = contracts_year_mine)
lm2ii <- lm(ln_PRICE_PER_TON_avg_weighted ~ ln_QTY_COAL_PURCH_sum + FUEL_CONTRACT_TYPE, data = contracts_year_mine)

# Aggregate by power plant
contracts_year_powerplant <- contracts %>%
  group_by(DLVY_YR, POWER_PLANT, FUEL_CONTRACT_TYPE) %>%
  summarise(QTY_COAL_PURCH_sum = sum(QTY_COAL_PURCH), 
            QTY_COAL_PURCH_x_PRICE_PER_TON_sum = sum(QTY_COAL_PURCH_x_PRICE_PER_TON)) %>%
  mutate(PRICE_PER_TON_avg_weighted = QTY_COAL_PURCH_x_PRICE_PER_TON_sum/QTY_COAL_PURCH_sum,
         ln_PRICE_PER_TON_avg_weighted = log(PRICE_PER_TON_avg_weighted),
         ln_QTY_COAL_PURCH_sum = log(QTY_COAL_PURCH_sum))

lm3i <- lm(ln_PRICE_PER_TON_avg_weighted ~ ln_QTY_COAL_PURCH_sum, data = contracts_year_powerplant)
lm3ii <- lm(ln_PRICE_PER_TON_avg_weighted ~ ln_QTY_COAL_PURCH_sum + FUEL_CONTRACT_TYPE, data = contracts_year_powerplant)

##-----##
# Seam height
##-----##

seamheight <- read_excel(file.path(ddir, "capiq", "SPGlobal_Export_seam_height.xls"), skip = 3, col_types = "text", na = "NA") %>%
  filter(!is.na(MSHA_MINE_ID))

for (i in 4:24) {
  year <- 2026-i
  colnames(seamheight)[i] <- as.character(year)
}

seamheight_long <- seamheight %>%
  select(-NAME, -MSHA_MINE_ID) %>%
  melt(id = "MINE_UNIQUE_IDENTIFIER", variable.name = "year", value.name = "seam_height_in") %>%
  mutate(na_indicator = ifelse(is.na(seam_height_in), 1, 0),
         ones = 1, 
         seam_height_in = as.numeric(seam_height_in)) %>%
  rename(KEY_MINE_ID = MINE_UNIQUE_IDENTIFIER, 
         DLVY_YR = year)
sum(seamheight_long$na_indicator)/sum(seamheight_long$ones)
hist(capiq_full$seam_height_in)

msha_capiq_crosswalk <- seamheight %>%
  select(MINE_UNIQUE_IDENTIFIER, MSHA_MINE_ID)

capiq_full <- seamheight_long %>%
  right_join(contracts, by = c("KEY_MINE_ID", "DLVY_YR"))

iv_first_stage <- lm(ln_PRICE_PER_TON ~ seam_height_in, data = capiq_full)
summary(iv_first_stage)

write_csv(capiq_full, file.path(ddir, "cleaned", "capiq_cleaned.csv"))

