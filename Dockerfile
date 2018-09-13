FROM jupyter/all-spark-notebook:137a295ff71b 

# Combines jupyter/all-spark-notebook, jupyter/datascience-notebook and jupyter/tensorflow-notebook
# See Dockerfiles for above notebooks
# Also adds even more packages (especially for R)

LABEL maintainer="mail@gdietz.de"

ARG TEST_ONLY_BUILD

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libz-dev \
    libcairo2-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.0.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "bea4570d7358016d8ed29d2c15787dbefaea3e746c570763e7ad6040f17831f3 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_USER

RUN conda install --quiet --yes \
    'rpy2=2.8*' \
    'r-plyr=1.8*' \
    'r-devtools=1.13*' \
    'r-tidyverse=1.1*' \
    'r-shiny=1.0*' \
    'r-rmarkdown=1.8*' \
    'r-forecast=8.2*' \
    'r-rsqlite=2.0*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=0.2*' \
    'r-caret=6.0*' \
    'r-crayon=1.3*' \
    'r-randomforest=4.6*' \
    'r-htmltools=0.3*' \
    'r-htmlwidgets=1.0*' \
    'r-hexbin=1.27*' \
    'r-lubridate=1.7.4' \
    'r-corrplot=0.84' \
    'r-gplots=3.0.1' \
    'r-e1071=1.7*' \
    'r-lars=1.2' \
    'r-reshape=0.8.7' \
    'r-rsm=2.9' \
    'r-viridis=0.5.1' \
    'r-xml=3.98*' \
    'r-car=3.0*' \
    'r-hash=2.2.6' \
    'r-vcd=1.4*' \
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
    'r-tensorflow=1.8' \
    'r-proc=1.12.1' \
  && conda clean -tipsy \
  && fix-permissions $CONDA_DIR

RUN Rscript -e 'update.packages(ask=FALSE, repos="https://cran.r-project.org")' \
  && Rscript -e 'install.packages(c("sensitivity", "xgboost"), repos="https://cran.r-project.org")' \
  && Rscript -e 'source("https://bioconductor.org/biocLite.R"); biocLite(c("GenomicRanges", "gRbase"))'

RUN julia -e 'import Pkg; Pkg.update()' && \
    (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    julia -e 'import Pkg; Pkg.add("Gadfly")' && \
    julia -e 'import Pkg; Pkg.add("RDatasets")' && \
    julia -e 'import Pkg; Pkg.add("IJulia")' && \
    julia -e 'using IJulia' && \
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter

RUN conda install --quiet --yes \
    'tensorflow=1.5*' \
    'keras=2.1*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

