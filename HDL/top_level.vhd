library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

-- m00_axi_aclk ==> s00_axi_aclk ==> logic clk

entity top_level is
  generic (
    -- Parameters of the AXI slave bus interface:
    C_S00_AXI_DATA_WIDTH : integer := 32;
    C_S00_AXI_ADDR_WIDTH : integer := 5;

    -- Parameters of the AXI master bus interface:
    C_M00_AXI_ADDR_WIDTH  : integer := 32;
    C_M00_AXI_DATA_WIDTH  : integer := 32
  );
  port (
    --------------------------------------
    -- Port for the AXI4 slave interface
    s00_axi_aclk  : in std_logic;
    s00_axi_aresetn : in std_logic;
    s00_axi_awaddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_awprot  : in std_logic_vector(2 downto 0);
    s00_axi_awvalid : in std_logic;
    s00_axi_awready : out std_logic;
    s00_axi_wdata : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_wstrb : in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
    s00_axi_wvalid  : in std_logic;
    s00_axi_wready  : out std_logic;
    s00_axi_bresp : out std_logic_vector(1 downto 0);
    s00_axi_bvalid  : out std_logic;
    s00_axi_bready  : in std_logic;
    s00_axi_araddr  : in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
    s00_axi_arprot  : in std_logic_vector(2 downto 0);
    s00_axi_arvalid : in std_logic;
    s00_axi_arready : out std_logic;
    s00_axi_rdata : out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
    s00_axi_rresp : out std_logic_vector(1 downto 0);
    s00_axi_rvalid  : out std_logic;
    s00_axi_rready  : in std_logic;

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
    m00_axi_rdata : in std_logic_vector(C_M00_AXI_DATA_WIDTH-1 downto 0)
  );
end top_level;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.constants.all;

architecture rtl of top_level is
  signal iClk : std_logic; -- Common internal CLK ==> m00_axi_aclk
  -- Control signals comming/going to the register file.
  signal slaveStart, slaveStop, slaveDone: std_logic;-- for slave <-> controller signals Start, Done and modified
  signal slaveGameOfLifeAddress : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);-- for slave <-> controller signals
  signal slaveFrameBufferAddress : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);-- for slave <-> controller signals
  signal slaveWindowTop : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);-- for slave <-> controller signals
  signal slaveWindowLeft : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);-- for slave <-> controller signals
  -- Control signals for the master reader/writer.
  signal masterStart, masterDone, masterError : std_logic;-- for master <-> controller signals
  signal masterReadWrite : std_logic; -- 0 = read, 1 = write. -- for master <-> controller signals
  signal masterAddress : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);-- for master <-> controller signals
  signal masterDataWrite, masterDataRead : std_logic_vector(C_M00_AXI_ADDR_WIDTH-1 downto 0);-- for master <-> controller signals data to write and data read
  -- Control signals for bram0
  signal ena0 : std_logic;
  signal enb0 : std_logic;
  signal wea0 : std_logic;
  signal addra0 : std_logic_vector(9 downto 0);
  signal addrb0 : std_logic_vector(9 downto 0);
  signal dia0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal dob0 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  -- Control signals for bram1
  signal ena1 : std_logic;
  signal enb1 : std_logic;
  signal wea1 : std_logic;
  signal addra1 : std_logic_vector(9 downto 0);
  signal addrb1 : std_logic_vector(9 downto 0);
  signal dia1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
  signal dob1 : std_logic_vector(CHECKERBOARD_SIZE-1 downto 0);
begin

  -- Internal signals.
  iClk <= m00_axi_aclk;

  -- Memory reader/writer (master)
  master_inst : entity work.master(rtl)
    generic map (C_M00_AXI_ADDR_WIDTH => C_M00_AXI_ADDR_WIDTH, C_M00_AXI_DATA_WIDTH => C_M00_AXI_DATA_WIDTH)
    port map (m00_axi_aclk => iClk, m00_axi_aresetn => m00_axi_aresetn,
      m00_axi_awvalid => m00_axi_awvalid, m00_axi_awready => m00_axi_awready, m00_axi_awprot => m00_axi_awprot,
      m00_axi_awaddr => m00_axi_awaddr, 
      m00_axi_wvalid => m00_axi_wvalid, m00_axi_wready => m00_axi_wready, m00_axi_wstrb => m00_axi_wstrb, 
      m00_axi_wdata => m00_axi_wdata, 
      m00_axi_bvalid => m00_axi_bvalid, m00_axi_bready => m00_axi_bready, m00_axi_bresp => m00_axi_bresp, 
      m00_axi_arvalid => m00_axi_arvalid, m00_axi_arready => m00_axi_arready, m00_axi_araddr => m00_axi_araddr, 
      m00_axi_rvalid => m00_axi_rvalid, m00_axi_rready => m00_axi_rready, m00_axi_rresp => m00_axi_rresp,
      m00_axi_rdata => m00_axi_rdata,
      start => masterStart, done => masterDone, error => masterError, readWrite => masterReadWrite,
      address => masterAddress, dataWrite => masterDataWrite, dataRead => masterDataRead      
    );

  -- Slave interface and register file.
  slave_inst : entity work.slave(rtl)
    generic map (C_S00_AXI_DATA_WIDTH => C_S00_AXI_DATA_WIDTH, C_S00_AXI_ADDR_WIDTH => C_S00_AXI_ADDR_WIDTH)
    port map (s00_axi_aclk => iClk, s00_axi_aresetn => s00_axi_aresetn,
      s00_axi_awaddr => s00_axi_awaddr, s00_axi_awprot => s00_axi_awprot, s00_axi_awvalid => s00_axi_awvalid,
      s00_axi_awready => s00_axi_awready, s00_axi_wdata => s00_axi_wdata, s00_axi_wstrb => s00_axi_wstrb,
      s00_axi_wvalid => s00_axi_wvalid, s00_axi_wready => s00_axi_wready, s00_axi_bresp => s00_axi_bresp,
      s00_axi_bvalid => s00_axi_bvalid, s00_axi_bready => s00_axi_bready, s00_axi_araddr => s00_axi_araddr,
      s00_axi_arprot => s00_axi_arprot, s00_axi_arvalid => s00_axi_arvalid, s00_axi_arready => s00_axi_arready,
      s00_axi_rdata => s00_axi_rdata, s00_axi_rresp => s00_axi_rresp, s00_axi_rvalid => s00_axi_rvalid,
      s00_axi_rready => s00_axi_rready,
      start => slaveStart, stop => slaveStop, done => slaveDone, game_of_life_address => slaveGameOfLifeAddress,
      frame_buffer_address => slaveFrameBufferAddress, window_top => slaveWindowTop, window_left => slaveWindowLeft
    );

  bram0_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => iClk, ena => ena0, enb => enb0, wea => wea0, addra => addra0, addrb => addrb0, dia => dia0,
      dob => dob0
    );
  bram1_inst : entity work.simple_dual_one_clock(syn)
    port map(clk => iClk, ena => ena1, enb => enb1, wea => wea1, addra => addra1, addrb => addrb1, dia => dia1,
      dob => dob1
    );

end rtl;

