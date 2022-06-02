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

        
        
        -- Parameters of the AXI master bus interface:
        constant C_M00_AXI_ADDR_WIDTH  : integer := 32;
        constant C_M00_AXI_DATA_WIDTH  : integer := 32;
   

        signal CLKxCI  : std_logic;
        signal RSTxRBI : std_logic;
        --zoomFact : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        signal GoLData :  std_logic_vector(GoL_DATA_LEN-1 downto 0);
        signal windowTop :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal windowLeft :  std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        signal VideoDriverStart, VideoDriverDone :  std_logic;
        signal GoLReady :  std_logic;
        signal frameBufferAddr :  std_logic_vector(SYS_DATA_LEN-1 downto 0);
        
        signal writeStart :  std_logic;
        signal pixelData :  std_logic_vector(SYS_DATA_LEN-1 downto 0);
        signal pixelAddr :  std_logic_vector(SYS_ADDR_LEN-1 downto 0);
        signal frameDone : std_logic;
        
        signal master_start :  std_logic;
        signal master_address :  std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal master_dataWrite :  std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        signal master_readWrite :  std_logic;
        signal master_done : std_logic;
        signal master_dataRead : std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
        signal enb0 : std_logic;
        signal addrb0 : std_logic_vector(9 downto 0);
        signal dob0:std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal dob1:std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);

        signal work_bram_is : std_logic;
        
        signal colCounter_video_driver :  unsigned(GoL_ADDR_LEN-1 downto 0);
        signal lineCounter_video_driver :  unsigned(GoL_ADDR_LEN-1 downto 0);
        
        signal ena1 : std_logic;
        signal wea1 : std_logic_vector(0 downto 0);
        signal addra1 : STD_LOGIC_VECTOR(9 DOWNTO 0);
        signal dia1 : STD_LOGIC_VECTOR(1023 DOWNTO 0);
        signal enb1 : std_logic;
        signal addrb1 : std_logic_vector(9 downto 0);

        procedure WriteValue(
          --signal master_address : in std_logic_vector(32-1 downto 0);
          --signal master_data : out std_logic_vector(32-1 downto 0);
          signal master_start : std_logic;
          signal master_done : out std_logic
          ) is
        begin
            wait until master_start = '1';
            wait for CLK_PER;
            master_done <= '0';
--            master_data <= master_address;
--            wait for CLK_PER;
--            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            master_done <= '1';
--            wait for CLK_PER;
--            master_done <= '0';
            
        end WriteValue;
        
        
        
        
         COMPONENT blk_mem_gen_0
            PORT (
            clka : IN STD_LOGIC;
            ena : IN STD_LOGIC;
            wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
            addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            dina : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
            clkb : IN STD_LOGIC;
            enb : IN STD_LOGIC;
            addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            doutb : OUT STD_LOGIC_VECTOR(1023 DOWNTO 0)
            );
        END COMPONENT;




--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

    -- Memory reader/writer (master)
--  init_block_inst : entity work.init_block(rtl)
--    port map (
--        CLK => CLKxCI,
--        resetn => RSTxRBI,
--        --------------------------------------
--        -- master
--        master_start => master_start,
--        master_done => master_done,
--        master_readWrite => master_readWrite,
--        master_address => master_address,
--        master_dataRead => master_dataRead,
        
--        -- Control signals for bram0
--        ena0 => ena0,
--        wea0 => wea0,
--        addra0 => addra0_init_block,
--        dia0 => dia0_init_block,
        
--        -- other signals 
--        GameOfLifeAddress => GameOfLifeAddress,
--        start => init_start,
--        done => init_done
--    );
--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
    -- master component
    -- FSM component
    

-- Memory reader/writer (master)
  VideoDriver: entity work.VideoDriver(rtl)
    port map(
        CLK =>  CLKxCI,
        resetn =>  RSTxRBI,
    
        windowTop =>  windowTop,
        windowLeft =>  windowLeft,
        
        GoLReady =>  VideoDriverStart,
        frameBufferAddr => frameBufferAddr,
        
        master_start => master_start,
        master_done => master_done,
        master_address => master_address,
        master_dataWrite => master_dataWrite,
        master_readWrite => master_readWrite,
        
        frameDone => VideoDriverDone,
        
        enb0 => enb0,
        addrb0 => addrb0,
        dob0 => dob0,
    
    
        enb1 => enb1,
        addrb1 => addrb1,
        dob1 => dob1,
    
        work_bram_is => work_bram_is,
        
        colCounter_video_driver => colCounter_video_driver,
        lineCounter_video_driver => lineCounter_video_driver
    );
    
    bram1_inst : blk_mem_gen_0
    PORT MAP (
        clka => CLKxCI,
        ena => ena1,
        wea => wea1,
        addra => addra1,
        dina => dia1,
        clkb => CLKxCI,
        enb => enb1,
        addrb => addrb1,
        doutb => dob1
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
    frameBufferAddr <= (others => '0');
    work_bram_is <= '0';
    for i in 0 to 1023 loop
        ena1 <= '1';
        wea1 <= "1";
        addra1 <= std_logic_vector(to_unsigned(i, addra1'length));
        dia1 <= x"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" when 
        (i mod 2 = 0) else
                x"5555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555";
        wait for CLK_PER;
    end loop;
    

        
    
    master_done<='1';

    wait for CLK_PER;

    VideoDriverStart <= '1';
    wait for CLK_PER;
    VideoDriverStart <= '0';
    for i in 0 to CHECKERBOARD_SIZE*CHECKERBOARD_SIZE loop
        --WriteValue(master_address, master_dataRead, master_start, master_done);
        WriteValue(master_start, master_done);
    end loop;
    
   
    wait until VideoDriverDone='1';
    wait for 10*CLK_PER;
    stop(0);
  end process;
end architecture;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
