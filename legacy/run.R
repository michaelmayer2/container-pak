if (file.exists(".Rprofile")) unlink(".Rprofile")
sink(".Rprofile")
options(repos=c(CRAN="https://p3m.dev/cran/__linux__/rhel9/2023-12-01"))
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
options(repos=c(CRAN="https://p3m.dev/cran/__linux__/rhel9/2022-05-01"))

pak::pak(as.vector(t(pkgs)), lib = site_library)

unlink(".Rprofile")
