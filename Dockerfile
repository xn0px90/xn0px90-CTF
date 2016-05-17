# using phusion/baseimage as base image. 
#FROM phusion/baseimage:0.9.9
FROM kalilinux/kali-linux-docker
MAINTAINER xn0px90@gmail.com 
#Kali APT source
RUN echo "deb http://http.kali.org/kali kali-rolling main contrib non-free" > /etc/apt/sources.list && \
    echo "deb-src http://http.kali.org/kali kali-rolling main contrib non-free" >> /etc/apt/sources.list

# Set correct environment variables.
ENV HOME /root

# Regenerate SSH host keys. baseimage-docker does not contain any
# RUN /etc/my_init.d/00_regen_ssh_host_keys.sh

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]



# Install tools
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y  

#VIM SPF13 awesome stuff
#RUN curl https://j.mp/spf13-vim3 -L > spf13-vim.sh && sh spf13-vim.sh

# create code directory
RUN mkdir -p /opt/code/

# install packages required to compile vala and radare2
RUN apt-get install -y software-properties-common python-all-dev wget curl httpie
RUN apt-get install -y swig flex bison git gcc g++ make pkg-config glib-2.0 vim
RUN apt-get install -y git python-gobject-dev valgrind gdb libcapstone-dev libzip-dev libmagic-dev 

ENV VALA_TAR vala-0.26.1

# compile vala
RUN cd /opt/code && \
	wget -c https://download.gnome.org/sources/vala/0.26/${VALA_TAR}.tar.xz && \
	shasum ${VALA_TAR}.tar.xz | grep -q 0839891fa02ed2c96f0fa704ecff492ff9a9cd24 && \
	tar -Jxf ${VALA_TAR}.tar.xm
RUN cd /opt/code/${VALA_TAR}; ./configure --prefix=/usr ; make && make install

# compile radare and bindings
RUN cd /opt/code
RUN git clone https://github.com/radare/radare2.git
RUN cd radare2; ./configure --prefix=/usr; make && make install

#install Go

ENV GOLANG_VERSION 1.6.2
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 e40c36ae71756198478624ed1bb4ce17597b3c19d243f3f0899bb5740d56212a

RUN curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
	&& echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - \
	&& tar -C /usr/local -xzf golang.tar.gz \
	&& rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH

COPY go-wrapper /usr/local/bin/
#debugging Go apps with dlv DWARF spec the right way
RUN go get github.com/derekparker/delve/cmd/dlv 

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
