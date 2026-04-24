/* =========================================================================
Project: Structural VAR (SVAR) Analysis of East Asian Economies
FVED Visualisation
Author: tjdqls0716
Date: 2026-04-24 
=========================================================================
*/

# 0. Load Libraries ----
library(tidyverse)

# 1. Global Settings ----
# Define a consistent color palette for all plots
# Dark Blue: Output | Medium Blue: Inflation | Light Blue: Exchange Rate
color_palette <- c("GDP Shock" = "#023858", "CPI Shock" = "#67A9CF", "REER Shock" = "#D1E5F0")

# =========================================================================
# SECTION 1. South Korea (KOR) ----
# =========================================================================

# --- 1.1 KOR: Real GDP Analysis ---
# Load data
df <- read_csv("FEVD-KOR-GDP.csv", skip = 1)
current_var <- "Real GDP"
current_country <- "South Korea"

# Reshape data to long format
df_long <- df_kor_GDP %>%
  pivot_longer(cols = -Step, 
               names_to = "Shock", 
               values_to = "Value") %>%
  mutate(Step = as.numeric(Step))
df_long$Shock <- factor(df_long$Shock, 
                        levels = c("GDP Shock", "CPI Shock", "REER Shock"))

# Plotting: GDP
ggplot(df_long, aes(x = Step, y = Value, fill = Shock)) +
  geom_area(color = "white", linewidth = 0.3, alpha = 0.9) +
  scale_fill_manual(values = color_palette, 
                    breaks = c("GDP Shock", "CPI Shock", "REER Shock"),
                    labels = c("Output (Self)", "Inflation Shock", "Exchange Rate Shock")) +
  scale_y_continuous(labels = scales::percent_format(), expand = c(0,0)) +
  scale_x_continuous(breaks = seq(1, 12, 1), expand = c(0,0)) +
  theme_minimal() +
  theme(
    text = element_text(family = "serif"), 
    plot.title = element_text(face = "bold", size = 15, hjust = 0.5),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "darkblue", face = "italic"),
    legend.position = "bottom",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank()
  ) +
  labs(
    title = paste0("Forecast Error Variance Decomposition: ", current_var),
    subtitle = paste0("Economy: ", current_country),
    x = "Quarters after Shock (Step)",
    y = "Variance Contribution (%)"
  )

# --- 1.2 KOR: CPI Analysis ---
# Load data
df <- read_csv("FEVD-KOR-CPI.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Inflation (Self)] ...

# --- 1.3 KOR: REER Analysis ---
# Load data
df <- read_csv("FEVD-KOR-REER.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Exchange Rate (Self)] ...

# =========================================================================
# SECTION 2. China (CHN) ----
# =========================================================================

# --- 2.1 CHN: Real GDP Analysis ---
df <- read_csv("FEVD-CHN-GDP.csv", skip = 1)
# ... [Continue the same structure for China] ...

# --- 2.2 CHN: CPI Analysis ---
# Load data
df <- read_csv("FEVD-CHN-CPI.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Inflation (Self)] ...

# --- 2.3 CHN: REER Analysis ---
# Load data
df <- read_csv("FEVD-CHN-REER.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Exchange Rate (Self)] ...

# =========================================================================
# SECTION 3. Japan (JPN) ----
# =========================================================================

# --- 3.1 JPN: Real GDP Analysis ---
df <- read_csv("FEVD-JPN-GDP.csv", skip = 1)
# ... [Continue the same structure for Japan] ...

# --- 3.2 JPN: CPI Analysis ---
# Load data
df <- read_csv("FEVD-JPN-CPI.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Inflation (Self)] ...

# --- 3.3 JPN: REER Analysis ---
# Load data
df <- read_csv("FEVD-JPN-REER.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Exchange Rate (Self)] ...

# =========================================================================
# SECTION 4. Taiwan (TWN) ----
# =========================================================================

# --- 4.1 TWN: Real GDP Analysis ---
df <- read_csv("FEVD-TWN-GDP.csv", skip = 1)
# ... [Continue the same structure for Taiwan] ...

# --- 4.2 TWN: CPI Analysis ---
# Load data
df <- read_csv("FEVD-TWN-CPI.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Inflation (Self)] ...

# --- 4.3 TWN: REER Analysis ---
# Load data
df <- read_csv("FEVD-TWN-REER.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Exchange Rate (Self)] ...

# =========================================================================
# SECTION 5. HongKong (HKG) ----
# =========================================================================

# --- 5.1 HKG: Real GDP Analysis ---
df <- read_csv("FEVD-HKG-GDP.csv", skip = 1)
# ... [Continue the same structure for HongKong] ...

# --- 5.2 HKG: CPI Analysis ---
# Load data
df <- read_csv("FEVD-HKG-CPI.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Inflation (Self)] ...

# --- 5.3 HKG: REER Analysis ---
# Load data
df <- read_csv("FEVD-HKG-REER.csv", skip = 1)
# ... [Insert the same ggplot code here, adjust 'labels' for Exchange Rate (Self)] ...
