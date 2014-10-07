FROM buildpack-deps:jessie 

MAINTAINER	Yannick Saint Martino 

#install jdk
RUN apt-get update && apt-get install --no-install-recommends -y openjdk-7-jdk

# install maven
RUN apt-get -y install maven

# install python
RUN apt-get install -y python python-dev python-pip python-virtualenv

# install ruby
ENV RUBY_MAJOR 2.1
ENV RUBY_VERSION 2.1.3

# some of ruby's build scripts are written in ruby
# we purge this later to make sure our final image uses what we just built
RUN apt-get install -y bison ruby \
        && rm -rf /var/lib/apt/lists/* \
        && mkdir -p /usr/src/ruby \
        && curl -SL "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.bz2" \
                | tar -xjC /usr/src/ruby --strip-components=1 \
        && cd /usr/src/ruby \
        && autoconf \
        && ./configure --disable-install-doc \
        && make -j"$(nproc)" \
        && apt-get purge -y --auto-remove bison ruby \
        && make install \
        && rm -r /usr/src/ruby

# skip installing gem documentation
RUN echo 'gem: --no-rdoc --no-ri' >> /.gemrc

RUN gem install bundler

# install compass
RUN gem install compass
VOLUME ["/input", "/output"]

#install nodejs
RUN \
  cd /tmp && \
  wget http://nodejs.org/dist/node-latest.tar.gz && \
  tar xvzf node-latest.tar.gz && \
  rm -f node-latest.tar.gz && \
  cd node-v* && \
  ./configure && \
  CXX="g++ -Wno-unused-local-typedefs" make && \
  CXX="g++ -Wno-unused-local-typedefs" make install && \
  cd /tmp && \
  rm -rf /tmp/node-v* && \
  echo '\n# Node.js\nexport PATH="node_modules/.bin:$PATH"' >> /root/.bashrc

# install yeoman
RUN npm install -g yo

# Install Bower & Grunt
RUN npm install -g bower grunt-cli gulp



