--!
--! @author:    N. Selvarajah
--! @brief:     Describes utility functions and constants used in the project.
--! @details:
--!
--! @license    This project is released under the terms of the MIT License. See LICENSE for more details.
--!

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package utils_pkg is
    type frequency_t is range 0 to natural'high units
        Hz;
        kHz = 1000 Hz;
        MHz = 1000 kHz;
        GHz = 1000 MHz;
    end units;

    -------------------------------------------------------------
    -- Function to convert a frequency to Hz
    -- usage: to_real(1.0 kHz); -- returns 1000.0
    -- usage: to_real(1.0 MHz); -- returns 1000000.0
    -- usage: to_real(1.0 GHz); -- returns 1000000000.0
    -------------------------------------------------------------
    function to_real(frequency: frequency_t) return real;

    -------------------------------------------------------------
    -- Function to convert a time value to seconds
    -- usage: to_real(1.0 fs); -- returns 1.0e
    -- usage: to_real(1.0 ps); -- returns 1.0e-12
    -- usage: to_real(1.0 ns); -- returns 1.0e
    -- usage: to_real(1.0 us); -- returns 1.0e-6
    -- usage: to_real(1.0 ms); -- returns 1.0e-3
    -- usage: to_real(1.0 sec); -- returns 1.0
    -- usage: to_real(1.0 min); -- returns 60.0
    -- usage: to_real(1.0 hr); -- returns 3600.0
    -------------------------------------------------------------
    function to_real(time_value: time) return real;

    -------------------------------------------------------------
    -- Function to convert a frequency to a time value
    -- usage: to_time(1.0 kHz); -- returns 1 ms
    -- usage: to_time(1.0 MHz); -- returns 1 us
    -- usage: to_time(1.0 GHz); -- returns 1 ns
    -- usage: to_time(1.0 THz); -- returns 1 ps
    -------------------------------------------------------------
    function to_time(frequency: frequency_t) return time;

    ------------------------------------------------------------
    -- Function to convert a time value to a frequency
    -- usage: to_frequency(1 ms); -- returns 1.0 kHz
    -- usage: to_frequency(1 us); -- returns 1.0 MHz
    -- usage: to_frequency(1 ns); -- returns 1.0 GHz
    -- usage: to_frequency(1 ps); -- returns 1.0 THz
    ------------------------------------------------------------
    function to_frequency(time_value: time) return frequency_t;

    ------------------------------------------------------------
    -- Function to convert a time value to clock cycles
    -- usage: to_clock_cycles(1 ms, 100 MHz); -- returns 100000
    -- usage: to_clock_cycles(1 us, 100 MHz); -- returns 100
    -- usage: to_clock_cycles(1 ns, 100 MHz); -- returns 100
    -- usage: to_clock_cycles(1 ps, 100 MHz); -- returns 0
    ------------------------------------------------------------
    function to_clock_cycles(time_value: time; clock_frequency: frequency_t) return positive;

    ------------------------------------------------------------
    -- Function to convert a natural or real number to the number of bits required to represent it
    -- usage: to_bits(8); -- returns 4, as 8 can be represented in 4 bits (1000)
    -- usage: to_bits(255); -- returns 8, as 255 can be represented in 8 bits
    ------------------------------------------------------------
    function to_bits(x: natural) return natural;
    function to_bits(x: real) return natural;

    ------------------------------------------------------------
    -- Function to convert a boolean to std_ulogic
    -- usage: '1' ?? true; -- returns '1'
    -- usage: '0' ?? false; -- returns '0'
    ------------------------------------------------------------
    function "??"(right: boolean) return std_ulogic;

    ------------------------------------------------------------
    -- Function to create an UNRESOLVED_UNSIGNED vector of a given length
    -- usage: 2 ** 8; -- returns an UNRESOLVED_UNSIGNED vector
    -- usage: 2 ** 8(0 to 7); -- returns an UNRESOLVED_UNSIGNED vector of length 8
    ------------------------------------------------------------
    function "**"(Left: integer; Right: UNRESOLVED_UNSIGNED) return UNRESOLVED_UNSIGNED;

    ------------------------------------------------------------
    -- Function to read a file and return the number of characters
    -- usage: file_length_in_characters("filename.txt");
    ------------------------------------------------------------
    impure function file_length_in_characters(filename: string) return natural;

    ------------------------------------------------------------
    -- Function to get stats about a std_ulogic_vector
    -- usage: get_amount_of_state(data, '1');
    ------------------------------------------------------------
    function get_amount_of_state(data: std_ulogic_vector; state: std_ulogic) return unsigned;
    function get_amount_of_state(data: std_ulogic_vector; state: std_ulogic) return natural;

    ------------------------------------------------------------
    -- Function to get the amount of trailing state in a std_ulogic_vector
    -- usage: get_amount_of_trailing_state(data, '1');
    ------------------------------------------------------------
    function get_amount_of_trailing_state(data: std_ulogic_vector; state: std_ulogic) return unsigned;
    function get_amount_of_trailing_state(data: std_ulogic_vector; state: std_ulogic) return natural;

    ------------------------------------------------------------
    -- Functions to get the lowest and highest active bit in a std_ulogic_vector
    -- usage: get_lowest_active_bit(data);
    -- usage: get_highest_active_bit(data);
    ------------------------------------------------------------
    function get_lowest_active_bit(data: std_ulogic_vector) return natural;
    function get_highest_active_bit(data: std_ulogic_vector) return natural;

    ------------------------------------------------------------
    -- Function to check if a std_ulogic_vector is one state
    -- usage: is_one_state(data, '1');
    -- usage: is_one_state(data, '0');
    -- Function to check if a std_ulogic_vector is one hot
    ------------------------------------------------------------
    function is_one_state(data: std_ulogic_vector; state: std_ulogic) return boolean;
    function is_one_hot(data: std_ulogic_vector) return boolean;
    function is_one_cold(data: std_ulogic_vector) return boolean;

    ----------------------------------------------------------------
    -- Function to check relatively equality of two real numbers
    -- usage: is_relatively_equal(a, b, epsilon);
    ----------------------------------------------------------------
    function is_relatively_equal(a, b: real; epsilon: real := 1.0e-6) return boolean;
end package;

package body utils_pkg is
    function to_real(frequency: frequency_t) return real is begin
        if (frequency < 1.0 kHz) then
            return real(frequency / 1.0 Hz); -- Already in Hz
        elsif (frequency < 1.0 MHz) then
            return real(frequency / 1.0 kHz) * 1.0e3;
        elsif (frequency < 1.0 GHz) then
            return real(frequency / 1.0 MHz) * 1.0e6;
        else
            return real(frequency / 1.0 GHz) * 1.0e9;
        end if;
    end function;

    function to_real(time_value: time) return real is begin
        if (time_value < 1.0 ns) then
            if (time_value < 1.0 ps) then
                return real(time_value / 1 fs) * 1.0e-15;
            else
                return real(time_value / 1 ps) * 1.0e-12;
            end if;
        elsif (time_value < 1.0 us) then
            return real(time_value / 1 ns) * 1.0e-9;
        elsif (time_value < 1.0 ms) then
            return real(time_value / 1 us) * 1.0e-6;
        elsif (time_value < 1.0 sec) then
            return real(time_value / 1 ms) * 1.0e-3;
        elsif (time_value < 1.0 min) then
            return real(time_value / 1 sec); -- Already in seconds
        elsif (time_value < 1.0 hr) then
            return real(time_value / 1 min) * 60.0;
        else
            return real(time_value / 1 hr) * 3600.0;
        end if;
    end function;

    function to_time(frequency: frequency_t) return time is
        variable frequency_value_hz: real;
    begin
        frequency_value_hz := to_real(frequency);
        if (frequency_value_hz = 0.0) then
            return 0 fs; -- Return zero time for zero frequency
        end if;
        return 1.0 / frequency_value_hz * 1.0 sec;
    end function;

    function to_frequency(time_value: time) return frequency_t is
        variable time_value_sec: real;
    begin
        time_value_sec := to_real(time_value);
        if (time_value_sec = 0.0) then
            return 0 Hz; -- Return zero frequency for zero time
        end if;
        return 1.0 / time_value_sec * 1.0 Hz;
    end function;

    function to_clock_cycles(time_value: time; clock_frequency: frequency_t) return positive is
        variable time_value_sec: real;
        variable clock_frequency_hz: real;
    begin
        clock_frequency_hz := to_real(clock_frequency);
        time_value_sec := to_real(time_value);
        return positive(ceil(time_value_sec * clock_frequency_hz));
    end function;

    function to_bits(x: real) return natural is begin
        return natural(ceil(log2(x)));
    end function;

    function to_bits(x: natural) return natural is begin
        return to_bits(real(x));
    end function;

    function "??"(right: boolean) return std_ulogic is begin
        if right then
            return '1';
        else
            return '0';
        end if;
    end function;

    function "**"(Left: integer; Right: UNRESOLVED_UNSIGNED) return UNRESOLVED_UNSIGNED is
        constant RIGHT_INT: natural := to_integer(Right);
        constant BITS_FOR_LEFT: natural := to_bits(Left);
        constant FINAL_BITS_WIDTH: natural := RIGHT_INT * BITS_FOR_LEFT;
        variable result: UNRESOLVED_UNSIGNED(FINAL_BITS_WIDTH - 1 downto 0) := (others => '0');
        variable power: integer := 1;
    begin
        -- Handle special cases
        if RIGHT_INT = 0 then
            result(0) := '1';  -- Return 1 when exponent is 0
            return result;
        end if;

        for i in 0 to RIGHT_INT - 1 loop
            power := power * Left;
        end loop;

        result := to_unsigned(power, FINAL_BITS_WIDTH);
        return result;
    end function;

    impure function file_length_in_characters(filename: string) return natural is
        type char_file_t is file of character;
        file char_file : char_file_t;
        variable char_v : character;
        variable res_v : natural;
    begin
        res_v := 0;
        file_open(char_file, filename, read_mode);

        while not endfile(char_file) loop
            read(char_file, char_v);
            res_v := res_v + 1;
        end loop;

        file_close(char_file);
        return res_v;
    end function;

    function get_amount_of_state(data: std_ulogic_vector; state: std_ulogic) return unsigned is
        variable res_v : unsigned(to_bits(data'length) - 1 downto 0) := (others => '0');
    begin
        for i in data'range loop
            if data(i) = state then
                res_v := res_v + 1;
            end if;
        end loop;
        return res_v;
    end function;

    function get_amount_of_state(data: std_ulogic_vector; state: std_ulogic) return natural is begin
        return to_integer(resize(get_amount_of_state(data => data, state => state), to_bits(natural'high)));
    end function;

    function get_amount_of_trailing_state(data: std_ulogic_vector; state: std_ulogic) return unsigned is
        -- +1 for the maximum amount of trailing zeroes
        variable trailing_state_amount: unsigned(to_bits(data'length) downto 0) := (others => '0');
    begin
        for i in data'low to data'high loop
            if data(i) = state then
                trailing_state_amount := trailing_state_amount + 1;
            else
                exit;
            end if;
        end loop;
        return trailing_state_amount;
    end function;

    function get_amount_of_trailing_state(data: std_ulogic_vector; state: std_ulogic) return natural is begin
        return to_integer(resize(get_amount_of_trailing_state(data => data, state => state), to_bits(natural'high)));
    end function;

    function get_lowest_active_bit(data: std_ulogic_vector) return natural is begin
        for i in data'low to data'high loop
            if data(i) then
                return i;
            end if;
        end loop;

        return data'length; -- Return length if no '1' is found
    end function;

    function get_highest_active_bit(data: std_ulogic_vector) return natural is begin
        for i in data'high to data'low loop
            if data(i) then
                return i;
            end if;
        end loop;

        return data'length; -- Return length if no '1' is found
    end function;

    function is_one_state(data: std_ulogic_vector; state: std_ulogic) return boolean is
        variable state_counter: natural range 0 to data'length := 0;
    begin
        for i in data'range loop
            if data(i) = state then
                state_counter := state_counter + 1;
            end if;
            if state_counter > 1 then
                return false;
            end if;
        end loop;
        return (state_counter = 1);
    end function;

    function is_one_hot(data: std_ulogic_vector) return boolean is begin
        return is_one_state(data => data, state => '1');
    end function;

    function is_one_cold(data: std_ulogic_vector) return boolean is begin
        return is_one_state(data => data, state => '0');
    end function;

    function is_relatively_equal(a, b: real; epsilon: real := 1.0e-6) return boolean is
        variable diff: real;
    begin
        diff := abs(a - b);
        if diff <= epsilon * maximum(abs(a), abs(b)) then
            return true;
        else
            return false;
        end if;
    end function;
end package body;
