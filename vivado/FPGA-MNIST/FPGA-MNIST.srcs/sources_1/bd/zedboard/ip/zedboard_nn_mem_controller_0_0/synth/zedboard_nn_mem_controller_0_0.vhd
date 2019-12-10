-- (c) Copyright 1995-2019 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
-- 
-- DO NOT MODIFY THIS FILE.

-- IP VLNV: tuwien.at:user:nn_mem_controller:1.0
-- IP Revision: 5

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY zedboard_nn_mem_controller_0_0 IS
  PORT (
    BRAM_PA_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    BRAM_PA_clk : OUT STD_LOGIC;
    BRAM_PA_dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    BRAM_PA_wea : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    BRAM_PB_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    BRAM_PB_clk : OUT STD_LOGIC;
    BRAM_PB_din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    BRAM_PB_rst : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
    m_layer_clk_i : IN STD_LOGIC;
    m_layer_aresetn_i : IN STD_LOGIC;
    m_layer_tvalid_o : OUT STD_LOGIC;
    m_layer_tdata_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_layer_tkeep_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_layer_tlast_o : OUT STD_LOGIC;
    m_layer_tready_i : IN STD_LOGIC;
    Dbg_s00_axis_dma_aclk : OUT STD_LOGIC;
    Dbg_s00_axis_dma_aresetn : OUT STD_LOGIC;
    Dbg_m00_axis_dma_tready : OUT STD_LOGIC;
    Dbg_s00_axis_dma_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    Dbg_s00_axis_dma_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    Dbg_s00_axis_dma_tlast : OUT STD_LOGIC;
    Dbg_s00_axis_dma_tvalid : OUT STD_LOGIC;
    m00_axis_dma_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m00_axis_dma_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m00_axis_dma_tlast : OUT STD_LOGIC;
    m00_axis_dma_tvalid : OUT STD_LOGIC;
    m00_axis_dma_tready : IN STD_LOGIC;
    m00_axis_dma_aclk : IN STD_LOGIC;
    m00_axis_dma_aresetn : IN STD_LOGIC;
    s00_axis_dma_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s00_axis_dma_tkeep : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s00_axis_dma_tlast : IN STD_LOGIC;
    s00_axis_dma_tvalid : IN STD_LOGIC;
    s00_axis_dma_tready : OUT STD_LOGIC;
    s00_axis_dma_aclk : IN STD_LOGIC;
    s00_axis_dma_aresetn : IN STD_LOGIC;
    s00_axi_awaddr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s00_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s00_axi_awvalid : IN STD_LOGIC;
    s00_axi_awready : OUT STD_LOGIC;
    s00_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s00_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    s00_axi_wvalid : IN STD_LOGIC;
    s00_axi_wready : OUT STD_LOGIC;
    s00_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s00_axi_bvalid : OUT STD_LOGIC;
    s00_axi_bready : IN STD_LOGIC;
    s00_axi_araddr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    s00_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    s00_axi_arvalid : IN STD_LOGIC;
    s00_axi_arready : OUT STD_LOGIC;
    s00_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    s00_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    s00_axi_rvalid : OUT STD_LOGIC;
    s00_axi_rready : IN STD_LOGIC;
    s00_axi_aclk : IN STD_LOGIC;
    s00_axi_aresetn : IN STD_LOGIC
  );
END zedboard_nn_mem_controller_0_0;

ARCHITECTURE zedboard_nn_mem_controller_0_0_arch OF zedboard_nn_mem_controller_0_0 IS
  ATTRIBUTE DowngradeIPIdentifiedWarnings : STRING;
  ATTRIBUTE DowngradeIPIdentifiedWarnings OF zedboard_nn_mem_controller_0_0_arch: ARCHITECTURE IS "yes";
  COMPONENT DMA_to_BRAM_v1_0 IS
    GENERIC (
      C_M00_AXIS_DMA_TDATA_WIDTH : INTEGER; -- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
      C_M00_AXIS_DMA_START_COUNT : INTEGER; -- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
      C_S00_AXIS_DMA_TDATA_WIDTH : INTEGER; -- AXI4Stream sink: Data Width
      C_S00_AXI_DATA_WIDTH : INTEGER; -- Width of S_AXI data bus
      C_S00_AXI_ADDR_WIDTH : INTEGER; -- Width of S_AXI address bus
      BRAM_ADDR_WIDTH : INTEGER;
      BRAM_DATA_WIDTH : INTEGER;
      USE_MAX_POOLING : BOOLEAN;
      MAX_POOLING_SIZE : INTEGER;
      LAYER_DIM_FEATURES : INTEGER;
      IS_INPUT_LAYER : BOOLEAN;
      NEXT_LAYER_IS_CNN : BOOLEAN;
      LAYER_DIM_ROW : INTEGER;
      LAYER_DIM_COL : INTEGER;
      RGB_INPUT : BOOLEAN
    );
    PORT (
      BRAM_PA_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
      BRAM_PA_clk : OUT STD_LOGIC;
      BRAM_PA_dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
      BRAM_PA_wea : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      BRAM_PB_addr : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
      BRAM_PB_clk : OUT STD_LOGIC;
      BRAM_PB_din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      BRAM_PB_rst : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
      s_layer_clk_i : IN STD_LOGIC;
      s_layer_aresetn_i : IN STD_LOGIC;
      s_layer_tvalid_i : IN STD_LOGIC;
      s_layer_tdata_i : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s_layer_tkeep_i : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s_layer_tlast_i : IN STD_LOGIC;
      s_layer_tready_o : OUT STD_LOGIC;
      m_layer_clk_i : IN STD_LOGIC;
      m_layer_aresetn_i : IN STD_LOGIC;
      m_layer_tvalid_o : OUT STD_LOGIC;
      m_layer_tdata_o : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m_layer_tkeep_o : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m_layer_tlast_o : OUT STD_LOGIC;
      m_layer_tready_i : IN STD_LOGIC;
      Dbg_s00_axis_dma_aclk : OUT STD_LOGIC;
      Dbg_s00_axis_dma_aresetn : OUT STD_LOGIC;
      Dbg_m00_axis_dma_tready : OUT STD_LOGIC;
      Dbg_s00_axis_dma_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      Dbg_s00_axis_dma_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      Dbg_s00_axis_dma_tlast : OUT STD_LOGIC;
      Dbg_s00_axis_dma_tvalid : OUT STD_LOGIC;
      m00_axis_dma_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      m00_axis_dma_tkeep : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      m00_axis_dma_tlast : OUT STD_LOGIC;
      m00_axis_dma_tvalid : OUT STD_LOGIC;
      m00_axis_dma_tready : IN STD_LOGIC;
      m00_axis_dma_aclk : IN STD_LOGIC;
      m00_axis_dma_aresetn : IN STD_LOGIC;
      s00_axis_dma_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s00_axis_dma_tkeep : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s00_axis_dma_tlast : IN STD_LOGIC;
      s00_axis_dma_tvalid : IN STD_LOGIC;
      s00_axis_dma_tready : OUT STD_LOGIC;
      s00_axis_dma_aclk : IN STD_LOGIC;
      s00_axis_dma_aresetn : IN STD_LOGIC;
      s00_axi_awaddr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s00_axi_awprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s00_axi_awvalid : IN STD_LOGIC;
      s00_axi_awready : OUT STD_LOGIC;
      s00_axi_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
      s00_axi_wstrb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      s00_axi_wvalid : IN STD_LOGIC;
      s00_axi_wready : OUT STD_LOGIC;
      s00_axi_bresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s00_axi_bvalid : OUT STD_LOGIC;
      s00_axi_bready : IN STD_LOGIC;
      s00_axi_araddr : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      s00_axi_arprot : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      s00_axi_arvalid : IN STD_LOGIC;
      s00_axi_arready : OUT STD_LOGIC;
      s00_axi_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
      s00_axi_rresp : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
      s00_axi_rvalid : OUT STD_LOGIC;
      s00_axi_rready : IN STD_LOGIC;
      s00_axi_aclk : IN STD_LOGIC;
      s00_axi_aresetn : IN STD_LOGIC
    );
  END COMPONENT DMA_to_BRAM_v1_0;
  ATTRIBUTE X_CORE_INFO : STRING;
  ATTRIBUTE X_CORE_INFO OF zedboard_nn_mem_controller_0_0_arch: ARCHITECTURE IS "DMA_to_BRAM_v1_0,Vivado 2017.4";
  ATTRIBUTE CHECK_LICENSE_TYPE : STRING;
  ATTRIBUTE CHECK_LICENSE_TYPE OF zedboard_nn_mem_controller_0_0_arch : ARCHITECTURE IS "zedboard_nn_mem_controller_0_0,DMA_to_BRAM_v1_0,{}";
  ATTRIBUTE X_INTERFACE_INFO : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER : STRING;
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_aresetn: SIGNAL IS "XIL_INTERFACENAME S00_AXI_RST, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 S00_AXI_RST RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_aclk: SIGNAL IS "XIL_INTERFACENAME S00_AXI_CLK, ASSOCIATED_BUSIF S00_AXI, ASSOCIATED_RESET s00_axi_aresetn, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 S00_AXI_CLK CLK";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RRESP";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_rdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI RDATA";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_arprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARPROT";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_araddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI ARADDR";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_bresp: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI BRESP";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wstrb: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WSTRB";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_wdata: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI WDATA";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awready: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awvalid: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awprot: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWPROT";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axi_awaddr: SIGNAL IS "XIL_INTERFACENAME S00_AXI, WIZ_DATA_WIDTH 32, WIZ_NUM_REG 64, SUPPORTS_NARROW_BURST 0, DATA_WIDTH 32, PROTOCOL AXI4LITE, FREQ_HZ 100000000, ID_WIDTH 0, ADDR_WIDTH 8, AWUSER_WIDTH 0, ARUSER_WIDTH 0, WUSER_WIDTH 0, RUSER_WIDTH 0, BUSER_WIDTH 0, READ_WRITE_MODE READ_WRITE, HAS_BURST 0, HAS_LOCK 0, HAS_PROT 1, HAS_CACHE 0, HAS_QOS 0, HAS_REGION 0, HAS_WSTRB 1, HAS_BRESP 1, HAS_RRESP 1, NUM_READ_OUTSTANDING 2, NUM_WRITE_OUTSTANDING 2, MAX_BURST_LENGTH 1, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0, NUM_READ_THREADS 1, NUM_WRITE_THREADS 1, RUSER_BITS_PER_BYTE 0, WUSER_BITS_PER_BYTE 0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axi_awaddr: SIGNAL IS "xilinx.com:interface:aximm:1.0 S00_AXI AWADDR";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axis_dma_aresetn: SIGNAL IS "XIL_INTERFACENAME S00_AXIS_DMA_RST, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 S00_AXIS_DMA_RST RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axis_dma_aclk: SIGNAL IS "XIL_INTERFACENAME S00_AXIS_DMA_CLK, ASSOCIATED_BUSIF S00_AXIS_DMA, ASSOCIATED_RESET s00_axis_dma_aresetn, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 S00_AXIS_DMA_CLK CLK";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_tready: SIGNAL IS "xilinx.com:interface:axis:1.0 S00_AXIS_DMA TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_tvalid: SIGNAL IS "xilinx.com:interface:axis:1.0 S00_AXIS_DMA TVALID";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_tlast: SIGNAL IS "xilinx.com:interface:axis:1.0 S00_AXIS_DMA TLAST";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_tkeep: SIGNAL IS "xilinx.com:interface:axis:1.0 S00_AXIS_DMA TKEEP";
  ATTRIBUTE X_INTERFACE_PARAMETER OF s00_axis_dma_tdata: SIGNAL IS "XIL_INTERFACENAME S00_AXIS_DMA, WIZ_DATA_WIDTH 32, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF s00_axis_dma_tdata: SIGNAL IS "xilinx.com:interface:axis:1.0 S00_AXIS_DMA TDATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m00_axis_dma_aresetn: SIGNAL IS "XIL_INTERFACENAME M00_AXIS_DMA_RST, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 M00_AXIS_DMA_RST RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m00_axis_dma_aclk: SIGNAL IS "XIL_INTERFACENAME M00_AXIS_DMA_CLK, ASSOCIATED_BUSIF M00_AXIS_DMA, ASSOCIATED_RESET m00_axis_dma_aresetn, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 M00_AXIS_DMA_CLK CLK";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_tready: SIGNAL IS "xilinx.com:interface:axis:1.0 M00_AXIS_DMA TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_tvalid: SIGNAL IS "xilinx.com:interface:axis:1.0 M00_AXIS_DMA TVALID";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_tlast: SIGNAL IS "xilinx.com:interface:axis:1.0 M00_AXIS_DMA TLAST";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_tkeep: SIGNAL IS "xilinx.com:interface:axis:1.0 M00_AXIS_DMA TKEEP";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m00_axis_dma_tdata: SIGNAL IS "XIL_INTERFACENAME M00_AXIS_DMA, WIZ_DATA_WIDTH 32, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF m00_axis_dma_tdata: SIGNAL IS "xilinx.com:interface:axis:1.0 M00_AXIS_DMA TDATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF Dbg_s00_axis_dma_aresetn: SIGNAL IS "XIL_INTERFACENAME Dbg_s00_axis_dma_aresetn, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_s00_axis_dma_aresetn: SIGNAL IS "xilinx.com:signal:reset:1.0 Dbg_s00_axis_dma_aresetn RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF Dbg_s00_axis_dma_aclk: SIGNAL IS "XIL_INTERFACENAME Dbg_s00_axis_dma_aclk, ASSOCIATED_RESET Dbg_s00_axis_dma_aresetn, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_nn_mem_controller_0_0_Dbg_s00_axis_dma_aclk";
  ATTRIBUTE X_INTERFACE_INFO OF Dbg_s00_axis_dma_aclk: SIGNAL IS "xilinx.com:signal:clock:1.0 Dbg_s00_axis_dma_aclk CLK";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_tready_i: SIGNAL IS "xilinx.com:interface:axis:1.0 M_LAYER TREADY";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_tlast_o: SIGNAL IS "xilinx.com:interface:axis:1.0 M_LAYER TLAST";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_tkeep_o: SIGNAL IS "xilinx.com:interface:axis:1.0 M_LAYER TKEEP";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_tdata_o: SIGNAL IS "xilinx.com:interface:axis:1.0 M_LAYER TDATA";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m_layer_tvalid_o: SIGNAL IS "XIL_INTERFACENAME M_LAYER, TDATA_NUM_BYTES 4, TDEST_WIDTH 0, TID_WIDTH 0, TUSER_WIDTH 0, HAS_TREADY 1, HAS_TSTRB 0, HAS_TKEEP 1, HAS_TLAST 1, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0, LAYERED_METADATA undef";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_tvalid_o: SIGNAL IS "xilinx.com:interface:axis:1.0 M_LAYER TVALID";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m_layer_aresetn_i: SIGNAL IS "XIL_INTERFACENAME m_layer_aresetn, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_aresetn_i: SIGNAL IS "xilinx.com:signal:reset:1.0 m_layer_aresetn RST";
  ATTRIBUTE X_INTERFACE_PARAMETER OF m_layer_clk_i: SIGNAL IS "XIL_INTERFACENAME m_layer_clk, ASSOCIATED_RESET m_layer_aresetn_i, ASSOCIATED_BUSIF M_LAYER, FREQ_HZ 100000000, PHASE 0.000, CLK_DOMAIN zedboard_processing_system7_0_0_FCLK_CLK0";
  ATTRIBUTE X_INTERFACE_INFO OF m_layer_clk_i: SIGNAL IS "xilinx.com:signal:clock:1.0 m_layer_clk CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER OF BRAM_PB_rst: SIGNAL IS "XIL_INTERFACENAME BRAM_PB_rst, POLARITY ACTIVE_LOW";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PB_rst: SIGNAL IS "xilinx.com:signal:reset:1.0 BRAM_PB_rst RST, xilinx.com:interface:bram:1.0 BRAM_PORTB RST";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PB_din: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT";
  ATTRIBUTE X_INTERFACE_PARAMETER OF BRAM_PB_clk: SIGNAL IS "XIL_INTERFACENAME BRAM_PB_clk, ASSOCIATED_RESET BRAM_PB_rst, ASSOCIATED_BUSIF BRAM_PORTB, FREQ_HZ 100000000, PHASE 0.000";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PB_clk: SIGNAL IS "xilinx.com:signal:clock:1.0 BRAM_PB_clk CLK, xilinx.com:interface:bram:1.0 BRAM_PORTB CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER OF BRAM_PB_addr: SIGNAL IS "XIL_INTERFACENAME BRAM_PORTB, ASSOCIATED_BUSIF BRAM_PB_clk, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_WRITE_MODE READ_WRITE";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PB_addr: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PA_wea: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA WE";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PA_dout: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN";
  ATTRIBUTE X_INTERFACE_PARAMETER OF BRAM_PA_clk: SIGNAL IS "XIL_INTERFACENAME BRAM_PA_clk, ASSOCIATED_BUSIF BRAM_PORTA, FREQ_HZ 100000000, PHASE 0.000";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PA_clk: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK, xilinx.com:signal:clock:1.0 BRAM_PA_clk CLK";
  ATTRIBUTE X_INTERFACE_PARAMETER OF BRAM_PA_addr: SIGNAL IS "XIL_INTERFACENAME BRAM_PORTA, ASSOCIATED_BUSIF BRAM_PA_clk, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE OTHER, READ_WRITE_MODE READ_WRITE";
  ATTRIBUTE X_INTERFACE_INFO OF BRAM_PA_addr: SIGNAL IS "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR";
BEGIN
  U0 : DMA_to_BRAM_v1_0
    GENERIC MAP (
      C_M00_AXIS_DMA_TDATA_WIDTH => 32,
      C_M00_AXIS_DMA_START_COUNT => 32,
      C_S00_AXIS_DMA_TDATA_WIDTH => 32,
      C_S00_AXI_DATA_WIDTH => 32,
      C_S00_AXI_ADDR_WIDTH => 8,
      BRAM_ADDR_WIDTH => 10,
      BRAM_DATA_WIDTH => 8,
      USE_MAX_POOLING => false,
      MAX_POOLING_SIZE => 2,
      LAYER_DIM_FEATURES => 4,
      IS_INPUT_LAYER => true,
      NEXT_LAYER_IS_CNN => true,
      LAYER_DIM_ROW => 28,
      LAYER_DIM_COL => 28,
      RGB_INPUT => false
    )
    PORT MAP (
      BRAM_PA_addr => BRAM_PA_addr,
      BRAM_PA_clk => BRAM_PA_clk,
      BRAM_PA_dout => BRAM_PA_dout,
      BRAM_PA_wea => BRAM_PA_wea,
      BRAM_PB_addr => BRAM_PB_addr,
      BRAM_PB_clk => BRAM_PB_clk,
      BRAM_PB_din => BRAM_PB_din,
      BRAM_PB_rst => BRAM_PB_rst,
      s_layer_clk_i => '0',
      s_layer_aresetn_i => '0',
      s_layer_tvalid_i => '0',
      s_layer_tdata_i => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 32)),
      s_layer_tkeep_i => STD_LOGIC_VECTOR(TO_UNSIGNED(0, 4)),
      s_layer_tlast_i => '0',
      m_layer_clk_i => m_layer_clk_i,
      m_layer_aresetn_i => m_layer_aresetn_i,
      m_layer_tvalid_o => m_layer_tvalid_o,
      m_layer_tdata_o => m_layer_tdata_o,
      m_layer_tkeep_o => m_layer_tkeep_o,
      m_layer_tlast_o => m_layer_tlast_o,
      m_layer_tready_i => m_layer_tready_i,
      Dbg_s00_axis_dma_aclk => Dbg_s00_axis_dma_aclk,
      Dbg_s00_axis_dma_aresetn => Dbg_s00_axis_dma_aresetn,
      Dbg_m00_axis_dma_tready => Dbg_m00_axis_dma_tready,
      Dbg_s00_axis_dma_tdata => Dbg_s00_axis_dma_tdata,
      Dbg_s00_axis_dma_tkeep => Dbg_s00_axis_dma_tkeep,
      Dbg_s00_axis_dma_tlast => Dbg_s00_axis_dma_tlast,
      Dbg_s00_axis_dma_tvalid => Dbg_s00_axis_dma_tvalid,
      m00_axis_dma_tdata => m00_axis_dma_tdata,
      m00_axis_dma_tkeep => m00_axis_dma_tkeep,
      m00_axis_dma_tlast => m00_axis_dma_tlast,
      m00_axis_dma_tvalid => m00_axis_dma_tvalid,
      m00_axis_dma_tready => m00_axis_dma_tready,
      m00_axis_dma_aclk => m00_axis_dma_aclk,
      m00_axis_dma_aresetn => m00_axis_dma_aresetn,
      s00_axis_dma_tdata => s00_axis_dma_tdata,
      s00_axis_dma_tkeep => s00_axis_dma_tkeep,
      s00_axis_dma_tlast => s00_axis_dma_tlast,
      s00_axis_dma_tvalid => s00_axis_dma_tvalid,
      s00_axis_dma_tready => s00_axis_dma_tready,
      s00_axis_dma_aclk => s00_axis_dma_aclk,
      s00_axis_dma_aresetn => s00_axis_dma_aresetn,
      s00_axi_awaddr => s00_axi_awaddr,
      s00_axi_awprot => s00_axi_awprot,
      s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_awready => s00_axi_awready,
      s00_axi_wdata => s00_axi_wdata,
      s00_axi_wstrb => s00_axi_wstrb,
      s00_axi_wvalid => s00_axi_wvalid,
      s00_axi_wready => s00_axi_wready,
      s00_axi_bresp => s00_axi_bresp,
      s00_axi_bvalid => s00_axi_bvalid,
      s00_axi_bready => s00_axi_bready,
      s00_axi_araddr => s00_axi_araddr,
      s00_axi_arprot => s00_axi_arprot,
      s00_axi_arvalid => s00_axi_arvalid,
      s00_axi_arready => s00_axi_arready,
      s00_axi_rdata => s00_axi_rdata,
      s00_axi_rresp => s00_axi_rresp,
      s00_axi_rvalid => s00_axi_rvalid,
      s00_axi_rready => s00_axi_rready,
      s00_axi_aclk => s00_axi_aclk,
      s00_axi_aresetn => s00_axi_aresetn
    );
END zedboard_nn_mem_controller_0_0_arch;
