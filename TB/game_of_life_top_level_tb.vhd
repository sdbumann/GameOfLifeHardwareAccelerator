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
entity game_of_life_top_tb is
end game_of_life_top_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of game_of_life_top_tb is
        --TB constants
        constant CLK_PER : time    := 8 ns;   -- 125 MHz clk freq
        constant CLK_LIM : integer := 2**10;  -- Stops simulation from running forever if circuit is not correct
        --constant period: time := 20 ns;
    
        signal CLKxCI  : std_logic := '0';
        signal RSTxRBI : std_logic := '0';
        --------------------------------------
        signal row_0, row_1, row_2     : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal start                   : std_logic;
        
        signal row_solution            : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal done                    : std_logic;
        --------------------------------------
        signal row_solution_tb         : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin


-- Memory reader/writer (master)
  game_of_life : entity work.game_of_life_top(rtl)
    port map (
        CLK => CLKxCI,
        resetn => RSTxRBI,
        row_0 => row_0,
        row_1 => row_1,
        row_2 => row_2,
        start => start,
        
        row_solution => row_solution,
        done => done
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

    for i in 0 to NUM_INST-1 loop
        row_0(CHECKERBOARD_SIZE-1-WORD_LENGTH*i downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH+1) <= "00000101111100000101111001100000";
        row_1(CHECKERBOARD_SIZE-1-WORD_LENGTH*i downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH+1) <= "00000000000001001001111001000000";
        row_2(CHECKERBOARD_SIZE-1-WORD_LENGTH*i downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH+1) <= "00000000000000000000000001000000";
        row_solution_tb(CHECKERBOARD_SIZE-1-WORD_LENGTH*i downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH+1) <= "00000000111000000011001011000000";
    end loop;
    
    wait for CLK_PER;
    start <= '1';
    wait for CLK_PER;
    start <= '0';
    
    wait until done='1';
    wait until rising_edge(CLKxCI);
    assert (row_solution = row_solution_tb)
    report "row_solution should be = row_solution_tb" severity error;
    

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
