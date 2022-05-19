library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

entity game_of_life_top is
    port(
        CLK, resetn             : in std_logic;
        row_0, row_1, row_2     : in std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        start                   : in std_logic;
        
        row_solution            : out std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
        done                    : out std_logic
    );
--  Port ( );
end game_of_life_top;

architecture rtl of game_of_life_top is
    type vector_LINE_LENGTH is array (natural range <>) of std_logic_vector(LINE_LENGTH-1 downto 0);
    signal multi_line_0, multi_line_1, multi_line_2 : vector_LINE_LENGTH(NUM_INST-1 downto 0);
    
    type vector_WORD_LENGTH is array (natural range <>) of std_logic_vector(WORD_LENGTH-1 downto 0);
    signal multi_line_solution : vector_WORD_LENGTH(NUM_INST-1 downto 0);
    
    type vector_DONE is array (natural range <>) of std_logic;
--    signal multi_done : vector_LINE_LENGTH(NUM_INST-1 downto 0);
    signal multi_done : std_logic_vector(NUM_INST-1 downto 0);
    
    component game_of_life
        port(
            CLK, resetn             : in std_logic;
            line_0, line_1, line_2  : in std_logic_vector(LINE_LENGTH-1 downto 0);
            start_gol               : in std_logic;
            
            line_solution           : out std_logic_vector(WORD_LENGTH-1 downto 0);
            done_gol                : out std_logic
        );
    end component;
    
    
    function and_reduce( V: std_logic_vector )
                return std_ulogic is
      variable result: std_ulogic;
    begin
      for i in V'range loop
        if i = V'left then
          result := V(i);
        else
          result := result and V(i);
        end if;
        exit when result = '1';
      end loop;
      return result;
    end and_reduce;

begin
    gen_game_of_life_inst:
    for i in 0 to NUM_INST-1 generate
        game_of_life_inst_x : game_of_life port map(
            CLK, resetn, multi_line_0(i), multi_line_1(i), multi_line_2(i), 
            start, multi_line_solution(i), multi_done(i)
        );
    end generate gen_game_of_life_inst;
    
    process(all)
    begin
        row_solution<=(others=>'0');
        done <= and_reduce( multi_done ); 
        --fill in the registers
        for i in 0 to NUM_INST-1 loop
            if i=0 then
                multi_line_0(i) <= '0'&row_0(CHECKERBOARD_SIZE-1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH);
                multi_line_1(i) <= '0'&row_1(CHECKERBOARD_SIZE-1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH);
                multi_line_2(i) <= '0'&row_2(CHECKERBOARD_SIZE-1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH);
            elsif i=NUM_INST-1 then
                multi_line_0(i) <= row_0(WORD_LENGTH-1+1 downto 0)&'0';
                multi_line_1(i) <= row_1(WORD_LENGTH-1+1 downto 0)&'0';
                multi_line_2(i) <= row_2(WORD_LENGTH-1+1 downto 0)&'0';
            else
                multi_line_0(i) <= row_0(CHECKERBOARD_SIZE-1-WORD_LENGTH*i+1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH);
                multi_line_1(i) <= row_1(CHECKERBOARD_SIZE-1-WORD_LENGTH*i+1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH);
                multi_line_2(i) <= row_2(CHECKERBOARD_SIZE-1-WORD_LENGTH*i+1 downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH);
            end if;
        end loop;
        if done='1' then
            for i in 0 to NUM_INST-1 loop
                row_solution(CHECKERBOARD_SIZE-1-WORD_LENGTH*i downto CHECKERBOARD_SIZE-1-WORD_LENGTH*i-WORD_LENGTH+1)<=multi_line_solution(i);
            end loop;
        end if;
    end process;
    
    

end rtl;
