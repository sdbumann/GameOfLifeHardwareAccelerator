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
use std.env.finish;

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
entity fsm_top_tb is
end fsm_top_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of fsm_top_tb is
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
        
        signal accelStart :  std_logic;
        signal accelDone :  std_logic;
        signal accelStop :  std_logic;
        -- init Block signals
        signal GameOfLifeAddress :  std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        -- Video Driver signals
        signal windowTop :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal windowLeft :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal frameBufferAddr :  std_logic_vector(SYS_DATA_LEN-1 downto 0);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin


-- Memory reader/writer (master)
  fsm_top_inst : entity work.fsm_top(rtl)
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
        
        accelStart => accelStart,
        accelDone => accelDone,
        accelStop => accelStop,
        -- init Block signals
        GameOfLifeAddress => GameOfLifeAddress,
        -- Video Driver signals
        windowTop => windowTop,
        windowLeft => windowLeft,
        frameBufferAddr => frameBufferAddr
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

    windowTop <= (others => '0');
    windowLeft <= (others => '0');
    GameOfLifeAddress <= x"16880000";
    frameBufferAddr <= std_logic_vector(to_unsigned(100,frameBufferAddr'length));
    
    
    master_done <= '1';
    master_dataRead <= std_logic_vector(to_unsigned(1,master_dataRead'length));
    
    accelStart <= '1';
    accelStop <= '0';
    
    wait for 5*CLK_PER;
    
    accelStart <= '0';
    accelStop <= '1';
    
    wait until accelDone = '1';
    wait for 3*CLK_PER;
    stop(0);
  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
