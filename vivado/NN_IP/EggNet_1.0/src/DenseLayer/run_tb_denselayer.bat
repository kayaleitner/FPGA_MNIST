ghdl -s --ieee=synopsys denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd layer.vhd NN.vhd tb_NN.vhd 
ghdl -a --ieee=synopsys denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd layer.vhd NN.vhd tb_NN.vhd
ghdl -e --ieee=synopsys tb_NN
ghdl -r --ieee=synopsys tb_NN --vcd=tb_NN.vcd