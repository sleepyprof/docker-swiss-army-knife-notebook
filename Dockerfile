FROM jupyter/all-spark-notebook:137a295ff71b 

LABEL maintainer="mail@gdietz.de"

USER root

RUN apt-get update \
  && apt-get install -y libxml2-dev libz-dev libcairo2-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

USER $NB_USER

RUN conda install --quiet --yes \
    'r-lubridate=1.7.4' \
    'r-corrplot=0.84' \
    'r-gplots=3.0.1' \
    'r-e1071=1.7*' \
    'r-kernlab=0.9*' \
    'r-lars=1.2' \
    'r-zoo=1.8*' \
    'r-reshape=0.8.7' \
    'r-rsm=2.9' \
    'r-viridis=0.5.1' \
    'r-xml=3.98*' \
    'r-car=3.0*' \
    'r-hash=2.2.6' \
    'r-vcd=1.4*' \
    'r-randomForest=4.6*' \
    'r-waveslim=1.7.5' \
    'r-smoother=1.1*' \
    'r-signal=0.7*' \
    'r-plotrix=3.7' \
    'r-algdesign=1.1*' \
    'r-scatterplot3d=0.3*' \
    'r-svglite=1.2.1' \
    'r-rann=2.6*' \
    'r-dt=0.4*' \
    'r-igraph=1.2.2' \
    'r-effects=4.0*' \
    'r-pracma=2.0.4' \
    'r-boot=1.3*' \
  && conda clean -tipsy \
  && fix-permissions $CONDA_DIR

RUN Rscript -e 'update.packages(ask=FALSE, repos="https://cran.r-project.org")' \
  && Rscript -e 'install.packages(c("sensitivity", "xgboost"), repos="https://cran.r-project.org")' \
  && Rscript -e 'source("https://bioconductor.org/biocLite.R"); biocLite(c("GenomicRanges", "gRbase"))'

