library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity number_select is
    Port ( clk : in STD_LOGIC;
           rst : in STD_LOGIC;
           en : in std_logic;
           is_max_10: in std_logic;
           actual_num: out std_logic_vector(6 downto 0);
           left_dig: out std_logic_vector(3 downto 0);
           right_dig: out std_logic_vector(3 downto 0)
           );
end number_select;

architecture Behavioral of number_select is

     constant COUNTER_MAX : integer := 99;
     subtype counter_range is natural range 0 to COUNTER_MAX;
     signal hidden_num_counter: counter_range; 
     signal hidden_num_reg: counter_range;
     signal hidden_num_reg_left_dig: natural range 0 to 9;
     signal hidden_num_reg_right_dig:natural range 0 to 9;


begin

    process(clk, rst)
    begin
        if rst = '1' then
            hidden_num_counter <= 0;
            hidden_num_reg_left_dig <= 0;
            hidden_num_reg_right_dig <= 0;
        elsif rising_edge(clk) then
            if hidden_num_counter < COUNTER_MAX then
                if en = '1' then
                    hidden_num_counter <= hidden_num_counter + 1;
                end if;
            else
                hidden_num_counter <= 1;
            end if;
                hidden_num_reg  <= hidden_num_counter;
                hidden_num_reg_left_dig <= hidden_num_counter / 10;
                hidden_num_reg_right_dig <= hidden_num_counter - ((hidden_num_counter / 10) * 10);
        end if;
    end process;

   actual_num <= std_logic_vector(to_unsigned(hidden_num_reg_right_dig, 7)) when is_max_10 = '1' else std_logic_vector(to_unsigned(hidden_num_reg, 7));
   left_dig <= std_logic_vector(to_unsigned(hidden_num_reg_left_dig,4));
   right_dig <= std_logic_vector(to_unsigned(hidden_num_reg_right_dig,4)); 

end Behavioral;
