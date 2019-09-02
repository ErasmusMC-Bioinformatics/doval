# Use an official Python runtime as a parent image
FROM python:3.6.5

# Install R
# Technically this is insecure, but at least it is consistent
RUN echo "deb http://cloud.r-project.org/bin/linux/debian stretch-cran35/" | tee -a /etc/apt/sources.list && \
	apt-get -qq update && \
	apt-get -qq install -y --allow-unauthenticated r-base r-base-dev
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
    apt-get install -y nodejs && \
    apt-get clean

# Install dependencies
RUN mkdir /repo /deps /deps/python /deps/R runner
ADD ./doval/doval/JUNIPER/src/install_requirements.py /deps/
ADD ./doval/doval/JUNIPER/src/python/gui-requirements.txt /deps/python/
ADD ./doval/doval/JUNIPER/src/python/wrapper-requirements.txt /deps/python/
ADD ./doval/doval/JUNIPER/src/R/requirements.txt /deps/R/

RUN cd deps && \
    pip install --upgrade pip && \
    python3 install_requirements.py && \
    cd / && \
    rm -fr /deps

RUN git clone https://github.com/JulianDekker/dovalapi
RUN cd /dovalapi && \
    pip install .

RUN pip install ipykernel
RUN python -m ipykernel install --user

# Install the R side (probably updated the least)
ADD ./doval/doval/JUNIPER/src/R /repo/R

RUN cd /repo/R && \
    R CMD build junipeR && \
    R -e "install.packages('junipeR_0.1.0.tar.gz', repos=NULL, quiet=TRUE)" && \
    cd /

#-------
# Install juniper_gui front-end
RUN rm -rf /usr/local/var/postgres/*

ADD ./doval /repo/DOVALJUNIPER
RUN cd /repo/DOVALJUNIPER/doval/JUNIPER/src/python/juniper_gui/juniper_gui/react && \
    npm install --production && \
    npm run build

# Install JUNIPER and JUNIPER-GUI
ADD ./doval/doval/JUNIPER/src/python/juniper /repo/juniper
RUN pip install /repo/DOVALJUNIPER/doval/JUNIPER/src/python/juniper /repo/DOVALJUNIPER/doval/JUNIPER/src/python/juniper_gui

#RUN rm -fr /repo

#ADD run_doval.py /runner/
WORKDIR /repo/DOVALJUNIPER/

EXPOSE 8000

ENV HOST 0.0.0.0
#RUN ls -R "/repo/"
#CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]
