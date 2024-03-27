#!/usr/bin/env bash

set -ex

cd $(dirname "$0")

if [[ -z "${Board}" ]]; then
  Arty='35t'
elif [[ $Board == '35t' ]]; then
  Arty='35t'
elif [[ $Board == '100t' ]]; then
  Arty='100t'
else
  echo "Error Board must be 35t or 100t"
  exit
fi

echo "Selected board is" $Arty

apt update -qq

apt install -y git

git clone --recursive https://github.com/stnolting/neorv32-setups

mkdir -p build

echo "Analyze NEORV32 CPU"

ghdl -i --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/*.vhd
ghdl -i --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/mem/neorv32_dmem.default.vhd
ghdl -i --workdir=build --work=neorv32  ./neorv32-setups/neorv32/rtl/core/mem/neorv32_imem.default.vhd
ghdl -i --workdir=build --work=neorv32 ./neorv32-setups/neorv32/rtl/test_setups/neorv32_test_setup_bootloader.vhd
ghdl -m --workdir=build --work=neorv32 neorv32_test_setup_bootloader

echo "Synthesis with yosys and ghdl as module"

yosys -m ghdl -p 'ghdl --workdir=build --work=neorv32 neorv32_test_setup_bootloader; synth_xilinx -nodsp -nolutram -flatten -abc9 -arch xc7 -top neorv32_test_setup_bootloader; write_json neorv32_test_setup_bootloader.json' 

if [[ $Arty == '35t' ]]; then
  echo "Place and route"
  nextpnr-xilinx --chipdb /usr/local/share/nextpnr/xilinx-chipdb/xc7a35t.bin --xdc arty.xdc --json neorv32_test_setup_bootloader.json --write neorv32_test_setup_bootloader_routed.json --fasm neorv32_test_setup_bootloader.fasm
  echo "Generate bitstream"
  ../../prjxray/utils/fasm2frames.py --part xc7a35tcsg324-1 --db-root /usr/local/share/nextpnr/prjxray-db/artix7 neorv32_test_setup_bootloader.fasm > neorv32_test_setup_bootloader.frames
  ../../prjxray/build/tools/xc7frames2bit --part_file /usr/local/share/nextpnr/prjxray-db/artix7/xc7a35tcsg324-1/part.yaml --part_name xc7a35tcsg324-1 --frm_file neorv32_test_setup_bootloader.frames --output_file neorv32_test_setup_bootloader_35t.bit
elif [[ $Arty == '100t' ]]; then
  echo "Place and route"
  nextpnr-xilinx --chipdb /usr/local/share/nextpnr/xilinx-chipdb/xc7a100t.bin --xdc arty.xdc --json neorv32_test_setup_bootloader.json --write neorv32_test_setup_bootloader_routed.json --fasm neorv32_test_setup_bootloader.fasm
  echo "Generate bitstream"
  ../../prjxray/utils/fasm2frames.py --part xc7a100tcsg324-1 --db-root /usr/local/share/nextpnr/prjxray-db/artix7 neorv32_test_setup_bootloader.fasm > neorv32_test_setup_bootloader.frames
  ../../prjxray/build/tools/xc7frames2bit --part_file /usr/local/share/nextpnr/prjxray-db/artix7/xc7a100tcsg324-1/part.yaml --part_name xc7a100tcsg324-1 --frm_file neorv32_test_setup_bootloader.frames --output_file neorv32_test_setup_bootloader_100t.bit
fi

echo "Implementation completed"
