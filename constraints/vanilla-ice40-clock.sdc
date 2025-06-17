create_clock -name CLK -period 10 [get_ports CLK]
create_clock -name ADC_CLK_TO_FPGA -period 20 [get_ports ADC_CLK_TO_FPGA]
