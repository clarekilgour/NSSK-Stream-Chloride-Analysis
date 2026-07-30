# Running the Analysis

## Headless (Rscript)

Run from the project root:

```bash
Rscript NSSK.R <input_csv_file> [-o <output_dir>]
```

`<input_csv_file>` — path to the CoSMo CSV export.

`-o <output_dir>` — optional. Directory under which the output tree will be written. If omitted, a timestamped directory is created in the current working directory (`analysis-YYYYMMDD-HHMMSS/`).

### Examples

```bash
# By default generates analysis resources in a timestamped directory (e.g. analysis-20260726-215424) in the current working directory
Rscript NSSK.R data/May_30_2025_Download.csv

# Explicit output directory
Rscript NSSK.R data/May_30_2025_Download.csv -o /path/to/analysis_results
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

### Graphics backend

For plot previews in the Plots pane to match the saved PNG output, set the RStudio graphics backend to AGG:

**Tools → Global Options → Graphics → Backend → AGG**

This is a one-time per-user setting. The script sets `options(ggplot2.use_agg = TRUE)` so saved files always use ragg; this setting makes the live preview consistent with them.

---

## Help

```bash
Rscript NSSK.R --help
```
