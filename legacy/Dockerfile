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
