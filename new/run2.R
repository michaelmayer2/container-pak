# URL of curated repo 
curated_repo_url <- "http://packagemanager:4242/repo"
curated_repo_url <- "https://pkg.current.posit.team/tested-r/__linux__/rhel9/latest"

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

Sys.setenv(PKG_SYSREQS_PLATFORM="redhat-9")
sysreqs <- pak::pkg_sysreqs(pak_input)
sysreqs
if (length(sysreqs$pre_install) > 0) system(sysreqs$pre_install)
if (length(sysreqs$install_scripts) > 0) system(sysreqs$install_scripts)
if (length(sysreqs$post_install) > 0) system(sysreqs$post_install)
