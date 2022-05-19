-- Example for the AXI4 Lite slave.
-- This code should not be considered as production-safe.
-- It takes some simplifications, such as blocking the write-address and 
-- write-data channels until both are valid. Otherwise, the slave would need
-- to add registers to store whichever comes first until the other arrives.
-- If both a read and write arrive at the same time, the read takes
-- precedence (the write waits, it's not discarded). The specification
-- allows proceeding in both concurrently.

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;


entity slave is
  generic (
    C_NUM_REGISTERS : integer := 7;
        
    -- Parameters of Axi Slave Bus Interface S00_AXI
    C_S00_AXI_DATA_WIDTH	: integer	:= 32;
    C_S00_AXI_ADDR_WIDTH	: integer	:= 5
  );
  port (
    -- Ports of Axi Slave Bus Interface S00_AXI
    s00_axi_aclk	: in std_logic;
    s00_axi_aresetn	: in std_logic;
    s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot	: in std_logic_vector(2 downto 0);
    s00_axi_awvalid	: in std_logic;
    s00_axi_awready	: out std_logic;
    s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid	: in std_logic;
    s00_axi_wready	: out std_logic;
    s00_axi_bresp	: out std_logic_vector(1 downto 0);
    s00_axi_bvalid	: out std_logic;
    s00_axi_bready	: in std_logic;
    s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot	: in std_logic_vector(2 downto 0);
    s00_axi_arvalid	: in std_logic;
    s00_axi_arready	: out std_logic;
    s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp	: out std_logic_vector(1 downto 0);
    s00_axi_rvalid	: out std_logic;
    s00_axi_rready	: in std_logic;

    -- User ports.
    start : out std_logic;
    stop : out std_logic;
    done : in std_logic;
    game_of_life_address : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    frame_buffer_address : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    window_top : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    window_left : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0)
  );
end slave;

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

architecture rtl of slave is
  type TState is (IDLE, READ, WAIT_BREADY);
  type TReg is array (C_NUM_REGISTERS - 1 downto 0) of std_logic_vector(31 downto 0);
    
  signal state, nstate : TState;
  signal registers, nregisters : TReg;
  signal aread, awrite : std_logic_vector(C_S00_AXI_ADDR_WIDTH - 1 - 2 downto 0);
    
begin	
  -- FIXED.
  s00_axi_rresp <= (OTHERS => '0'); -- "OKAY"
  s00_axi_bresp <= (OTHERS => '0'); -- "OKAY"
	
  -- Internal. Accesses are 32-bit, so we can index the register file just with these bits.
  aread <= s00_axi_araddr(C_S00_AXI_ADDR_WIDTH - 1 downto 2);
  awrite <= s00_axi_awaddr(C_S00_AXI_ADDR_WIDTH - 1 downto 2);
		
  process (s00_axi_aclk, s00_axi_aresetn)
  begin
    if rising_edge(s00_axi_aclk) then
      if s00_axi_aresetn = '0' then
        registers <= ( OTHERS => (OTHERS => '0'));
        state <= IDLE;
      else
        state <= nstate;
        registers <= nregisters; 
      end if;
    end if;
  end process;
	
--  process (state, s00_axi_arvalid, registers, s00_axi_arvalid, s00_axi_awvalid,
--          s00_axi_wvalid, awrite, s00_axi_wdata, s00_axi_rready, aread, s00_axi_bready)
    process (all)
    variable regIndex : integer;
  begin
    nregisters <= registers;
    nstate <= state;
    s00_axi_rdata <= (OTHERS => '0');
    s00_axi_rvalid <= '0';
    s00_axi_bvalid <= '0';
    s00_axi_wready <= '0';  -- We limit that we accept the data only if the address is also on the bus, both at the same time.
    s00_axi_arready <= '0';
    s00_axi_awready <= '0';
	   
    case state is
      when IDLE =>
        -- Check if read started.
        if s00_axi_arvalid = '1' then
          if s00_axi_rready = '1' then
            s00_axi_arready <= '1';
            s00_axi_rvalid <= '1';
            --s00_axi_rdata <= registers(to_integer(unsigned(aread)));
            -- [TODO1.1] change the following IF statement
            regIndex := to_integer(unsigned(aread));
            if (regIndex = 0) or (regIndex = 1) or (regIndex = 3) or (regIndex = 4) or (regIndex = 5) or (regIndex = 6) then -- these registers can be read by bus because they are output to logic controller
              s00_axi_rdata <= registers(regIndex);
            elsif regIndex = 2 then
              s00_axi_rdata <= "0000000000000000000000000000000" & done; -- we do this because done is input from logic controller  
            else
              s00_axi_rdata <= x"DEADBEEF"; -- Undefined behavior
            end if;
          else
            nState <= READ;
          end if;
          
        elsif (s00_axi_awvalid = '1') and (s00_axi_wvalid = '1') then
          s00_axi_awready <= '1';
          s00_axi_wready <= '1';
          s00_axi_bvalid <= '1';
          if s00_axi_bready = '0' then
            nState <= WAIT_BREADY;
          end if;
          --nregisters(to_integer(unsigned(awrite))) <= s00_axi_wdata;
          -- [TODO2] change the following IF statement
          regIndex := to_integer(unsigned(awrite));
          if (regIndex = 0) then -- because start is only one bit
            start <= s00_axi_wdata(0);
          elsif (regIndex = 1) then -- because start is only one bit
            stop <= s00_axi_wdata(0);
          elsif (regIndex < C_NUM_REGISTERS) then 
            nregisters(regIndex) <= s00_axi_wdata;
          end if;
        end if;

      when READ =>
        if s00_axi_rready = '1' then
          s00_axi_arready <= '1';
          s00_axi_rvalid <= '1';
          nstate <= IDLE;
        end if;

        --s00_axi_rdata <= registers(to_integer(unsigned(aread)));
        -- [TODO1.2] change the following IF statement
        regIndex := to_integer(unsigned(aread));
        if (regIndex = 0) or (regIndex = 1) or (regIndex = 3) or (regIndex = 4) or (regIndex = 5) or (regIndex = 6) then -- these registers can be read by bus because they are output to logic controller
          s00_axi_rdata <= registers(regIndex);
        elsif regIndex = 2 then
          s00_axi_rdata <= "0000000000000000000000000000000" & done; -- we do this because done is input from logic controller  
        else
          s00_axi_rdata <= x"DEADBEEF"; -- Undefined behavior
        end if;
                   
      when WAIT_BREADY =>
        s00_axi_bvalid <= '1';
        if s00_axi_bready = '1' then
          nstate <= IDLE;
        end if;
       
      when OTHERS =>
        NULL;  
    end case;             

  end process;


  -- Logic.
  -- [TODO3] correct registers to outputsignals that are not only 1 bit
  game_of_life_address <= registers(3);
  frame_buffer_address <= registers(4);
  window_top <= registers(5);
  window_left <= registers(6);
	
end rtl;
