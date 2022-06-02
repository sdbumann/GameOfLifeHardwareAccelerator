library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

-- m00_axi_aclk ==> s00_axi_aclk ==> logic clk

entity init_block is
  generic (
    -- Parameters of the AXI master bus interface:
    C_M00_AXI_ADDR_WIDTH  : integer := 32;
    C_M00_AXI_DATA_WIDTH  : integer := 32
  );
  port (
    --------------------------------------
    CLK : in std_logic;
    resetn : in std_logic;
    --------------------------------------
    -- master
    master_start : out std_logic;
    master_done : in std_logic;
    master_readWrite : out std_logic;
    master_address : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    master_dataRead : in std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    
    -- Control signals for bram0
    ena0 : out std_logic;
    wea0 : out std_logic;
    addra0 : out std_logic_vector(9 downto 0);
    dia0 : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- other signals 
    GameOfLifeAddress : in std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    start : in std_logic;
    done : out std_logic;
    init_row_0_out, init_row_1_out, init_row_2_out : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    count_line_init : out unsigned(NUM_INST_NUM_BITS-1 downto 0);
    count_row_init : out unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0)
  );
end init_block;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

architecture rtl of init_block is
  type TState is (IDLE, START_READ, WAIT_DRAM, READ_DRAM, WRITE_BRAM);
  signal rState, nrState                      : TState;
--  signal init_row_0_p, init_row_0_n, init_row_1_p, init_row_1_n, init_row_2_p, init_row_2_n : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal row_temp_p, row_temp_n : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal count_line_p, count_line_n : unsigned(NUM_INST_NUM_BITS-1 downto 0);
  signal count_line_en, count_line_reset, count_line_done    : std_logic;
  signal count_row_p, count_row_n : unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0);
  signal count_row_en, count_row_reset, count_row_done : std_logic;
  
begin
--  init_row_0_out <= init_row_0_p;
--  init_row_1_out <= init_row_1_p;
--  init_row_2_out <= init_row_2_p;
  process (CLK, resetn)
  begin
    if rising_edge(CLK) then 
      if resetn = '0' then
        rState <= IDLE;
        count_row_p <= (others => '0');
        count_line_p <= (others => '0');
        row_temp_p <= (others => '0');
      else
        rState <= nrState;
        count_row_p <= count_row_n;
        count_line_p <= count_line_n;
        row_temp_p <= row_temp_n;
      end if;
    end if;
  end process;
  
  --FSM
  process (all)
  begin
    nrState                 <= rState;
    row_temp_n              <= row_temp_p;
    
    count_line_reset<='0';
    count_row_reset<='0';
    count_line_en <= '0';
    count_row_en <= '0';
    
    count_row_n <= count_row_p;
    count_line_n <= count_line_p;
    
    dia0 <= (others => '0');
    addra0 <= (others => '0');
    wea0 <= '0';
    ena0 <= '0';
    
    done <= '0';
    
    master_address <=  (others => '0');
    master_readWrite <= '0'; --we want to read
    master_start<='0';
    

    case rState is
        when IDLE =>
            count_line_n <= (others => '0');
            count_row_n <= (others => '0');
            row_temp_n <= (others => '0');
            done <= '1';
             
            if start='1' then
                nrState <= START_READ; 
--                master_address <= std_logic_vector(unsigned(GameOfLifeAddress) + WORD_LENGTH/8*count_line_p + count_row_p * CHECKERBOARD_SIZE/8);
--                master_readWrite <= '0'; --we want to read
--                master_start<='1';
            end if;

        when START_READ =>
            if master_done = '1' then
                master_address <= std_logic_vector(unsigned(GameOfLifeAddress) + WORD_LENGTH/8*count_line_p + count_row_p * CHECKERBOARD_SIZE/8);
                master_readWrite <= '0'; --we want to read
                master_start <= '1';
                nrState <= WAIT_DRAM;
            end if;
            
--            if count_row_done = '1' then 
--                count_row_reset <= '1';
--                nrState <= DONE_STATE;
--            elsif count_line_done = '1' then
--                count_line_en <= '1';
--                nrState <= WRITE_BRAM;

                


        when WAIT_DRAM =>
            master_address <= std_logic_vector(unsigned(GameOfLifeAddress) + WORD_LENGTH/8*count_line_p + count_row_p * CHECKERBOARD_SIZE/8);
            master_readWrite <= '0'; --we want to read

            
--            if count_row_done = '1' then 
--                count_row_reset <= '1';
--                nrState <= DONE_STATE;
--            elsif count_line_done = '1' then
--                count_line_en <= '1';
--                nrState <= WRITE_BRAM;
            if master_done = '1' then
                nrState <= READ_DRAM;
            end if;
        
        when READ_DRAM =>
            master_address <= std_logic_vector(unsigned(GameOfLifeAddress) + WORD_LENGTH/8*count_line_p + count_row_p * CHECKERBOARD_SIZE/8);
            row_temp_n(CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p) downto CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p)-WORD_LENGTH+1) <= master_dataRead;
            --if count_line_done = '1' then
            if count_line_p = to_unsigned(NUM_INST-1, count_line_p'length) then
                --count_line_en <= '1';
                nrState <= WRITE_BRAM;
            else
                --count_line_en <= '1';
                count_line_n <= count_line_p + 1;
                nrState <= START_READ;
            end if;
                        
        when WRITE_BRAM =>
            dia0 <= row_temp_p;
            addra0 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0));
            wea0 <= '1';
            ena0 <= '1';
            
--            init_row_0_n <= (others => '0');
--            if count_row_p = to_unsigned(0, count_row_p'length) then 
--                init_row_1_n <= row_temp_p;
--            elsif count_row_p = to_unsigned(1, count_row_p'length) then
--                init_row_2_n <= row_temp_p;
--            end if;
            
            --if count_row_done = '1' then 
            if count_row_p = to_unsigned(CHECKERBOARD_SIZE-1, count_row_p'length) then
                --count_row_reset <= '1';
                nrState <= IDLE;
            else 
                --count_row_en <= '1';
                count_row_n <= count_row_p + 1;
                nrState <= START_READ;
                count_line_n <= (others => '0');
            end if;
            
            
        when OTHERS =>
            NULL;
    end case;
  end process;
  
   
--  --row counter
--  count_row_done <= '1' when count_row_p = to_unsigned(CHECKERBOARD_SIZE-1, count_row_p'length) else
--                    '0';
--  count_row_n <=    to_unsigned(0, count_row_n'length) when count_row_reset='1' else
--                    count_row_p + to_unsigned(1, count_row_p'length) when count_row_en = '1' else
--                    count_row_p;
                
--  --line counter
--  count_line_done <= '1' when count_line_p = to_unsigned(NUM_INST-1, count_line_p'length) else
--                     '0';
--  count_line_n <=   to_unsigned(0, count_line_n'length) when count_line_reset='1' else
--                    count_line_p + to_unsigned(1, count_line_p'length) when count_line_en = '1' else
--                    count_line_p;
                    
  --ILA debugging
  count_line_init <= count_line_p;
  count_row_init <= count_row_p;            
end rtl;


