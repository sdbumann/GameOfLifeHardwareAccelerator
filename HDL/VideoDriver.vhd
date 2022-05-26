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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VideoDriver is
    generic (
        SYS_DATA_LEN : natural := 32;
        SYS_ADDR_LEN : natural := 32;
        GoL_DATA_LEN : natural := 32; --1024
        GoL_ADDR_LEN : natural := 5; --10
        
        SCREEN_WIDTH : natural := 16; --change!!!! 320
        SCREEN_HEIGHT : natural := 12; --CHANGE!!! 240
        
        WINDOW_DIVISION_FACTOR : natural := 1;
        
        WINDOW_WIDTH : natural := SCREEN_WIDTH/WINDOW_DIVISION_FACTOR;
        WINDOW_HEIGHT : natural := SCREEN_HEIGHT/WINDOW_DIVISION_FACTOR
    );
    Port ( 
        CLK : in std_logic;
        resetn : in std_logic;
        --zoomFact : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        GoLData : in std_logic_vector(GoL_DATA_LEN-1 downto 0);
        windowTop : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        windowLeft : in std_logic_vector(SYS_DATA_LEN-1 downto 0); -- with respect to the 1024 x 1024 grid
        writeReady : in std_logic;
        GoLReady : in std_logic;
        frameBufferAddr : in std_logic_vector(SYS_DATA_LEN-1 downto 0);
        
        writeStart : out std_logic;
        pixelData : out std_logic_vector(SYS_DATA_LEN-1 downto 0);
        pixelAddr : out std_logic_vector(SYS_ADDR_LEN-1 downto 0);
        GoLAddr : out std_logic_vector (GoL_ADDR_LEN-1 downto 0);
        frameDone : out std_logic
    );
end VideoDriver;

architecture rtl of VideoDriver is
    signal windowTopRegulated : unsigned(GoL_ADDR_LEN-1 downto 0);
    signal windowLeftRegulated : unsigned(GoL_ADDR_LEN-1 downto 0);
    
    signal lineCounterP, lineCounterN, colCounterP, colCounterN : unsigned(GoL_ADDR_LEN-1 downto 0);
    
    type STATE is (IDLE, WAIT_BRAM_READ, LOAD_LINE, SAVE_LINE, WRITE_PIXEL);
    signal stateP, stateN : STATE;
    signal GoLLineP, GoLLineN : std_logic_vector(GoL_DATA_LEN-1 downto 0);
    signal GoLAddrP, GoLAddrN : unsigned (GoL_ADDR_LEN-1 downto 0);
    
    
    signal lineCounterPResized : unsigned(SYS_DATA_LEN-1 downto 0);
    
begin
    windowTopRegulated <= to_unsigned(WINDOW_HEIGHT, windowTopRegulated'length) 
                            when unsigned(windowTop) > WINDOW_HEIGHT else
                          unsigned(windowTop(GoL_ADDR_LEN-1 downto 0));
    windowLeftRegulated <= to_unsigned(GoL_DATA_LEN - WINDOW_WIDTH, windowLeftRegulated'length) 
                            when unsigned(windowLeft) > GoL_DATA_LEN - WINDOW_WIDTH else
                          unsigned(windowLeft(GoL_ADDR_LEN-1 downto 0));   
    --lineCounterPResized <=  resize(lineCounterP,frameBufferAddr'length)*to_unsigned(WINDOW_WIDTH,frameBufferAddr'length);                              
    
    pixelAddr <= std_logic_vector(unsigned(frameBufferAddr) + lineCounterP*WINDOW_WIDTH + resize(colCounterP,frameBufferAddr'length));
    GoLAddr <= std_logic_vector(GoLAddrP);
    
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
        case stateP is
            when IDLE => 
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
            when SAVE_LINE =>
                GoLLineN <= GoLData;
                stateN <= WRITE_PIXEL;
            when WRITE_PIXEL =>
                if GoLLineP(to_integer(colCounterP)) = '1' then -- mirrors the board
                    pixelData <= x"FF"&x"FF"&x"FF"&x"00";
                else
                    pixelData <= x"00"&x"FF"&x"00"&x"00";
                end if;
                writeStart <= '1';
                if writeReady = '1' then
                    if  to_integer(colCounterP) = 2 ** colCounterP'length - 1 then
                        colCounterN <= (others => '0');
                        if to_integer(lineCounterP) = 2 ** lineCounterP'length - 1 then
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
end rtl;
