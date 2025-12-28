#
# local functions
#
namespace eval local {
    proc is_installed {board} {
        return [llength [get_board_parts -quiet $board]]
    }

    proc create_xip_cell {ip name args} {
        set cell [create_bd_cell -type ip -vlnv xilinx.com:ip:$ip $name]
        if {[llength $args] > 0} {
            set_property -dict [lindex $args 0] $cell
        }
        return $cell
    }

    proc create_inline_hdl {ihdl name args} {
        set cell [create_bd_cell -type inline_hdl -vlnv xilinx.com:inline_hdl:$ihdl $name]
        if {[llength $args] > 0} {
            set_property -dict [lindex $args 0] $cell
        }
        return $cell
    } 

    proc connect_pins_list {obj_a obj_b pins_list} {
        if {[llength $pins_list] > 0} {
            set pins [lindex $pins_list 0]
            set pin_a $obj_a/[lindex $pins 0]
            set pin_b $obj_b/[lindex $pins 1]
            connect_pins $pin_a $pin_b
            connect_pins_list $obj_a $obj_b [lrange $pins_list 1 end]
        }
    }

    proc connect_pins {src_pin dst_pins args} {
        if {[llength $args] > 0} {
            connect_pins_list $src_pin $dst_pins [lindex $args 0]
        } else {
            set len [llength $dst_pins]
            if {$len >= 1} {
                connect_bd_net [get_bd_pins $src_pin] [get_bd_pins [lindex $dst_pins 0]]
                if {$len > 1} {
                    connect_pins $src_pin [lrange $dst_pins 1 end]
                }
            }
        }
    }

    proc connect_ifs {if_a if_b} {
        connect_bd_intf_net [get_bd_intf_pins $if_a] [get_bd_intf_pins $if_b]
    }

    proc connect_bd_port {bd_port bd_pins} {
        set len [llength $bd_pins]
        if {$len >= 1} {
            connect_bd_net [get_bd_ports $bd_port] [get_bd_pins [lindex $bd_pins 0]]
            if {$len > 1} {
                connect_bd_port $bd_port [lrange $bd_pins 1 end]
            }
        }
    }

    proc make_pin_external {bd_pin name} {
        make_bd_pins_external  [get_bd_pins $bd_pin] -name $name
    }

    proc make_if_external {bd_if name} {
        make_bd_intf_pins_external  [get_bd_intf_pins $bd_if] -name $name
    }
}

