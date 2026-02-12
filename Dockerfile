FROM ubuntu:24.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    wget \
    python3 \
    python3-dev \
    python3-pip \
    python3-numpy \
    python3-setuptools \
    pkg-config \
    swig \
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
    qtbase5-dev \
    libqt5sql5-sqlite \
    libqt5xml5 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/MTG/gaia.git gaia_src \
    && cd gaia_src \
    && python3 waf configure \
    && python3 waf \
    && python3 waf install

RUN git clone https://github.com/MTG/essentia.git essentia_src \
    && cd essentia_src \
    && python3 waf configure \
        --build-static \
        --with-python \
        --with-cpptests \
        --with-examples \
        --with-vamp \
        --with-gaia \
        --pythondir=/usr/local/lib/python3.12/dist-packages \
    && python3 waf \
    && python3 waf install

RUN mkdir -p /tmp/svm_models \
    && wget -q https://essentia.upf.edu/svm_models/essentia-extractor-svm_models-v2.1_beta5.tar.gz \
    && tar -xzf essentia-extractor-svm_models-v2.1_beta5.tar.gz -C /tmp/svm_models --strip-components=1 \
    && cd /tmp/svm_models \
    && echo "outputFormat: json" > profile.conf \
    && echo "highlevel:" >> profile.conf \
    && echo "  svm_models:" >> profile.conf \
    && for f in *.history; do echo "    - /usr/local/share/essentia/svm_models/$f" >> profile.conf; done

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
    libqt5core5a \
    libqt5xml5 \
    libqt5sql5 \
    libqt5sql5-sqlite \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local /usr/local

COPY --from=builder /tmp/svm_models /usr/local/share/essentia/svm_models

ENV LD_LIBRARY_PATH=/usr/local/lib
ENV PYTHONPATH=/usr/local/lib/python3.12/dist-packages

WORKDIR /workspace

CMD ["python3", "-c", "import essentia; print(f'Essentia version: {essentia.__version__} installed successfully')"]
