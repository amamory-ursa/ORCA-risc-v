library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;


entity register_file is
  generic(
    REGISTER_SIZE      : positive;
    REGISTER_NAME_SIZE : positive
    );
  port(
    clk              : in std_logic;
    stall            : in std_logic;
    valid_input      : in std_logic;
    rs1_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    rs2_sel          : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_sel    : in std_logic_vector(REGISTER_NAME_SIZE -1 downto 0);
    writeback_data   : in std_logic_vector(REGISTER_SIZE -1 downto 0);
    writeback_enable : in std_logic;

    rs1_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0);
    rs2_data : buffer std_logic_vector(REGISTER_SIZE -1 downto 0)

    );
end;

architecture rtl of register_file is
  type register_list is array(31 downto 0) of std_logic_vector(REGISTER_SIZE-1 downto 0);


  signal registers : register_list := (others => (others => '0'));

  constant ZERO : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0) := (others => '0');

  signal we      : std_logic;
  signal re      : std_logic;
  signal out1    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal out2    : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal outreg2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal rs1_sel_latched : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal rs2_sel_latched : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);

  signal read_during_write1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal read_during_write2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_fwd_data1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_fwd_data2 : std_logic_vector(REGISTER_SIZE-1 downto 0);

  signal wb_data_latched : std_logic_vector(REGISTER_SIZE-1 downto 0);
  signal wb_sel_latched  : std_logic_vector(REGISTER_NAME_SIZE-1 downto 0);
  signal wb_en_latched   : std_logic;

--These aliases are useful during simulation of software.
  alias ra  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(1);
  alias sp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(2);
  alias gp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(3);
  alias tp  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(4);
  alias t0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(5);
  alias t1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(6);
  alias t2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(7);
  alias s0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(8);
  alias s1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(9);
  alias a0  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(10);
  alias a1  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(11);
  alias a2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(12);
  alias a3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(13);
  alias a4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(14);
  alias a5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(15);
  alias a6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(16);
  alias a7  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(17);
  alias s2  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(18);
  alias s3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(19);
  alias s4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(20);
  alias s5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(21);
  alias s6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(22);
  alias s7  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(23);
  alias s8  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(24);
  alias s9  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(25);
  alias s10 : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(26);
  alias s11 : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(27);
  alias t3  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(28);
  alias t4  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(29);
  alias t5  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(30);
  alias t6  : std_logic_vector(REGISTER_SIZE-1 downto 0) is registers(31);

  signal rdw1_en : std_logic;
  signal wbf1_en : std_logic;

begin

  we <= writeback_enable;
  re <= not stall;
  register_proc : process (clk) is
    variable read1 : std_logic_vector(REGISTER_SIZE-1 downto 0);
    variable read2 : std_logic_vector(REGISTER_SIZE-1 downto 0);
  begin
    if rising_edge(clk) then
      if we = '1' then
        registers(to_integer(unsigned(writeback_sel))) <= writeback_data;
      end if;
      out1 <= registers(to_integer(unsigned(rs1_sel)));
      out2 <= registers(to_integer(unsigned(rs2_sel)));
    end if;  --rising edge
  end process;

  read_during_write1 <= wb_data_latched when wb_en_latched = '1' and wb_sel_latched = rs1_sel_latched   else out1;
  wb_fwd_data1       <= writeback_data  when writeback_sel = rs1_sel_latched and writeback_enable = '1' else read_during_write1;

  read_during_write2 <= wb_data_latched when wb_en_latched = '1' and wb_sel_latched = rs2_sel_latched   else out2;
  wb_fwd_data2       <= writeback_data  when writeback_sel = rs2_sel_latched and writeback_enable = '1' else read_during_write2;

  process(clk) is
  begin
    if rising_edge(clk) then
      if stall = '0' then
        outreg1 <= wb_fwd_data1;
        outreg2 <= wb_fwd_data2;
      end if;

      rs1_sel_latched <= rs1_sel;
      rs2_sel_latched <= rs2_sel;

      wb_data_latched <= writeback_data;
      wb_sel_latched  <= writeback_sel;
      wb_en_latched   <= writeback_enable;

    end if;
  end process;


  rs1_data <= outreg1;
  rs2_data <= outreg2;


end architecture;
