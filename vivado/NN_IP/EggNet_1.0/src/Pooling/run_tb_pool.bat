ghdl -s --ieee=synopsys ../Fifo_vhdl/fifo_dist_ram.vhd MaxPooling.vhd tb_maxpool.vhd 
ghdl -a --ieee=synopsys ../Fifo_vhdl/fifo_dist_ram.vhd MaxPooling.vhd tb_maxpool.vhd
ghdl -e --ieee=synopsys tb_MaxPooling
ghdl -r --ieee=synopsys tb_MaxPooling --vcd=tb_MaxPooling.vcd