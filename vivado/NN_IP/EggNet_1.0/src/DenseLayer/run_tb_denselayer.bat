ghdl -s --ieee=synopsys --std=08 ../clogb2/clogb2_Pkg.vhd denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd dense_layer.vhd NN.vhd tb_NN.vhd 
ghdl -a --ieee=synopsys --std=08 ../clogb2/clogb2_Pkg.vhd denseLayerPkg.vhd romModule.vhd accumulator.vhd multiplier.vhd vectorMultiplier.vhd dense_layer.vhd NN.vhd tb_NN.vhd
ghdl -e --ieee=synopsys --std=08 tb_NN
ghdl -r --ieee=synopsys --std=08 tb_NN --vcd=tb_NN.vcd --max-stack-alloc=0