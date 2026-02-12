FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3 \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-setuptools \
    pkg-config \
    libfftw3-dev \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    libsamplerate0-dev \
    libtag1-dev \
    libyaml-dev \
    libchromaprint-dev \
    libeigen3-dev \
    vamp-plugin-sdk \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/MTG/essentia.git . \
    && python3 waf configure \
        --build-static \
        --with-python \
        --with-cpptests \
        --with-examples \
        --with-vamp \
        --pythondir=/usr/local/lib/python3.12/dist-packages \
    && python3 waf \
    && python3 waf install

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-numpy \
    python3-six \
    python3-yaml \
    libfftw3-single3 \
    libfftw3-double3 \
    libavcodec60 \
    libavformat60 \
    libavutil58 \
    libswresample4 \
    libsamplerate0 \
    libtag1v5 \
    libyaml-0-2 \
    libchromaprint1 \
    libvamp-sdk2v5 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PYTHONPATH=/usr/local/lib/python3.12/dist-packages

WORKDIR /workspace

CMD ["python3", "-c", "import essentia; print(f'Essentia version: {essentia.__version__} installed successfully')"]
