#Script for synthesising all reconfigurable modules out-of-context

set part_num "xc7z020clg484-1"

#obtain RM files
#set rm_files {}
set rm_files [glob /home/anv17/FYP/fyp-rca/rca/pr_modules/*.sv]

#form module names

set rm_names {}

foreach file_name $rm_files {
	set rm_name [string map {".sv" ""} [scan $file_name "/home/anv17/FYP/fyp-rca/rca/pr_modules/%s"]] 
	append rm_name "_ou"
	lappend rm_names $rm_name
}
puts [llength $rm_names]

#append passthrough OU file to lists

lappend rm_files /home/anv17/FYP/fyp-rca/rca/pr_module_pt.sv
lappend rm_names pr_module_pt


#OOC Synthesis of the modules

#Read config files

read_verilog -sv /home/anv17/FYP/fyp-rca/core/taiga_config.sv
read_verilog -sv /home/anv17/FYP/fyp-rca/core/riscv_types.sv
read_verilog -sv /home/anv17/FYP/fyp-rca/core/taiga_types.sv
read_verilog -sv /home/anv17/FYP/fyp-rca/rca/rca_config.sv


foreach file_name $rm_files rm_name $rm_names {
	read_verilog -sv $file_name
  reorder_files -auto
	synth_design -top $rm_name -part $part_num -mode out_of_context
        set dcp_path /home/anv17/FYP/fyp-rca/rca/dcps/rm_ooc_synth_dcps/
	append dcp_path $rm_name "_synth.dcp"
	write_checkpoint $dcp_path
}
#Rename PR module DCP
exec mv /home/anv17/FYP/fyp-rca/rca/dcps/rm_ooc_synth_dcps/pr_module_pt_synth.dcp /home/anv17/FYP/fyp-rca/rca/dcps/rm_ooc_synth_dcps/pt_ou_synth.dcp
