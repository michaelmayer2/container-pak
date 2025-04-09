FROM rockylinux:9

COPY run2.R /

RUN yum install -y epel-release && crb enable

ARG R_VERSION_LIST=4.4.3
RUN for R_VERSION in ${R_VERSION_LIST}; \
do \
    yum install -y \
      https://cdn.rstudio.com/r/rhel-9/pkgs/R-${R_VERSION}-1-1.x86_64.rpm && \
    /opt/R/$R_VERSION_LIST/bin/Rscript run2.R ; \
done

RUN rm -f run2.R
