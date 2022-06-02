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
entity game_of_life_dram_copier_tb is
end game_of_life_dram_copier_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of game_of_life_dram_copier_tb is
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

        
        -- Control signals for bram0
        signal ena0 : std_logic;
        signal wea0 : std_logic_vector(0 downto 0);
        signal addra0 : std_logic_vector(9 downto 0);
        signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0 : std_logic; 
        signal addrb0 : std_logic_vector(9 downto 0);
        signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        

        
        -- Control signals for bram0 for game_of_life_block

        
        -- Control signals for bram0
        signal ena1 : std_logic;
        signal wea1 : std_logic_vector(0 downto 0);
        signal addra1 : std_logic_vector(9 downto 0);
        signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1 : std_logic; 
        signal addrb1 : std_logic_vector(9 downto 0);
        signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        signal ena0_gol_block : std_logic;
        signal wea0_gol_block : std_logic_vector(0 downto 0);
        signal addra0_gol_block : std_logic_vector(9 downto 0);
        signal dia0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0_gol_block : std_logic; 
        signal addrb0_gol_block : std_logic_vector(9 downto 0);
        signal dob0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        
        -- Control signals for bram1 for game_of_life_block
        signal ena1_gol_block : std_logic;
        signal wea1_gol_block : std_logic_vector(0 downto 0);
        signal addra1_gol_block : std_logic_vector(9 downto 0);
        signal dia1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1_gol_block : std_logic; 
        signal addrb1_gol_block : std_logic_vector(9 downto 0);
        signal dob1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        signal ena0_bram_block : std_logic;
        signal wea0_bram_block : std_logic_vector(0 downto 0);
        signal addra0_bram_block : std_logic_vector(9 downto 0);
        signal dia0_bram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0_bram_block : std_logic; 
        signal addrb0_bram_block : std_logic_vector(9 downto 0);
        signal dob0_bram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        
        -- Control signals for bram1 for game_of_life_block
        signal ena1_bram_block : std_logic;
        signal wea1_bram_block : std_logic_vector(0 downto 0);
        signal addra1_bram_block : std_logic_vector(9 downto 0);
        signal dia1_bram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1_bram_block : std_logic; 
        signal addrb1_bram_block : std_logic_vector(9 downto 0);
        signal dob1_bram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        

        
        -- other signals 
        signal GameOfLifeAddress : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);

        signal GOL_block_start :  std_logic;
        signal GOL_block_done : std_logic;
        signal work_bram_is : std_logic := '0';

        
        signal tb_master_data_ok : std_logic;
        
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
            master_data <= master_address;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            master_done <= '1';
--            wait for CLK_PER;
--            master_done <= '0';
            
        end WriteValue;
        
        type TState is (GAME_OF_LIFE_BLOCK, BRAM_BLOCK);
        signal state : TSTATE;
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

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



    
    game_of_life_block_inst: entity work.game_of_life_block(rtl)
    port map(CLK => CLKxCI, resetn => RSTxRBI, 
    ena0 => ena0_gol_block, 
    wea0 => wea0_gol_block(0), 
    addra0 => addra0_gol_block,
    dia0  => dia0_gol_block,
    enb0  => enb0_gol_block,
    addrb0  => addrb0_gol_block,
    dob0  => dob0_gol_block,
    
    -- Control signals for bram1
    ena1  => ena1_gol_block,
    wea1  => wea1_gol_block(0),
    addra1  => addra1_gol_block,
    dia1  => dia1_gol_block,
    enb1  => enb1_gol_block,
    addrb1  => addrb1_gol_block,
    dob1  => dob1_gol_block,
    
    -- other signals 
    start  => GOL_block_start,
    done  => GOL_block_done,
    work_bram_is => work_bram_is
    );

    ena0 <= ena0_gol_block when state = GAME_OF_LIFE_BLOCK else
            ena0_bram_block;
    wea0 <= wea0_gol_block when state = GAME_OF_LIFE_BLOCK else
            wea0_bram_block;
    addra0 <= addra0_gol_block when state = GAME_OF_LIFE_BLOCK else
            addra0_bram_block;
            
    dia0 <= dia0_gol_block when state = GAME_OF_LIFE_BLOCK else
            dia0_bram_block;
    enb0 <= enb0_gol_block when state = GAME_OF_LIFE_BLOCK else
            enb0_bram_block;        
    addrb0 <= addrb0_gol_block when state = GAME_OF_LIFE_BLOCK else
            addrb0_bram_block;
    dob0_gol_block <= dob0;
    dob0_bram_block <= dob0;
--CLK : in std_logic;

    ena1 <= ena1_gol_block when state = GAME_OF_LIFE_BLOCK else
            ena1_bram_block;
    wea1 <= wea1_gol_block when state = GAME_OF_LIFE_BLOCK else
            wea1_bram_block;
    addra1 <= addra1_gol_block when state = GAME_OF_LIFE_BLOCK else
            addra1_bram_block;
            
    dia1 <= dia1_gol_block when state = GAME_OF_LIFE_BLOCK else
            dia1_bram_block;
    enb1 <= enb1_gol_block when state = GAME_OF_LIFE_BLOCK else
            enb1_bram_block;        
    addrb1 <= addrb1_gol_block when state = GAME_OF_LIFE_BLOCK else
            addrb1_bram_block;
    dob1_gol_block <= dob1;
    dob1_bram_block <= dob1;


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
    state <= BRAM_BLOCK;
    work_bram_is <= '0';
    for i in 0 to 1023 loop
        ena0_bram_block <= '1';
        wea0_bram_block <= "1";
        addra0_bram_block <= std_logic_vector(to_unsigned(i, addra0'length));
        dia0_bram_block <= std_logic_vector(to_unsigned(i, dia0'length));
        wait for CLK_PER;
    end loop;
    
    state <= GAME_OF_LIFE_BLOCK;
    
    GOL_block_start <= '1';
    wait for 2*CLK_PER;
    GOL_block_start <= '0';
    

    
    wait until GOL_block_done='1';
    
    state <= BRAM_BLOCK;
    
    for i in 0 to 1023 loop
        enb1_bram_block <= '1';
        addrb1_bram_block <= std_logic_vector(to_unsigned(i, addra1'length));
        wait for 2*CLK_PER;
    end loop;
    
    wait until dob1 = std_logic_vector(to_unsigned(1023, dob1'length));
    wait until rising_edge(CLKxCI);
    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
