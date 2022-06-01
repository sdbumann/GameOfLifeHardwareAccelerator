----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/11/2022 11:57:00 AM
-- Design Name: 
-- Module Name: VideoDriver - rtl
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

entity VideoDriver is
    generic (
        -- Parameters of the AXI master bus interface:
        C_M00_AXI_ADDR_WIDTH  : integer := 32;
        C_M00_AXI_DATA_WIDTH  : integer := 32
    );
    Port ( 
        CLK : in std_logic;
        resetn : in std_logic;
        --zoomFact : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        windowTop : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        windowLeft : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        
        GoLReady : in std_logic;
        frameBufferAddr : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        
        
        frameDone : out std_logic;
        
        master_start : out std_logic;
        master_done : in std_logic;
        master_address : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
        master_dataWrite : out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
        master_readWrite : out std_logic;
            
        
        -- Control signals for bram0
        enb0 : out std_logic;
        addrb0 : out std_logic_vector(9 downto 0);
        dob0 : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        
        -- Control signals for bram1

        enb1 : out std_logic;
        addrb1 : out std_logic_vector(9 downto 0);
        dob1 : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);

        work_bram_is : in std_logic;
        
        --ILA signals
        colCounter_video_driver : out unsigned(GoL_ADDR_LEN-1 downto 0);
        lineCounter_video_driver : out unsigned(GoL_ADDR_LEN-1 downto 0)
    );
end VideoDriver;

architecture rtl of VideoDriver is
    signal windowTopRegulated : unsigned(GoL_ADDR_LEN-1 downto 0);
    signal windowLeftRegulated : unsigned(GoL_ADDR_LEN-1 downto 0);
    
    signal lineCounterP, lineCounterN, colCounterP, colCounterN : unsigned(GoL_ADDR_LEN-1 downto 0);
    
    type STATE is (IDLE, WAIT_BRAM_READ, LOAD_LINE, SAVE_LINE, WRITE_PIXEL_WAIT, WRITE_PIXEL);
    signal stateP, stateN : STATE;
    signal GoLLineP, GoLLineN : std_logic_vector(GoL_DATA_LEN-1 downto 0);
    signal GoLAddrP, GoLAddrN : unsigned (GoL_ADDR_LEN-1 downto 0);
    
    signal GoLData :  std_logic_vector(GoL_DATA_LEN-1 downto 0);
    signal bramReadEnable : std_logic;
    
    signal writeReady : std_logic;
    signal writeStart :  std_logic;
    signal pixelData :  std_logic_vector(SYS_DATA_LEN-1 downto 0);
    signal pixelAddr :  std_logic_vector(SYS_ADDR_LEN-1 downto 0);
    
begin
    windowTopRegulated <= to_unsigned(WINDOW_HEIGHT, windowTopRegulated'length) 
                            when unsigned(windowTop) > WINDOW_HEIGHT else
                          unsigned(windowTop(GoL_ADDR_LEN-1 downto 0));
    windowLeftRegulated <= to_unsigned(GoL_DATA_LEN - WINDOW_WIDTH, windowLeftRegulated'length) 
                            when unsigned(windowLeft) > GoL_DATA_LEN - WINDOW_WIDTH else
                          unsigned(windowLeft(GoL_ADDR_LEN-1 downto 0));   

    pixelAddr <= std_logic_vector(unsigned(frameBufferAddr) + shift_left("00000"&(lineCounterP*WINDOW_WIDTH + colCounterP),2));
    
    writeReady <= master_done;
    master_start <= writeStart;
    master_address <= pixelAddr;
    master_dataWrite <= pixelData;
    master_readWrite <= '1'; -- the video driver always writes
    
    bram_multiplexing: process(all)
    begin
        enb0 <= '0';
        addrb0 <= (others => '0');
        enb1 <= '0';
        addrb1 <= (others => '0');
        if work_bram_is = '0' then 
            enb1 <= bramReadEnable;
            addrb1 <= std_logic_vector(GoLAddrP);
            GoLData <= dob1;
        else
            enb0 <= bramReadEnable;
            addrb0 <= std_logic_vector(GoLAddrP);
            GoLData <= dob0;
        end if;
    end process;
    
    registers: process (CLK,resetn)
    begin
        if rising_edge(CLK) then
            if resetn = '0' then
                lineCounterP <= (OTHERS => '0');
                colCounterP <= (OTHERS => '0');
                stateP <= IDLE;
                GoLLineP <= (OTHERS => '0');
                GoLAddrP <= (OTHERS => '0');
            else
                lineCounterP <= lineCounterN;
                colCounterP <= colCounterN;
                stateP <= stateN;
                GoLLineP <= GoLLineN;
                GoLAddrP <= GoLAddrN;
            end if;
        end if;
    end process;
    
    process(all)
    begin
        stateN <= stateP;
        lineCounterN <= lineCounterP;
        colCounterN <= colCounterP;
        GoLLineN <= GoLLineP;
        GoLAddrN <= GoLAddrP;
        pixelData <= (others => '0');
        writeStart <= '0';
        frameDone <= '0';
        bramReadEnable <= '0';
        case stateP is
            when IDLE => 
                lineCounterN <= (others => '0');
                colCounterN <= (others => '0');
                frameDone <= '1';
                if GoLReady = '1' then
                    GolAddrN <= windowTopRegulated;
                    stateN <= WAIT_BRAM_READ;
                end if;
            when LOAD_LINE => 
                GolAddrN <= windowTopRegulated + lineCounterP;
                stateN <= WAIT_BRAM_READ;
            when WAIT_BRAM_READ =>
                stateN <= SAVE_LINE;
                bramReadEnable <= '1';
            when SAVE_LINE =>
                GoLLineN <= GoLData;
                bramReadEnable <= '1';
                stateN <= WRITE_PIXEL_WAIT;
            when WRITE_PIXEL_WAIT =>
                if GoLLineP(to_integer(windowLeftRegulated + colCounterP)) = '0' then -- mirrors the board
                    pixelData <= x"00"&x"FF"&x"FF"&x"FF";
                else
                    pixelData <= x"00"&x"FF"&x"00"&x"FF";
                end if;
                writeStart <= '1';
                stateN <= WRITE_PIXEL;            
            when WRITE_PIXEL =>
                if GoLLineP(to_integer(windowLeftRegulated + colCounterP)) = '0' then -- mirrors the board
                    pixelData <= x"00"&x"FF"&x"FF"&x"FF";
                else
                    pixelData <= x"00"&x"FF"&x"00"&x"FF";
                end if;
                writeStart <= '1';
                if writeReady = '1' then
                    if  to_integer(colCounterP) = WINDOW_WIDTH - 1 then
                        colCounterN <= (others => '0');
                        if to_integer(lineCounterP) = WINDOW_HEIGHT - 1 then
                            lineCounterN <= (others => '0');
                            stateN <= IDLE;
                        else
                            lineCounterN <= lineCounterP + 1;
                            stateN <= LOAD_LINE;
                        end if;
                    else colCounterN <= colCounterP + 1;
                    end if;
                end if;
            when OTHERS =>
                stateN <= IDLE;
        end case;
    end process;
    
    --ILA
    colCounter_video_driver <= colCounterP;
    lineCounter_video_driver <= lineCounterP;
end rtl;
