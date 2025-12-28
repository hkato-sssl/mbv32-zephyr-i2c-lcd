# Connect AXI IIC to PMOD B
set_property IOSTANDARD LVCMOS33 [get_ports i2c_scl_io]
set_property IOSTANDARD LVCMOS33 [get_ports i2c_sda_io]
set_property PACKAGE_PIN B15 [get_ports i2c_scl_io]
set_property PACKAGE_PIN B16 [get_ports i2c_sda_io]
