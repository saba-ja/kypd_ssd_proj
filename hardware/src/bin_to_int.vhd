library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bin_to_int_tb is
--  Port ( );
end bin_to_int_tb;

architecture Behavioral of bin_to_int_tb is


      function bin2int(left_digit: std_logic_vector(3 downto 0); right_digit: std_logic_vector(3 downto 0)) return integer is
        variable result : integer := 0;
        variable l_dig : integer := 0;
        variable r_dig : integer := 0;
      begin
        l_dig := to_integer(unsigned(left_digit)) * 10;
        r_dig := to_integer(unsigned(right_digit));
        result := l_dig + r_dig;
        return result;
      end function;
      signal v1:  std_logic_vector(3 downto 0);
      signal v2:  std_logic_vector(3 downto 0);
      signal result: integer;

      signal clk: std_logic;
begin

process
begin
    clk <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
end process;

process
begin
    v1 <= "0001";
    v2 <= "0001";
    result <= bin2int(v1, v2);
    wait for 10 ns;

    v1 <= "0011";
    v2 <= "1000";
    result <= bin2int(v1, v2);
    wait for 10 ns;
    v1 <= "0010";
    v2 <= "1001";
    result <= bin2int(v1, v2);
    wait for 10 ns;
    v1 <= "0111";
    v2 <= "0011";
    result <= bin2int(v1, v2);
    wait for 10 ns;
    v1 <= "0000";
    v2 <= "0000";
    result <= bin2int(v1, v2);
    wait;
 end process;

end Behavioral;
