--=============================================================================
-- @file pwm_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

--=============================================================================
--
-- game_of_life_tb.vhd
--
-- @brief This file specifies the test-bench for the game of life HDL block
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR pwm_tb
--=============================================================================
entity game_of_life_tb is
end game_of_life_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of game_of_life_tb is
        --TB constants
        constant CLK_PER : time    := 8 ns;   -- 125 MHz clk freq
        constant CLK_LIM : integer := 2**10;  -- Stops simulation from running forever if circuit is not correct
        --constant period: time := 20 ns;
    
        signal CLKxCI  : std_logic := '0';
        signal RSTxRBI : std_logic := '0';
        --------------------------------------
        signal line_0, line_1, line_2  : std_logic_vector(LINE_LENGTH-1 downto 0);
        signal start_gol               : std_logic;
        
        signal line_solution           : std_logic_vector(WORD_LENGTH-1 downto 0);
        signal done_gol                : std_logic;

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
    -- master component
    -- FSM component
    


--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin


-- Memory reader/writer (master)
  game_of_life : entity work.game_of_life(rtl)
    port map (
        CLK => CLKxCI,
        resetn => RSTxRBI,
        line_0 => line_0,
        line_1 => line_1,
        line_2 => line_2,
        start_gol => start_gol,
        
        line_solution => line_solution,
        done_gol => done_gol
    );
    

--=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_clock: process
  begin
    CLKxCI <= '0';
    wait for CLK_PER / 2;
    CLKxCI <= '1';
    wait for CLK_PER / 2;
  end process;

--=============================================================================
-- RESET PROCESS
-- Process for generating the reset signal
--=============================================================================
  p_reset: process
  begin
    -- Reset the registers
    wait for CLK_PER;
    RSTxRBI <= '0';
    wait for CLK_PER;
    RSTxRBI <= '1';
    wait;
  end process;

--=============================================================================
-- TEST PROCESSS
--=============================================================================
  p_stim: process

  begin
    
    wait until RSTxRBI = '1';

    line_0 <= "0000001011111000001011110011000000";
    line_1 <= "0000000000000010010011110010000000";
    line_2 <= "0000000000000000000000000010000000";
    
    
    -- go into stae Read_start
    wait for CLK_PER;
    start_gol <= '1';
    wait for CLK_PER;
    start_gol <= '0';
    
    
    
    wait until done_gol='1';
    assert (line_solution = "00000000111000000011001011000000")
    report "line_solution should be = 0b00000000111000000011001011000000" severity error;

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
