`ifndef RV_SIM_CONFIG_SVH
`define RV_SIM_CONFIG_SVH

//
// Shared configuration for RISC-V simulations
//
// This file centralizes all configuration parameter conversions from
// Makefile defines to SystemVerilog localparams. Include this file
// inside your rv_*_sim module to access these configuration values.
//
// Makefile defines:
//   -DSVC_MEM_SRAM          - Use SRAM memory type (vs BRAM default)
//   -DSVC_CPU_SINGLE_CYCLE  - Use single-cycle CPU (vs pipelined default)
//   -DRV_ARCH_ZMMUL         - Enable Zmmul extension (hardware multiply only)
//   -DRV_ARCH_M             - Enable M extension (hardware multiply/divide)
//

`include "svc_rv_defs.svh"

//
// Memory type configuration
//
`ifdef SVC_MEM_BRAM_CACHE
localparam int MEM_TYPE = MEM_TYPE_BRAM_CACHE;
`elsif SVC_MEM_SRAM
localparam int MEM_TYPE = MEM_TYPE_SRAM;
`else
localparam int MEM_TYPE = MEM_TYPE_BRAM;
`endif

//
// CPU pipeline configuration
//
`ifdef SVC_CPU_SINGLE_CYCLE
localparam int PIPELINED = 0;
`else
localparam int PIPELINED = 1;
`endif

//
// ISA extension configuration
//
`ifdef RV_ARCH_ZMMUL
localparam int EXT_ZMMUL = 1;
`else
localparam int EXT_ZMMUL = 0;
`endif

`ifdef RV_ARCH_M
localparam int EXT_M = 1;
`else
localparam int EXT_M = 0;
`endif

//
// Pipeline optimization parameters
//
// These are automatically disabled in single-cycle mode since pipeline
// optimizations (forwarding, branch prediction, BTB, RAS) only make sense
// in a pipelined architecture.
//
localparam int FWD_REGFILE = (PIPELINED != 0) ? 1 : 0;
localparam int FWD = (PIPELINED != 0) ? 1 : 0;
localparam int BPRED = (PIPELINED != 0) ? 1 : 0;
localparam int BTB_ENABLE = (PIPELINED != 0) ? 1 : 0;
localparam int RAS_ENABLE = (PIPELINED != 0) ? 1 : 0;
localparam int RAS_DEPTH = 8;

//
// PC_REG: Pipeline register between PC and IF stages
//
// When enabled, adds a register stage that approximates Rocket-style BTB
// timing. This affects branch prediction timing and can be used to measure
// the impact of late predictions.
//
`ifdef SVC_PC_REG
localparam int PC_REG = 1;
`else
localparam int PC_REG = 0;
`endif

//
// Memory depth configuration
//
// These can be overridden via Makefile defines for each program
//
`ifndef RV_IMEM_DEPTH
`define RV_IMEM_DEPTH 4096
`endif

`ifndef RV_DMEM_DEPTH
`define RV_DMEM_DEPTH 1024
`endif

localparam int IMEM_DEPTH = `RV_IMEM_DEPTH;
localparam int DMEM_DEPTH = `RV_DMEM_DEPTH;

//
// Memory initialization file
//
// Provided by Makefile as -DRV_SIM_HEX='"path/to/file.hex"'
// Default fallback for builds without the define
//
`ifndef RV_SIM_HEX
`define RV_SIM_HEX ".build/sw/rv32i/hello/hello.hex"
`endif

// Use untyped localparam for Icarus compatibility
localparam MEM_INIT = `RV_SIM_HEX;

initial begin
  $display("rv_sim_config: RV_SIM_HEX=%s", `RV_SIM_HEX);
  $display("rv_sim_config: MEM_INIT=%s", MEM_INIT);
  $fflush();
end

`endif
