library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity PmodKYPD is
    port (
        clk : in STD_LOGIC;
        rst: in std_logic;
        kypd : inout STD_LOGIC_VECTOR (7 downto 0); -- PmodKYPD is designed to be connected to JA
        an : out std_logic;                         -- Controls which position of the seven segment display to display
        seg : out STD_LOGIC_VECTOR (6 downto 0);
        led_r: out std_logic;
        led_g: out std_logic;
        led_b: out std_logic;
        capture: in std_logic;
        sw_level_select: in std_logic;
        show_hidden_num: in std_logic;
        led: out std_logic_vector(3 downto 0)
        ); 
end PmodKYPD;

architecture Behavioral of PmodKYPD is

    component Decoder is
        port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            Row : in STD_LOGIC_VECTOR (3 downto 0);
            Col : out STD_LOGIC_VECTOR (3 downto 0);
            DecodeOut : out STD_LOGIC_VECTOR (3 downto 0);
            is_a_key_pressed: out std_logic
            );
    end component;
    
    
    component DisplayController is
        port (
            DispVal : in STD_LOGIC_VECTOR (3 downto 0);
            segOut : out STD_LOGIC_VECTOR (6 downto 0));
    end component;
    
    component debounce is
    generic (
        clk_freq    : integer; 
        stable_time : integer;
        input_width : integer
        );        
    port (
            clk     : in std_logic;   
            rst : in std_logic;   
            button  : in std_logic;
            continuous_result  : out std_logic;
            pulse_result : out std_logic); 
    end component;


    component number_select is
        Port ( clk : in STD_LOGIC;
               rst : in STD_LOGIC;
               en : in std_logic;
               is_max_10: in std_logic;
               actual_num: out std_logic_vector(6 downto 0);
               left_dig: out std_logic_vector(3 downto 0);
               right_dig: out std_logic_vector(3 downto 0)
               );
    end component;
    
    constant clk_freq    : integer := 50_000_000; 
    constant stable_time : integer := 10;
    constant KYPD_INPUT_WIDTH : integer := 4;
   
     signal decode : STD_LOGIC_VECTOR (3 downto 0);
     
     signal kypd_pressed_confirm: std_logic;
     signal is_kypd_pressed: std_logic;
     
     signal digit_sel: std_logic;
     
     constant CLK_CNT_WIDTH: integer := 20;
     signal clk_cnt: unsigned(CLK_CNT_WIDTH-1 downto 0);
     
     signal decode0: std_logic_vector(3 downto 0);
     signal decode1: std_logic_vector(3 downto 0);
     
     signal seg0: std_logic_vector(6 downto 0);
     signal seg1: std_logic_vector(6 downto 0);
     signal seg2: std_logic_vector(6 downto 0);
     signal seg3: std_logic_vector(6 downto 0);
     
     subtype counter_range is integer range 0 to 99;
     
     signal level1_hidden_num:  std_logic_vector(6 downto 0);
     signal level1_left_dig:  std_logic_vector(3 downto 0);
     signal level1_right_dig: std_logic_vector(3 downto 0);

     signal level2_hidden_num: std_logic_vector(6 downto 0);
     signal level2_left_dig: std_logic_vector(3 downto 0);
     signal level2_right_dig:std_logic_vector(3 downto 0);

     signal hidden_num_reg:  integer;
     signal hidden_num_reg_left_dig: std_logic_vector(3 downto 0);
     signal hidden_num_reg_right_dig: std_logic_vector(3 downto 0);

     signal is_capture_btn_pressed: std_logic;
     
     signal continue_showing_hidden_num: std_logic;
     signal is_show_hidden_num_btn_pressed: std_logic;
     
     signal progress_status: std_logic_vector(2 downto 0);
     
     signal curr_user_input:  integer; 
     signal prev_user_input:  integer;
     
     type calc_prog_state_t is (disable, enable);
     signal calc_prog_state : calc_prog_state_t;  
      
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
      
begin

    NM0: number_select port map(clk => clk, rst => rst, en => '1', is_max_10 => '1', 
                                actual_num => level1_hidden_num, left_dig => level1_left_dig, right_dig => level1_right_dig);
    NM1: number_select port map(clk => clk, rst => rst, en => '1', is_max_10 => '0', 
                                actual_num => level2_hidden_num, left_dig => level2_left_dig, right_dig => level2_right_dig);

    process(clk, rst)
    begin
        if rst = '1' then
            hidden_num_reg <= 0;
            hidden_num_reg_left_dig <= (others=>'0');
            hidden_num_reg_right_dig <= (others=>'0');
        elsif rising_edge(clk) then
            if is_capture_btn_pressed = '1' then
                if sw_level_select = '1' then
                    hidden_num_reg <= to_integer(unsigned(level2_hidden_num));
                    hidden_num_reg_left_dig <= level2_left_dig;
                    hidden_num_reg_right_dig <= level2_right_dig;
                else
                    hidden_num_reg <= to_integer(unsigned(level1_hidden_num));
                    hidden_num_reg_left_dig <= (others=>'0');
                    hidden_num_reg_right_dig <= level1_right_dig;
                end if;                
            end if; 
        end if;
    end process;

    DC0 : Decoder port map(clk => clk, 
                           rst => rst, 
                           Row => kypd(7 downto 4), 
                           Col => kypd(3 downto 0), 
                           DecodeOut => Decode,
                           is_a_key_pressed => is_kypd_pressed);
    
    SD0: DisplayController port map(DispVal => decode0, segOut => seg0); -- right digit
    SD1: DisplayController port map(DispVal => decode1, segOut => seg1); -- left digit
    SD2: DisplayController port map(DispVal => std_logic_vector(hidden_num_reg_right_dig), segOut => seg2);
    SD3: DisplayController port map(DispVal => std_logic_vector(hidden_num_reg_left_dig), segOut => seg3);
    
    
    DB: debounce generic map(clk_freq => clk_freq, stable_time => stable_time, input_width => 1)
                 port map(clk => clk, 
                          rst => rst, 
                          button => is_kypd_pressed, 
                          continuous_result => open, 
                          pulse_result => kypd_pressed_confirm);

    DB4: debounce generic map(clk_freq => clk_freq, stable_time => stable_time, input_width => 1)
                  port map(clk => clk, 
                           rst => rst, 
                           button => capture, 
                           continuous_result => open,
                           pulse_result => is_capture_btn_pressed);
    
    DB5: debounce generic map(clk_freq => clk_freq, stable_time => stable_time, input_width => 1) 
                  port map(clk => clk, 
                           rst => rst, 
                           button => show_hidden_num, 
                           continuous_result => continue_showing_hidden_num,
                           pulse_result => is_show_hidden_num_btn_pressed);
   
    process(clk, rst)
    begin
        if rst = '1' then
            clk_cnt <= (others => '0');
        elsif rising_edge(clk) then
            clk_cnt <= clk_cnt + 1;
        end if;
    end process;
    
    
    process(clk, rst)
    begin
        if rst = '1' then
            digit_sel <= '0';
            decode0 <= (others => '0');
            decode1 <= (others => '0');
            calc_prog_state <= disable;
            prev_user_input <= 0;
            curr_user_input <= 0;
        elsif rising_edge(clk) then
            calc_prog_state <= disable;
            if kypd_pressed_confirm = '1' then
            
                if sw_level_select = '1' then
                    digit_sel <= NOT digit_sel;
    
                    if digit_sel = '0' then
                        decode1 <= decode;
                    elsif digit_sel = '1' then
                        decode0 <= decode;
                        prev_user_input <= curr_user_input;
                        curr_user_input <= bin2int(decode1, decode);
                        calc_prog_state <= enable;
                    end if;
                 else
                     digit_sel <= '0';
                     decode0 <= decode;
                     decode1 <= (others=>'0');
                     prev_user_input <= curr_user_input;
                     curr_user_input <= bin2int("0000", decode);
                     calc_prog_state <= enable;
                 end if;
            end if;
        end if;
    end process;
    
   
    process (clk, rst)
        variable curr_diff : integer := 0;
        variable prev_diff : integer := 0;
    begin
        if rst = '1' then
            progress_status <= (others => '0');
        elsif rising_edge(clk) then    
            if calc_prog_state = enable then       
                 curr_diff := get_diff(hidden_num_reg, curr_user_input);
                 prev_diff := get_diff(hidden_num_reg, prev_user_input);
                  
                 if hidden_num_reg = 0 then
                    progress_status <= "000";
                 elsif (curr_diff = 0) then
                    progress_status <= "010"; -- Turne on green
                 elsif curr_diff <= prev_diff then
                    progress_status <= "100";  -- Turne on red
                 elsif curr_diff > prev_diff then
                    progress_status <= "001";  -- Turne on blue
                 else
                    progress_status <= "111";
                 end if;
            end if;                    
        end if;
    end process;
    
    
    process(clk_cnt'high, continue_showing_hidden_num)
    begin
        if clk_cnt(clk_cnt'high) = '0' then
            if continue_showing_hidden_num = '1' then
                seg <= seg2;
            else
                seg <= seg0;
            end if;
        else
            if continue_showing_hidden_num = '1' then
                seg <= seg3;
            else
                seg <= seg1;
            end if;
       end if;   
    end process;
    an <= clk_cnt(clk_cnt'high);
    

     led_r <= progress_status(2);
     led_g <= progress_status(1); 
     led_b <= progress_status(0); 
     led <= std_logic_vector(to_unsigned(prev_user_input,4));
end Behavioral;