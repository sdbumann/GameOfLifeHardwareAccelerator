library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

-- m00_axi_aclk ==> s00_axi_aclk ==> logic clk

entity save_dram_block is
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
    
    -- master signals
    master_start : out std_logic;
    master_done : in std_logic;
    master_address : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    master_dataWrite : out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    master_readWrite : out std_logic;
    
    -- Control signals for bram0
    ena0 : out std_logic;
    wea0 : out std_logic;
    addra0 : out std_logic_vector(9 downto 0);
    dia0 : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    enb0 : out std_logic;
    addrb0 : out std_logic_vector(9 downto 0);
    dob0 : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- Control signals for bram1
    ena1 : out std_logic;
    wea1 : out std_logic;
    addra1 : out std_logic_vector(9 downto 0);
    dia1 : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    enb1 : out std_logic;
    addrb1 : out std_logic_vector(9 downto 0);
    dob1 : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    
    -- other signals 
    start : in std_logic;
    done : out std_logic;
    GameOfLifeAddress : in std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0); 
    work_bram_is : in std_logic;
    
    
    -- ILA signals
    count_line_save_dram : out unsigned(NUM_INST_NUM_BITS-1 downto 0);
    count_row_save_dram : out unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0)
  );
end save_dram_block;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

architecture rtl of save_dram_block is
  type TState is (IDLE, READ_BRAM_WAIT, READ_BRAM, WRITE_DRAM, WRITE_DRAM_WAIT);
  signal rState, nrState : TState;
  signal row_p, row_n : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal count_row_p, count_row_n : unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0);
  signal count_row_en, count_row_reset, count_row_done : std_logic;
  signal count_line_p, count_line_n : unsigned(NUM_INST_NUM_BITS-1 downto 0);
  signal count_line_en, count_line_reset, count_line_done    : std_logic;
begin
  
  master_address <= std_logic_vector(unsigned(GameOfLifeAddress) + WORD_LENGTH/8*count_line_p + count_row_p * CHECKERBOARD_SIZE/8);  
  process (CLK, resetn)
  begin
    if rising_edge(CLK) then 
      if resetn = '0' then
        rState <= IDLE;
        count_row_p <= (others => '0');
        count_line_p <= (others => '0');
        row_p <= (others => '0');
      else
        rState <= nrState;
        count_row_p <= count_row_n;
        count_line_p <= count_line_n;
        row_p <= row_n;
      end if;
    end if;
  end process;
  
  --FSM
  process (all)
  begin
    nrState                 <= rState;
    row_n                 <= row_p;
    
    count_row_reset<='0';
    count_line_en <= '0';
    count_line_reset <= '0';
    count_row_en <= '0';
    
    dia0 <= (others => '0');
    addra0 <= (others => '0');
    wea0 <= '0';
    ena0 <= '0';
    enb0 <= '0';
    addrb0 <= (others => '0');
    
    dia1 <= (others => '0');
    addra1 <= (others => '0');
    wea1 <= '0';
    ena1 <= '0';
    enb1 <= '0';
    addrb1 <= (others => '0');
    
    master_readWrite <= '1'; --we want to read
    master_start<='0';
    master_dataWrite <= (others => '0');
    
    done <= '0';

    case rState is
        when IDLE => 
            row_n <= (others => '0');
            done <= '1';
            count_row_reset <= '1';
            count_line_reset <= '1';
            if start = '1' then 
                nrState <= READ_BRAM_WAIT; 
          
            end if; 
            
            
        when READ_BRAM_WAIT =>
            -- one needs 2 cycles to read from dram -> thus give tha address and enable='1' here and read in in next state of FSM
            if work_bram_is = '0' then
                addrb1 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0));
                enb1 <= '1';
            else
                addrb0 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0));
                enb0 <= '1';
            end if;
            nrState <= READ_BRAM;
            
        when READ_BRAM =>
            if work_bram_is = '0' then
                addrb1 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0));
                enb1 <= '1';
                row_n <= dob1;
            else
                addrb0 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0));
                enb0 <= '1';
                row_n <= dob0;
            end if;
        
            nrState <= WRITE_DRAM_WAIT;
        
        when WRITE_DRAM_WAIT => -- master_done is always one  
            master_readWrite <= '1'; -- 1 for write
            master_dataWrite <= row_p(CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p) downto CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p)-WORD_LENGTH+1);
            master_start <= '1';  
            nrState <= WRITE_DRAM;
            
        when WRITE_DRAM => 
            master_readWrite <= '1'; -- 1 for write
            master_dataWrite <= row_p(CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p) downto CHECKERBOARD_SIZE-1-WORD_LENGTH*to_integer(count_line_p)-WORD_LENGTH+1);
            --master_start <= '1';
            
            if master_done = '1' then
                nrState <= WRITE_DRAM_WAIT;
                count_line_en <= '1';
                if count_line_p = to_unsigned(NUM_INST-1, count_line_p'length) and count_row_p = to_unsigned(CHECKERBOARD_SIZE-1, count_row_p'length) then
                    nrState <= IDLE;
                elsif count_line_p = to_unsigned(NUM_INST-1, count_line_p'length) then
                    count_row_en <= '1';
                    nrState <= READ_BRAM_WAIT;
                end if;
            end if;
            
        when OTHERS =>
            NULL;
    end case;
  end process;
  
   
  --row counter
  count_row_done <= '1' when count_row_p = to_unsigned(CHECKERBOARD_SIZE+1, count_row_p'length) else
                    '0';
  count_row_n <=    to_unsigned(0, count_row_n'length) when (count_row_done='1' or count_row_reset='1') else
                    count_row_p + to_unsigned(1, count_row_p'length) when count_row_en = '1' else
                    count_row_p;
                    
  --line counter
  count_line_n <=   to_unsigned(0, count_line_n'length) when count_line_reset='1' else
                    count_line_p + to_unsigned(1, count_line_p'length) when count_line_en = '1' else
                    count_line_p;         
                    
  --ILA
  count_row_save_dram <= count_row_p;
  count_line_save_dram <= count_line_p;
end rtl;


