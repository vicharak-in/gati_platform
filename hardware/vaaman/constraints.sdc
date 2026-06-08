create_clock -period 40.0000 tx_pixel_clk
create_clock -period 20.0000 tx_vga_clk
create_clock -period 1.8750  d_clk
create_clock -period 40.0000 rx_pixel_clk
create_clock -period 12.3457 clk_81mhz
create_clock -period 12.3457 s_clk
create_clock -period 12.3457 m_clk
create_clock -period 12.3457 i_clk

set_clock_groups -exclusive -group {tx_pixel_clk tx_vga_clk} -group {rx_pixel_clk} -group {i_clk s_clk m_clk} -group {clk_81mhz}

# DDR Constraints
#####################
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {aaddr[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {aaddr[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {aburst[1] aburst[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {aburst[1] aburst[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {aid[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {aid[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {alen[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {alen[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {alock[1] alock[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {alock[1] alock[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {asize[2] asize[1] asize[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {asize[2] asize[1] asize[0]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {atype}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {atype}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {avalid}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {avalid}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {bready}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {bready}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {rready}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {rready}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {wdata[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {wdata[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {wid[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {wid[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {wlast}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {wlast}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {wstrb[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {wstrb[*]}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 2.500 [get_ports {wvalid}]
set_output_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min -0.400 [get_ports {wvalid}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {aready}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {aready}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {bid[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {bid[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {bvalid}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {bvalid}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {rdata[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {rdata[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {rid[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {rid[*]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {rlast}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {rlast}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {rresp[1] rresp[0]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {rresp[1] rresp[0]}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {rvalid}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {rvalid}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -max 3.000 [get_ports {wready}]
set_input_delay -clock i_clk -reference_pin [get_ports {i_clk~CLKOUT~337~166}] -min 1.500 [get_ports {wready}]
