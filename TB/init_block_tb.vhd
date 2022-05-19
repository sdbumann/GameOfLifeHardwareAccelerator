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
entity init_block_tb is
end init_block_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of init_block_tb is
        --TB constants
        constant CLK_PER : time    := 8 ns;   -- 125 MHz clk freq
        constant CLK_LIM : integer := 2**10;  -- Stops simulation from running forever if circuit is not correct
        --constant period: time := 20 ns;
    
        signal CLKxCI  : std_logic := '0';
        signal RSTxRBI : std_logic := '0';
        --------------------------------------
        
        
        
        constant C_M00_AXI_ADDR_WIDTH  : integer := 32;
        constant C_M00_AXI_DATA_WIDTH  : integer := 32;
    
        --------------------------------------
        -- master
        signal master_start : std_logic;
        signal master_done : std_logic;
        signal master_readWrite : std_logic;
        signal master_address : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal master_dataRead : std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
        -- Control signals for bram0
        signal ena0 : std_logic;
        signal wea0 : std_logic;
        signal addra0 : std_logic_vector(9 downto 0);
        signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        signal enb0 : std_logic; 
        signal addrb0: std_logic_vector(9 downto 0);
        signal dob0:std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- other signals 
        signal GameOfLifeAddress : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal start :  std_logic;
        signal done : std_logic;
        signal init_row_0_out, init_row_1_out, init_row_2_out : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
     
        

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin


-- Memory reader/writer (master)
  init_block_inst : entity work.init_block(rtl)
--    generic map ( 
--        C_M00_AXI_ADDR_WIDTH => 32,
--        C_M00_AXI_DATA_WIDTH => 32,
--    )
    port map (
        CLK => CLKxCI,
        resetn => RSTxRBI,
        --------------------------------------
        -- master
        master_start => master_start,
        master_done => master_done,
        master_readWrite => master_readWrite,
        master_address => master_address,
        master_dataRead => master_dataRead,
        
        -- Control signals for bram0
        ena0 => ena0,
        wea0 => wea0,
        addra0 => addra0,
        dia0 => dia0,
        
        -- other signals 
        GameOfLifeAddress => GameOfLifeAddress,
        start => start,
        done => done,
        init_row_0_out => init_row_0_out,
        init_row_1_out => init_row_1_out,
        init_row_2_out => init_row_2_out
    );
    
    bram0_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => CLKxCI, ena => ena0, enb => enb0, wea => wea0, addra => addra0, addrb => addrb0, dia => dia0,
      dob => dob0
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

    wait for CLK_PER;
    start <= '1';
    master_done <= '1';
    GameOfLifeAddress <= std_logic_vector(to_unsigned(1,GameOfLifeAddress'length));
    wait for CLK_PER;
    start <= '0';
    
    master_dataRead <= std_logic_vector(to_unsigned(1, master_dataRead'length));
    
    wait until done='1';
    wait until rising_edge(CLKxCI);
--    assert (row_solution = row_solution_tb)
--    report "row_solution should be = row_solution_tb" severity error;
    

    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
