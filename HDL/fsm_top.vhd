----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/26/2022 11:23:38 AM
-- Design Name: 
-- Module Name: fsm_top - rtl
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.constants.all;


entity fsm_top is
    generic (
        -- Parameters of the AXI master bus interface:
        C_M00_AXI_ADDR_WIDTH  : integer := 32;
        C_M00_AXI_DATA_WIDTH  : integer := 32
    );
    Port ( 
        clk, resetn : in std_logic;
       
-- AXI4 signals
    -- master
        master_start : out std_logic;
        master_done : in std_logic; -- assigned to writeReady in video driver 
        master_readWrite : out std_logic;
        master_address : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        master_dataRead : in std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
    -- slave
        -- fsm_top signals        
        accelStart : in std_logic;
        accelDone : out std_logic;
        accelStop : out std_logic;
        -- init Block signals
        GameOfLifeAddress : in std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        -- Video Driver 
        windowTop : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        windowLeft : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        frameBufferAddr : in std_logic_vector(SYS_DATA_LEN-1 downto 0)
    );
end fsm_top;

architecture rtl of fsm_top is

-- fsm_top signals ----------------------------------------
    type TState is (IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, VIDEO_DRIVER_BLOCK, DRAM_BLOCK);
    signal stateP, stateN : TState;
-- bram control signals ----------------------------------------------------
    -- Control signals for bram0
    signal ena0 : std_logic;
    signal wea0 : std_logic;
    signal addra0 : std_logic_vector(9 downto 0);
    signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0 : std_logic;
    signal addrb0 : std_logic_vector(9 downto 0);
    signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- Control signals for bram1
    signal ena1 : std_logic;
    signal wea1 : std_logic;
    signal addra1 : std_logic_vector(9 downto 0);
    signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb1 : std_logic;
    signal addrb1 : std_logic_vector(9 downto 0);
    signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);

-- init_block Signals ------------------------------------------------------
    signal initBlockStart, initBlockDone : std_logic;     
    signal init_row_0, init_row_1, init_row_2 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
   
    -- Control signals for bram0 for init_block
    signal ena0_init_block : std_logic;
    signal wea0_init_block : std_logic;
    signal addra0_init_block : std_logic_vector(9 downto 0);
    signal dia0_init_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0_init_block : std_logic; 
    signal addrb0_init_block : std_logic_vector(9 downto 0);
    signal dob0_init_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
   
    signal init_master_start : std_logic;
    signal init_master_readWrite : std_logic;
    signal init_master_address : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    
    
--  game_of_life_block Signals ----------------------
    signal GoLBlockStart, GoLBlockDone : std_logic;
    signal work_bram_is : std_logic;

    -- Control signals for bram0 for game_of_life_block
    signal ena0_gol_block : std_logic;
    signal wea0_gol_block : std_logic;
    signal addra0_gol_block : std_logic_vector(9 downto 0);
    signal dia0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0_gol_block : std_logic; 
    signal addrb0_gol_block : std_logic_vector(9 downto 0);
    signal dob0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- Control signals for bram1 for game_of_life_block
    signal ena1_gol_block : std_logic;
    signal wea1_gol_block : std_logic;
    signal addra1_gol_block : std_logic_vector(9 downto 0);
    signal dia1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb1_gol_block : std_logic; 
    signal addrb1_gol_block : std_logic_vector(9 downto 0);
    signal dob1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    

 
-- VideoDriver Signals ----------------------------
    signal VideoDriverStart, VideoDriverDone : std_logic;
    signal GoLData : std_logic_vector(GoL_DATA_LEN-1 downto 0);



    signal writeStart : std_logic;
    signal pixelData : std_logic_vector(SYS_DATA_LEN-1 downto 0);
    signal pixelAddr : std_logic_vector(SYS_ADDR_LEN-1 downto 0);
    signal GoLAddr : std_logic_vector (GoL_ADDR_LEN-1 downto 0);
    signal frameDone : std_logic;
    signal bramReadEnable : std_logic;

begin
-- COMPONENT INSTANTIATIONS
init_block_inst : entity work.init_block(rtl)
    port map (
        CLK => clk,
        resetn => resetn,
        --------------------------------------
        -- master
        master_start => init_master_start,
        master_done => master_done,
        master_readWrite => init_master_readWrite,
        master_address => init_master_address,
        master_dataRead => master_dataRead,
        
        -- Control signals for bram0
        ena0 => ena0_init_block,
        wea0 => wea0_init_block,
        addra0 => addra0_init_block,
        dia0 => dia0_init_block,
        
        -- other signals 
        GameOfLifeAddress => GameOfLifeAddress,
        start => initBlockStart,
        done => initBlockDone,
        init_row_0_out => init_row_0,
        init_row_1_out => init_row_1,
        init_row_2_out => init_row_2
    );
    
    bram0_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => clk, ena => ena0, enb => enb0, wea => wea0, addra => addra0, addrb => addrb0, dia => dia0,
      dob => dob0
    );
    
    bram1_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => clk, ena => ena1, enb => enb1, wea => wea1, addra => addra1, addrb => addrb1, dia => dia1,
      dob => dob1
    );
    
    game_of_life_block_inst: entity work.game_of_life_block(rtl)
    port map(CLK => clk, resetn => resetn, 
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
    start  => GoLBlockStart,
    done  => GoLBlockDone,
    init_row_0 => init_row_0, 
    init_row_1 => init_row_1,
    init_row_2 => init_row_2,
    work_bram_is => work_bram_is
    );

    VideoDriverInst : entity work.VideoDriver(rtl)
    port map(
    CLK =>  clk,
    resetn =>  resetn,
    
    GoLData =>  GoLData,
    windowTop =>  windowTop,
    windowLeft =>  windowLeft,
    writeReady =>  master_done,
    GoLReady =>  VideoDriverStart,
    frameBufferAddr => frameBufferAddr,
    
    writeStart =>  writeStart,
    pixelData =>  pixelData,
    pixelAddr =>  pixelAddr,
    GoLAddr =>  GoLAddr,
    frameDone => VideoDriverDone,
    bramReadEnable => bramReadEnable
    );

-- SIGNAL MULTIPLEXING
    -- routing for bram1
    ena1    <=  ena1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                '0';
    wea1    <=  wea1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                '0';
    addra1  <=  addra1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    dia1    <=  dia1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    enb1    <=  enb1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                '0';
    addrb1  <=  addrb1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                (others=>'0');
    dob1_gol_block <= dob1;
                
                
    -- routing for bram0
    ena0    <=  ena0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                ena0_init_block when stateP = INIT_BLOCK else
                '0';
    wea0    <=  wea0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                wea0_init_block when stateP = INIT_BLOCK else
                '0';
    addra0  <=  addra0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addra0_init_block when stateP = INIT_BLOCK else
                (others=>'0');
    dia0    <=  dia0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                dia0_init_block when stateP = INIT_BLOCK else
                (others=>'0');
    enb0    <=  enb0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                enb0_init_block when stateP = INIT_BLOCK else
                '0';
    addrb0  <=  addrb0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addrb0_init_block when stateP = INIT_BLOCK else
                (others=>'0');
    dob0_gol_block <= dob0;
    dob0_init_block <= dob0;

-- REGISTERS
    registers: process(clk,resetn) is
    begin
        if rising_edge(CLK) then
            if resetn = '0' then
                stateP <= IDLE;
            else
                stateP <= stateN;
            end if;
        end if;
    end process;
    
-- FSM_TOP
    fsm_top: process(all) is
    begin --IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, VIDEO_DRIVER_BLOCK, DRAM_BLOCK
        stateN <= stateP;
        initBlockStart <= '0';
        GoLBlockStart <= '0';
        VideoDriverStart <= '0';
        case stateP is
            when IDLE =>
                if accelStart = '1' then
                    stateN <= INIT_BLOCK;
                    initBlockStart <= '1';
                end if;
            when INIT_BLOCK =>
                if initBlockDone = '1' then
                    GoLBlockStart <= '1';
                    stateN <= GAME_OF_LIFE_BLOCK;
                end if;
            when GAME_OF_LIFE_BLOCK =>
                if GoLBlockDone = '1' then
                    VideoDriverStart <= '1';
                    stateN <= VIDEO_DRIVER_BLOCK;
                end if;
        end case;
    end process;
end rtl;
