FROM docker.io/btdi/latex

RUN cd $(dirname "$0") \ 
# Add Pygments for minted support 
&& apt update -qq \
&& apt install -y python3-pip \
&& pip3 install Pygments


