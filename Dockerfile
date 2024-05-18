# Use Alpine as a build environment
FROM alpine:latest as build

# Update package repository and install necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        git \
        linux-headers \
        alpine-sdk \
        cmake \
        tcl \
        openssl-dev \
        zlib-dev

# Set the working directory to /tmp
WORKDIR /tmp

# Clone the required repositories
RUN git clone --depth 1 https://github.com/alexandre-leites/srtla.git && \
    git clone --depth 1 https://github.com/alexandre-leites/srt.git && \
	git clone --depth 1 https://github.com/alexandre-leites/srt-live-server.git

# Switch to the srt repository directory
WORKDIR /tmp/srt

# Checkout the master branch and build and install srt library
RUN git checkout master && \
    ./configure && \
    make -j8 && \
    make install

# Switch to the srtla repository directory
WORKDIR /tmp/srtla

# Checkout the master branch and build srtla library
RUN git checkout main && \
    make -j8 srtla_rec

# Switch to the sls repository directory
WORKDIR /tmp/srt-live-server

# Checkout the master branch and build sls library
RUN git checkout master && \
    make -j8

# Use Alpine Linux as the final base image
FROM alpine:latest

# Set environment variables
ENV LD_LIBRARY_PATH /lib:/usr/lib:/usr/local/lib64

# Update package repository and install necessary dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache \
        supervisor \
        openssl \
		bash \
        libstdc++

# Add a user for running the application
RUN mkdir /etc/sls /logs

# Copy necessary files and directories from the build stage
COPY --from=build /usr/local/bin/srt-* /usr/local/bin/
COPY --from=build /usr/local/lib/libsrt* /usr/local/lib/
COPY --from=build /tmp/srt-live-server/bin/* /usr/local/bin/
COPY --from=build /tmp/srt/srt-live-transmit /usr/local/bin/srt-live-transmit
COPY --from=build /tmp/srt/srt-tunnel /usr/local/bin/srt-tunnel
COPY --from=build /tmp/srtla/srtla_rec /usr/local/bin/srtla_rec

# Copy the sls.conf file to /etc/sls directory
COPY --from=build /tmp/srt-live-server/sls.conf /etc/sls/

# Create a volume for logs
VOLUME /logs

# Environment Variables
ENV SRTLA_PORT          5000

ENV SLS_HTTP_PORT       8181
ENV SLS_SRT_PORT        30000
ENV SLS_DEFAULT_SID     live/feed1
ENV SLS_SRT_LATENCY     1000
ENV SLS_SRT_TIMEOUT     -1

ENV SLS_SRT_LATENCY     1000
ENV SLT_SRT_LOSSMAXTTL  40

# Expose ports
EXPOSE $SLS_HTTP_PORT/tcp $SRTLA_PORT/udp $SLS_SRT_PORT/udp

# Set working dir to /opt
WORKDIR /opt

# Copy necessary configurations and scripts
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY restart_all_on_exit.sh /usr/local/bin/restart_all_on_exit.sh

# Ensure the scripts are executable
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/restart_all_on_exit.sh

# Set the entrypoint to entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
