library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity game_of_life is
    port(
        CLK, resetn             : in std_logic;
        line_0, line_1, line_2  : in std_logic_vector(LINE_LENGTH-1 downto 0);
        start_gol               : in std_logic;
        
        line_solution           : out std_logic_vector(WORD_LENGTH-1 downto 0);
        done_gol                : out std_logic
    );
--  Port ( );
end game_of_life;

architecture rtl of game_of_life is
    type TState is (IDLE, GAME_OF_LIFE, COUNT_INCREMENT, DONE);
    signal rState, nrState                      : TState;
    signal count_n, count_p                     : unsigned(LINE_LENGTH_NUM_BITS downto 0);
    signal line_solution_n, line_solution_p     : std_logic_vector(LINE_LENGTH-1 downto 0);
    signal count_en, count_reset, count_done    : std_logic;
    signal sum_neighbors_of_pixel               : unsigned(SUM_NEIGHBOR_NUM_BITS downto 0);
    signal pixel_out                            : unsigned(1 downto 1);
    signal pixel                                : unsigned(1 downto 1);
begin

  -- Sequential process for the state and counter register.
  process (CLK, resetn)
  begin
    if rising_edge(CLK) then 
      if resetn = '0' then
        rState <= IDLE;
        count_p <= (others => '0');
        line_solution_p <= (others => '0');
      else
        rState <= nrState;
        count_p <= count_n;
        line_solution_p <= line_solution_n;
      end if;
    end if;
  end process;
  
  --FSM
  process (all)
  begin
    nrState                 <= rState;
    line_solution_n <= line_solution_p;
    done_gol                <= '0';
    count_reset             <= '0';
    count_en                <= '0';
    sum_neighbors_of_pixel  <= (others => '0');
    line_solution           <= line_solution_p(LINE_LENGTH-2 downto 1);
    pixel_out               <= "0";
    pixel                   <= "0";

    case rState is
        when IDLE =>
            count_reset<='1';
            if start_gol = '1' then
                nrState <= GAME_OF_LIFE;
            end if;

        when GAME_OF_LIFE =>
            sum_neighbors_of_pixel <=   to_unsigned(     to_integer(unsigned(line_0(LINE_LENGTH-1-to_integer(count_p) downto LINE_LENGTH-1-to_integer(count_p))))
                                                        +to_integer(unsigned(line_0(LINE_LENGTH-2-to_integer(count_p) downto LINE_LENGTH-2-to_integer(count_p))))
                                                        +to_integer(unsigned(line_0(LINE_LENGTH-3-to_integer(count_p) downto LINE_LENGTH-3-to_integer(count_p))))
                                                        +to_integer(unsigned(line_1(LINE_LENGTH-1-to_integer(count_p) downto LINE_LENGTH-1-to_integer(count_p))))
                                                        +to_integer(unsigned(line_1(LINE_LENGTH-3-to_integer(count_p) downto LINE_LENGTH-3-to_integer(count_p))))
                                                        +to_integer(unsigned(line_2(LINE_LENGTH-1-to_integer(count_p) downto LINE_LENGTH-1-to_integer(count_p))))
                                                        +to_integer(unsigned(line_2(LINE_LENGTH-2-to_integer(count_p) downto LINE_LENGTH-2-to_integer(count_p))))
                                                        +to_integer(unsigned(line_2(LINE_LENGTH-3-to_integer(count_p) downto LINE_LENGTH-3-to_integer(count_p)))), sum_neighbors_of_pixel'length);
            
            --sum_neighbors_of_pixel <= to_unsigned(0, sum_neighbors_of_pixel'length);
            pixel <= unsigned(line_1(LINE_LENGTH-2-to_integer(count_p) downto LINE_LENGTH-2-to_integer(count_p)));
            
            if pixel = 1 then
                if sum_neighbors_of_pixel<2 then
                    pixel_out <= "0";
                elsif sum_neighbors_of_pixel=2 or sum_neighbors_of_pixel=3 then
                    pixel_out <= "1";
                else --sum_neighbors_of_pixel>3
                    pixel_out <= "0";
                end if;
            else --pixel = 0
                if sum_neighbors_of_pixel=3 then
                    pixel_out <= "1";
                else --sum_neighbors_of_pixel~=3
                    pixel_out <= "0";
                end if;
            end if;
            line_solution_n(LINE_LENGTH-2-to_integer(count_p) downto LINE_LENGTH-2-to_integer(count_p)) <= std_logic_vector(pixel_out);
            
            --nrState <= COUNT_INCREMENT;
            if count_done='1' then 
                nrState <= DONE;
            else
                nrState <= COUNT_INCREMENT;
            end if;
            
        when COUNT_INCREMENT =>
            count_en<='1';
--            if count_done='1' then 
--                nrState <= DONE;
--            else
            nrState <= GAME_OF_LIFE;
--            end if;
        

        when DONE =>
            done_gol <= '1';
            nrState <= IDLE;
            
        

        when OTHERS =>
            NULL;
    end case;
  end process;
  
  --counter
  count_done <= '1' when count_p = to_unsigned(LINE_LENGTH-3, LINE_LENGTH_NUM_BITS) else
                '0';
  count_n <=    to_unsigned(0, count_n'length) when (count_done='1' or count_reset='1') else
                count_p + to_unsigned(1, count_p'length) when count_en = '1' else
                count_p;

end rtl;
