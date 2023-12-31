set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {btn[0]}]
set_property DRIVE 12 [get_ports {led[0]}]
set_property SLEW SLOW [get_ports {led[0]}]
set_property PACKAGE_PIN U12 [get_ports {btn[0]}]
set_property PACKAGE_PIN V12 [get_ports {btn[1]}]
set_property PACKAGE_PIN U7 [get_ports {btn[2]}]
set_property PACKAGE_PIN Y6 [get_ports {btn[3]}]
set_property PACKAGE_PIN Y9 [get_ports {led[0]}]
set_property PACKAGE_PIN Y8 [get_ports {led[1]}]
set_property PACKAGE_PIN V7 [get_ports {led[2]}]
set_property PACKAGE_PIN W7 [get_ports {led[3]}]
set_property PACKAGE_PIN V10 [get_ports {led[4]}]
set_property PACKAGE_PIN W12 [get_ports {led[5]}]
set_property PACKAGE_PIN W11 [get_ports {led[6]}]
set_property PACKAGE_PIN V8 [get_ports {led[7]}]

set_property PACKAGE_PIN J20 [get_ports {sseg_an[3]}]
set_property PACKAGE_PIN J18 [get_ports {sseg_an[2]}]
set_property PACKAGE_PIN H20 [get_ports {sseg_an[1]}]
set_property PACKAGE_PIN K19 [get_ports {sseg_an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sseg_an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_ca]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_cb]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_cc]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_cd]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_ce]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_cf]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_cg]
set_property IOSTANDARD LVCMOS33 [get_ports sseg_dp]
set_property IOSTANDARD LVCMOS33 [get_ports sysclk_125mhz]

set_property PACKAGE_PIN K20 [get_ports sseg_dp]
set_property PACKAGE_PIN L19 [get_ports sseg_cg]
set_property PACKAGE_PIN H18 [get_ports sseg_cf]
set_property PACKAGE_PIN M20 [get_ports sseg_ce]
set_property PACKAGE_PIN K21 [get_ports sseg_cd]
set_property PACKAGE_PIN K18 [get_ports sseg_cc]
set_property PACKAGE_PIN H17 [get_ports sseg_cb]
set_property PACKAGE_PIN H19 [get_ports sseg_ca]

set_property PACKAGE_PIN L18 [get_ports sysclk_125mhz]
set_property PACKAGE_PIN V9 [get_ports {sw[7]}]
set_property PACKAGE_PIN W10 [get_ports {sw[6]}]
set_property PACKAGE_PIN U9 [get_ports {sw[5]}]
set_property PACKAGE_PIN W8 [get_ports {sw[4]}]
set_property PACKAGE_PIN V4 [get_ports {sw[3]}]
set_property PACKAGE_PIN T4 [get_ports {sw[2]}]
set_property PACKAGE_PIN U5 [get_ports {sw[1]}]
set_property PACKAGE_PIN T6 [get_ports {sw[0]}]

set_property PACKAGE_PIN R15 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

# HDMI
set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { hdmi_cec    }]; #IO_L5N_T0_AD9N_35 Sch=hdmi_cec
set_property -dict { PACKAGE_PIN B20   IOSTANDARD TMDS_33  } [get_ports { hdmi_clk_n  }]; #IO_L13N_T2_MRCC_35 Sch=hdmi_clk_n
set_property -dict { PACKAGE_PIN B19   IOSTANDARD TMDS_33  } [get_ports { hdmi_clk_p  }]; #IO_L13P_T2_MRCC_35 Sch=hdmi_clk_p
set_property -dict { PACKAGE_PIN C18   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_n[0] }]; #IO_L11N_T1_SRCC_35 Sch=hdmi_d_n[0]
set_property -dict { PACKAGE_PIN C17   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_p[0] }]; #IO_L11P_T1_SRCC_35 Sch=hdmi_d_p[0]
set_property -dict { PACKAGE_PIN D17   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_n[1] }]; #IO_L2N_T0_AD8N_35 Sch=hdmi_d_n[1]
set_property -dict { PACKAGE_PIN D16   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_p[1] }]; #IO_L2P_T0_AD8P_35 Sch=hdmi_d_p[1]
set_property -dict { PACKAGE_PIN G16   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_n[2] }]; #IO_L4N_T0_35 Sch=hdmi_d_n[2]
set_property -dict { PACKAGE_PIN G15   IOSTANDARD TMDS_33  } [get_ports { hdmi_d_p[2] }]; #IO_L4P_T0_35 Sch=hdmi_d_p[2]
set_property -dict { PACKAGE_PIN F16   IOSTANDARD LVCMOS33 } [get_ports { hdmi_hpd    }]; #IO_L1P_T0_AD0P_35 Sch=hdmi_hpd
set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { hdmi_out_en }]; #IO_L6N_T0_VREF_35 Sch=hdmi_out_en
set_property -dict { PACKAGE_PIN G20   IOSTANDARD LVCMOS33 } [get_ports { hdmi_scl    }]; #IO_L22P_T3_AD7P_35 Sch=hdmi_scl
set_property -dict { PACKAGE_PIN G21   IOSTANDARD LVCMOS33 } [get_ports { hdmi_sda    }]; #IO_L22N_T3_AD7N_35 Sch=hdmi_sda

#audio
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { ac_bclk   }]; #IO_L12P_T1_MRCC_35 Sch=ac_bclk
set_property -dict { PACKAGE_PIN L22   IOSTANDARD LVCMOS33 } [get_ports { ac_mclk   }]; #IO_L10N_T1_34 Sch=ac_mclk
set_property -dict { PACKAGE_PIN J21   IOSTANDARD LVCMOS33 } [get_ports { ac_muten  }]; #IO_L8P_T1_34 Sch=ac_muten
set_property -dict { PACKAGE_PIN L21   IOSTANDARD LVCMOS33 } [get_ports { ac_pbdat  }]; #IO_L10P_T1_34 Sch=ac_pbdat
set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { ac_pblrc  }]; #IO_L5P_T0_AD9P_35 Sch=ac_pblrc
set_property -dict { PACKAGE_PIN J22   IOSTANDARD LVCMOS33 } [get_ports { ac_recdat }]; #IO_L8N_T1_34 Sch=ac_recdat
set_property -dict { PACKAGE_PIN C19   IOSTANDARD LVCMOS33 } [get_ports { ac_reclrc }]; #IO_L12N_T1_MRCC_35 Sch=ac_reclrc
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { ac_scl    }]; #IO_L5N_T0_34 Sch=ac_scl
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { ac_sda    }]; #IO_L5P_T0_34 Sch=ac_sda
