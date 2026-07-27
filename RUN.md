# Running the Analysis

## Data

Input data is a CSV export from the [CoSMo / CIOOS data portal](https://cioos.ca).

**[PLACEHOLDER: DESCRIBE THE SPECIFIC DATASET, SEARCH PARAMETERS, OR DOWNLOAD STEPS NEEDED TO REPRODUCE THE INPUT FILE]**

The default interactive filename is `May_30_2025_Download.csv` placed at the project root. A different file can be supplied at runtime — see below.

---

## Headless (Rscript)

Run from the project root:

```bash
Rscript NSSK.R <input_csv_file> [-o <output_dir>]
```

`<input_csv_file>` — path to the CoSMo CSV export.

`-o <output_dir>` — optional. Directory under which the output tree will be written. If omitted, a timestamped directory is created in the current working directory (`analysis-YYYYMMDD-HHMMSS/`).

### Examples

```bash
# Timestamped output in cwd
Rscript NSSK.R data/May_30_2025_Download.csv

# Explicit output directory
Rscript NSSK.R data/May_30_2025_Download.csv -o results/may-2025
```

### Output location

```
<output_dir>/
  02 Data/
  03 Outputs/
  combined_results.csv
  Rplots.pdf
```

All plots are additionally written individually as PNGs under `03 Outputs/`. `Rplots.pdf` collects all plots in a single file and is only produced in headless mode.

---

## Interactive (RStudio)

Open `NSSK Analysis.Rproj` in RStudio and source `NSSK.R`.

By default the script reads `./May_30_2025_Download.csv` relative to the project root. Place the CoSMo export there before sourcing, or update the default path near the top of section 1.2.

Output is written to a timestamped directory in the project root. Plots are displayed sequentially in the RStudio Plots pane during the run and are navigable via the pane's history arrows. `Rplots.pdf` is not produced in interactive mode.

---

## Help

```bash
Rscript NSSK.R --help
```
