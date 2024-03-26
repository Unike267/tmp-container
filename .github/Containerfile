FROM gcr.io/hdl-containers/impl/icestorm

ARG USERNAME=unike
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN cd $(dirname "$0") \ 
# Create the user; Modify ID from 0 to 1000
# This is done because in prjxray/Makefile in line 17-18 the user id is checked and if it is 0 the program stops
&& groupadd --gid $USER_GID $USERNAME \
&& useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
# Add sudo support
&& apt update -qq \
&& apt install -y sudo \
&& echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
&& chmod 0440 /etc/sudoers.d/$USERNAME 

RUN apt install -y git \
&& apt install -y python3 python3-pip python3-yaml cmake\
&& apt install -y cython3 \
# Clone prjxray repository and build
&& sudo git clone https://github.com/SymbiFlow/prjxray.git \
&& cd prjxray \
&& git submodule update --init --recursive 

USER $USERNAME

RUN sudo chown -R unike prjxray \
&& cd prjxray \
&& make build

USER root

RUN chown -R root prjxray \
&& cd prjxray \
&& python3 setup.py install \
&& cd third_party/fasm \
&& python3 setup.py install \
&& cd ../.. \
&& ./download-latest-db.sh \
&& mkdir -p /usr/local/share/nextpnr \
&& cp -r database /usr/local/share/nextpnr/prjxray-db \
&& cd .. 

# Clone nextpnr-xilinx repository, build and install
RUN apt install -y libeigen3-dev \
&& git clone https://github.com/gatecat/nextpnr-xilinx.git \
&& cd nextpnr-xilinx \
&& git submodule update --init --recursive \
&& mkdir build \
&& cd build \
&& cmake ../ -DARCH=xilinx -DBUILD_GUI=OFF -DBUILD_PYTHON=OFF \
&& make \
&& make install \
&& cd .. \
# Generate the chipdb for arty 35t
&& python3 xilinx/python/bbaexport.py --device xc7a35tcsg324-1 --bba xilinx/xc7a35t.bba \
&& ./build/bba/bbasm --l xilinx/xc7a35t.bba xilinx/xc7a35t.bin \
&& mkdir -p /usr/local/share/nextpnr/xilinx-chipdb \
&& cp xilinx/xc7a35t.bin /usr/local/share/nextpnr/xilinx-chipdb/ \
# Generate the chipdb for arty 100t
&& python3 xilinx/python/bbaexport.py --device xc7a100tcsg324-1 --bba xilinx/xc7a100t.bba \
&& ./build/bba/bbasm --l xilinx/xc7a100t.bba xilinx/xc7a100t.bin \
&& cp xilinx/xc7a100t.bin /usr/local/share/nextpnr/xilinx-chipdb/ 

