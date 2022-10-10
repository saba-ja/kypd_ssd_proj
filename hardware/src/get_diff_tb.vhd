library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity get_diff_tb is
--  Port ( );
end get_diff_tb;

architecture Behavioral of get_diff_tb is

      function get_diff(value1: integer; value2: integer) return integer is
        variable a: signed(31 downto 0);
        variable b: signed(31 downto 0);
        variable r: integer; 
      begin
        a := to_signed(value1, 32);
        b := to_signed(value2, 32);
        r := to_integer(abs(a - b));
        return r;
      end function;
      
      signal v1: integer;
      signal v2: integer;
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
    v1 <= 10;
    v2 <= 5;
    result <= get_diff(v1, v2);
    wait for 10 ns;

    v1 <= 3;
    v2 <= 10;
    result <= get_diff(v1, v2);
    wait for 10 ns;
    v1 <= 20;
    v2 <= 9;
    result <= get_diff(v1, v2);
    wait for 10 ns;
    v1 <= 10;
    v2 <= 3;
    result <= get_diff(v1, v2);
    wait for 10 ns;
    wait;
 end process;

end Behavioral;
