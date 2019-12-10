
# Loading additional proc with user specified bodies to compute parameter values.
source [file join [file dirname [file dirname [info script]]] gui/DMA_to_BRAM_v1_0.gtcl]

# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Neural_Network [ipgui::add_page $IPINST -name "Neural Network"]
  #Adding Group
  set General [ipgui::add_group $IPINST -name "General" -parent ${Neural_Network} -layout horizontal]
  ipgui::add_param $IPINST -name "IS_INPUT_LAYER" -parent ${General}
  ipgui::add_param $IPINST -name "RGB_INPUT" -parent ${General}

  #Adding Group
  set Layers [ipgui::add_group $IPINST -name "Layers" -parent ${Neural_Network}]
  ipgui::add_param $IPINST -name "NEXT_LAYER_IS_CNN" -parent ${Layers}
  ipgui::add_param $IPINST -name "LAYER_DIM_FEATURES" -parent ${Layers}
  ipgui::add_param $IPINST -name "LAYER_DIM_COL" -parent ${Layers}
  ipgui::add_param $IPINST -name "LAYER_DIM_ROW" -parent ${Layers}

  #Adding Group
  set Max_Pooling [ipgui::add_group $IPINST -name "Max Pooling" -parent ${Neural_Network}]
  ipgui::add_param $IPINST -name "USE_MAX_POOLING" -parent ${Max_Pooling}
  ipgui::add_param $IPINST -name "MAX_POOLING_SIZE" -parent ${Max_Pooling}


  #Adding Page
  set BRAM_Port [ipgui::add_page $IPINST -name "BRAM Port" -display_name {BRAM Ports}]
  ipgui::add_param $IPINST -name "BRAM_ADDR_WIDTH" -parent ${BRAM_Port}
  ipgui::add_param $IPINST -name "BRAM_DATA_WIDTH" -parent ${BRAM_Port}

  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0" -display_name {AXI}]
  set C_M00_AXIS_DMA_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_M00_AXIS_DMA_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.} ${C_M00_AXIS_DMA_TDATA_WIDTH}
  set C_M00_AXIS_DMA_START_COUNT [ipgui::add_param $IPINST -name "C_M00_AXIS_DMA_START_COUNT" -parent ${Page_0}]
  set_property tooltip {Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.} ${C_M00_AXIS_DMA_START_COUNT}
  set C_S00_AXIS_DMA_TDATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXIS_DMA_TDATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {AXI4Stream sink: Data Width} ${C_S00_AXIS_DMA_TDATA_WIDTH}
  set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S00_AXI_DATA_WIDTH}
  set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Width of S_AXI address bus} ${C_S00_AXI_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}


}

proc update_PARAM_VALUE.LAYER_DIM_FEATURES { PARAM_VALUE.LAYER_DIM_FEATURES PARAM_VALUE.IS_INPUT_LAYER } {
	# Procedure called to update LAYER_DIM_FEATURES when any of the dependent parameters in the arguments change
	
	set LAYER_DIM_FEATURES ${PARAM_VALUE.LAYER_DIM_FEATURES}
	set IS_INPUT_LAYER ${PARAM_VALUE.IS_INPUT_LAYER}
	set values(IS_INPUT_LAYER) [get_property value $IS_INPUT_LAYER]
	if { [gen_USERPARAMETER_LAYER_DIM_FEATURES_ENABLEMENT $values(IS_INPUT_LAYER)] } {
		set_property enabled true $LAYER_DIM_FEATURES
	} else {
		set_property enabled false $LAYER_DIM_FEATURES
	}
}

proc validate_PARAM_VALUE.LAYER_DIM_FEATURES { PARAM_VALUE.LAYER_DIM_FEATURES } {
	# Procedure called to validate LAYER_DIM_FEATURES
	return true
}

proc update_PARAM_VALUE.MAX_POOLING_SIZE { PARAM_VALUE.MAX_POOLING_SIZE PARAM_VALUE.USE_MAX_POOLING } {
	# Procedure called to update MAX_POOLING_SIZE when any of the dependent parameters in the arguments change
	
	set MAX_POOLING_SIZE ${PARAM_VALUE.MAX_POOLING_SIZE}
	set USE_MAX_POOLING ${PARAM_VALUE.USE_MAX_POOLING}
	set values(USE_MAX_POOLING) [get_property value $USE_MAX_POOLING]
	if { [gen_USERPARAMETER_MAX_POOLING_SIZE_ENABLEMENT $values(USE_MAX_POOLING)] } {
		set_property enabled true $MAX_POOLING_SIZE
	} else {
		set_property enabled false $MAX_POOLING_SIZE
	}
}

proc validate_PARAM_VALUE.MAX_POOLING_SIZE { PARAM_VALUE.MAX_POOLING_SIZE } {
	# Procedure called to validate MAX_POOLING_SIZE
	return true
}

proc update_PARAM_VALUE.RGB_INPUT { PARAM_VALUE.RGB_INPUT PARAM_VALUE.IS_INPUT_LAYER } {
	# Procedure called to update RGB_INPUT when any of the dependent parameters in the arguments change
	
	set RGB_INPUT ${PARAM_VALUE.RGB_INPUT}
	set IS_INPUT_LAYER ${PARAM_VALUE.IS_INPUT_LAYER}
	set values(IS_INPUT_LAYER) [get_property value $IS_INPUT_LAYER]
	if { [gen_USERPARAMETER_RGB_INPUT_ENABLEMENT $values(IS_INPUT_LAYER)] } {
		set_property enabled true $RGB_INPUT
	} else {
		set_property enabled false $RGB_INPUT
	}
}

proc validate_PARAM_VALUE.RGB_INPUT { PARAM_VALUE.RGB_INPUT } {
	# Procedure called to validate RGB_INPUT
	return true
}

proc update_PARAM_VALUE.BRAM_ADDR_WIDTH { PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to update BRAM_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_ADDR_WIDTH { PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to validate BRAM_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to update BRAM_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BRAM_DATA_WIDTH { PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to validate BRAM_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.IS_INPUT_LAYER { PARAM_VALUE.IS_INPUT_LAYER } {
	# Procedure called to update IS_INPUT_LAYER when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IS_INPUT_LAYER { PARAM_VALUE.IS_INPUT_LAYER } {
	# Procedure called to validate IS_INPUT_LAYER
	return true
}

proc update_PARAM_VALUE.LAYER_DIM_COL { PARAM_VALUE.LAYER_DIM_COL } {
	# Procedure called to update LAYER_DIM_COL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LAYER_DIM_COL { PARAM_VALUE.LAYER_DIM_COL } {
	# Procedure called to validate LAYER_DIM_COL
	return true
}

proc update_PARAM_VALUE.LAYER_DIM_ROW { PARAM_VALUE.LAYER_DIM_ROW } {
	# Procedure called to update LAYER_DIM_ROW when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.LAYER_DIM_ROW { PARAM_VALUE.LAYER_DIM_ROW } {
	# Procedure called to validate LAYER_DIM_ROW
	return true
}

proc update_PARAM_VALUE.NEXT_LAYER_IS_CNN { PARAM_VALUE.NEXT_LAYER_IS_CNN } {
	# Procedure called to update NEXT_LAYER_IS_CNN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.NEXT_LAYER_IS_CNN { PARAM_VALUE.NEXT_LAYER_IS_CNN } {
	# Procedure called to validate NEXT_LAYER_IS_CNN
	return true
}

proc update_PARAM_VALUE.USE_MAX_POOLING { PARAM_VALUE.USE_MAX_POOLING } {
	# Procedure called to update USE_MAX_POOLING when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.USE_MAX_POOLING { PARAM_VALUE.USE_MAX_POOLING } {
	# Procedure called to validate USE_MAX_POOLING
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to update C_M00_AXIS_DMA_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH { PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to validate C_M00_AXIS_DMA_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT { PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT } {
	# Procedure called to update C_M00_AXIS_DMA_START_COUNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT { PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT } {
	# Procedure called to validate C_M00_AXIS_DMA_START_COUNT
	return true
}

proc update_PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to update C_S00_AXIS_DMA_TDATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH { PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to validate C_S00_AXIS_DMA_TDATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH { MODELPARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_M00_AXIS_DMA_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_M00_AXIS_DMA_START_COUNT { MODELPARAM_VALUE.C_M00_AXIS_DMA_START_COUNT PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_M00_AXIS_DMA_START_COUNT}] ${MODELPARAM_VALUE.C_M00_AXIS_DMA_START_COUNT}
}

proc update_MODELPARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH { MODELPARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXIS_DMA_TDATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.BRAM_ADDR_WIDTH { MODELPARAM_VALUE.BRAM_ADDR_WIDTH PARAM_VALUE.BRAM_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_ADDR_WIDTH}] ${MODELPARAM_VALUE.BRAM_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.BRAM_DATA_WIDTH { MODELPARAM_VALUE.BRAM_DATA_WIDTH PARAM_VALUE.BRAM_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BRAM_DATA_WIDTH}] ${MODELPARAM_VALUE.BRAM_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.USE_MAX_POOLING { MODELPARAM_VALUE.USE_MAX_POOLING PARAM_VALUE.USE_MAX_POOLING } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.USE_MAX_POOLING}] ${MODELPARAM_VALUE.USE_MAX_POOLING}
}

proc update_MODELPARAM_VALUE.MAX_POOLING_SIZE { MODELPARAM_VALUE.MAX_POOLING_SIZE PARAM_VALUE.MAX_POOLING_SIZE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAX_POOLING_SIZE}] ${MODELPARAM_VALUE.MAX_POOLING_SIZE}
}

proc update_MODELPARAM_VALUE.LAYER_DIM_FEATURES { MODELPARAM_VALUE.LAYER_DIM_FEATURES PARAM_VALUE.LAYER_DIM_FEATURES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LAYER_DIM_FEATURES}] ${MODELPARAM_VALUE.LAYER_DIM_FEATURES}
}

proc update_MODELPARAM_VALUE.IS_INPUT_LAYER { MODELPARAM_VALUE.IS_INPUT_LAYER PARAM_VALUE.IS_INPUT_LAYER } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IS_INPUT_LAYER}] ${MODELPARAM_VALUE.IS_INPUT_LAYER}
}

proc update_MODELPARAM_VALUE.NEXT_LAYER_IS_CNN { MODELPARAM_VALUE.NEXT_LAYER_IS_CNN PARAM_VALUE.NEXT_LAYER_IS_CNN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.NEXT_LAYER_IS_CNN}] ${MODELPARAM_VALUE.NEXT_LAYER_IS_CNN}
}

proc update_MODELPARAM_VALUE.LAYER_DIM_ROW { MODELPARAM_VALUE.LAYER_DIM_ROW PARAM_VALUE.LAYER_DIM_ROW } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LAYER_DIM_ROW}] ${MODELPARAM_VALUE.LAYER_DIM_ROW}
}

proc update_MODELPARAM_VALUE.LAYER_DIM_COL { MODELPARAM_VALUE.LAYER_DIM_COL PARAM_VALUE.LAYER_DIM_COL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.LAYER_DIM_COL}] ${MODELPARAM_VALUE.LAYER_DIM_COL}
}

proc update_MODELPARAM_VALUE.RGB_INPUT { MODELPARAM_VALUE.RGB_INPUT PARAM_VALUE.RGB_INPUT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RGB_INPUT}] ${MODELPARAM_VALUE.RGB_INPUT}
}

