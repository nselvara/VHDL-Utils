[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)

# VHDL-Utils

A collection of reusable VHDL utilities, components, and testbenches to accelerate hardware design workflows. This repository provides tested, reliable building blocks for digital design projects with comprehensive simulation support.

The utilities are designed to work with VHDL-2008 simulators and include support for [VUnit framework](https://vunit.github.io/) and [OSVVM](https://osvvm.org/) for enhanced testing capabilities.

## Requirements

- **VHDL Simulator**: Any simulator that supports **VHDL-2008**
- **IDE** (Optional but recommended):
  - [`VSCode latest`](https://code.visualstudio.com/download) with VHDL language support:
    - [`TerosHDL`](https://marketplace.visualstudio.com/items?itemName=teros-technology.teroshdl) by Teros Technology
    - [`VHDL-LS`](https://marketplace.visualstudio.com/items?itemName=hbohlin.vhdl-ls) by Henrik Bohlin
- **Python 3.11+** (Optional): For VUnit-based simulation automation

## Initial Setup

### Clone repository

- Open terminal
- Run `git clone git@github.com:nselvara/VHDL-Utils.git`
- Run `cd VHDL-Utils`
- Run `code .` to open VSCode in the current directory

## Available Components

This repository includes the following VHDL utilities and components:

### Core VHDL Utilities (`utils_pkg.vhd`)
- **Bit calculation functions**: `to_bits()` - Calculate minimum bits needed to represent a number
- **Boolean conversion**: `??` operator - Convert boolean to std_ulogic  
- **Vector operations**: `**` operator - Create UNRESOLVED_UNSIGNED vectors
- **File operations**: `file_length_in_characters()` - Get file size in characters
- **Signal analysis**: `get_amount_of_state()` - Count occurrences of specific states in vectors

### Testbench Utilities (`tb_utils.vhd`)
- **Clock generation**: 
  - `generate_clock()` - Basic clock generation with frequency control
  - `generate_clock()` with reset - Clock generation with reset synchronization
  - `generate_derived_clock()` - Derived clock generation with division factors
- **Reset patterns**: Predefined weight distributions for realistic reset scenarios
- **Random signal generation**: 50/50 weight distributions for balanced testing

### Simulation Support
- **VUnit integration** (`run_all_testbenches_lib.py`): Python library for automated testbench execution
- **Xilinx library support**: Automatic glbl module handling for Xilinx simulations  
- **Wave file automation** (`find_wave_file.do`): ModelSim script for automatic wave file loading

## Usage

To use these utilities in your VHDL projects:

1. Include the relevant package files in your project
2. Add the appropriate `use` statements in your VHDL files:
   ```vhdl
   library work;
   use work.utils_pkg.all;     -- For general utilities
   use work.tb_utils.all;      -- For testbench utilities
   ```
3. For VUnit-based testing, use the provided Python library to automate simulation runs
