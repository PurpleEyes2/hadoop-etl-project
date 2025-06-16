FROM bde2020/hadoop-namenode:2.0.0-hadoop3.2.1-java8


RUN sed -i 's|http://deb.debian.org/debian|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i 's|http://security.debian.org/debian-security|http://archive.debian.org/debian|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    sed -i '/stretch\/updates/d' /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update && \
    apt-get install -y wget build-essential libssl-dev libffi-dev \
        libbz2-dev libreadline-dev libsqlite3-dev zlib1g-dev \
        libncurses5-dev libncursesw5-dev xz-utils tk-dev curl make gcc


RUN cd /usr/src && \
    wget https://www.python.org/ftp/python/3.8.18/Python-3.8.18.tgz && \
    tar xzf Python-3.8.18.tgz && \
    cd Python-3.8.18 && \
    ./configure --enable-optimizations && \
    make -j$(nproc) && \
    make altinstall && \
    ln -sf /usr/local/bin/python3.8 /usr/bin/python && \
    /usr/bin/python -m ensurepip && \
    /usr/bin/python -m pip install --upgrade pip


RUN ln -sf /usr/local/bin/python3.8 /usr/bin/python && \
    ln -sf /usr/local/bin/python3.8 /usr/bin/python3 && \
    ln -sf /usr/local/bin/pip3.8 /usr/bin/pip && \
    ln -sf /usr/local/bin/pip3.8 /usr/bin/pip3


COPY requirements.txt /tmp/requirements.txt
RUN python -m pip install --no-cache-dir -r /tmp/requirements.txt


COPY ./scripts /scripts
WORKDIR /scripts