#!/bin/bash

# Put the base packages to unhold
for package in r-base r-base-core r-base-dev r-base-html r-cran-boot r-cran-class r-cran-cluster r-cran-codetools r-cran-foreign r-cran-kernsmooth r-cran-lattice r-cran-mass r-cran-matrix r-cran-mgcv r-cran-nlme r-cran-nnet r-cran-rpart r-cran-spatial r-cran-survival r-doc-html r-recommended ; do apt-mark unhold $package; done

# Remove the old r packages
apt-get purge r-base-* r-cran-* -y --force-yes
apt-get autoremove -y
apt-get update

# Remove the CRAN packages
rm -fr /usr/lib/R/site-library  /usr/local/lib/R/site-library
rm -fr /var/cache/R/*

exit 0
