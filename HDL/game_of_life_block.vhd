library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

-- m00_axi_aclk ==> s00_axi_aclk ==> logic clk

entity game_of_life_block is
  port (
    --------------------------------------
    CLK : in std_logic;
    resetn : in std_logic;
    --------------------------------------
    
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
--    init_row_0, init_row_1, init_row_2 : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
    work_bram_is : in std_logic;
    
    -- ILA debug signals
    count_row_GoL : out unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0);
    row_solution_GoL : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0)
    
    
  );
end game_of_life_block;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

architecture rtl of game_of_life_block is
  type TState is (IDLE, START_GOL_FULL_ROW_STATE, SAVE_ROWS, EXCHANGE_ROWS, DONE_STATE, READ_INITIAL_ROW_ONE_WAIT, READ_INITIAL_ROW_ONE, READ_INITIAL_ROW_TWO_WAIT, READ_INITIAL_ROW_TWO);
  signal rState, nrState : TState;
--  signal init_row_0_p, init_row_0_n, init_row_1_p, init_row_1_n, init_row_2_p, init_row_2_n : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal row_0_p, row_0_n, row_1_p, row_1_n, row_2_p, row_2_n : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal row_solution_p, row_solution_n, row_solution_gol_full_row : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal count_row_p, count_row_n : unsigned(CHECKERBOARD_SIZE_NUM_BITS downto 0);
  signal count_row_en, count_row_reset, count_row_done : std_logic;
  signal start_GOL_full_row, done_GOL_full_row : std_logic;
  
begin
    game_of_life_full_row : entity work.game_of_life_top(rtl)
    port map (
        CLK => CLK,
        resetn => resetn,
        row_0 => row_0_p,
        row_1 => row_1_P,
        row_2 => row_2_P,
        start => start_GOL_full_row,
        
        row_solution => row_solution_gol_full_row,
        done => done_GOL_full_row
    );

  
  process (CLK, resetn)
  begin
    if rising_edge(CLK) then 
      if resetn = '0' then
        rState <= IDLE;
        count_row_p <= (others => '0');
        row_0_p <= (others => '0');
        row_1_p <= (others => '0');
        row_2_p <= (others => '0');
        row_solution_p <= (others => '0');
      else
        rState <= nrState;
        count_row_p <= count_row_n;
        row_0_p <= row_0_n;
        row_1_p <= row_1_n;
        row_2_p <= row_2_n;
        row_solution_p <= row_solution_n;
      end if;
    end if;
  end process;
  
  --FSM
  process (all)
  begin
    nrState                 <= rState;
    row_0_n                 <= row_0_p;
    row_1_n                 <= row_1_p;
    row_2_n                 <= row_2_p;
    row_solution_n          <= row_solution_p;
    
    count_row_reset<='0';
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
    
    done <= '0';

    start_GOL_full_row <= '0';
        
    case rState is
        when IDLE =>  
            row_0_n                 <= (others => '0');
            row_1_n                 <= (others => '0');
            row_2_n                 <= (others => '0');
            row_solution_n          <= (others => '0');
            if start='1' then
                row_0_n <= (others => '0');
                if work_bram_is = '0' then
                    addrb0 <= std_logic_vector(to_unsigned(0, addrb0'length));
                    enb0 <= '1';
                else
                    addrb1 <= std_logic_vector(to_unsigned(0, addrb0'length));
                    enb1 <= '1';
                end if;
                nrState <= READ_INITIAL_ROW_ONE;
            end if;
            
        when READ_INITIAL_ROW_ONE =>
            if work_bram_is = '0' then
                addrb0 <= std_logic_vector(to_unsigned(0, addrb0'length));
                enb0 <= '1';
                row_1_n <= dob0;
            else
                addrb1 <= std_logic_vector(to_unsigned(0, addrb0'length));
                enb1 <= '1';
                row_1_n <= dob1;
            end if;
            nrState <= READ_INITIAL_ROW_TWO_WAIT;
            
        when READ_INITIAL_ROW_TWO_WAIT =>
            if work_bram_is = '0' then
                addrb0 <= std_logic_vector(to_unsigned(1, addrb0'length));
                enb0 <= '1';
            else
                addrb1 <= std_logic_vector(to_unsigned(1, addrb0'length));
                enb1 <= '1';
            end if;
            nrState <= READ_INITIAL_ROW_TWO;
        
        when READ_INITIAL_ROW_TWO =>
            if work_bram_is = '0' then
                addrb0 <= std_logic_vector(to_unsigned(1, addrb0'length));
                enb0 <= '1';
                row_2_n <= dob0;
            else
                addrb1 <= std_logic_vector(to_unsigned(1, addrb0'length));
                enb1 <= '1';
                row_2_n <= dob1;
            end if;
            nrState <= START_GOL_FULL_ROW_STATE;

        when START_GOL_FULL_ROW_STATE =>
            start_GOL_full_row <= '1';
            if done_GOL_full_row = '1' then
                row_solution_n <= row_solution_gol_full_row;
                if count_row_p < to_unsigned(CHECKERBOARD_SIZE, count_row_p'length) then
                    count_row_en <= '1';
                else
                    count_row_en <= '0';
                end if;
                nrState <= SAVE_ROWS;
            end if;
            
        when SAVE_ROWS =>
            -- one needs 2 cycles to read from dram -> thus give tha address and enable='1' here and read in in next state of FSM
            if work_bram_is = '0' then
                addrb0 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0)+1);
                enb0 <= '1';
            else
                addrb1 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0)+1);
                enb1 <= '1';
            end if;
            
            -- save solution in bram
            if work_bram_is = '0' then
                ena1 <= '1';
                wea1 <= '1';
                addra1 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0)-1);
                dia1 <= row_solution_p;
            else
                ena0 <= '1';
                wea0 <= '1';
                addra0 <= std_logic_vector(count_row_p(CHECKERBOARD_SIZE_NUM_BITS-1 downto 0)-1);
                dia0 <= row_solution_p;
            end if;
            
            nrState <= EXCHANGE_ROWS;
            
        when EXCHANGE_ROWS =>
            if count_row_p = to_unsigned(CHECKERBOARD_SIZE, count_row_p'length) then
                nrState <= DONE_STATE;
            else
                -- switch and exchange different rows
                row_0_n <= row_1_p;
                row_1_n <= row_2_p;
                -- the row "outside" of the playing (row 1024) is only zeros
                if count_row_p = to_unsigned(CHECKERBOARD_SIZE, count_row_p'length)-1 then
                    row_2_n<=(others=>'0');
                elsif work_bram_is = '0' then
                    row_2_n <= dob0;
                else
                    row_2_n <= dob1;
                end if;
                nrState <= START_GOL_FULL_ROW_STATE;
            end if;
            
            
            
            
        when DONE_STATE => 
            done <= '1';
            count_row_reset<='1';
            nrState <= IDLE;
            
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
                    
                
  count_row_GoL <= count_row_p;
  row_solution_GoL <= row_solution_p;                
end rtl;


