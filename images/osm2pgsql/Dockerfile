FROM ubuntu:18.04
RUN apt-get -y update && apt-get -y install software-properties-common
RUN apt -y install make \
  cmake \
  g++ \
  libboost-dev \
  libboost-system-dev \
  libboost-filesystem-dev \
  libexpat1-dev \
  zlib1g-dev \
  libbz2-dev \
  libpq-dev \
  libgeos-dev \
  libgeos++-dev \
  libproj-dev \
  lua5.2 \
  liblua5.2-dev \
  git-core \
  postgresql-client \ 
  wget
ENV workdir /src
WORKDIR $workdir
RUN git clone git://github.com/openstreetmap/osm2pgsql.git && \
  cd osm2pgsql && \
  git checkout c4c66d0faf6a4883f054d0a05e8928dd9b2b539f && \
  mkdir build && \
  cd build && \
  cmake .. && \
  make && \
  make install
COPY ./start.sh .
COPY ./config/openstreetmap-carto.lua .
COPY ./config/openstreetmap-carto.style .
COPY ./config/first-osm-import.osm .
RUN chmod a+x $workdir/start.sh
CMD ./start.sh