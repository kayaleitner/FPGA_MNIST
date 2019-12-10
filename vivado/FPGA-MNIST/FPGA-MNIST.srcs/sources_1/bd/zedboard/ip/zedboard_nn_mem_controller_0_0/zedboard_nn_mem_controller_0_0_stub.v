// Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2017.4 (win64) Build 2086221 Fri Dec 15 20:55:39 MST 2017
// Date        : Tue Dec 10 13:35:09 2019
// Host        : DESKTOP-QIIVLD9 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/lukas/Documents/SoC_Lab/FPGA_MNIST/vivado/FPGA-MNIST/FPGA-MNIST.srcs/sources_1/bd/zedboard/ip/zedboard_nn_mem_controller_0_0/zedboard_nn_mem_controller_0_0_stub.v
// Design      : zedboard_nn_mem_controller_0_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7z020clg484-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "DMA_to_BRAM_v1_0,Vivado 2017.4" *)
module zedboard_nn_mem_controller_0_0(BRAM_PA_addr, BRAM_PA_clk, BRAM_PA_dout, 
  BRAM_PA_wea, BRAM_PB_addr, BRAM_PB_clk, BRAM_PB_din, BRAM_PB_rst, m_layer_clk_i, 
  m_layer_aresetn_i, m_layer_tvalid_o, m_layer_tdata_o, m_layer_tkeep_o, m_layer_tlast_o, 
  m_layer_tready_i, Dbg_s00_axis_dma_aclk, Dbg_s00_axis_dma_aresetn, 
  Dbg_m00_axis_dma_tready, Dbg_s00_axis_dma_tdata, Dbg_s00_axis_dma_tkeep, 
  Dbg_s00_axis_dma_tlast, Dbg_s00_axis_dma_tvalid, m00_axis_dma_tdata, 
  m00_axis_dma_tkeep, m00_axis_dma_tlast, m00_axis_dma_tvalid, m00_axis_dma_tready, 
  m00_axis_dma_aclk, m00_axis_dma_aresetn, s00_axis_dma_tdata, s00_axis_dma_tkeep, 
  s00_axis_dma_tlast, s00_axis_dma_tvalid, s00_axis_dma_tready, s00_axis_dma_aclk, 
  s00_axis_dma_aresetn, s00_axi_awaddr, s00_axi_awprot, s00_axi_awvalid, s00_axi_awready, 
  s00_axi_wdata, s00_axi_wstrb, s00_axi_wvalid, s00_axi_wready, s00_axi_bresp, 
  s00_axi_bvalid, s00_axi_bready, s00_axi_araddr, s00_axi_arprot, s00_axi_arvalid, 
  s00_axi_arready, s00_axi_rdata, s00_axi_rresp, s00_axi_rvalid, s00_axi_rready, 
  s00_axi_aclk, s00_axi_aresetn)
/* synthesis syn_black_box black_box_pad_pin="BRAM_PA_addr[9:0],BRAM_PA_clk,BRAM_PA_dout[7:0],BRAM_PA_wea[0:0],BRAM_PB_addr[9:0],BRAM_PB_clk,BRAM_PB_din[7:0],BRAM_PB_rst[0:0],m_layer_clk_i,m_layer_aresetn_i,m_layer_tvalid_o,m_layer_tdata_o[31:0],m_layer_tkeep_o[3:0],m_layer_tlast_o,m_layer_tready_i,Dbg_s00_axis_dma_aclk,Dbg_s00_axis_dma_aresetn,Dbg_m00_axis_dma_tready,Dbg_s00_axis_dma_tdata[31:0],Dbg_s00_axis_dma_tkeep[3:0],Dbg_s00_axis_dma_tlast,Dbg_s00_axis_dma_tvalid,m00_axis_dma_tdata[31:0],m00_axis_dma_tkeep[3:0],m00_axis_dma_tlast,m00_axis_dma_tvalid,m00_axis_dma_tready,m00_axis_dma_aclk,m00_axis_dma_aresetn,s00_axis_dma_tdata[31:0],s00_axis_dma_tkeep[3:0],s00_axis_dma_tlast,s00_axis_dma_tvalid,s00_axis_dma_tready,s00_axis_dma_aclk,s00_axis_dma_aresetn,s00_axi_awaddr[7:0],s00_axi_awprot[2:0],s00_axi_awvalid,s00_axi_awready,s00_axi_wdata[31:0],s00_axi_wstrb[3:0],s00_axi_wvalid,s00_axi_wready,s00_axi_bresp[1:0],s00_axi_bvalid,s00_axi_bready,s00_axi_araddr[7:0],s00_axi_arprot[2:0],s00_axi_arvalid,s00_axi_arready,s00_axi_rdata[31:0],s00_axi_rresp[1:0],s00_axi_rvalid,s00_axi_rready,s00_axi_aclk,s00_axi_aresetn" */;
  output [9:0]BRAM_PA_addr;
  output BRAM_PA_clk;
  output [7:0]BRAM_PA_dout;
  output [0:0]BRAM_PA_wea;
  output [9:0]BRAM_PB_addr;
  output BRAM_PB_clk;
  input [7:0]BRAM_PB_din;
  output [0:0]BRAM_PB_rst;
  input m_layer_clk_i;
  input m_layer_aresetn_i;
  output m_layer_tvalid_o;
  output [31:0]m_layer_tdata_o;
  output [3:0]m_layer_tkeep_o;
  output m_layer_tlast_o;
  input m_layer_tready_i;
  output Dbg_s00_axis_dma_aclk;
  output Dbg_s00_axis_dma_aresetn;
  output Dbg_m00_axis_dma_tready;
  output [31:0]Dbg_s00_axis_dma_tdata;
  output [3:0]Dbg_s00_axis_dma_tkeep;
  output Dbg_s00_axis_dma_tlast;
  output Dbg_s00_axis_dma_tvalid;
  output [31:0]m00_axis_dma_tdata;
  output [3:0]m00_axis_dma_tkeep;
  output m00_axis_dma_tlast;
  output m00_axis_dma_tvalid;
  input m00_axis_dma_tready;
  input m00_axis_dma_aclk;
  input m00_axis_dma_aresetn;
  input [31:0]s00_axis_dma_tdata;
  input [3:0]s00_axis_dma_tkeep;
  input s00_axis_dma_tlast;
  input s00_axis_dma_tvalid;
  output s00_axis_dma_tready;
  input s00_axis_dma_aclk;
  input s00_axis_dma_aresetn;
  input [7:0]s00_axi_awaddr;
  input [2:0]s00_axi_awprot;
  input s00_axi_awvalid;
  output s00_axi_awready;
  input [31:0]s00_axi_wdata;
  input [3:0]s00_axi_wstrb;
  input s00_axi_wvalid;
  output s00_axi_wready;
  output [1:0]s00_axi_bresp;
  output s00_axi_bvalid;
  input s00_axi_bready;
  input [7:0]s00_axi_araddr;
  input [2:0]s00_axi_arprot;
  input s00_axi_arvalid;
  output s00_axi_arready;
  output [31:0]s00_axi_rdata;
  output [1:0]s00_axi_rresp;
  output s00_axi_rvalid;
  input s00_axi_rready;
  input s00_axi_aclk;
  input s00_axi_aresetn;
endmodule
