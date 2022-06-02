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
entity save_dram_block_tb is
end save_dram_block_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of save_dram_block_tb is
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
        -- master signals 
        signal master_start : std_logic;
        signal master_done : std_logic;
        signal master_readWrite : std_logic;
        signal master_address : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal master_dataRead : std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        signal master_dataWrite : std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
        
     
        -- master signals for save_dram_block
        signal master_start_save_dram_block : std_logic;
        signal master_done_save_dram_block : std_logic;
        signal master_readWrite_save_dram_block : std_logic;
        signal master_address_save_dram_block : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        signal master_dataWrite_save_dram_block : std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        signal master_dataRead_save_dram_block : std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
        -- Control signals for bram0
        signal ena0 : std_logic;
        signal wea0 : std_logic_vector(0 downto 0);
        signal addra0 : std_logic_vector(9 downto 0);
        signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0 : std_logic; 
        signal addrb0 : std_logic_vector(9 downto 0);
        signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
       
        -- Control signals for bram0 for sace_dram_block
        signal ena0_save_dram_block : std_logic;
        signal wea0_save_dram_block : std_logic;
        signal addra0_save_dram_block : std_logic_vector(9 downto 0);
        signal dia0_save_dram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb0_save_dram_block : std_logic; 
        signal addrb0_save_dram_block : std_logic_vector(9 downto 0);
        signal dob0_save_dram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
               
        -- Control signals for bram0
        signal ena1 : std_logic;
        signal wea1 : std_logic_vector(0 downto 0);
        signal addra1 : std_logic_vector(9 downto 0);
        signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1 : std_logic; 
        signal addrb1 : std_logic_vector(9 downto 0);
        signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram1 for save_dram_block
        signal ena1_save_dram_block : std_logic;
        signal wea1_save_dram_block : std_logic;
        signal addra1_save_dram_block : std_logic_vector(9 downto 0);
        signal dia1_save_dram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        signal enb1_save_dram_block : std_logic; 
        signal addrb1_save_dram_block : std_logic_vector(9 downto 0);
        signal dob1_save_dram_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        
        -- other signals 
        signal GameOfLifeAddress : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
   
        signal save_dram_block_start :  std_logic;
        signal save_dram_block_done : std_logic;
--        signal GOL_block_start :  std_logic;
--        signal GOL_block_done : std_logic;
      
        signal work_bram_is : std_logic := '0';
     
        
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
        
     
        type TState is (BRAM_BLOCK, DRAM_BLOCK);
        signal rState, nrState : TState;
        
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
          signal master_data : in std_logic_vector(32-1 downto 0);
          signal master_start : in std_logic;
          signal master_done : out std_logic
          ) is
        begin
            wait until master_start = '1';
            wait for CLK_PER;
            master_done <= '0';
            --master_data <= std_logic_vector(shift_right(unsigned(master_address),2));
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            wait for CLK_PER;
            master_done <= '1';
--            wait for CLK_PER;
--            master_done <= '0';
            
        end WriteValue;
        
        
        procedure ReadValue(
          signal master_address : in std_logic_vector(32-1 downto 0);
          signal master_data : out std_logic_vector(32-1 downto 0);
          signal master_start : in std_logic;
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
            
        end ReadValue;

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
--        master_start => master_start_init_block,
--        master_done => master_done_init_block,
--        master_readWrite => master_readWrite_init_block,
--        master_address => master_address_init_block,
--        master_dataRead => master_dataRead_init_block,
        
--        -- Control signals for bram0
--        ena0 => ena0_init_block,
--        wea0 => wea0_init_block,
--        addra0 => addra0_init_block,
--        dia0 => dia0_init_block,
        
--        -- other signals 
--        GameOfLifeAddress => GameOfLifeAddress,
--        start => init_start,
--        done => init_done
--    );
    
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
    
--    bram0_inst : entity work.simple_dual_one_clock(syn)
--    port map(clk => CLKxCI, ena => ena0, enb => enb0, wea => wea0, addra => addra0, addrb => addrb0, dia => dia0,
--      dob => dob0
--    );
    
--    bram1_inst : entity work.simple_dual_one_clock(syn)
--    port map(clk => CLKxCI, ena => ena1, enb => enb1, wea => wea1, addra => addra1, addrb => addrb1, dia => dia1,
--      dob => dob1
--    );
    
    
    save_dram_block_inst: entity work.save_dram_block(rtl)
    port map(CLK => CLKxCI, resetn => RSTxRBI, 
    
    master_start => master_start_save_dram_block,
    master_done => master_done_save_dram_block,
    master_address => master_address_save_dram_block,
    master_dataWrite => master_dataWrite_save_dram_block,
    
    
    ena0 => ena0_save_dram_block, 
    wea0 => wea0_save_dram_block, 
    addra0 => addra0_save_dram_block,
    dia0  => dia0_save_dram_block,
    enb0  => enb0_save_dram_block,
    addrb0  => addrb0_save_dram_block,
    dob0  => dob0_save_dram_block,
    
    -- Control signals for bram1
    ena1  => ena1_save_dram_block,
    wea1  => wea1_save_dram_block,
    addra1  => addra1_save_dram_block,
    dia1  => dia1_save_dram_block,
    enb1  => enb1_save_dram_block,
    addrb1  => addrb1_save_dram_block,
    dob1  => dob1_save_dram_block,
    
    -- other signals 
    start  => save_dram_block_start,
    done  => save_dram_block_done,
    GameOfLifeAddress => GameOfLifeAddress,
    work_bram_is => work_bram_is
    );
    
    

--=============================================================================
-- Logic for rauting of bram signals
--=============================================================================
    -- routing for bram1
--    ena1    <=  ena1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                ena1_init_block when rState = INIT_BLOCK else
--                '0';
--    wea1(0)    <=  wea1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                wea1_init_block when rState = INIT_BLOCK else
--                '0';
--    addra1  <=  addra1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                addra1_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    dia1    <=  dia1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                dia1_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    enb1    <=  enb1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                enb1_init_block when rState = INIT_BLOCK else
--                '0';
--    addrb1  <=  addrb1_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                addrb1_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    dob1_save_dram_block <= dob1;
--    dob1_init_block <= dob1;
                
                
--    -- routing for bram0
--    ena0    <=  ena0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                ena0_init_block when rState = INIT_BLOCK else
--                '0';
--    wea0(0)    <=  wea0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                wea0_init_block when rState = INIT_BLOCK else
--                '0';
--    addra0  <=  addra0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                addra0_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    dia0    <=  dia0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                dia0_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    enb0    <=  enb0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                enb0_init_block when rState = INIT_BLOCK else
--                '0';
--    addrb0  <=  addrb0_save_dram_block when rState = SAVE_DRAM_BLOCK else
--                addrb0_init_block when rState = INIT_BLOCK else
--                (others=>'0');
--    dob0_save_dram_block <= dob0;
--    dob0_init_block <= dob0;

  --  routing for master signals
    master_start <=     master_start_save_dram_block ;
    master_readWrite <= master_readWrite_save_dram_block;
    master_address <=   master_address_save_dram_block;
    master_dataWrite <= master_dataWrite_save_dram_block;
    master_dataRead_save_dram_block <= master_dataRead;
    --master_done_save_dram_block <= master_done;
   
    
    
    ena0 <= ena0_save_dram_block when rState = DRAM_BLOCK else
            ena0_bram_block;
    wea0(0) <= wea0_save_dram_block when rState = DRAM_BLOCK else
            wea0_bram_block(0);
    addra0 <= addra0_save_dram_block when rState = DRAM_BLOCK else
            addra0_bram_block;
            
    dia0 <= dia0_save_dram_block when rState = DRAM_BLOCK else
            dia0_bram_block;
    enb0 <= enb0_save_dram_block when rState = DRAM_BLOCK else
            enb0_bram_block;        
    addrb0 <= addrb0_save_dram_block when rState = DRAM_BLOCK else
            addrb0_bram_block;
    dob0_save_dram_block <= dob0;
    dob0_bram_block <= dob0;
--CLK : in std_logic;

    ena1 <= ena1_save_dram_block when rState = DRAM_BLOCK else
            ena1_bram_block;
    wea1(0) <= wea1_save_dram_block when rState = DRAM_BLOCK else
            wea1_bram_block(0);
    addra1 <= addra1_save_dram_block when rState = DRAM_BLOCK else
            addra1_bram_block;
            
    dia1 <= dia1_save_dram_block when rState = DRAM_BLOCK else
            dia1_bram_block;
    enb1 <= enb1_save_dram_block when rState = DRAM_BLOCK else
            enb1_bram_block;        
    addrb1 <= addrb1_save_dram_block when rState = DRAM_BLOCK else
            addrb1_bram_block;
    dob1_save_dram_block <= dob1;
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

    -- initialize bram
    rState <= BRAM_BLOCK;

--    master_done<='1';
--    -- fill working memory
--    wait for CLK_PER;
--    GameOfLifeAddress <= std_logic_vector(to_unsigned(0,GameOfLifeAddress'length));
--    init_start <= '1';
----    wait for CLK_PER;
----    start <= '0';
--    for i in 0 to CHECKERBOARD_SIZE*CHECKERBOARD_SIZE/32-1 loop
--        ReadValue(master_address, master_dataRead, master_start, master_done);
--    end loop;
--    init_start <= '0';
--    wait until init_done='1';
--    wait until rising_edge(CLKxCI);
--    init_start <= '0';
    for i in 0 to 1023 loop
        ena0_bram_block <= '1';
        wea0_bram_block <= "1";
        addra0_bram_block <= std_logic_vector(to_unsigned(i, addra0'length));
        
        dia0_bram_block <= x"1234567890aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa124654aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa634f23aaaa" when 
        (i mod 2 = 0) else
                           x"5555555555555234564575555555555555555555555523534634655555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555555553453453456435663";
        
        wait for CLK_PER;
    end loop;

    




    --test save_dram_block
    rState <= DRAM_BLOCK; -- this signal is there for the routing of the bram signals
    GameOfLifeAddress <= (others => '0');
    master_done_save_dram_block <= '1';

    work_bram_is <= '1';--we write content from bram0 to dram
    save_dram_block_start <= '1';
    
    
    
    for i in 0 to CHECKERBOARD_SIZE*CHECKERBOARD_SIZE/32-1 loop
        WriteValue(master_address_save_dram_block, master_dataWrite_save_dram_block, master_start_save_dram_block, master_done_save_dram_block);
    end loop;
    
    
    wait until save_dram_block_done='1';
    wait for 3*CLK_PER;
    wait until rising_edge(CLKxCI);
    stop(0);

  end process;
end tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
