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
entity VideoDriver_tb is
end VideoDriver_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of VideoDriver_tb is
        --TB constants
        constant CLK_PER : time    := 8 ns;   -- 125 MHz clk freq
        constant CLK_LIM : integer := 2**10;  -- Stops simulation from running forever if circuit is not correct
        --constant period: time := 20 ns;
        
        constant SYS_DATA_LEN : natural := 32;
        constant SYS_ADDR_LEN : natural := 32;
        constant GoL_DATA_LEN : natural := 8; --1024
        constant GoL_ADDR_LEN : natural := 3; --10
        
        constant SCREEN_WIDTH : natural := 4; --change!!!! 320
        constant SCREEN_HEIGHT : natural := 3; --CHANGE!!! 240
        
        constant WINDOW_DIVISION_FACTOR : natural := 1;
        
        constant WINDOW_WIDTH : natural := SCREEN_WIDTH/WINDOW_DIVISION_FACTOR;
        constant WINDOW_HEIGHT : natural := SCREEN_HEIGHT/WINDOW_DIVISION_FACTOR;

        signal CLKxCI  : std_logic;
        signal RSTxRBI : std_logic;
        --zoomFact : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        signal GoLData :  std_logic_vector(GoL_DATA_LEN-1 downto 0);
        signal windowTop :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal windowLeft :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal writeReady :  std_logic;
        signal GoLReady :  std_logic;
        signal frameBufferAddr :  std_logic_vector(SYS_DATA_LEN-1 downto 0);
        
        signal writeStart :  std_logic;
        signal pixelData :  std_logic_vector(SYS_DATA_LEN-1 downto 0);
        signal pixelAddr :  std_logic_vector(SYS_ADDR_LEN-1 downto 0);
        signal GoLAddr :  std_logic_vector (GoL_ADDR_LEN-1 downto 0);
        signal frameDone : std_logic;

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
  VideoDriver: entity work.VideoDriver(rtl)
    generic map (
         SYS_DATA_LEN => SYS_DATA_LEN,
         SYS_ADDR_LEN  => SYS_ADDR_LEN,
         GoL_DATA_LEN  => GoL_DATA_LEN,
         GoL_ADDR_LEN   => GoL_ADDR_LEN,
        
         SCREEN_WIDTH  => SCREEN_WIDTH,
         SCREEN_HEIGHT  => SCREEN_HEIGHT,
        
         WINDOW_DIVISION_FACTOR  => WINDOW_DIVISION_FACTOR,
        
         WINDOW_WIDTH  => WINDOW_WIDTH,
         WINDOW_HEIGHT => WINDOW_HEIGHT
    )
    port map (
        CLK => CLKxCI,
        resetn => RSTxRBI,
        GoLData => GoLData,
        windowTop => windowTop,
        windowLeft => windowLeft,
        writeReady => writeReady,
        
        GoLReady => GoLReady,
        frameBufferAddr => frameBufferAddr,
        writeStart => writeStart,
        pixelData => pixelData,
        pixelAddr => pixelAddr,
        GoLAddr => GoLAddr,
        frameDone => frameDone
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

    GoLReady <= '1';
    GoLData <= x"AA";
    windowTop <= std_logic_vector(to_unsigned(1,windowTop'length));
    windowLeft <= std_logic_vector(to_unsigned(1,windowTop'length));
    frameBufferAddr <= std_logic_vector(to_unsigned(1,frameBufferAddr'length));

    wait until frameDone='1';
  end process;
  
  write_stim: process
  begin
    writeReady <= '1';
    wait until writeStart = '1';
    writeReady <= '0';
    wait for CLK_PER;
  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
