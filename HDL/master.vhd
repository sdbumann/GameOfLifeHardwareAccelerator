library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity master is
  generic (
    -- Parameters of the AXI master bus interface:
    C_M00_AXI_ADDR_WIDTH  : integer := 32;
    C_M00_AXI_DATA_WIDTH  : integer := 32
  );
  port (
    --------------------------------------
    -- Ports for the AXI4 master interface
    m00_axi_aclk : in std_logic;
    m00_axi_aresetn : in std_logic; -- AXI active low reset

    m00_axi_awvalid : out std_logic;
    m00_axi_awready : in std_logic;
    -- Privilege and security level of the transaction, and whether the 
    -- transaction is a data or an instruction access:
    m00_axi_awprot : out std_logic_vector(2 downto 0);
    m00_axi_awaddr : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);

    m00_axi_wvalid : out std_logic;
    m00_axi_wready : in std_logic;
    -- One strobe bit for each byte of the write data bus.
    m00_axi_wstrb : out std_logic_vector(C_M00_AXI_DATA_WIDTH/8-1 downto 0); -- 3 downto 0
    m00_axi_wdata : out std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);

    m00_axi_bvalid : in std_logic;
    m00_axi_bready : out std_logic;
    -- Status of the write transaction. "00" --> OK
    m00_axi_bresp : in std_logic_vector(1 downto 0);

    m00_axi_arvalid : out std_logic;
    m00_axi_arready : in std_logic;
    -- Privilege and security level of the transaction, and whether the 
    -- transaction is a data or an instruction access:
    m00_axi_arprot : out std_logic_vector(2 downto 0);
    m00_axi_araddr : out std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);

    m00_axi_rvalid : in std_logic;
    m00_axi_rready : out std_logic;
    -- Status of the read transfer.
    m00_axi_rresp : in std_logic_vector(1 downto 0);
    m00_axi_rdata : in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);

    -- Additional control signals for this module.
    start : in std_logic;
    done, error : out std_logic;
    readWrite : in std_logic;
    address : in std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);
    dataWrite : in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);
    dataRead : out std_logic_Vector(C_M00_AXI_DATA_WIDTH-1 downto 0)
  );
end master;


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of master is
  type TState is (IDLE, START_READ, WAIT_READ_DATA, START_WRITE, WAIT_ADDRESS_READY, WAIT_DATA_READY, WAIT_BVALID);
  signal rState, nrState : TState;
  -- We register the data read from the bus.
  signal rDataRead, nrDataRead : std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0);

begin
  -- Signals that are fixed to a value.
  m00_axi_wstrb <= (OTHERS => '1');
  m00_axi_awprot <= "000";
  m00_axi_arprot <= "000";

  dataRead <= rDataRead;

  -- Sequential process for the state.
  process (m00_axi_aclk, m00_axi_aresetn)
  begin
    if rising_edge(m00_axi_aclk) then
      if m00_axi_aresetn = '0' then
        rState <= IDLE;
        rDataRead <= (OTHERS => '0');
      else
        rState <= nrState;
        rDataRead <= nrDataRead;
      end if;
    end if;
  end process;

  -- Combinational process to generate next state and Moore/Mealy outputs.
  process (rState, rDataRead, m00_axi_awready, m00_axi_wready, m00_axi_bvalid, m00_axi_arready, m00_axi_rvalid,
          m00_axi_rresp, m00_axi_rdata, start, readWrite, address, dataWrite)
  begin
    nrState <= rState;
    nrDataRead <= rDataRead;
    done <= '0';
    m00_axi_arvalid <= '0';
    m00_axi_araddr <= (OTHERS => '0');
    m00_axi_rready <= '0';
    m00_axi_awvalid <= '0';
    m00_axi_wvalid <= '0';
    m00_axi_awaddr <= (OTHERS => '0');
    m00_axi_wdata <= (OTHERS => '0');
    m00_axi_bready <= '0';
  
    case rState is
      when IDLE =>
        done <= '1';
        if (start = '1') and (readWrite = '0')  then
          nrState <= START_READ;
        elsif (start = '1') and (readWrite = '1') then
          nrState <= START_WRITE;
        end if;

      when START_READ =>
        m00_axi_arvalid <= '1';
        m00_axi_araddr <= address;
        if m00_axi_arready = '1' then
          nrState <= WAIT_READ_DATA;
        end if;

      when WAIT_READ_DATA =>
        m00_axi_rready <= '1';
        if m00_axi_rvalid = '1' then
          nrState <= IDLE;
          nrDataRead <= m00_axi_rdata;
        end if;
        
      when START_WRITE =>
        m00_axi_awvalid <= '1';
        m00_axi_wvalid <= '1';
        m00_axi_awaddr <= address;
        m00_axi_wdata <= dataWrite;
        if (m00_axi_awready = '1') and (m00_axi_wready = '1') then 
          nrState <= WAIT_BVALID;
        elsif (m00_axi_awready = '1') then
          nrState <= WAIT_DATA_READY;
        elsif (m00_axi_wready = '1') then
          nrState <= WAIT_ADDRESS_READY;
        end if;
        
      when WAIT_ADDRESS_READY =>
        m00_axi_awvalid <= '1';
        m00_axi_awaddr <= address;
        if (m00_axi_awready = '1') then
          nrState <= WAIT_BVALID;
        end if;

      when WAIT_DATA_READY =>
        m00_axi_wvalid <= '1';
        m00_axi_wdata <= dataWrite;
        if (m00_axi_wready = '1') then
          nrState <= WAIT_BVALID;
        end if;
        
      when WAIT_BVALID =>
        m00_axi_bready <= '1';
        if (m00_axi_bvalid = '1') then
          nrState <= IDLE;
        end if;

    when OTHERS =>
      NULL;
    end case;
  end process;

  -- Calculate this based on bresp and a flip-flop that gets reset after exiting the idle state.
  error <= '0';

end rtl;

