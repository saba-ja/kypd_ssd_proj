library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity blinky_tb is
--  Port ( );
end blinky_tb;

architecture Behavioral of blinky_tb is

component blinky is
    Generic(
        BLINK_COUNT: integer := 10;
        FREQ_OUT: integer  := 4;
        FREQ_IN: integer := 50000000
    );
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           dis : in std_logic;
           sig_in : in STD_LOGIC;
           sig_out : out STD_LOGIC);
end component;

signal clk_tb : STD_LOGIC;
signal rst_tb : STD_LOGIC;
signal dis_tb : std_logic;
signal sig_in_tb : STD_LOGIC;
signal sig_out_tb : STD_LOGIC;

constant cp: time := 10ns;
begin

bl0: blinky generic map(BLINK_COUNT=> 10, FREQ_OUT=> 4, FREQ_IN=>80)
            port map(clk => clk_tb, rst => rst_tb, dis => dis_tb, sig_in => sig_in_tb, sig_out => sig_out_tb);

process
begin
    clk_tb <= '1';
    wait for cp/2;
    clk_tb <= '0';
    wait for cp/2;
end process;


process
begin
    rst_tb <= '1';
    sig_in_tb <= '0';
    dis_tb <= '0';
    wait for cp;
    rst_tb <= '0';
    wait for cp;
    sig_in_tb <= '1';
    wait for 40 * cp;
    sig_in_tb <= '0';
    wait for cp;
    sig_in_tb <= '1';
    wait for 40 * cp;    
    wait;
end process;

end Behavioral;
