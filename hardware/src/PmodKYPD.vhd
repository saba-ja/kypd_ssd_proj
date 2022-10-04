library IEEE;
use IEEE.STD_LOGIC_1164.all;
--use IEEE.STD_LOGIC_ARITH.all;
--use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;

entity PmodKYPD is
    port (
        clk : in STD_LOGIC;
        rst: in std_logic;
        kypd : inout STD_LOGIC_VECTOR (7 downto 0); -- PmodKYPD is designed to be connected to JA
        an : out std_logic; -- Controls which position of the seven segment display to display
        seg : out STD_LOGIC_VECTOR (6 downto 0);
        led_r: out std_logic;
        led_g: out std_logic;
        led_b: out std_logic;
        capture: in std_logic;
        show_hidden_num: in std_logic
        ); -- digit to display on the seven segment display 
end PmodKYPD;

architecture Behavioral of PmodKYPD is

    component Decoder is
        port (
            clk : in STD_LOGIC;
            rst : in STD_LOGIC;
            Row : in STD_LOGIC_VECTOR (3 downto 0);
            Col : out STD_LOGIC_VECTOR (3 downto 0);
            DecodeOut : out STD_LOGIC_VECTOR (3 downto 0)
            );
    end component;
    
    
    component DisplayController is
        port (
            DispVal : in STD_LOGIC_VECTOR (3 downto 0);
            segOut : out STD_LOGIC_VECTOR (6 downto 0));
    end component;
    
    component debounce is
    generic (
        clk_freq    : integer := 50_000_000; --system clock frequency in Hz
        stable_time : integer := 10);        --time button must remain stable in ms
    port (
        clk     : in std_logic;   --input clock
        rst : in std_logic;   --asynchronous active low reset
        button  : in std_logic;   --input signal to be debounced
        result  : out std_logic); --debounced signal
    end component;
    
     signal decode : STD_LOGIC_VECTOR (3 downto 0);
     signal decode_confirm: STD_LOGIC_VECTOR (3 downto 0);
     signal digit_sel: std_logic;
     
     constant CLK_CNT_WIDTH: integer := 20;
     signal clk_cnt: unsigned(CLK_CNT_WIDTH-1 downto 0);
     signal decode0: std_logic_vector(3 downto 0);
     signal decode1: std_logic_vector(3 downto 0);
     
     signal seg0: std_logic_vector(6 downto 0);
     signal seg1: std_logic_vector(6 downto 0);
     signal seg2: std_logic_vector(6 downto 0);
     
     signal hidden_num_counter: unsigned(3 downto 0);
     signal hidden_num_reg: unsigned(3 downto 0);
     signal capture_confirm: std_logic;
     signal show_hidden_num_confirm: std_logic;
     signal progress_status: std_logic_vector(2 downto 0);
     
     signal curr_user_input: std_logic_vector(3 downto 0);
     signal prev_user_input: std_logic_vector(3 downto 0);
     
      
begin

    DC0 : Decoder port map(clk => clk, rst => rst, Row => kypd(7 downto 4), Col => kypd(3 downto 0), DecodeOut => Decode);
    
    SD0: DisplayController port map(DispVal => Decode0, segOut => seg0);
    SD1: DisplayController port map(DispVal => Decode1, segOut => seg1);
    
    SD2: DisplayController port map(DispVal => std_logic_vector(hidden_num_reg), segOut => seg2);
    
    DB0: debounce port map(clk => clk, rst => rst, button => Decode(0) , result => decode_confirm(0));
    DB1: debounce port map(clk => clk, rst => rst, button => Decode(1) , result => decode_confirm(1));
    DB2: debounce port map(clk => clk, rst => rst, button => Decode(2) , result => decode_confirm(2));
    DB3: debounce port map(clk => clk, rst => rst, button => Decode(3) , result => decode_confirm(3));
    
    
    
    DB4: debounce port map(clk => clk, rst => rst, button => capture , result => capture_confirm);
    DB5: debounce port map(clk => clk, rst => rst, button => show_hidden_num, result => show_hidden_num_confirm);

    
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
        elsif rising_edge(clk) then
            if decode /= decode_confirm then
                digit_sel <= NOT digit_sel;
            else
--                if digit_sel = '0' then
                    decode0 <= decode;
                    prev_user_input <= curr_user_input;
                    curr_user_input <= decode;
--                else
--                    decode1 <= decode;
--                end if;
            end if;
        end if;
    end process;
    
    process(clk, rst)
    begin
        if rst = '1' then
            hidden_num_counter <= (others =>'0');
            hidden_num_reg <= (others =>'0');
        elsif rising_edge(clk) then
            hidden_num_counter <= hidden_num_counter + 1;
            
            if capture_confirm = '1' then
                hidden_num_reg <= hidden_num_counter;
            end if;
        end if;
    end process;
    
    process (clk, rst)
    variable curr_diff : integer := 0;
    variable prev_diff : integer := 0;
    begin
        if rst = '1' then
            
        elsif rising_edge(clk) then
             curr_diff := abs(to_integer(unsigned(hidden_num_reg)) - to_integer(unsigned(curr_user_input)));
             prev_diff := abs(to_integer(unsigned(hidden_num_reg)) - to_integer(unsigned(prev_user_input)));
              
             if std_logic_vector(hidden_num_reg) = curr_user_input then
                progress_status <= "010";
             elsif curr_diff > prev_diff then
                progress_status <= "100";
             elsif curr_diff < prev_diff then
                progress_status <= "001";
             else
                progress_status <= progress_status;
             end if;
                
        end if;
    
    end process;
    
    an <= '0'; --when show_hidden_num_confirm = '1' else clk_cnt(clk_cnt'high);
    
--    seg <= seg2 when show_hidden_num_confirm = '1' else 
--           seg0 when clk_cnt(clk_cnt'high) = '0' else 
--           seg1;

     seg <= seg2 when show_hidden_num_confirm = '1' else
            seg0;
            
     led_r <= progress_status(2);
     led_g <= progress_status(1); 
     led_b <= progress_status(0); 
   
end Behavioral;     

