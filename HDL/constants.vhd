library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package constants is

    -- general
    constant CHECKERBOARD_SIZE : natural := 1024;
    constant CHECKERBOARD_SIZE_NUM_BITS : natural := 10;
    constant WORD_LENGTH : natural := 32;
    constant WORD_NUM_BITS : natural := 5;
    
    --game of life
    constant SUM_NEIGHBOR_NUM_BITS : natural := 4;
    constant LINE_LENGTH : natural := WORD_LENGTH+2;--because the different lines that are put in the different game_of_life instantiations must overlap
    constant LINE_LENGTH_NUM_BITS : natural := WORD_NUM_BITS+1;
    
    --game of life top
    constant NUM_INST : natural := CHECKERBOARD_SIZE/WORD_LENGTH;
    constant NUM_INST_NUM_BITS : natural := 5;
    
    -- video driver
    constant SYS_DATA_LEN : natural := 32;
    constant SYS_ADDR_LEN : natural := 32;
    constant GoL_DATA_LEN : natural := 1024; --1024
    constant GoL_ADDR_LEN : natural := 10; --10
    
    constant SCREEN_WIDTH : natural := 640; --change!!!! 320
    constant SCREEN_HEIGHT : natural := 480; --CHANGE!!! 240
    
    constant WINDOW_DIVISION_FACTOR : natural := 1;
    
    constant WINDOW_WIDTH : natural := SCREEN_WIDTH/WINDOW_DIVISION_FACTOR;
    constant WINDOW_HEIGHT : natural := SCREEN_HEIGHT/WINDOW_DIVISION_FACTOR;

end package constants;
