# NSSK Stream Chloride Analysis

**[ONE SENTENCE SUMMARY OF THE PROJECT AND ITS PURPOSE]**

Original analysis code by [Clare L. Kilgour](https://github.com/clarekilgour).

---

## Overview

**[BRIEF DESCRIPTION OF THE MONITORING CONTEXT — E.G. WATERSHED, TIME PERIOD, REGULATORY BACKGROUND]**

**[BRIEF DESCRIPTION OF WHAT THE ANALYSIS PRODUCES — E.G. PULSE DETECTION, EXCEEDANCE RISK, SUMMARY PLOTS]**

## Methodology

**[PLACEHOLDER: DESCRIBE THE ANALYTICAL APPROACH — CHLORIDE CONVERSION, PULSE DETECTION CRITERIA, BOOTSTRAP EXCEEDANCE METHOD]**

## Outputs

Each run produces a timestamped output directory containing:

| Path | Contents |
|---|---|
| `02 Data/Wagg.csv` | Filtered monitoring data for WAGG01 and WAGG03 |
| `02 Data/WaggSTAPulses.csv` | Detected short-term acute pulse events |
| `02 Data/WaggLTCPulses.csv` | Detected long-term chronic pulse events |
| `03 Outputs/WaggSurfaceWaterChloride2022-25.png` | Conductance and chloride time series |
| `03 Outputs/WaggSurfaceWaterChloride2021-25CircledPulses.png` | Time series with pulse events marked |
| `03 Outputs/WaggPulseTypes.png` | Pulse counts by month and type |
| `03 Outputs/WAGG01PulseSummaryTable.png` | Pulse summary table — WAGG01 |
| `03 Outputs/WAGG03PulseSummaryTable.png` | Pulse summary table — WAGG03 |
| `03 Outputs/OddsofLTCExceedbyMonthTraceWagg.png` | Monthly exceedance risk overlay |
| `combined_results.csv` | Bootstrap exceedance results by location and month |
| `Rplots.pdf` | All plots in a single PDF (headless mode only) |

## Setup

See [SETUP.md](SETUP.md) for installation instructions for Mac, Unix, and Windows.

## Running the Analysis

See [RUN.md](RUN.md) for instructions on running headlessly with `Rscript` or interactively in RStudio.

## Further Reading

- [LINK TO EXTERNAL RESOURCE 1]
- [LINK TO EXTERNAL RESOURCE 2]
- [LINK TO EXTERNAL RESOURCE 3]

## License

MIT — see [LICENSE](LICENSE).
