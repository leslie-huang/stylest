## Release summary

## Test environments
* local OS X install, R 3.4.3
* OS 10.12.6 (on travis-ci), R 3.5.0, R-oldrel, R-devel
* ubuntu 14.04 (on travis-ci), R 3.5.0, R-oldrel, R-devel
* windows server 2012 (on appveyor), R 3.5.0

## R CMD check results
There were no ERRORs or WARNINGs. There was 1 NOTE:

* new submission from new maintainer

## Reverse dependencies

None.

## Ignored build failures

The OSX/R-devel build fails on travis-ci with the following error; while I have been unable to resolve this error using suggestions from similar issues on GitHub, I believe it is unrelated to my package.

 <!--
The command "Rscript -e 'deps <- devtools::dev_package_deps(dependencies = NA);devtools::install_deps(dependencies = TRUE);if (!all(deps$package %in% installed.packages())) { message("missing: ", paste(setdiff(deps$package, installed.packages()), collapse=", ")); q(status = 1, save = "no")}'" failed and exited with 1 during .
--!>