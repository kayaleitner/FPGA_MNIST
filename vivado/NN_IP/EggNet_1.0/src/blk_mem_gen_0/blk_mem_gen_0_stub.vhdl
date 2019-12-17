-- Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
-- Date        : Tue Dec 17 11:10:45 2019
-- Host        : DESKTOP-QIIVLD9 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/NN_IP/EggNet_1.0/src/blk_mem_gen_0/blk_mem_gen_0_stub.vhdl
-- Design      : blk_mem_gen_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7z020clg484-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity blk_mem_gen_0 is
  Port ( 
    clka : in STD_LOGIC;
    wea : in STD_LOGIC_VECTOR ( 0 to 0 );
    addra : in STD_LOGIC_VECTOR ( 10 downto 0 );
    dina : in STD_LOGIC_VECTOR ( 7 downto 0 );
    clkb : in STD_LOGIC;
    rstb : in STD_LOGIC;
    addrb : in STD_LOGIC_VECTOR ( 10 downto 0 );
    doutb : out STD_LOGIC_VECTOR ( 7 downto 0 );
    rsta_busy : out STD_LOGIC;
    rstb_busy : out STD_LOGIC
  );

end blk_mem_gen_0;

architecture stub of blk_mem_gen_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clka,wea[0:0],addra[10:0],dina[7:0],clkb,rstb,addrb[10:0],doutb[7:0],rsta_busy,rstb_busy";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "blk_mem_gen_v8_4_1,Vivado 2017.4";
begin
end;
