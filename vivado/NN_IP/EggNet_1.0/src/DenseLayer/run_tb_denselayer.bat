ghdl -s --ieee=synopsys --std=08 denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd layer.vhd NN.vhd tb_NN.vhd 
ghdl -a --ieee=synopsys --std=08 denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd layer.vhd NN.vhd tb_NN.vhd
ghdl -e --ieee=synopsys --std=08 tb_NN
ghdl -r --ieee=synopsys --std=08 tb_NN --vcd=tb_NN.vcd --max-stack-alloc=0