FROM buildpack-deps:jessie 

MAINTAINER	Yannick Saint Martino 

RUN apt-get -y update

# install python-software-properties (so you can do add-apt-repository)
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y -q python-software-properties software-properties-common

#install tools
RUN apt-get install -y curl wget unzip vim git sudo zip bzip2 fontconfig 

#install jdk
RUN apt-get install --no-install-recommends -y openjdk-7-jdk

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

VOLUME ["/workspace"]
WORKDIR /workspace

EXPOSE 80
EXPOSE 8000
EXPOSE 8080 
EXPOSE 9000 
EXPOSE 35729

# install SSH server so we can connect multiple times to the container
RUN apt-get -y install openssh-server \
 && rm -rf /var/lib/apt/lists/*
RUN mkdir /var/run/sshd
RUN echo 'root:toor' |chpasswd
RUN groupadd devweb && useradd devweb -s /bin/bash -m -g devweb -G devweb && adduser devweb sudo
RUN echo 'devweb:devweb' |chpasswd
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD /usr/sbin/sshd -D
