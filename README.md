# Single-Stage Pipeline Register with Valid/Ready Handshake

A fully synthesizable SystemVerilog implementation of a single-stage pipeline register with standard valid/ready handshake protocol, designed for high-performance digital systems.

## Overview

This project implements a fundamental building block for pipelined digital designs - a single-stage pipeline register that enables proper flow control and backpressure handling between producer and consumer modules.

## Features

- ✅ Standard valid/ready handshake protocol
- ✅ Configurable data width via parameter
- ✅ Full backpressure support without data loss
- ✅ Single-cycle throughput when not stalled
- ✅ Asynchronous active-low reset
- ✅ Fully synthesizable RTL
- ✅ Comprehensive testbench with multiple test scenarios

## Design Specifications

### Interface

| Port Name  | Direction | Width       | Description                              |
|------------|-----------|-------------|------------------------------------------|
| clk        | Input     | 1           | Clock signal                             |
| rst_n      | Input     | 1           | Active-high asynchronous reset            |
| in_valid   | Input     | 1           | Input data valid signal                  |
| in_ready   | Output    | 1           | Ready to accept input data               |
| in_data    | Input     | DATA_WIDTH  | Input data bus                           |
| out_valid  | Output    | 1           | Output data valid signal                 |
| out_ready  | Input     | 1           | Downstream ready to accept output        |
| out_data   | Output    | DATA_WIDTH  | Output data bus                          |

### Parameters

- `DATA_WIDTH` - Width of data bus (default: 32 bits)

### Handshake Protocol

The module implements a standard valid/ready handshake:

- **Data Transfer**: Occurs when both `valid` and `ready` are asserted on the same clock edge
- **Backpressure**: When `out_ready` is low, the register holds data and deasserts `in_ready`
- **Ready Signal**: `in_ready` is high when the register is either:
  - Empty (not holding valid data), OR
  - Currently draining (output being consumed)

### State Machine

The pipeline register operates in two states:

1. **Empty State** (`valid_reg = 0`):
   - `in_ready = 1` - Ready to accept new data
   - `out_valid = 0` - No valid output data

2. **Full State** (`valid_reg = 1`):
   - `in_ready = out_ready` - Ready if downstream is consuming
   - `out_valid = 1` - Valid output data available

## File Structure

```
pipeline-register/
├── design.sv          # RTL implementation
├── testbench.sv       # Comprehensive testbench
└── README.md          # This file
```

## Testbench Coverage

The testbench includes 8 comprehensive test cases:

1. **Reset State Check** - Verifies proper initialization
2. **Single Transfer** - Basic handshake operation
3. **Back-to-back Transfers** - Maximum throughput test
4. **Backpressure Handling** - Data preservation during stalls
5. **Simultaneous Input/Output** - Pipeline flow-through capability
6. **Sporadic Input Pattern** - Random valid/ready toggling
7. **No Data Loss Verification** - Parallel sender/receiver with 20 transactions
8. **Reset During Operation** - Recovery from mid-transaction reset

### Test Results

```
========================================
Pipeline Register Testbench
========================================
[TEST 1] Reset State Check - PASS
[TEST 2] Single Transfer - PASS
[TEST 3] Back-to-back Transfers - PASS
[TEST 4] Backpressure Handling - PASS
[TEST 5] Simultaneous Input/Output - PASS
[TEST 6] Sporadic Input Pattern - PASS
[TEST 7] No Data Loss Verification - PASS
[TEST 8] Reset During Operation - PASS

*** ALL TESTS PASSED ***
========================================
```

## Running the Simulation

### Using Cadence Xcelium

```bash
xrun -Q -unbuffered -timescale 1ns/1ns -sysv -access +rw design.sv testbench.sv
```

### Online Simulation (EDA Playground)

This design has been tested and verified on EDA Playground using Cadence Xcelium simulator.

**Live Simulation Link**: [https://www.edaplayground.com/x/grnZ](https://www.edaplayground.com/x/grnZ)

You can run the simulation directly in your browser by clicking the link above.

## Waveform Analysis

The testbench automatically generates a VCD waveform file (`pipeline_register.vcd`) for debugging and verification. Key signals to observe:

- `in_valid` & `in_ready` - Input handshake
- `out_valid` & `out_ready` - Output handshake
- `in_data` & `out_data` - Data flow
- `valid_reg` - Internal state

## Synthesis Considerations

- **Fully Synthesizable**: No simulation-only constructs in RTL
- **Clock Gating**: Not implemented (can be added for power optimization)
- **Reset Strategy**: Asynchronous active-low reset for fast recovery
- **Timing**: Single-cycle throughput, zero bubble penalty when flowing

## Key Design Decisions

1. **Asynchronous Reset**: Enables immediate clearing of pipeline state
2. **Combinational Ready Logic**: Minimizes latency in handshake path
3. **Single Register Stage**: Balances simplicity with functionality
4. **Data Width Parameterization**: Reusable across different data types

## Applications

This pipeline register is ideal for:

- AXI-Stream interfaces
- FIFO interfaces
- Clock domain crossing (with additional synchronization)
- Rate matching between modules
- Pipeline stage insertion for timing closure

## Performance Characteristics

| Metric                    | Value                           |
|---------------------------|---------------------------------|
| Throughput               | 1 transfer/cycle (when flowing) |
| Latency                  | 1 cycle                         |
| Backpressure Propagation | 0 cycles (combinational)        |
| Area                     | Minimal (1 data reg + 1 flag)   |


## Author

**Razi Ahmed**  
Applying for: ASIC/RTL Design Intern at optoML  
Email: md.razi720@gmail.com  
LinkedIn: https://www.linkedin.com/in/razi-ahmed-809613201

## License

This project is submitted as part of the optoML ASIC/RTL Design Internship application.

---

*Last Updated: February 2026*
