# -*- coding: utf-8 -*-
"""
Entry point for VUnit-based simulation framework.
Author: N. Selvarajah

Xilinx glbl Module Handling:
---------------------------
When use_xilinx_libs=True, this script automatically handles the Xilinx glbl module:

1. First tries to use XILINX_VIVADO environment variable
2. Falls back to hardcoded path: C:/Xilinx/Vivado/2023.2/data/verilog/src/glbl.v
3. Adds proper compilation flags for glbl module

To set the environment variable:
Windows: setx XILINX_VIVADO "C:\\Xilinx\\Vivado\\2023.2"
Linux: export XILINX_VIVADO="/opt/Xilinx/Vivado/2023.2"

Alternative manual approach:
If automatic detection fails, you can manually copy glbl.v to your project
and include it as a regular source file.
"""

from os import walk, getenv
import os
from os.path import dirname, join, exists
from pathlib import Path
from vunit import VUnit


def find_xilinx_glbl():
    """
    Find the Xilinx glbl.v file in common installation locations.
    Returns the path to glbl.v or None if not found.
    """
    search_paths = []

    # Try environment variable first
    xilinx_vivado = getenv('XILINX_VIVADO')
    if xilinx_vivado:
        search_paths.append(f"{xilinx_vivado}/data/verilog/src/glbl.v")

    # Common installation paths
    common_paths = [
        "C:/Xilinx/Vivado/2023.2/data/verilog/src/glbl.v",
        "C:/Xilinx/Vivado/2023.1/data/verilog/src/glbl.v",
        "C:/Xilinx/Vivado/2024.1/data/verilog/src/glbl.v",
        "/opt/xilinx/vivado/2023.2/data/verilog/src/glbl.v",
        "/opt/xilinx/vivado/2023.1/data/verilog/src/glbl.v",
        "/opt/xilinx/vivado/2024.1/data/verilog/src/glbl.v",
        "/opt/xilinx/vivado/data/vhdl/src/glbl.v", # For NVC compatibility
    ]

    search_paths.extend(common_paths)

    for path in search_paths:
        if exists(path):
            return path

    return None


def discover_hdl_files(root_dir, extensions=(".vhd", ".vhdl", ".v"), ignore_pattern='~', excluded_list=[]):
    """
    Recursively find HDL source files, filtering out unwanted patterns.
    """
    return [
        join(path, file)
        for path, _, files in walk(root_dir)
        for file in files
        if file.endswith(extensions) and ignore_pattern not in file and file not in excluded_list
    ]


def setup_vunit_environment(testbench_glob="**", gui_enabled=False, compile_only=False, clean_run=False, debug=False, xunit_xml=None):
    """
    Set up the VUnit project with basic options and source discovery.
    """
    import sys
    args = sys.argv[1:]

    args.extend(["-p", "1"])
    # Only add testbench_glob if it's not the default wildcard
    if testbench_glob != "**":
        args.append(testbench_glob)
    if gui_enabled:
        args.append("--gui")
    if compile_only:
        args.append("--compile")
    if clean_run:
        args.append("--clean")
    if debug:
        args.append("--log-level=debug")
    if xunit_xml:
        args.extend(["--xunit-xml", xunit_xml])

    vu = VUnit.from_argv(argv=args)
    vu.add_vhdl_builtins()
    vu.add_osvvm()
    return vu


def configure_compile_options(vu, use_xilinx_libs=False, use_intel_altera_libs=False):
    """
    Configure common compilation settings.
    """

    nvc_compilation_options = ["--relaxed"]
    vu.set_compile_option("nvc.a_flags", nvc_compilation_options)
    
    # Add library search paths for NVC when using vendor libraries
    nvc_global_options = []
    if use_xilinx_libs:
        nvc_global_options += ["-L", "unisim", "-L", "unimacro", "-L", "unifast"]
    if use_intel_altera_libs:
        nvc_global_options += ["-L", "altera_mf"]
    
    if nvc_global_options:
        vu.set_compile_option("nvc.global_flags", nvc_global_options)


def configure_simulation_options(vu, timeout_ms=0.5, use_xilinx_libs=False, use_intel_altera_libs=False):
    """
    Configure common simulation settings.
    """
    vu.set_generic("SIMULATION_TIMEOUT_IN_MS", str(timeout_ms), allow_empty=True)

    # Common ModelSim/QuestaSim simulation options
    modelsim_simulation_options = ["-t 1ps", "-voptargs=+acc"]
    # nvc_simulation_options = ["--format=fmt"]

    if use_intel_altera_libs:
        modelsim_simulation_options += ["-L altera_mf_ver", "-L altera_lnsim_ver", "-L lpm_ver"]

    if use_xilinx_libs:
        # Add Xilinx simulation libraries and add glbl module for Xilinx simulations (compiled separately in main)
        modelsim_simulation_options += ["-L unisims_ver", "-L unimacro_ver", "-L xpm", "-L secureip", "glbl"]

    if "questa_base" in getenv('VUNIT_MODELSIM_PATH', ''):
        # For Questa base optimization, enable simulation statistics, and print simulation statistics
        modelsim_simulation_options += ["-qbase_tune", "-printsimstats", "-simstats"]

    vu.set_sim_option("modelsim.vsim_flags", modelsim_simulation_options)
    # vu.set_sim_option("nvc.sim_flags", nvc_simulation_options)
    vu.set_sim_option("disable_ieee_warnings", True)

    # Add file to initialise the simulation when running in GUI mode
    current_directory_path = Path(__file__).resolve().parent
    wave_do_path = f"{current_directory_path}\\find_wave_file.do"
    vu.set_sim_option("modelsim.init_file.gui", wave_do_path, allow_empty=True)


def main(path=".", tb_pattern="**", timeout_ms=0.5, gui=False, compile_only=False, clean=False, debug=False, use_xilinx_libs=False, use_intel_altera_libs=False, excluded_list=[], xunit_xml=None):
    vu = setup_vunit_environment(
        testbench_glob=tb_pattern,
        gui_enabled=gui,
        compile_only=compile_only,
        clean_run=clean,
        debug=debug,
        xunit_xml=xunit_xml
    )

    lib = vu.add_library("vunit_library")
    # Include VHDL files (NVC now supports Verilog but we focus on VHDL for our HDL core library)
    source_files = discover_hdl_files(path, extensions=(".vhd", ".vhdl"), excluded_list=excluded_list)
    lib.add_source_files(source_files, allow_empty=True)

    # Add Xilinx glbl module if Xilinx libraries are enabled
    if use_xilinx_libs:
        glbl_path = find_xilinx_glbl()
        if glbl_path:
            try:
                lib.add_source_file(glbl_path)
                print(f"Added Xilinx glbl module from: {glbl_path}")
            except Exception as e:
                print(f"Warning: Could not add glbl module: {e}")
        else:
            print("Warning: Xilinx glbl.v not found!")
            print(
                "   Please ensure Xilinx Vivado is installed and/or set XILINX_VIVADO environment variable")
            print("   Example: setx XILINX_VIVADO \"C:\\\\Xilinx\\\\Vivado\\\\2023.2\"")
            print("   Or manually copy glbl.v to your project directory")

    configure_compile_options(vu, use_xilinx_libs, use_intel_altera_libs)
    configure_simulation_options(vu, timeout_ms, use_xilinx_libs, use_intel_altera_libs)

    # Start simulation
    try:
        vu.main()
    except SystemExit as exception:
        return exception.code
    return 0


class bcolours:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'


if __name__ == "__main__":
    main()
