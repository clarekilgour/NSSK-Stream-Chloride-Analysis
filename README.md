# NSSK Stream Chloride Analysis

**[ONE SENTENCE SUMMARY OF THE PROJECT AND ITS PURPOSE]**

Original analysis code by [Clare L. Kilgour](https://github.com/clarekilgour).

---

## Overview

**[BRIEF DESCRIPTION OF THE MONITORING CONTEXT — E.G. WATERSHED, TIME PERIOD, REGULATORY BACKGROUND]**

**[BRIEF DESCRIPTION OF WHAT THE ANALYSIS PRODUCES — E.G. PULSE DETECTION, EXCEEDANCE RISK, SUMMARY PLOTS]**

## Methodology

**[PLACEHOLDER: BRIEF DESCRIPTION OF THE ANALYTICAL APPROACH — CHLORIDE CONVERSION, PULSE DETECTION CRITERIA, BOOTSTRAP EXCEEDANCE METHOD]**

## Setup

See [SETUP.md](SETUP.md) for installation instructions for Mac, Unix, and Windows.

## Running the Analysis

See [RUN.md](RUN.md) for instructions on running headlessly with `Rscript` or interactively in RStudio.

## Input

Input is an CSV export of the [DFO PSEC Community Stream Monitoring (CoSMo)](https://datastream.org/en-ca/dataset/4c8d3691-99e5-4fa9-ad09-da077baa37c5) dataset (DOI: [10.25976/0gvo-9d12](https://doi.org/10.25976/0gvo-9d12)). CoSMo is a collaborative initiative collecting long-term water quality data for resource management and stewardship across southwest British Columbia, led by Fisheries and Oceans Canada (DFO) Pacific Science Enterprise Centre (PSEC).

This analysis uses monitoring locations WAGG01 and WAGG03 (Wagg Creek). The following columns must be present in the input CSV:

| Column | Description |
|---|---|
| `MonitoringLocationID` | Site identifier — analysis filters to `WAGG01` and `WAGG03` |
| `MonitoringLocationName` | Human-readable site name |
| `MonitoringLocationLatitude` | Site latitude |
| `MonitoringLocationLongitude` | Site longitude |
| `MonitoringLocationType` | Location type (e.g. `River/Stream`) |
| `ActivityType` | Measurement activity type |
| `ActivityMediaName` | Sample medium (e.g. `Surface Water`) |
| `ActivityStartDate` | Measurement date (`YYYY-MM-DD`) |
| `ActivityStartTime` | Measurement time (`HH:MM:SS`) |
| `SampleCollectionEquipmentName` | Instrument used |
| `CharacteristicName` | Parameter name — analysis uses `Specific conductance` and `Temperature, water` |
| `ResultValue` | Measured value |

## Outputs

Each run produces a parent output directory containing the following resources:

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

## Further Reading

- [LINK TO EXTERNAL RESOURCE 1]
- [LINK TO EXTERNAL RESOURCE 2]
- [LINK TO EXTERNAL RESOURCE 3]

## License

MIT — see [LICENSE](LICENSE).
