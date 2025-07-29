--!
--! @author:    N. Selvarajah
--! @brief:     This package contains testbench utility functions used in the project.
--! @details:
--!
--! @license    This project is released under the terms of the MIT License. See LICENSE.md for more details.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all; -- for resize
use ieee.math_real.all; -- for ceil and to_bits functions

library osvvm;
use osvvm.RandomPkg.RandomPType;
use osvvm.RandomPkg.NaturalVSlType;

library vunit_lib;
context vunit_lib.vunit_context;

package tb_utils is
    -- Only 1% of the time is reset(_n) active
    constant RESET_N_WEIGHT: NaturalVSlType(std_ulogic'('0') to '1') := ('0' => 1, '1' => 99);
    constant RESET_WEIGHT: NaturalVSlType(std_ulogic'('0') to '1') := ('0' => 99, '1' => 1);
    -- For 50% of the time, the signal is '0' or '1'
    constant WEIGHT_50_PERCENT: NaturalVSlType(std_ulogic'('0') to '1') := ('0' => 50, '1' => 50);

    ------------------------------------------------------------
    -- Procedure for clock generation (less time resolution issues)
    -- usage: generate_clock(sys_clk, 66.67E6); -- 66.67MHz
    ------------------------------------------------------------
    procedure generate_clock(signal clk: out std_ulogic; constant FREQ: real);

    ------------------------------------------------------------
    -- Procedure for clock generation with reset control
    -- Clock is forced to '0' during reset (rst_n='0')
    -- usage: generate_clock_with_reset(sys_clk, rst_n, 66.67E6); -- 66.67MHz
    ------------------------------------------------------------
    procedure generate_clock(signal clk: out std_ulogic; signal rst_n: in std_ulogic; constant FREQ: real);

    ------------------------------------------------------------
    -- Procedure for generating a derived clock signal
    -- from an input clock signal with a specified division factor.
    -- usage: generate_derived_clock(clk_in, rst_n, clk_out, 4); -- Divide by 4
    ------------------------------------------------------------
    procedure generate_derived_clock(
        signal clk_in: in std_ulogic;
        signal rst_n: in std_ulogic;
        signal clk_out: out std_ulogic;
        constant factor: in natural
    );

    ------------------------------------------------------------
    -- Advanced procedure for clock generation
    -- with period adjust to match frequency over time, and run control by signal
    -- usage: generate_advanced_clock(sys_clk, 66.67E6, 0 fs, enable, 50.0);
    ------------------------------------------------------------
    procedure generate_advanced_clock(
        signal clk_out: out std_ulogic;
        target_freq: real;
        initial_delay: time := 0 fs;
        enable: std_ulogic;
        duty: real := 50.0;
        initial_value: std_ulogic := '1'
    );

    ------------------------------------------------------------
    -- Function to convert an integer vector to a string representation
    -- usage: to_string(input_vector);
    ------------------------------------------------------------
    -- NOTE: There's no way to create a generic function with an array type in VHDL-2008
    impure function to_string(input: integer_vector) return string;
end package;

package body tb_utils is
    ------------------------------------------------------------
    -- Procedure for clock generation (less time resolution issues)
    -- usage: generate_clock(sys_clk, 66.67E6); -- 66.67MHz
    ------------------------------------------------------------
    procedure generate_clock(signal clk: out std_ulogic; constant FREQ: real) is
        constant PERIOD: time:= 1 sec / FREQ; -- Full period
        constant HIGH_PERIOD: time:= PERIOD / 2; -- High time
        constant LOW_PERIOD: time:= PERIOD - HIGH_PERIOD; -- Low time; always >= HIGH_PERIOD
    begin
        check(expr => HIGH_PERIOD /= 0 fs, msg => "generate_clock: High time is zero; time resolution to large for frequency");

        while true loop
            clk <= '1';
            wait for HIGH_PERIOD;
            clk <= '0';
            wait for LOW_PERIOD;
        end loop;
    end procedure;
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- Procedure for clock generation with reset control
    -- Clock is forced to '0' during reset (rst_n='0')
    -- usage: generate_clock_with_reset(sys_clk, rst_n, 66.67E6); -- 66.67MHz
    ------------------------------------------------------------
    procedure generate_clock(signal clk: out std_ulogic; signal rst_n: in std_ulogic; constant FREQ: real) is
        constant PERIOD: time:= 1 sec / FREQ; -- Full period
        constant HIGH_PERIOD: time:= PERIOD / 2; -- High time
        constant LOW_PERIOD: time:= PERIOD - HIGH_PERIOD; -- Low time; always >= HIGH_PERIOD
    begin
        check(expr => HIGH_PERIOD /= 0 fs, msg => "generate_clock: High time is zero; time resolution to large for frequency");

        while true loop
            if rst_n = '0' then
                clk <= '0';
                wait until rst_n = '1';
            else
                clk <= '1';
                wait for HIGH_PERIOD;
                clk <= '0';
                wait for LOW_PERIOD;
            end if;
        end loop;
    end procedure;
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- Procedure for generating a derived clock signal
    -- from an input clock signal with a specified division factor.
    -- usage: generate_derived_clock(clk_in, rst_n, clk_out, 4); -- Divide by 4
    ------------------------------------------------------------
    procedure generate_derived_clock(
        signal clk_in: in std_ulogic;
        signal rst_n: in std_ulogic;
        signal clk_out: out std_ulogic;
        constant factor: in natural
    ) is
        constant HALF_FACTOR: natural := factor / 2; -- Half the factor for toggling
        variable counter: natural range 0 to HALF_FACTOR - 1 := HALF_FACTOR - 1;
        variable output: std_ulogic := '0';
    begin
        check(expr => factor > 0, msg => "generate_derived_clock: Division factor must be greater than zero");
        check(expr => factor mod 2 = 0, msg => "generate_derived_clock: Division factor must be an even number");

        while true loop
            wait until rising_edge(clk_in);

            if rst_n = '0' then
                output := '0';
                counter := counter'subtype'high;
            elsif counter = counter'subtype'high then
                counter := 0;
                output := not output;
            else
                counter := counter + 1;
            end if;

            clk_out <= output;
        end loop;
    end procedure;
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- Enhanced clock generator with precise frequency control
    -- Features: phase offset, duty cycle control, run/pause capability
    -- usage: generate_advanced_clock(sys_clk, 66.67E6, 0 fs, enable, 50.0);
    ------------------------------------------------------------
    procedure generate_advanced_clock(
        signal clk_out: out std_ulogic;
        target_freq: real;
        initial_delay: time := 0 fs;
        enable: std_ulogic;
        duty: real := 50.0;
        initial_value: std_ulogic := '1'
    ) is
        constant FULL_CYCLE_TIME: time := 1.0 sec / target_freq;
        constant PULSE_WIDTH: time := (duty/100.0) * FULL_CYCLE_TIME;
        constant IDLE_WIDTH: time := FULL_CYCLE_TIME - PULSE_WIDTH;

        variable elapsed: time := 0 fs;
        variable cycle_count: integer := 0;
        variable timing_adjustment: time := 0 fs;
        variable actual_LOW_PERIOD: time;
    begin
        -- Parameter validation
        assert (PULSE_WIDTH > 0 fs)
            report "Clock generation failed: resolution too low for requested frequency"
            severity FAILURE;

        -- Apply initial phase delay before starting
        clk_out <= initial_value;
        if initial_delay > 0 fs then
            wait for initial_delay;
        end if;

        -- Main clock generation loop with drift correction
        while true loop
            if enable then
                -- High portion of clock cycle
                clk_out <= initial_value;
                wait for PULSE_WIDTH;

                -- Low portion with timing correction
                clk_out <= not initial_value;

                -- Calculate precise low time to maintain frequency accuracy
                elapsed := elapsed + PULSE_WIDTH;
                cycle_count := cycle_count + 1;
                timing_adjustment := (cycle_count * FULL_CYCLE_TIME) - elapsed;
                actual_LOW_PERIOD := IDLE_WIDTH + timing_adjustment;

                wait for actual_LOW_PERIOD;
                elapsed := elapsed + actual_LOW_PERIOD;
            else
                clk_out <= not initial_value;
                wait until enable;
            end if;
        end loop;
    end procedure;
    ------------------------------------------------------------

    ------------------------------------------------------------
    -- Function to convert an integer vector to a string representation
    -- usage: to_string(input_vector);
    ------------------------------------------------------------
    impure function to_string(input: integer_vector) return string is
        impure function recursively_concatenate(input: integer_vector; index: natural) return string is begin
            if index = input'subtype'high then
                return to_string(input(index));
            else
                return to_string(input(index)) & ", " & recursively_concatenate(input, index + 1);
            end if;
        end function;
    begin
        return recursively_concatenate(input, index => input'subtype'low);
    end function;
end package body;
