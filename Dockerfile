# Use build argument to set the architecture
ARG TARGETARCH

# Define the base image depending on the architecture
FROM emscripten/emsdk:3.1.61 AS amd64-base
FROM emscripten/emsdk:3.1.61-arm64 AS arm64-base

# Use a conditional to select the right base image
FROM ${TARGETARCH}-base

RUN apt-get update && apt-get install -y git help2man perl python3 python3-pip make autoconf g++ flex bison ccache build-essential libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlib1g zlib1g-dev libpython3-dev maven wget

# Build our patched Verilator
RUN git clone -b wasm_patched https://github.com/CSE140L/verilator.git /tools/verilator
WORKDIR /tools/verilator
RUN autoconf && ./configure && make -j16 
RUN sed -i "s/CXX =/CXX ?=/" include/verilated.mk
RUN make install

# Build our patched Digital
WORKDIR /tools
RUN git clone https://github.com/CSE140L/Digital
WORKDIR /tools/Digital
RUN mvn install -DskipTests
ADD tools/Digital.sh /usr/bin/digital

# Install autograder dependencies
RUN pip3 install cocotb~=1.9 pytest
RUN git clone https://github.com/CSE140L/cocotb_gradescope /tools/cocotb_gradescope
RUN cd /tools/cocotb_gradescope && pip3 install .
RUN git clone https://github.com/CSE140L/cse140l-python /tools/cse140l-python
RUN cd /tools/cse140l-python && pip3 install .

## Install emsdk
#RUN apt-get -y install lsb-release wget software-properties-common gnupg
#WORKDIR /tools
#RUN wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh
#RUN ./llvm.sh 19
#RUN for exe in $(ls /usr/bin | grep llvm); do tool=$(echo $exe | sed 's/-19//g'); ln -s /usr/bin/$exe /usr/bin/$tool; done
#RUN ln -s /usr/bin/clang-19 /usr/bin/clang
#
#RUN git clone https://github.com/emscripten-core/emsdk.git
#WORKDIR /tools/emsdk
#RUN ./emsdk install 3.1.61
#ENV PATH="$PATH:/tools/emsdk:/tools/emsdk/node/18.20.3_64bit/bin:/tools/emsdk/upstream/emscripten"
#RUN emcc --generate-config

WORKDIR /src
