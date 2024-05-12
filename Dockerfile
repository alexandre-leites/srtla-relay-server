# Stage 1: Build stage
FROM ubuntu:latest AS build

# Install dependencies
RUN apt-get update && \
    apt-get install -y sudo tclsh pkg-config cmake libssl-dev build-essential git

# Clone repositories
WORKDIR /tmp
RUN git clone https://github.com/BELABOX/srtla.git && \
    git clone https://github.com/BELABOX/srt.git

# Build SRT
WORKDIR /tmp/srt
RUN ./configure && \
    make

# Build SRTLA
WORKDIR /tmp/srtla
RUN make srtla_rec

# Stage 2: Final stage
FROM ubuntu:latest

# Expose ports
EXPOSE 5000 5001

# Copy executables from build stage
COPY --from=build /tmp/srt/srt-live-transmit /opt/srt/srt-live-transmit
COPY --from=build /tmp/srtla/srtla_rec /opt/srtla/srtla_rec

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y bash

# Set default values for environment variables
ENV LOSSMAXTTL=40
ENV LATENCY=2000

# Run services with environment variables
CMD /opt/srt/srt-live-transmit -st:yes "srt://127.0.0.1:5002?mode=listener&lossmaxttl=${LOSSMAXTTL}&latency=${LATENCY}" "srt://0.0.0.0:5001?mode=listener" 2>&1 | tee /dev/console & \
    /opt/srtla/srtla_rec 5000 127.0.0.1 5002 2>&1 | tee /dev/console
