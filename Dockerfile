FROM jupyter/all-spark-notebook:59b402ce701d 

# Combines jupyter/all-spark-notebook, jupyter/datascience-notebook and jupyter/tensorflow-notebook
# See Dockerfiles for above notebooks
# Also adds even more packages (especially for R)

LABEL maintainer="mail@gdietz.de"

ARG TEST_ONLY_BUILD

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    unixodbc \
    unixodbc-dev \
    r-cran-rodbc && \
    rm -rf /var/lib/apt/lists/*

RUN ln -s /bin/tar /bin/gtar

ENV JULIA_DEPOT_PATH=/opt/julia
ENV JULIA_PKGDIR=/opt/julia
ENV JULIA_VERSION=1.1.0

RUN mkdir /opt/julia-${JULIA_VERSION} && \
    cd /tmp && \
    wget -q https://julialang-s3.julialang.org/bin/linux/x64/`echo ${JULIA_VERSION} | cut -d. -f 1,2`/julia-${JULIA_VERSION}-linux-x86_64.tar.gz && \
    echo "80cfd013e526b5145ec3254920afd89bb459f1db7a2a3f21849125af20c05471 *julia-${JULIA_VERSION}-linux-x86_64.tar.gz" | sha256sum -c - && \
    tar xzf julia-${JULIA_VERSION}-linux-x86_64.tar.gz -C /opt/julia-${JULIA_VERSION} --strip-components=1 && \
    rm /tmp/julia-${JULIA_VERSION}-linux-x86_64.tar.gz
RUN ln -fs /opt/julia-*/bin/julia /usr/local/bin/julia

RUN mkdir /etc/julia && \
    echo "push!(Libdl.DL_LOAD_PATH, \"$CONDA_DIR/lib\")" >> /etc/julia/juliarc.jl && \
    mkdir $JULIA_PKGDIR && \
    chown $NB_USER $JULIA_PKGDIR && \
    fix-permissions $JULIA_PKGDIR

USER $NB_UID

RUN conda install --quiet --yes \
    'r-rodbc=1.3*' \
    'unixodbc=2.3.*' \
    'r-plyr=1.8*' \
    'r-devtools=2.0*' \
    'r-tidyverse=1.2*' \
    'r-shiny=1.2*' \
    'r-rmarkdown=1.11*' \
    'r-forecast=8.2*' \
    'r-rsqlite=2.1*' \
    'r-reshape2=1.4*' \
    'r-nycflights13=1.0*' \
    'r-caret=6.0*' \
    'r-rcurl=1.95*' \
    'r-crayon=1.3*' \
    'r-randomforest=4.6*' \
    'r-htmltools=0.3*' \
    'r-htmlwidgets=1.2*' \
    'r-hexbin=1.27*' \
    'rpy2=2.9*' \
    'tensorflow=1.12*' \
    'keras=2.2*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR

RUN julia -e 'import Pkg; Pkg.update()' && \
    (test $TEST_ONLY_BUILD || julia -e 'import Pkg; Pkg.add("HDF5")') && \
    julia -e "using Pkg; pkg\"add Gadfly RDatasets IJulia InstantiateFromURL\"; pkg\"precompile\"" && \ 
    mv $HOME/.local/share/jupyter/kernels/julia* $CONDA_DIR/share/jupyter/kernels/ && \
    chmod -R go+rx $CONDA_DIR/share/jupyter && \
    rm -rf $HOME/.local && \
    fix-permissions $JULIA_PKGDIR $CONDA_DIR/share/jupyter

# own extensions

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    libxml2-dev \
    libz-dev \
    libcairo2-dev \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

USER $NB_USER

RUN conda install --quiet --yes \
    'r-corrplot=0.84*' \
    'r-gplots=3.0.1*' \
    'r-e1071=1.7*' \
    'r-kernlab=0.9*' \
    'r-lars=1.2*' \
    'r-reshape=0.8.8*' \
    'r-rsm=2.10*' \
    'r-viridis=0.5.1*' \
    'r-xml=3.98*' \
    'r-car=3.0*' \
    'r-hash=3.0.1*' \
    'r-vcd=1.4*' \
    'r-waveslim=1.7.5*' \
    'r-smoother=1.1*' \
    'r-signal=0.7*' \
    'r-plotrix=3.7*' \
    'r-algdesign=1.1*' \
    'r-scatterplot3d=0.3*' \
    'r-svglite=1.2.1*' \
    'r-rann=2.6*' \
    'r-dt=0.5*' \
    'r-igraph=1.2.4*' \
    'r-effects=4.1*' \
    'r-pracma=2.2.2*' \
    'r-boot=1.3*' \
    'r-proc=1.12.1*' \
    'r-tensorflow=1.10*' \
    'r-parsedate=1.1.3*' \
    'r-xgboost=0.82*' \
    'r-plotly=4.8.0*' \
    'h2o=3.18*' \
    'h2o-py=3.18*' \
    'tabulate=0.8.3*' \
    'python-graphviz=0.10.1*' && \
    conda clean -tipsy && \
    fix-permissions $CONDA_DIR

RUN Rscript -e 'install.packages(c("sensitivity", "h2o"), repos="https://cran.r-project.org")' && \
    Rscript -e 'source("https://bioconductor.org/biocLite.R"); biocLite(c("GenomicRanges", "gRbase"))'

RUN Rscript -e 'update.packages(ask=FALSE, repos="https://cran.r-project.org")'

