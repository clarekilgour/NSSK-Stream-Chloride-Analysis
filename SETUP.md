# Setup

## R

Install R from [CRAN](https://cran.r-project.org). Tested with R 4.6.

### Mac

Install R from CRAN or via Homebrew:

```bash
brew install --cask r
```

Some packages (notably `ragg`) require system libraries. If installation fails, install the dependencies via Homebrew:

```bash
brew install libpng freetype harfbuzz fribidi
```

### Unix / Linux

Install R via your distribution's package manager. On Debian/Ubuntu:

```bash
sudo apt-get install r-base r-base-dev
```

Install the required R packages and the Liberation Sans font (a metrically identical Arial substitute used by the analysis) via apt:

```bash
sudo apt-get install r-cran-tidyverse r-cran-lubridate r-cran-ragg r-cran-conflicted fonts-liberation
```

On Fedora the font package is named `liberation-fonts`.

`gt` is not available as an apt package. Install it from within R:

```r
install.packages("gt")
```

#### Debian 13 — build R 4.6.1 from source

The build dependencies below cover both R itself and the system libraries required by R packages including `ragg`.

```bash
sudo apt-get install -y \
  build-essential gfortran libreadline-dev libx11-dev libxt-dev \
  libcairo2-dev libpng-dev libjpeg-dev libtiff-dev libicu-dev \
  libbz2-dev liblzma-dev libcurl4-openssl-dev libpcre2-dev zlib1g-dev \
  texinfo libuv1-dev libprotobuf-dev protobuf-compiler libudunits2-dev \
  libnode-dev libv8-dev libsecret-1-dev libmagick++-dev

sudo apt-get install -y texlive-fonts-extra texlive-latex-extra
```

Download the R 4.6.1 source from [CRAN](https://cran.r-project.org/src/base/), extract, and build:

```bash
PREFIX="$HOME/opt/r-lang-4.6.1"   # adjust to your preferred install location

./configure \
  --prefix="$PREFIX" \
  --enable-R-shlib \
  --enable-memory-profiling \
  --with-cairo \
  --with-libpng \
  --with-libtiff \
  --with-jpeglib \
  --with-lapack \
  --with-blas \
  --with-tcltk
make -j6
make install
```

R is installed to `$PREFIX/bin/R`. Add that directory to your `PATH` or invoke `Rscript` via its full path.

### Windows

Install R from [CRAN](https://cran.r-project.org/bin/windows/base/). Pre-compiled binaries are available for all required packages — no additional build tools are needed for a standard installation.

---

## R Packages

From an R session at the project root:

```r
install.packages(c("tidyverse", "lubridate", "gt", "ragg", "conflicted", "fs"))
```

`grid` is included with base R and does not need to be installed separately.
