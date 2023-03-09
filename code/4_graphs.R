# Last updated: Mar 5, 2023

library(tidyverse)
library(haven)

ddir_cedric <- "/Users/gelkouh/Google Drive (UChicago)/Classes/ECON 21110/data/"
cdir_cedric <- "/Users/gelkouh/Library/CloudStorage/OneDrive-Personal/Documents/School/UChicago/Year 4/ECON 21110/FINAL PROJECT/econ-21110-winter-2023/"
ddir_matt <- './data/'
ddir <- ddir_matt

##----------##
# Fig 4 Replication
##----------##

rep_df <- read_dta(paste0(ddir,'/ChinaCoalElasticity.dta'))

fig4_df <- rep_df %>%
  group_by(year) %>%
  drop_na(year,coalpriceindex,ppi,coalprice_usd_imf,yuanperdollar) %>%
  summarise(avg_coalpriceindex = mean(coalpriceindex),
            avg_ppi = mean(ppi),
            avg_foreigncoalprice = mean(coalprice_usd_imf * yuanperdollar))

fig4_df$avg_coalpriceindex = fig4_df$avg_coalpriceindex / 
  fig4_df$avg_coalpriceindex[1]
fig4_df$avg_ppi = fig4_df$avg_ppi / 
  fig4_df$avg_ppi[1]
fig4_df$avg_foreigncoalprice = fig4_df$avg_foreigncoalprice / 
  fig4_df$avg_foreigncoalprice[1]

# dropping some data in 2012?
ggplot(data = fig4_df, mapping = aes(x=year)) + 
  geom_line(mapping = aes(y = avg_ppi), linetype = 'longdash', color = 'gray') + 
  geom_line(mapping = aes(y = avg_coalpriceindex), color = 'black') +
  geom_line(mapping = aes(y = avg_foreigncoalprice),
            linetype = 'dotted', color = 'black') +
  theme_classic() + ggtitle("Replication of Fig.4") +
  ylab("Index (1998 = 1 . Qinghuangdao index = coal price index in 2003)") +
  scale_x_continuous(breaks = seq(1998,2012,2),limits=c(1998,2012)) +
  scale_y_continuous(breaks = seq(0.5,3,0.5),limits=c(0.5,3.5)) +
  theme(plot.title = element_text(size = 18, hjust = 0.5),
        axis.title.x=element_blank(),
        axis.text.x=element_text(size = 12),
        axis.title.y=element_text(size = 14),
        axis.text.y=element_text(size = 12))
ggsave(filename = 'fig4rep.png',
       path = './output',
       device = "png",
       width = 22,
       height = 18,
       limitsize = FALSE,
       dpi = 175,
       units = "cm")

  
##----------##
# Elasticity CIs (Replication)
##----------##

# 1998-2007, 2008-2012
year <- c(2001.5,2008.5)
point_est <- c(0.0795,-0.179)
se <- c(0.1303,0.0718)
repCI_df <- tibble(year,point_est,se) %>%
  mutate(wd = 1.96 * se)

ggplot(data = repCI_df, mapping = aes(x=year,y = point_est)) + 
  geom_point() + 
  geom_errorbar(aes(ymin=point_est-wd, ymax=point_est+wd), width=0.75) + 
  geom_hline(yintercept = 0, alpha = 0.4, linetype = 'longdash') + 
  theme_classic() + ggtitle("Change in Demand Elasticity for Coal in China") +
  ylab("95% CI for Demand Elasticity of Coal") +
  scale_x_continuous(breaks = c(1998,2012),limits=c(1998,2012)) +
  theme(plot.title = element_text(size = 18, hjust = 0.5),
        axis.title.x=element_blank(),
        axis.text.x=element_text(size = 12),
        axis.title.y=element_text(size = 14),
        axis.text.y=element_text(size = 12))
ggsave(filename = 'rep_CIs.png',
       path = file.path(ddir, "output"),
       device = "png",
       width = 22,
       height = 18,
       limitsize = FALSE,
       dpi = 175,
       units = "cm")

##----------##
# Elasticity CIs (Extension)
##----------##

# bins are 2002-06, 07-11, 12-16, 17-21
year <- c(2004,2009,2014,2019)
point_est <- c(-5.808,-2.984,-1.092,2.101)
se <- c(0.5802,0.962,1.3146,1.5442)
repCI_df <- tibble(year,point_est,se) %>%
  mutate(wd = 1.96 * se)

ggplot(data = repCI_df, mapping = aes(x=year,y = point_est)) + 
  geom_point() + 
  geom_errorbar(aes(ymin=point_est-wd, ymax=point_est+wd), width=0.75) + 
  geom_hline(yintercept = 0, alpha = 0.4, linetype = 'longdash') + 
  theme_classic() + ggtitle("Change in Demand Elasticity for Coal in the US") +
  ylab("95% CI for Demand Elasticity of Coal") +
  scale_x_continuous(breaks = seq(2002,2022,3),limits=c(2002,2022)) +
  theme(plot.title = element_text(size = 18, hjust = 0.5),
        axis.title.x=element_blank(),
        axis.text.x=element_text(size = 12),
        axis.title.y=element_text(size = 14),
        axis.text.y=element_text(size = 12))
ggsave(filename = 'ext_CIs.png',
       path = file.path(ddir, "output"),
       device = "png",
       width = 22,
       height = 18,
       limitsize = FALSE,
       dpi = 175,
       units = "cm")

