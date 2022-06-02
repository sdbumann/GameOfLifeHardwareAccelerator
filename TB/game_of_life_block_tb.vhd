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
entity game_of_life_block_tb is
end game_of_life_block_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of game_of_life_block_tb is
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
        signal addrb0 : std_logic_vector(9 downto 0);
        signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram0 for init_block
        signal ena0_init_block : std_logic;
        signal wea0_init_block : std_logic;
        signal addra0_init_block : std_logic_vector(9 downto 0);
        signal dia0_init_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0_init_block : std_logic; 
        signal addrb0_init_block : std_logic_vector(9 downto 0);
        signal dob0_init_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram0 for game_of_life_block
        signal ena0_gol_block : std_logic;
        signal wea0_gol_block : std_logic;
        signal addra0_gol_block : std_logic_vector(9 downto 0);
        signal dia0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0_gol_block : std_logic; 
        signal addrb0_gol_block : std_logic_vector(9 downto 0);
        signal dob0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram0
        signal ena1 : std_logic;
        signal wea1 : std_logic;
        signal addra1 : std_logic_vector(9 downto 0);
        signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1 : std_logic; 
        signal addrb1 : std_logic_vector(9 downto 0);
        signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram1 for game_of_life_block
        signal ena1_gol_block : std_logic;
        signal wea1_gol_block : std_logic;
        signal addra1_gol_block : std_logic_vector(9 downto 0);
        signal dia1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1_gol_block : std_logic; 
        signal addrb1_gol_block : std_logic_vector(9 downto 0);
        signal dob1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- other signals 
        signal GameOfLifeAddress : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal init_start :  std_logic;
        signal init_done : std_logic;
        signal GOL_block_start :  std_logic;
        signal GOL_block_done : std_logic;
        signal work_bram_is : std_logic := '0';
     
        type TState is (IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, SEND_TO_FRAME_BUFFER, SEND_TO_DAAM);
        signal rState, nrState : TState;
        
        signal tb_master_data_ok : std_logic;
        
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
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin


-- Memory reader/writer (master)
  init_block_inst : entity work.init_block(rtl)
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
        ena0 => ena0_init_block,
        wea0 => wea0_init_block,
        addra0 => addra0_init_block,
        dia0 => dia0_init_block,
        
        -- other signals 
        GameOfLifeAddress => GameOfLifeAddress,
        start => init_start,
        done => init_done
    );
    
    bram0_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => CLKxCI, ena => ena0, enb => enb0, wea => wea0, addra => addra0, addrb => addrb0, dia => dia0,
      dob => dob0
    );
    
    bram1_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => CLKxCI, ena => ena1, enb => enb1, wea => wea1, addra => addra1, addrb => addrb1, dia => dia1,
      dob => dob1
    );
    
    game_of_life_block_inst: entity work.game_of_life_block(rtl)
    port map(CLK => CLKxCI, resetn => RSTxRBI, 
    ena0 => ena0_gol_block, 
    wea0 => wea0_gol_block, 
    addra0 => addra0_gol_block,
    dia0  => dia0_gol_block,
    enb0  => enb0_gol_block,
    addrb0  => addrb0_gol_block,
    dob0  => dob0_gol_block,
    
    -- Control signals for bram1
    ena1  => ena1_gol_block,
    wea1  => wea1_gol_block,
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
    

--=============================================================================
-- Logic for rauting of bram signals
--=============================================================================
    -- routing for bram1
    ena1    <=  ena1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                '0';
    wea1    <=  wea1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                '0';
    addra1  <=  addra1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    dia1    <=  dia1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    enb1    <=  enb1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                '0';
    addrb1  <=  addrb1_gol_block when rState = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    dob1_gol_block <= dob1;
                
                
    -- routing for bram0
    ena0    <=  ena0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                ena0_init_block when rState = INIT_BLOCK else
                '0';
    wea0    <=  wea0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                wea0_init_block when rState = INIT_BLOCK else
                '0';
    addra0  <=  addra0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                addra0_init_block when rState = INIT_BLOCK else
                (others=>'0');
    dia0    <=  dia0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                dia0_init_block when rState = INIT_BLOCK else
                (others=>'0');
    enb0    <=  enb0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                enb0_init_block when rState = INIT_BLOCK else
                '0';
    addrb0  <=  addrb0_gol_block when rState = GAME_OF_LIFE_BLOCK else
                addrb0_init_block when rState = INIT_BLOCK else
                (others=>'0');
    dob0_gol_block <= dob0;
    dob0_init_block <= dob0;



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
    wait for CLK_PER;
    wait for CLK_PER;
    wait for CLK_PER;
    wait for CLK_PER;


    -- fill working memory
    rState <= INIT_BLOCK; -- this signal is there for the routing of the bram signals
    wait for CLK_PER;
    GameOfLifeAddress <= std_logic_vector(to_unsigned(0,GameOfLifeAddress'length));
    init_start <= '1';
--    wait for CLK_PER;
--    init_start <= '0';
    for i in 0 to CHECKERBOARD_SIZE*CHECKERBOARD_SIZE/32-1 loop
        WriteValue(master_address, master_dataRead, master_start, master_done);
    end loop;
    wait until init_done='1';
    wait until rising_edge(CLKxCI);

    --test game_of_life_block
    rState <= GAME_OF_LIFE_BLOCK; -- this signal is there for the routing of the bram signals
    wait for CLK_PER;
    work_bram_is <= '0';
    GOL_block_start <= '1';
    wait for CLK_per;
    GOL_block_start <= '0';
    
    wait until GOL_block_done='1';
    wait until rising_edge(CLKxCI);
    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
