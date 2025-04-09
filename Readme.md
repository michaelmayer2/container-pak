## Introduction

This document serves as a quick reference on how [pak](https://pak.r-lib.org/) could be used to 

* simplify and/or speed up the build of containers for customers still having a need for legacy R versions (R < 4.0) 
* help customers manage the problem of providing system dependencies for R packages (e.g. when offering a curated repository and allowing the on-demand instalation of R packages via tools such as [renv](https://github.com/rstudio/renv))

In the concrete example here there will be a container with legacy R versions (3.6 and earlier, 3.4.3 and 3.6.3 to be more specific) that will have packages in specific versions pre-installed into the container.

In addition to that there is going to be a new container with the latest version of R where on-demand package installation is allowed from a curated package manager repo via [renv](https://github.com/rstudio/renv)

## Legacy R version container

The first step is to create a file containing the versions installed on the old container

```{r}
#get current R version
r_version<-paste(R.Version()$major,R.Version()$minor,sep=".")

#list all installed packages (make sure user library is empty)
df<-as.data.frame(installed.packages())

#write to 
write(file=paste0("packages-",r_version,".txt"),
      paste(df$Package, df$Version, sep = "@"))
```

This file can be used in the docker build process by leveraging `pak` . Due to current version of pak only supporting R 3.5+, we use pak 0.5.1, the most recent version still supporting R 3.4.3

Then let's read in the txt file created and use `pak` to install all packages at once. 

```{r}
# run.R

if (file.exists(".Rprofile")) unlink(".Rprofile")
sink(".Rprofile")
options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/rhel9/2023-12-01"))
sink()

options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/rhel9/2023-05-01"))

r_version <- paste(R.Version()$major,R.Version()$minor,sep=".")

install.packages("remotes")


if (r_version < "3.6.0") {
  remotes::install_github("r-lib/pak", "v0.5.1", force = TRUE)
  install.packages(c("pkgdepends", "glue", "callr", "processx"),
                   file.path(R.home(), "library/pak/library"))
} else {
  remotes::install_github("r-lib/pak", "v0.5.1", force = TRUE)
}

pkgs <- read.csv(header = FALSE, paste0("packages-", r_version, ".txt"))

site_library <- file.path(R.home(), "site-library")
  
if (!dir.exists(site_library)) dir.create(site_library)

#run pak to install all packages including system requirements at once
options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/rhel9/2022-05-01"))

pak::pak(as.vector(t(pkgs)), lib = site_library)

unlink(".Rprofile")
```

You then can put this together in a Dockerfile and use something like this (cf. https://docs.posit.co/resources/install-r-source.html, we need to build R from source because those R versions are no longer built by Posit for current versions of linux distributions). In the below Dockerfile we build R 3.4.3 and 3.6.3 and then use `pak` to precisely deploy the same versions of R packages that we collected earlier. 

```{bash}
FROM rockylinux:9

COPY packages-3.4.3.txt /
COPY packages-3.6.3.txt /
COPY run.R /

ARG R_VERSION_LIST="3.4.3 3.6.3"
RUN yum install -y epel-release which && crb enable

RUN yum install -y 'dnf-command(builddep)' && yum builddep -y R 

RUN for R_VERSION in ${R_VERSION_LIST}; \
do \
    curl -O https://cran.rstudio.com/src/base/R-3/R-${R_VERSION}.tar.gz && \
	tar -xzvf R-${R_VERSION}.tar.gz && \
	cd R-${R_VERSION} && \
		export FFLAGS="-fallow-argument-mismatch" && \
		export CFLAGS="-fcommon" && \
		./configure --prefix=/opt/R/${R_VERSION} \
				--enable-R-shlib \  
				--enable-memory-profiling && \
		make -j 8 && make install && \
    	cd .. && rm -rf R-${R_VERSION} && \
    /opt/R/$R_VERSION/bin/Rscript run.R ; \
done

RUN rm -f packages-3.4.3.txt packages-3.6.3.txt
```

## New R version container

Here the basic Dockerfile would be much more simple. We simply need to change `curated_repo_url` and beyond that the Dockerfile will install R 3.4.3 and 3.6.3 and eventually install all system dependencies for any package in the curated repo. 

```{bash}
FROM rockylinux:9

COPY run2.R /

ARG R_VERSION_LIST=4.4.3
RUN for R_VERSION in ${R_VERSION_LIST}; \
do \
    yum install -y \
      https://cdn.rstudio.com/r/rhel-9/pkgs/R-${R_VERSION}-1-1.x86_64.rpm && \
    /opt/R/$R_VERSION_LIST/bin/Rscript run2.R ; \
done

RUN rm -f run2.R
```

Where `run2.R` now contains

```{R}
# run2.R

# URL of curated repo 
curated_repo_url <- "http://localhost:4242/tested-r/latest"

# install pak 
install.packages("pak", repos = sprintf(
  "https://r-lib.github.io/p/pak/stable/%s/%s/%s",
  .Platform$pkgType,
  R.Version()$os,
  R.Version()$arch
))

# get a list of all available.packages in curate repo
av_packages <- as.data.frame(available.packages(repos = curated_repo_url)) 

# flatten them into pak strings
pak_input <- paste(av_packages$Package, av_packages$Version, sep = "@")

# finally run pak::pkg_sysreqs() to install system requirements 
# for all packages in curated repo 

Sys.setenv("PKG_SYSREQS_PLATFORM"="redhat-9")
sysreqs <- pak::pkg_sysreqs(pak_input)

if (length(sysreqs$pre_install) > 0) system("sysreqs$pre_install")
if (length(sysreqs$install_scripts) > 0) system("sysreqs$install_scripts")
if (length(sysreqs$post_install) > 0) system("sysreqs$post_install")
```
