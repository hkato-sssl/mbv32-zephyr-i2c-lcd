# Clock
local::create_xip clk_wiz:6.0 system_clock {
    CONFIG.USE_RESET    false
    CONFIG.CLK_IN1_BOARD_INTERFACE sys_clock
}
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface sys_clock } [get_bd_pins system_clock/clk_in1]

# MicroBlaze-V
set mbv [local::create_xip microblaze_riscv:1.0 microblaze_riscv_0]
apply_bd_automation -rule xilinx.com:bd_rule:microblaze_riscv -config {
    axi_intc        {1}
    axi_periph      {Enabled}
    debug_module    {Debug Enabled}
    ecc             {None}
    local_mem       {128KB}
    preset          {Real-time}
} $mbv
set_property -dict { 
    CONFIG.C_USE_DCACHE 0
    CONFIG.C_USE_ICACHE 0
} $mbv

# Configure the AXI Interrupt Controller
set_property CONFIG.C_HAS_FAST {0} [get_bd_cells microblaze_riscv_0_axi_intc]

# Configure the AXI Interconnect
set_property CONFIG.NUM_MI {7} [get_bd_cells microblaze_riscv_0_axi_periph]

# AXI Timer
local::create_xip axi_timer:2.0 axi_timer_0

# AXI UART Lite
local::create_xip axi_uartlite:2.0 axi_uartlite_0 {
    CONFIG.C_BAUDRATE   115200
}
apply_board_connection -board_interface usb_uart -ip_intf axi_uartlite_0/UART -diagram $BD_DESIGN

# AXI IIC
local::create_xip  axi_iic:2.1 axi_iic_0
local::make_if_external axi_iic_0/IIC i2c

# Connect buttons and slide switches to GPIO
local::create_xip axi_gpio:2.0 axi_gpio_inputs {
    CONFIG.C_INTERRUPT_PRESENT  1
}
apply_board_connection -board_interface push_buttons_4bits -ip_intf axi_gpio_inputs/GPIO -diagram $BD_DESIGN
apply_board_connection -board_interface dip_switches_16bits -ip_intf axi_gpio_inputs/GPIO2 -diagram $BD_DESIGN

# Connect LEDs to GPIO
local::create_xip axi_gpio:2.0 axi_gpio_led_16bits
apply_board_connection -board_interface led_16bits -ip_intf axi_gpio_led_16bits/GPIO -diagram $BD_DESIGN

# Connect 7-segment display to GPIO
local::create_xip axi_gpio:2.0 axi_gpio_7seg {
    CONFIG.C_INTERRUPT_PRESENT  0
    CONFIG.C_DOUT_DEFAULT       0x0000000F
}
apply_board_connection -board_interface seven_seg_led_an -ip_intf axi_gpio_7seg/GPIO -diagram $BD_DESIGN
apply_board_connection -board_interface seven_seg_led_disp -ip_intf axi_gpio_7seg/GPIO2 -diagram $BD_DESIGN

# Interrupt signal
set_property CONFIG.NUM_PORTS {4} [get_bd_cells microblaze_riscv_0_xlconcat]
local::connect_pins axi_timer_0/interrupt microblaze_riscv_0_xlconcat/In0
local::connect_pins axi_uartlite_0/interrupt microblaze_riscv_0_xlconcat/In1
local::connect_pins axi_gpio_inputs/ip2intc_irpt microblaze_riscv_0_xlconcat/In2
local::connect_pins axi_iic_0/iic2intc_irpt microblaze_riscv_0_xlconcat/In3

# Connect reset signals
apply_board_connection -board_interface reset -ip_intf rst_system_clock_100M/ext_reset -diagram $BD_DESIGN
local::connect_pins rst_system_clock_100M/peripheral_aresetn {
    microblaze_riscv_0_axi_periph/M01_ARESETN
    microblaze_riscv_0_axi_periph/M02_ARESETN
    microblaze_riscv_0_axi_periph/M03_ARESETN
    microblaze_riscv_0_axi_periph/M04_ARESETN
    microblaze_riscv_0_axi_periph/M05_ARESETN
    microblaze_riscv_0_axi_periph/M06_ARESETN
    axi_timer_0/s_axi_aresetn
    axi_uartlite_0/s_axi_aresetn
    axi_gpio_inputs/s_axi_aresetn
    axi_gpio_led_16bits/s_axi_aresetn
    axi_gpio_7seg/s_axi_aresetn
    axi_iic_0/s_axi_aresetn
}

# Connect clock signals
local::connect_pins system_clock/clk_out1 {
    microblaze_riscv_0_axi_periph/M01_ACLK
    microblaze_riscv_0_axi_periph/M02_ACLK
    microblaze_riscv_0_axi_periph/M03_ACLK
    microblaze_riscv_0_axi_periph/M04_ACLK
    microblaze_riscv_0_axi_periph/M05_ACLK
    microblaze_riscv_0_axi_periph/M06_ACLK
    axi_timer_0/s_axi_aclk
    axi_uartlite_0/s_axi_aclk
    axi_gpio_inputs/s_axi_aclk
    axi_gpio_led_16bits/s_axi_aclk
    axi_gpio_7seg/s_axi_aclk
    axi_iic_0/s_axi_aclk
}

# Connect AXI interfaces
local::connect_ifs microblaze_riscv_0_axi_periph/M01_AXI axi_timer_0/S_AXI
local::connect_ifs microblaze_riscv_0_axi_periph/M02_AXI axi_uartlite_0/S_AXI
local::connect_ifs microblaze_riscv_0_axi_periph/M03_AXI axi_gpio_inputs/S_AXI
local::connect_ifs microblaze_riscv_0_axi_periph/M04_AXI axi_gpio_led_16bits/S_AXI
local::connect_ifs microblaze_riscv_0_axi_periph/M05_AXI axi_gpio_7seg/S_AXI
local::connect_ifs microblaze_riscv_0_axi_periph/M06_AXI axi_iic_0/S_AXI

# Epilogue
assign_bd_address
regenerate_bd_layout

