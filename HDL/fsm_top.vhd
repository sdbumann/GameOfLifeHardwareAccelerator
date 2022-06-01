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
        master_dataWrite : out std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        
    -- slave
        -- fsm_top signals        
        accelStart : in std_logic;
        accelDone : out std_logic;
        accelStop : in std_logic;
        -- init Block signals
        GameOfLifeAddress : in std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        -- Video Driver signals
        windowTop : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        windowLeft : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        frameBufferAddr : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        
    -- ILA debug signals
        fsm_top_state : out std_logic_vector(2 downto 0);
        count_line_save_dram : out unsigned(NUM_INST_NUM_BITS-1 downto 0);
        count_row_save_dram : out unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0)
    );
end fsm_top;

architecture rtl of fsm_top is

-- fsm_top signals ----------------------------------------
    type TState is (IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, VIDEO_DRIVER_BLOCK, SAVE_DRAM_BLOCK);
    signal stateP, stateN : TState;
    
    signal workMemP, workMemN : std_logic;
-- bram control signals ----------------------------------------------------
    -- Control signals for bram0
    signal ena0 : std_logic;
    signal wea0 : std_logic_vector(0 downto 0);
    signal addra0 : std_logic_vector(9 downto 0);
    signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0 : std_logic;
    signal addrb0 : std_logic_vector(9 downto 0);
    signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- Control signals for bram1
    signal ena1 : std_logic;
    signal wea1 : std_logic_vector(0 downto 0);
    signal addra1 : std_logic_vector(9 downto 0);
    signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb1 : std_logic;
    signal addrb1 : std_logic_vector(9 downto 0);
    signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
-- init_block & game_of_life_block signals
    signal init_row_0, init_row_1, init_row_2 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
-- game_of_life_block, video driver & save_dram_block signals
    signal work_bram_is : std_logic;

-- init_block Signals ------------------------------------------------------
    signal initBlockStart, initBlockDone : std_logic;   
    
    -- master 
    signal master_start_init_block :  std_logic;
    signal master_address_init_block :  std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    signal master_readWrite_init_block :  std_logic;  
   
    -- Control signals for bram0 for init_block
    signal ena0_init_block : std_logic;
    signal wea0_init_block : std_logic;
    signal addra0_init_block : std_logic_vector(9 downto 0);
    signal dia0_init_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);

    
    
--  game_of_life_block Signals ----------------------
    signal GoLBlockStart, GoLBlockDone : std_logic;

    -- Control signals for bram0 for game_of_life_block
    signal ena0_gol_block : std_logic;
    signal wea0_gol_block : std_logic;
    signal addra0_gol_block : std_logic_vector(9 downto 0);
    signal dia0_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0_gol_block : std_logic; 
    signal addrb0_gol_block : std_logic_vector(9 downto 0);
    
    -- Control signals for bram1 for game_of_life_block
    signal ena1_gol_block : std_logic;
    signal wea1_gol_block : std_logic;
    signal addra1_gol_block : std_logic_vector(9 downto 0);
    signal dia1_gol_block : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb1_gol_block : std_logic; 
    signal addrb1_gol_block : std_logic_vector(9 downto 0);
    

 
-- VideoDriver Signals ----------------------------
    signal VideoDriverStart, VideoDriverDone : std_logic;
    

    
    signal master_start_video_driver_block :  std_logic;
    signal master_address_video_driver_block :  std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    signal master_dataWrite_video_driver_block :  std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    signal master_readWrite_video_driver_block :  std_logic;

    
    signal enb0_video_driver_block : std_logic;
    signal addrb0_video_driver_block : std_logic_vector(9 downto 0);
    
    -- Control signals for bram1

    signal enb1_video_driver_block : std_logic;
    signal addrb1_video_driver_block : std_logic_vector(9 downto 0);

   
-- save_dram_block signals
    signal SaveDramStart, SaveDramDone : std_logic;
    -- master signals
    signal master_start_save_dram_block :  std_logic;
    signal master_address_save_dram_block :  std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    signal master_dataWrite_save_dram_block :  std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    signal master_readWrite_save_dram_block :  std_logic;
    
    -- Control signals for bram0
    signal ena0_save_dram_block :  std_logic;
    signal wea0_save_dram_block :  std_logic;
    signal addra0_save_dram_block :  std_logic_vector(9 downto 0);
    signal dia0_save_dram_block :  std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb0_save_dram_block :  std_logic;
    signal addrb0_save_dram_block :  std_logic_vector(9 downto 0);
    
    -- Control signals for bram1
    signal ena1_save_dram_block :  std_logic;
    signal wea1_save_dram_block :  std_logic;
    signal addra1_save_dram_block :  std_logic_vector(9 downto 0);
    signal dia1_save_dram_block :  std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    signal enb1_save_dram_block :  std_logic;
    signal addrb1_save_dram_block :  std_logic_vector(9 downto 0);
    
-- bram
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
   
begin
-- COMPONENT INSTANTIATIONS
init_block_inst : entity work.init_block(rtl)
    port map (
        CLK => clk,
        resetn => resetn,
        --------------------------------------
        -- master
        master_start => master_start_init_block,
        master_done => master_done,
        master_readWrite => master_readWrite_init_block,
        master_address => master_address_init_block,
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
    
--      PORT (
--    clka : IN STD_LOGIC;
--    ena : IN STD_LOGIC;
--    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
--    addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--    dina : IN STD_LOGIC_VECTOR(1023 DOWNTO 0);
--    clkb : IN STD_LOGIC;
--    enb : IN STD_LOGIC;
--    addrb : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
--    doutb : OUT STD_LOGIC_VECTOR(1023 DOWNTO 0)
--  );

    bram0_inst : blk_mem_gen_0
    PORT MAP (
        clka => clk,
        ena => ena0,
        wea => wea0,
        addra => addra0,
        dina => dia0,
        clkb => clk,
        enb => enb0,
        addrb => addrb0,
        doutb => dob0
    );
    
    bram1_inst : blk_mem_gen_0
    PORT MAP (
        clka => clk,
        ena => ena1,
        wea => wea1,
        addra => addra1,
        dina => dia1,
        clkb => clk,
        enb => enb1,
        addrb => addrb1,
        doutb => dob1
    );
    
    game_of_life_block_inst: entity work.game_of_life_block(rtl)
    port map(CLK => clk, resetn => resetn, 
    ena0 => ena0_gol_block, 
    wea0 => wea0_gol_block, 
    addra0 => addra0_gol_block,
    dia0  => dia0_gol_block,
    enb0  => enb0_gol_block,
    addrb0  => addrb0_gol_block,
    dob0  => dob0,
    
    -- Control signals for bram1
    ena1  => ena1_gol_block,
    wea1  => wea1_gol_block,
    addra1  => addra1_gol_block,
    dia1  => dia1_gol_block,
    enb1  => enb1_gol_block,
    addrb1  => addrb1_gol_block,
    dob1  => dob1,
    
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

    windowTop =>  windowTop,
    windowLeft =>  windowLeft,
    
    GoLReady =>  VideoDriverStart,
    frameBufferAddr => frameBufferAddr,
    
    master_start => master_start_video_driver_block,
    master_done => master_done,
    master_address => master_address_video_driver_block,
    master_dataWrite => master_dataWrite_video_driver_block,
    master_readWrite => master_readWrite_video_driver_block,
    
    frameDone => VideoDriverDone,
    
    enb0 => enb0_video_driver_block,
    addrb0 => addrb0_video_driver_block,
    dob0 => dob0,


    enb1 => enb1_video_driver_block,
    addrb1 => addrb1_video_driver_block,
    dob1 => dob1,

    work_bram_is => work_bram_is
    );
    
    save_dram_inst : entity work.save_dram_block(rtl)
    port map(
    CLK =>  clk,
    resetn =>  resetn,
    
    -- master signals
    master_start => master_start_save_dram_block,
    master_done =>master_done,
    master_address => master_address_save_dram_block,
    master_dataWrite => master_dataWrite_save_dram_block,
    master_readWrite => master_readWrite_save_dram_block,
    
    -- Control signals for bram0
    ena0 => ena0_save_dram_block,
    wea0 => wea0_save_dram_block,
    addra0 => addra0_save_dram_block,
    dia0 => dia0_save_dram_block,
    enb0 => enb0_save_dram_block,
    addrb0 => addrb0_save_dram_block,
    dob0 => dob0,
    
    -- Control signals for bram1
    ena1 => ena1_save_dram_block,
    wea1 => wea1_save_dram_block,
    addra1 => addra1_save_dram_block,
    dia1 => dia1_save_dram_block,
    enb1 => enb1_save_dram_block,
    addrb1 => addrb1_save_dram_block,
    dob1 => dob1,
    
    -- other signals 
    start => SaveDramStart,
    done => SaveDramDone,
    GameOfLifeAddress => GameOfLifeAddress,
    work_bram_is => work_bram_is,
    
    count_line_save_dram => count_line_save_dram,
    count_row_save_dram => count_row_save_dram
    );
    
--======================================================
-- SIGNAL MULTIPLEXING
--======================================================
    -- routing for bram1
    ena1    <=  ena1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                ena1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                '0';
    wea1(0) <=  wea1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                wea1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                '0';
    addra1  <=  addra1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addra1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                (others=>'0');
    dia1    <=  dia1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                dia1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                (others=>'0');
    enb1    <=  enb1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                enb1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                enb1_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                '0';
    addrb1  <=  addrb1_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addrb1_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                addrb1_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                (others=>'0');
                
                
    -- routing for bram0
    ena0    <=  ena0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                ena0_init_block when stateP = INIT_BLOCK else
                ena0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                '0';
    wea0(0) <=  wea0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                wea0_init_block when stateP = INIT_BLOCK else
                wea0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                '0';
    addra0  <=  addra0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addra0_init_block when stateP = INIT_BLOCK else
                addra0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                (others=>'0');
    dia0    <=  dia0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                dia0_init_block when stateP = INIT_BLOCK else
                dia0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                (others=>'0');
    enb0    <=  enb0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                enb0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                enb0_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                '0';
    addrb0  <=  addrb0_gol_block when stateP = GAME_OF_LIFE_BLOCK else
                addrb0_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                addrb0_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                (others=>'0');
    
    -- routing for AXI master signals
    master_start <= master_start_init_block when stateP = INIT_BLOCK else
                    master_start_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                    master_start_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                    '0';
    master_readWrite <= master_readWrite_init_block when stateP = INIT_BLOCK else
                        master_readWrite_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                        master_readWrite_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                        '0';
    master_address   <= master_address_init_block when stateP = INIT_BLOCK else
                        master_address_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                        master_address_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                        (others=> '0');  
    master_dataWrite <= master_dataWrite_video_driver_block when stateP = VIDEO_DRIVER_BLOCK else
                        master_dataWrite_save_dram_block when stateP = SAVE_DRAM_BLOCK else
                        (others=> '0');                                        

-- REGISTERS
    registers: process(clk,resetn) is
    begin
        if rising_edge(CLK) then
            if resetn = '0' then
                stateP <= IDLE;
                workMemP <= '0';
            else
                stateP <= stateN;
                workMemP <= workMemN;
            end if;
        end if;
    end process;
    
    work_bram_is <= workMemP;
    
-- FSM_TOP
--    fsm_top: process(all) is
--    begin --IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, VIDEO_DRIVER_BLOCK, DRAM_BLOCK
--        stateN <= stateP;
--        workMemN <= workMemP;
--        initBlockStart <= '0';
--        GoLBlockStart <= '0';
--        VideoDriverStart <= '0';
--        SaveDramStart <= '0';
--        accelDone <= '0';
--        case stateP is
--            when IDLE =>
--                accelDone <= '1';
--                if accelStart = '1' then
--                    stateN <= INIT_BLOCK;
--                    initBlockStart <= '1';
--                end if;
--            when INIT_BLOCK =>
--                if initBlockDone = '1' then
--                    GoLBlockStart <= '1';
--                    stateN <= GAME_OF_LIFE_BLOCK;
--                    workMemN <= '0';
--                end if;
--            when GAME_OF_LIFE_BLOCK =>
--                if GoLBlockDone = '1' then
--                    VideoDriverStart <= '1';
--                    stateN <= VIDEO_DRIVER_BLOCK;
--                end if;
--            when VIDEO_DRIVER_BLOCK =>
--                if VideoDriverDone = '1' then
--                    if accelStop = '1' then
--                        SaveDramStart <= '1';
--                        stateN <= SAVE_DRAM_BLOCK;
--                    elsif accelStart = '1' then
--                        stateN <= GAME_OF_LIFE_BLOCK;
--                        GoLBlockStart <= '1';
--                        workMemN <= '1' when workMemP = '0' else '0';
--                    else
--                        stateN <= IDLE;
--                    end if;
--                end if;
--            when SAVE_DRAM_BLOCK =>
--                if SaveDramDone = '1' then
--                    stateN <= IDLE;
--                end if;
--            when OTHERS =>
--                stateN <= IDLE;
--        end case;
--    end process;
    
    
    fsm_top: process(all) is
    begin --IDLE, INIT_BLOCK, GAME_OF_LIFE_BLOCK, VIDEO_DRIVER_BLOCK, DRAM_BLOCK
        stateN <= stateP;
        workMemN <= workMemP;
        initBlockStart <= '0';
        GoLBlockStart <= '0';
        VideoDriverStart <= '0';
        SaveDramStart <= '0';
        accelDone <= '0';
        case stateP is
            when IDLE =>
                accelDone <= '1';
                if accelStart = '1' then
                    stateN <= INIT_BLOCK;
                    initBlockStart <= '1';
                end if;
            when INIT_BLOCK =>
                if initBlockDone = '1' then
                    GoLBlockStart <= '1';
                    stateN <= GAME_OF_LIFE_BLOCK;
                    workMemN <= '0';
                end if;
            when GAME_OF_LIFE_BLOCK =>
                if GoLBlockDone = '1' then
                    SaveDramStart <= '1';
                    stateN <= SAVE_DRAM_BLOCK;
                end if;
           when SAVE_DRAM_BLOCK =>
                if SaveDramDone = '1' then
                    stateN <= IDLE;
                end if;
            when OTHERS =>
                stateN <= IDLE;
        end case;
    end process;
    
    fsm_top_state <= "010" when stateP = INIT_BLOCK else
                     "011" when stateP = GAME_OF_LIFE_BLOCK else
                     "100" when stateP = VIDEO_DRIVER_BLOCK else
                     "101" when stateP = SAVE_DRAM_BLOCK else
                     "001" when stateP = IDLE else
                     "000";
end rtl;
