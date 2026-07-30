# THE ROAD SALT AND PACIFIC SALMON SUCCESS PROJECT - North Shore Streamkeepers Summary 2021-2024
# Code written by: Clare L. Kilgour
# Last Edited: October 2025

# 0 NOTES ---------------------------------------------------------------------
# Atomic weight Na = 23 g/mol
# Atomic weight Cl = 35.5 g/mol
# Atomic weight NaCl = 58.44 g/mol

# 1 SETTING UP WORKSPACE ------------------------------------------------------
rm(list=ls()) #this cleans up the workspace (gets rid of variables etc)
# no-op in Rscript (fresh environment per invocation)

## 1.1 Load Packages ----

# conflicted must be loaded before other packages so its shims are in place
# when conflicting names are introduced. conflict_prefer() calls must come after
# the packages that create the conflicts, so preferences can be registered against
# known conflicts.
library(conflicted)

library(tidyverse)
library(lubridate)
library(gt)
library(grid)
library(ragg)

# Resolve ambiguities between dplyr and stats for functions used in the analysis.
# dplyr masking stats is already the default behaviour due to load order, but
# conflict_prefer() enforces this explicitly rather than relying on that implicit order.
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# Use ragg for all ggsave() bitmap output — consistent device across headless and RStudio,
# independent of OS graphics stack (Cairo/Quartz/GDI).
options(ggplot2.use_agg = TRUE)

########################################
# traceback()

# enable traceback effectively for debugging
if (!interactive()) {
  options(error = function() {
    traceback(2)
    quit(status = 1)
  })
}
########################################

## 1.1.1 Source files ----
# Resolve the directory containing this script so external files can be sourced by path
# regardless of the working directory at invocation time.
# Rscript:   derived from --file= in commandArgs(trailingOnly = FALSE)
# RStudio:   falls back to getwd(), which is the project root via the .Rproj file
.script_dir <- if (!interactive()) {
  file_arg <- grep("--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  dirname(normalizePath(sub("--file=", "", file_arg[1])))
} else {
  getwd()
}
source(file.path(.script_dir, "render.R")) # save_gt_png: renders gt tables to PNG
source(file.path(.script_dir, "shell.R"))  # parse_args, input_file_arg, output_dir_arg: command-line argument parsing

########################################
## 1.1.2 Shell argument processing ----
parsed     <- parse_args(commandArgs(trailingOnly = TRUE))
input_file <- parsed[[input_file_arg]]
if (is.null(input_file)) stop("internal error: parse_args returned NULL for input_file")
output_dir <- parsed[[output_dir_arg]]
if (is.null(output_dir)) stop("internal error: parse_args returned NULL for output_dir")
cat("\nInput CSV file: ", input_file, "\n")
## 1.1.3 Output directory ----
# output_dir is fully resolved by parse_args() in shell.R (section 1.1.2).
cat("Output directory: ", output_dir, "\n")
# Create parent and subdirectories
if (!dir.create(output_dir, recursive = TRUE, showWarnings = FALSE) && !dir.exists(output_dir)) {
    stop("Failed to create output directory: ", output_dir)
}
data_dir <- file.path(output_dir, "02 Data")
plot_dir <- file.path(output_dir, "03 Outputs")
for (d in c(data_dir, plot_dir)) {
    if (!dir.create(d, recursive = TRUE, showWarnings = FALSE) && !dir.exists(d)) {
        stop("Failed to create subdirectory: ", d)
    }
}

############################
## 1.2 Setup file path for outputs ----

# Full path for the filtered Wagg dataset (monitoring locations WAGG01 and WAGG03, with non‑missing specific conductance).
wagg_path <- file.path(data_dir, "Wagg.csv")

# Full path for short‑term acute pulse CSV
stapulses_path <- file.path(data_dir, "WaggSTAPulses.csv")

# Full path for long‑term chronic pulse CSV
ltcpulses_path <- file.path(data_dir, "WaggLTCPulses.csv")

# Full path for combined bootstrap results CSV
combined_path <- file.path(output_dir, "combined_results.csv")

# Full paths for pulse summary table PNGs
wagg01_table_path   <- file.path(plot_dir, "WAGG01PulseSummaryTable.png")
wagg03_table_path   <- file.path(plot_dir, "WAGG03PulseSummaryTable.png")

# Full paths for ggplot PNGs
chloride_summary_path <- file.path(plot_dir, "WaggSurfaceWaterChloride2022-25.png")
chloride_pulses_path  <- file.path(plot_dir, "WaggSurfaceWaterChloride2021-25CircledPulses.png")
pulse_types_path      <- file.path(plot_dir, "WaggPulseTypes.png")
ltc_exceedance_path   <- file.path(plot_dir, "OddsofLTCExceedbyMonthTraceWagg.png")

# Full path for the default R plot device output
rplots_path <- file.path(output_dir, "Rplots.pdf")
if (!interactive()) pdf(file = rplots_path)
#############################

# 2 LOADING DATA --------------------------------------------------------------
Data <- read.csv(input_file) %>%
  select(MonitoringLocationID, MonitoringLocationName,MonitoringLocationLatitude,MonitoringLocationLongitude,
         MonitoringLocationType,ActivityType,ActivityMediaName,ActivityStartDate,ActivityStartTime,
         SampleCollectionEquipmentName,CharacteristicName,ResultValue) 
# 16,147,708 obs.

# 3 TIDYING DATA --------------------------------------------------------------
# Data checks
summary(Data)
sapply(Data, function(x) sum(is.na(x)))
colnames(Data)

# Checking for duplicates 
DataDups <- Data %>%
  group_by(MonitoringLocationID, MonitoringLocationName, MonitoringLocationLatitude,
           MonitoringLocationLongitude, MonitoringLocationType, ActivityType, ActivityMediaName, ActivityStartDate,
           ActivityStartTime, SampleCollectionEquipmentName, CharacteristicName) %>%
  summarise(n = n(), .groups = "drop") %>%
  filter(n > 1L) # 30,261 obs.

DataDups$MonitoringLocationID <- as.factor(DataDups$MonitoringLocationID)
DataDups$CharacteristicName <- as.factor(DataDups$CharacteristicName) 

# Removing duplicates 
Data2 <- Data %>% 
  distinct(MonitoringLocationID, MonitoringLocationName, MonitoringLocationLatitude, MonitoringLocationLongitude,
           MonitoringLocationType, ActivityType, ActivityMediaName, ActivityStartDate, ActivityStartTime,
           SampleCollectionEquipmentName, CharacteristicName, 
           .keep_all = TRUE) # the number of observations should be equal to the total obs. in the og data set, minus the dupes
# 16147708 obs. - 30261 obs. = 16117447 is CORRECT

DataWide <- Data2 %>% 
  group_by(MonitoringLocationID,ActivityStartDate,ActivityStartTime) %>% 
  pivot_wider(names_from = CharacteristicName, values_from = ResultValue) 

DataWide$MonitoringLocationID <- as.factor(DataWide$MonitoringLocationID)
levels(DataWide$MonitoringLocationID) # checking all locations present

## 3.1 Converting to NaCl (mg/L) (mM) -----
DataWide$Cl_mgL <- (DataWide$`Specific conductance`) * 0.3117 #Kistriz, gives Cl in mg/L)
DataWide$Cl_mM <- (DataWide$Cl_mgL)/35.5 #divide by molar mass Cl to give mM
#Assume all chloride is from NaCl
DataWide$NaCl_mgL <- (DataWide$Cl_mM)*58.44 #multiply by the molar mass of NaCl to give mg/L

## 3.2 Pulling out Year, monthday, and datetime -----
DataWide$ActivityStartDate <- as.Date(DataWide$ActivityStartDate)
DataWide$Year <- as.numeric(format(DataWide$ActivityStartDate, "%Y"))
DataWide$monthday <- format(DataWide$ActivityStartDate, "%m-%d")
#DataWide$monthday <- as.Date(DataWide$monthday, "%m-%d") #makes every date 2023, which works I guess
DataWide$datetime <- as.POSIXct(paste(DataWide$ActivityStartDate,
                                      DataWide$ActivityStartTime),
                                format = "%Y-%m-%d %H:%M:%S")

# Data Checks 
sum(is.na(DataWide$datetime)) # 467 obs.

## 4.3 Dealing with problematic dates
problem_rows <- DataWide %>% filter(is.na(datetime)) #467 obs.from March 10-14 2024 across various locations
unique(problem_rows$ActivityStartDate)
unique(problem_rows$ActivityStartTime)

problem_rows$parsed_dates <- as.Date(problem_rows$ActivityStartDate, format = "%Y-%m-%d")
problem_rows$parsed_times <- strptime(problem_rows$ActivityStartTime, format = "%H:%M:%S")

problem_rows <- problem_rows %>%
  mutate(
    ActivityStartDate = str_trim(ActivityStartDate),
    ActivityStartTime = str_trim(ActivityStartTime)
  )

problem_rows$parsed_datetime <- as.POSIXct(
  paste(problem_rows$ActivityStartDate, problem_rows$ActivityStartTime),
  format = "%Y-%m-%d %H:%M:%S",
  tz = "UTC"
)

problem_rows$ActivityStartDate <- as.Date(problem_rows$ActivityStartDate)

na_indices <- which(is.na(DataWide$datetime))

# Update datetime only for rows with NA values using parsed_datetime from problem_rows
DataWide$datetime[na_indices] <- problem_rows$parsed_datetime[match(
  paste(DataWide$MonitoringLocationID[na_indices], 
        DataWide$ActivityStartDate[na_indices], 
        DataWide$ActivityStartTime[na_indices]),
  paste(problem_rows$MonitoringLocationID, 
        problem_rows$ActivityStartDate, 
        problem_rows$ActivityStartTime)
)]

## 3.4 Adding BC's WQGs for Cl  -----
DataWide$LTC <- as.numeric("150") 
DataWide$STA <- as.numeric("600") 
DataWide$LTCExceed <- ifelse(DataWide$Cl_mgL>150,"Yes","No")
DataWide$LTCExceed <- as.factor(DataWide$LTCExceed)
DataWide$STAExceed <- ifelse(DataWide$Cl_mgL>600, "Yes", "No")
DataWide$STAExceed <- as.factor(DataWide$STAExceed)

Wagg <- DataWide %>%
  subset(MonitoringLocationID %in% c('WAGG01',"WAGG03")) %>%
  subset(!is.na(`Specific conductance`))
#254,548 obs.

write.csv(Wagg, wagg_path, row.names = FALSE)

# 4 FINDING PULSES ------------------------------------------------------------
## 4.1 Short-term acute pulses (exceed the acute water quality guideline) -----
STAPulses <- Wagg %>%
  filter(Cl_mgL > 600) %>%
  filter(MonitoringLocationType == "River/Stream") %>%
  arrange(MonitoringLocationID, datetime) %>%
  group_by(MonitoringLocationID) %>%
  mutate(
    time_diff = c(0, diff(datetime)),  # Time difference between rows
    exceedance = Cl_mgL > 600,
    pulse_id = cumsum(  # Assign pulse IDs
      time_diff > 1 * 60 * 60 |
        (!exceedance & lag(exceedance, default = FALSE) &
           lead(exceedance, default = FALSE) &
           lead(time_diff, default = Inf) <= 1 * 60 * 60)
    ),
    WaterTemp = `Temperature, water`
  ) %>%
  ungroup() %>%
  group_by(MonitoringLocationID, pulse_id) %>%
  summarise(
    Start = min(datetime),
    End = max(datetime),
    PeakValue = max(Cl_mgL), # maximum concentration attained by each pulse
    PeakDate = datetime[which.max(Cl_mgL)],  # Identify date of max Cl_mgL
    CumulativeDose = sum((Cl_mgL[-1] + Cl_mgL[-n()]) * diff(as.numeric(datetime)) / 2/ 60 / 60, na.rm = TRUE), #Cumulative Dose in mg*h/L
    AvgWaterTemp = mean(WaterTemp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Merge overlapping pulses
  group_by(MonitoringLocationID) %>%
  mutate(
    merged_pulse_id = cumsum(Start > lag(End, default = min(Start))) + 1
  ) %>%
  group_by(MonitoringLocationID, merged_pulse_id) %>%
  summarise(
    Start = min(Start),
    End = max(End),
    PeakValue = max(PeakValue),
    PeakDate = as.Date(PeakDate[which.max(PeakValue)],),
    Duration = as.numeric(difftime(max(End), min(Start), units = "days")),
    CumulativeDose = sum(CumulativeDose, na.rm = TRUE),  # Combine cumulative doses of merged peaks
    AvgWaterTemp = mean(AvgWaterTemp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(Duration > 0) #Remove pulses with zero duration
write.csv(STAPulses, stapulses_path, row.names = FALSE)

## 4.2 Long-term acute pulses (exceed the chronic water quality guideline) ----
LTCPulses <- Wagg %>%
  filter(Cl_mgL > 150) %>%
  filter(MonitoringLocationType == "River/Stream") %>%
  arrange(MonitoringLocationID, datetime) %>%
  group_by(MonitoringLocationID) %>%
  mutate(
    time_diff = c(0, diff(datetime)),  # Time difference between rows
    exceedance = Cl_mgL > 150,
    pulse_id = cumsum(  # Assign pulse IDs
      time_diff > 1 * 60 * 60 |
        (!exceedance & lag(exceedance, default = FALSE) &
           lead(exceedance, default = FALSE) &
           lead(time_diff, default = Inf) <= 1 * 60 * 60)
    ),
    WaterTemp = `Temperature, water`
  ) %>%
  ungroup() %>%
  group_by(MonitoringLocationID, pulse_id) %>%
  summarise(
    Start = min(datetime),
    End = max(datetime),
    PeakValue = max(Cl_mgL), # maximum concentration attained by each pulse
    PeakDate = datetime[which.max(Cl_mgL)],  # Identify date of max Cl_mgL
    CumulativeDose = sum((Cl_mgL[-1] + Cl_mgL[-n()]) * diff(as.numeric(datetime)) / 2/ 60 / 60, na.rm = TRUE), #Cumulative Dose in mg*h/L
    AvgWaterTemp = mean(WaterTemp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  # Merge overlapping pulses
  group_by(MonitoringLocationID) %>%
  mutate(
    merged_pulse_id = cumsum(Start > lag(End, default = min(Start))) + 1
  ) %>%
  group_by(MonitoringLocationID, merged_pulse_id) %>%
  summarise(
    Start = min(Start),
    End = max(End),
    PeakValue = max(PeakValue),
    PeakDate = as.Date(PeakDate[which.max(PeakValue)],),
    Duration = as.numeric(difftime(max(End), min(Start), units = "days")),
    CumulativeDose = sum(CumulativeDose, na.rm = TRUE),  # Combine cumulative doses of merged peaks
    AvgWaterTemp = mean(AvgWaterTemp, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  filter(Duration > 0) #Remove pulses with zero duration
write.csv(LTCPulses, ltcpulses_path, row.names = FALSE)

# just the pulses which exceed the long-term chronic guideline, but not the acute
LTCPulses_unique <- anti_join(LTCPulses, STAPulses, by = c("PeakDate", "PeakValue"))

# 5 PLOTTING ------------------------------------------------------------------
## 5.1 Conductivity and calculated chloride summary ----
gg <- ggplot(data = Wagg %>%
               subset(!is.na(`Specific conductance`)), # Don't want any empty values
             aes(x = ActivityStartDate, y = `Specific conductance`))
gg <- gg + geom_line(aes(colour = MonitoringLocationID), alpha = 0.7) 
gg <- gg + scale_y_continuous(name = "Specific Conductance (μS/cm)",
                              sec.axis = sec_axis(transform=~.*0.3117, name = "Calculated Chloride (mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 600/0.3117, linetype = "Short Term Acute (600 mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 150 / 0.3117, linetype = "Long Term Chronic (150 mg/L)")) 
gg <- gg + scale_linetype_manual(values = c("Long Term Chronic (150 mg/L)" = "dashed", "Short Term Acute (600 mg/L)" = "solid"))
gg <- gg + scale_colour_manual(values = c("#0E7C7B","#F76C5E"))
gg <- gg + labs(linetype = "BC Water Quality Guidelines\nfor Chloride",
                colour = "Monitoring Location", 
                x = "Date")
gg <- gg + theme(text = element_text(size = 15))
gg <- gg + theme_bw()
gg 
# height matches the RStudio Plots pane default (5.94 in / 1781 px at 300 dpi).
# Without an explicit height, ggsave() inherits the current device height:
# headless uses the pdf() device default (7 in), RStudio uses the pane size — producing different outputs.
ggsave(filename = chloride_summary_path, plot = gg, width = 10, height = 5.94)

## 5.2 Highlighting pulse events ----
gg <- ggplot(data = Wagg %>%
               subset(!is.na(`Specific conductance`)), # Don't want any empty values
             aes(x = ActivityStartDate, y = `Specific conductance`))
gg <- gg + geom_line(aes(colour = MonitoringLocationID), alpha = 0.7) 
gg <- gg + geom_point(data = STAPulses, aes(x = PeakDate, y = (PeakValue/0.3117), fill = "Pulses above the acute guideline"), colour = "red", pch = 21, size = 4, stroke = 1, alpha = 0.5)
gg <- gg + geom_point(data = LTCPulses_unique, aes(x = PeakDate, y = (PeakValue/0.3117), fill = "Pulses above the chronic guideline"), colour = "orange", pch = 21, size = 2, stroke = 1, alpha = 0.5)
gg <- gg + scale_y_continuous(name = "Specific Conductance (μS/cm)",
                              sec.axis = sec_axis(transform=~.*0.3117, name = "Calculated Chloride (mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 600/0.3117, linetype = "Short Term Acute (600 mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 150 / 0.3117, linetype = "Long Term Chronic (150 mg/L)")) 
gg <- gg + scale_linetype_manual(values = c("Long Term Chronic (150 mg/L)" = "dashed", "Short Term Acute (600 mg/L)" = "solid"))
gg <- gg + scale_colour_manual(values = c("#0E7C7B","#F76C5E"))
gg <- gg + scale_fill_manual(values = c("Pulses above the chronic guideline" = "orange","Pulses above the acute guideline" = "red"))
gg <- gg + labs(linetype = "BC Water Quality Guidelines\nfor Chloride",
                colour = "Monitoring Location", 
                fill = "Pulse Type",
                x = "Date")
gg <- gg + theme(text = element_text(size = 15))
gg <- gg + theme_bw()
gg 
ggsave(filename = chloride_pulses_path, plot = gg, width = 10, height = 5.94)

# 6 KEY VALUES ----------------------------------------------------------------
## 6.1 Total number of unique pulses ---
STAPulses_unique <- STAPulses %>%
  anti_join(LTCPulses, 
            by = c("PeakDate","PeakValue")) # sometimes distinct acute pulses occur without being counted as distinct chronic pulses

PulsesTable <- LTCPulses %>%
  bind_rows(STAPulses_unique) %>%
  arrange(PeakDate) %>%
  mutate(PulseType = if_else(
    PeakDate %in% LTCPulses_unique$PeakDate & PeakValue %in% LTCPulses_unique$PeakValue,
    "Above Chronic WQG","Above Acute WQG")) %>%
  select(-merged_pulse_id)

## 6.1 Number of pulses ----
print(count(PulsesTable))
# 44

## 6.3 Most common months ----
PulsesTableMonths <- PulsesTable %>%
  mutate(month = month(PeakDate, label = TRUE, abbr = FALSE), 
         month = factor(month, levels = c("September","October","November","December","January","February","March","April","May","June","July","August")),
         PulseType = if_else(
           PeakDate %in% LTCPulses_unique$PeakDate & PeakValue %in% LTCPulses_unique$PeakValue,
           "Above the chronic guideline","Above the acute guideline")) 

gg <- ggplot(data = PulsesTableMonths, aes(x = month))
gg <- gg + geom_bar(aes(fill = PulseType), position = position_dodge(preserve = "single"))
gg <- gg + scale_fill_manual(values = c("red","orange"))
gg <- gg + theme_bw()
gg <- gg + labs(x = "Month",
                y = "Pulse Count",
                fill = "Pulse Type")
gg <- gg + facet_wrap(~MonitoringLocationID, ncol = 1, scales = "free_y")
gg
ggsave(filename = pulse_types_path, plot = gg, width = 12, height = 5.94)

## 6.3 Summary table ----
### WAGG01
PulsesTablegt <- PulsesTable %>%
  subset(MonitoringLocationID == "WAGG01") %>%
  gt() %>%
  tab_header(
    title = "Chloride Pulse Events in Wagg Creek 2021-2024"
  ) %>%
  cols_label(
    MonitoringLocationID = "Monitoring Location",
    Start = " Pulse Start Time",
    End = "Pulse End Time",
    PeakValue = "Peak Cl (mg/L)",
    PeakDate = "Peak Date",
    Duration = "Duration (days)",
    CumulativeDose = "Cumulative Concentration (mg·h/L)",
    AvgWaterTemp = "Avg Water Temp (°C)",
    PulseType = "Pulse Type"
  ) %>%
  fmt_number(
    columns = c(PeakValue, CumulativeDose),
    decimals = 0
  ) %>%
  fmt_number(
    columns = c(Duration, AvgWaterTemp),
    decimals = 2
  ) %>%
  fmt_datetime(
    columns = c(Start, End),
    date_style = "iso",
    time_style = "h_m_p"
  ) %>%
  tab_style(
    style = cell_fill(color = "#FF000080"),  # semi-transparent red
    locations = cells_body(
      columns = PulseType,
      rows = PulseType == "Above Acute WQG"
    )
  ) %>%
  tab_style(
    style = cell_fill(color = "#FFA50080"),  # semi-transparent orange
    locations = cells_body(
      columns = PulseType,
      rows = PulseType == "Above Chronic WQG"
    )
  ) %>%
  tab_options(
    table.font.size = "small",
    row.striping.include_table_body = TRUE,
    row.striping.background_color = "#f9f9f9"
  ) %>%
  tab_options(
    table.font.size = "small",
    row.striping.include_table_body = TRUE,
    row.striping.background_color = "#f9f9f9"
  )
save_gt_png(PulsesTablegt, wagg01_table_path, width = 2000)

### WAGG03
PulsesTablegt <- PulsesTable %>%
  subset(MonitoringLocationID == "WAGG03") %>%
  gt() %>%
  tab_header(
    title = "Chloride Pulse Events in Wagg Creek 2021-2024"
  ) %>%
  cols_label(
    MonitoringLocationID = "Monitoring Location",
    Start = " Pulse Start Time",
    End = "Pulse End Time",
    PeakValue = "Peak Cl (mg/L)",
    PeakDate = "Peak Date",
    Duration = "Duration (days)",
    CumulativeDose = "Cumulative Concentration (mg·h/L)",
    AvgWaterTemp = "Avg Water Temp (°C)",
    PulseType = "Pulse Type"
  ) %>%
  fmt_number(
    columns = c(PeakValue, CumulativeDose),
    decimals = 0
  ) %>%
  fmt_number(
    columns = c(Duration, AvgWaterTemp),
    decimals = 2
  ) %>%
  fmt_datetime(
    columns = c(Start, End),
    date_style = "iso",
    time_style = "h_m_p"
  ) %>%
  tab_style(
    style = cell_fill(color = "#FF000080"),  # semi-transparent red
    locations = cells_body(
      columns = PulseType,
      rows = PulseType == "Above Acute WQG"
    )
  ) %>%
  tab_style(
    style = cell_fill(color = "#FFA50080"),  # semi-transparent orange
    locations = cells_body(
      columns = PulseType,
      rows = PulseType == "Above Chronic WQG"
    )
  ) %>%
  tab_options(
    table.font.size = "small",
    row.striping.include_table_body = TRUE,
    row.striping.background_color = "#f9f9f9"
  ) %>%
  tab_options(
    table.font.size = "small",
    row.striping.include_table_body = TRUE,
    row.striping.background_color = "#f9f9f9"
  )
save_gt_png(PulsesTablegt, wagg03_table_path, width = 2000)

# 7 EXCEEDANCE OF LTC WQG BOOTSTRAPPING ---------------------------------------
Wagg <- read.csv(wagg_path)

monthly_coverage <- Wagg %>%
  filter(!is.na(Cl_mgL)) %>%
  filter(MonitoringLocationType == "River/Stream") %>%
  mutate(
    year = year(datetime),
    month = month(datetime),
    date = as_date(datetime)
  ) %>%
  group_by(MonitoringLocationID, year, month) %>%
  summarise(
    n_days_with_data = n_distinct(date),
    total_days_in_month = days_in_month(first(date)),
    .groups = "drop"
  ) %>%
  filter(n_days_with_data >= 10)  # Keep only months with at least 10 days of data

DataBoot <- Wagg %>%
  filter(!is.na(Cl_mgL)) %>%
  filter(MonitoringLocationType == "River/Stream") %>%
  mutate(
    year = year(datetime),
    month = month(datetime)
  ) %>%
  inner_join(
    monthly_coverage %>% select(MonitoringLocationID, year, month),
    by = c("MonitoringLocationID", "year", "month")
  ) %>%
  droplevels()

# Make MonitoringLocationID a factor and check levels
DataBoot$MonitoringLocationID <- as.factor(DataBoot$MonitoringLocationID)
levels(DataBoot$MonitoringLocationID)

# Set parameters
set.seed(10) 
guideline <- 150 # Long-term chronic guideline (BC)
n_samples <- 5 # Samples per month
total_iterations <- 1000 # Total number of iterations
batch_size <- 10 # Iterations per batch (easier on computing power)

combined_results <- tibble(
  MonitoringLocationID = character(),
  Month = character(),
  RiskOfExceedance = numeric()
)

# Bootstrap function
bootstrap_sampling_monthly <- function(data, n_iterations, guideline, n_samples) {
  exceedance_results <- rep(NA, n_iterations)  # Store results of each iteration
  
  for (i in 1:n_iterations) {
    # Randomly select the start day
    start_day <- sample(1:min(7, nrow(data)), 1)  # Random start day
    sampled_days <- seq(from = start_day, by = 5, length.out = n_samples)
    sampled_days <- sampled_days[sampled_days <= nrow(data)]  # Ensure valid indices
    
    if (length(sampled_days) == n_samples) {
      # Subset data for selected days
      sampled_data <- data[sampled_days, ]
      
      # Randomly select one datetime per day
      sampled_data <- sampled_data %>%
        group_by(as.Date(ActivityStartDate)) %>%  # Group by day
        sample_n(1) %>%  # Randomly select one datetime per group
        ungroup()
      
      # Calculate mean chloride for the selected datetimes
      mean_chloride <- mean(sampled_data$Cl_mgL, na.rm = TRUE)
      exceedance_results[i] <- mean_chloride > guideline
    }
  }
  
  return(mean(exceedance_results, na.rm = TRUE))
}

# Initialize .csv file 
write.csv(combined_results, combined_path, row.names = FALSE)

# Run in batches
for (i in seq(1, total_iterations, by = batch_size)) {
  print(paste("Running batch", i, "to", i + batch_size - 1))
  
  # Perform batch bootstrapping
  batch_results <- DataBoot %>%
    mutate(Month = format(as.Date(ActivityStartDate), "%Y-%m")) %>%
    group_split(MonitoringLocationID, Month) %>%
    purrr::map_dfr(~ {
      data <- .x
      location_id <- unique(data$MonitoringLocationID)
      month <- unique(data$Month)
      risk <- bootstrap_sampling_monthly(
        data = data,
        n_iterations = batch_size,  # Run for the current batch size
        guideline = guideline,
        n_samples = n_samples
      )
      tibble(MonitoringLocationID = location_id,
             Month = month,
             RiskOfExceedance = risk)
    })
  
  # Combine batch results in memory
  combined_results <- bind_rows(combined_results, batch_results)
  
  
  # Write batch results to the .csv file
  write.table(batch_results, combined_path, append = TRUE, sep = ",",
              row.names = FALSE, col.names = FALSE)  # Avoid writing headers again
}

combined_results <- read.csv(combined_path)

# Aggregate results across batches
final_results <- combined_results %>%
  mutate(Year = year(ym(Month)),
         onlymonth = month(ym(Month))) %>%
  group_by(MonitoringLocationID, Year, onlymonth) %>%
  summarize(
    RiskOfExceedance = mean(RiskOfExceedance, na.rm = TRUE),
    .groups = "drop"
  )

final_results$MonitoringLocationID <- factor(
  final_results$MonitoringLocationID,
  levels = rev(sort(unique(final_results$MonitoringLocationID)))
)

shading <- final_results %>%
  mutate(
    start = as.Date(paste(Year, onlymonth, "01", sep = "-")),
    end = start + months(1),
    ymin = -Inf,
    ymax = Inf)

Wagg$ActivityStartDate <- as.Date(Wagg$ActivityStartDate)

gg <- ggplot(data = Wagg %>%
               subset(!is.na(`Specific.conductance`)), # Don't want any empty values
             aes(x = ActivityStartDate, y = `Specific.conductance`))
gg <- gg + geom_line(aes(colour = MonitoringLocationID), alpha = 1) 
gg <- gg + scale_y_continuous(name = "Specific Conductance (μS/cm)",
                              sec.axis = sec_axis(transform=~.*0.3117, name = "Calculated Chloride (mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 600/0.3117, linetype = "Short Term Acute (600 mg/L)"))
gg <- gg + geom_hline(aes(yintercept = 150 / 0.3117, linetype = "Long Term Chronic (150 mg/L)")) 
gg <- gg + scale_linetype_manual(values = c("Long Term Chronic (150 mg/L)" = "dashed", "Short Term Acute (600 mg/L)" = "solid"))
gg <- gg + scale_colour_manual(values = c("#0E7C7B","#F76C5E"))
gg <- gg + labs(linetype = "BC Water Quality Guidelines\nfor Chloride",
                colour = "Monitoring Location", 
                x = "Date",
                alpha = "Monthly Odds of Capturing an \nExceedance of BC's\nLong-Term Chronic \nGuideline for Chloride (%)")
gg <- gg + theme(text = element_text(size = 15))
gg <- gg + theme_bw()
gg <- gg + geom_rect(
  data = shading,
  inherit.aes = FALSE,
  aes(xmin = start, xmax = end, ymin = ymin, ymax = ymax, 
      alpha = RiskOfExceedance*100))
gg <- gg + scale_alpha_continuous(range = c(0, 0.4),
                                  breaks = c(0, 10, 20,30,40, 50))
gg <- gg + facet_wrap(~MonitoringLocationID, ncol = 1, scales = "free_y")
gg <- gg + coord_cartesian(ylim = c(0,2000))
gg 
ggsave(filename = ltc_exceedance_path, plot = gg, width = 10, height = 5.94)

# Close the PDF device opened at rplots_path; matches the pdf() call in section 1.2
if (!interactive()) invisible(dev.off())
