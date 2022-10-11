library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.math_real.all;

entity blinky is
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
end blinky;

architecture Behavioral of blinky is

signal ff_0: std_logic;
signal ff_1: std_logic;
signal counter: integer range 0 to FREQ_IN;
constant MID_POINT : integer := (FREQ_IN/(2*FREQ_OUT));
constant MAX_POINT : integer := FREQ_IN;

signal en : std_logic;
signal run_counter : std_logic;
signal slow_clk : std_logic;

signal blink_counter: integer range 0 to (2*BLINK_COUNT) -1;
signal sig_out_reg : std_logic;

signal fast_clk_counter : integer;

begin

process(clk, rst)
begin
    if rst = '1' then
        fast_clk_counter <= 0;
    elsif rising_edge(clk) then
        if fast_clk_counter < FREQ_IN-1 then
            fast_clk_counter <= fast_clk_counter + 1;
        else
            fast_clk_counter <= 0;
        end if;
    end if;
end process;

process(clk, rst)
begin
    if rst = '1' then
        ff_0 <= '0';
        ff_1 <= '0';
        en <= '0';
        run_counter <= '0';
    elsif rising_edge(clk) then
        ff_0 <= sig_in;
        ff_1 <= ff_0;
        
        en <= not ff_1 and ff_0;
        
        if en = '1' then
            run_counter <= '1';
        elsif blink_counter = (2*BLINK_COUNT) - 1 then
            run_counter <= '0';
        else 
            run_counter <= run_counter;
        end if;
          
    end if;
end process;


process(clk, rst)
begin
    if rst = '1' then
        counter <= 0;
        slow_clk <= '0';
    elsif rising_edge(clk) then
        counter <= counter + 1;
        if counter = MID_POINT-1 then
            slow_clk <= NOT slow_clk;
            counter <= 0;
        end if; 
    end if;
end process;


process(slow_clk, rst)
begin
    if rst = '1' then
        blink_counter <= 0;
        sig_out_reg <= '0';
    elsif rising_edge(slow_clk) then
    
        if dis = '1' then
            sig_out_reg <= '0';
            blink_counter <= 0;
        elsif run_counter = '0' then
            sig_out_reg <= sig_out_reg;
            blink_counter <= 0;
        elsif run_counter = '1' then
            blink_counter <= blink_counter + 1;
            sig_out_reg <= NOT sig_out_reg;
        end if;
    end if;
end process;

sig_out <= sig_out_reg;

end Behavioral;
