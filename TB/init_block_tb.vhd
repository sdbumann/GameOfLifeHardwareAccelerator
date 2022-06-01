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
        constant CLK_PER : time    := 18.18 ns;   -- 125 MHz clk freq
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
        signal wea0 : std_logic_vector(0 downto 0);
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
     
        procedure WriteValue(
          signal master_address : in std_logic_vector(32-1 downto 0);
          signal master_data : out std_logic_vector(32-1 downto 0);
          signal master_start : std_logic;
          signal master_done : out std_logic
          ) is
        begin
            wait until master_start = '1';
            wait for CLK_PER;
            master_done <= '0';
            master_data <= std_logic_vector(shift_right(unsigned(master_address),2));
            wait for CLK_PER;
            wait for CLK_PER;
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
        wea0 => wea0(0),
        addra0 => addra0,
        dia0 => dia0,
        
        -- other signals 
        GameOfLifeAddress => GameOfLifeAddress,
        start => start,
        done => done
    );
    
    bram0_inst : blk_mem_gen_0
    PORT MAP (
        clka => CLKxCI,
        ena => ena0,
        wea => wea0,
        addra => addra0,
        dina => dia0,
        clkb => CLKxCI,
        enb => enb0,
        addrb => addrb0,
        doutb => dob0
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
    master_done<='1';
    --start <= '1';
--    wait for CLK_PER;
--    wait for CLK_PER;
--    wait for CLK_PER;
--    wait for CLK_PER;


    -- fill working memory
    wait for CLK_PER;
    GameOfLifeAddress <= std_logic_vector(to_unsigned(0,GameOfLifeAddress'length));
    start <= '1';
--    wait for CLK_PER;
--    start <= '0';
    for i in 0 to CHECKERBOARD_SIZE*CHECKERBOARD_SIZE/32-1 loop
        WriteValue(master_address, master_dataRead, master_start, master_done);
    end loop;
    wait until done='1';
    wait until rising_edge(CLKxCI);
    

    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
