# parameters
set JOBS 8
set PROJ_NAME basys3-mbv32-i2c
set PROJ_DIR $env(HOME)/ws/vivado/$PROJ_NAME
set SCRIPT_DIR [file dirname [info script]]
set XDC_FILE $SCRIPT_DIR/$PROJ_NAME.xdc
set BD_FILE $SCRIPT_DIR/${PROJ_NAME}-bd.tcl
set BD_DESIGN design_1

# import the local functions
source $SCRIPT_DIR/local-funcs.tcl

# set the board repository path
set_param board.repoPaths $env(HOME)/.Xilinx/Vivado/2025.1/xhub/board_store

# create the project
if {! [local::is_installed digilentinc.com:basys3:part0:1.2]} {
    xhub::refresh_catalog [xhub::get_xstores xilinx_board_store]
    xhub::install [xhub::get_xitems digilentinc.com:xilinx_board_store:basys3:1.2]
}
create_project $PROJ_NAME $PROJ_DIR -part xc7a35tcpg236-1
set_property board_part digilentinc.com:basys3:part0:1.2 [current_project]

# create the block design
create_bd_design $BD_DESIGN
source $BD_FILE
save_bd_design

# create the wrapper file
make_wrapper -files [get_files $PROJ_DIR/$PROJ_NAME.srcs/sources_1/bd/$BD_DESIGN/$BD_DESIGN.bd] -top
add_files -norecurse $PROJ_DIR/$PROJ_NAME.gen/sources_1/bd/$BD_DESIGN/hdl/${BD_DESIGN}_wrapper.v

# add the constraint file
add_files -fileset constrs_1 -norecurse $XDC_FILE

# generate the bitstream file
update_compile_order -fileset sources_1
launch_runs impl_1 -to_step write_bitstream -jobs $JOBS
wait_on_run impl_1

# write the XSA file
write_hw_platform -fixed -include_bit -force -file $PROJ_DIR/$PROJ_NAME.xsa

