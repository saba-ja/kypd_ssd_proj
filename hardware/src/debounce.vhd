--------------------------------------------------------------------------------
--
--   FileName:         debounce.vhd
--   Dependencies:     none
--   Design Software:  Quartus Prime Version 17.0.0 Build 595 SJ Lite Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 2.0 6/28/2019 Scott Larson
--     Added asynchronous active-low reset
--     Made stable time higher resolution and simpler to specify
--   Version 1.0 3/26/2012 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity debounce is
    generic (
        clk_freq    : integer := 50_000_000; --system clock frequency in Hz
        stable_time : integer := 10; --        --time button must remain stable in ms
        input_width : integer := 4);
    port (
        clk     : in std_logic;   
        rst : in std_logic;   
        button  : in std_logic_vector(input_width-1 downto 0);   
        continuous_result  : out std_logic_vector(input_width-1 downto 0);
        pulse_result : out std_logic
        ); 
end debounce;

architecture logic of debounce is
    signal flipflop0   : std_logic_vector(input_width-1 downto 0);
    signal flipflop1   : std_logic_vector(input_width-1 downto 0);
    signal pulse_reg0 : std_logic;
    signal pulse_reg1 : std_logic;
    signal continuous_result_reg : std_logic_vector(input_width-1 downto 0);
    signal counter_set : std_logic;             

    constant MAX_COUNT: integer := clk_freq * stable_time/1000; --counter for timing
    signal count : integer range 0 to MAX_COUNT; 
    signal en_counter : std_logic;
    
  
begin
    counter_set <= '1' when flipflop0 /= flipflop1 else '0'; --determine when to start/reset counter

    process (clk, rst)
        
    begin
        if (rst = '1') then              
            flipflop0 <= (others => '0');
            flipflop1 <= (others => '0');
            pulse_reg0 <= '0'; 
            pulse_reg1 <= '0';
            count <= 0;
            en_counter <= '0';
            continuous_result_reg <= (others => '0'); 
            
        elsif (clk'EVENT and clk = '1') then             
            
            flipflop0 <= button;                         
            flipflop1 <= flipflop0;                    
            
            if (counter_set = '1') then                
                count <= 0;
                en_counter <= '1'; 
                continuous_result_reg <= (others=>'0');
                pulse_reg0 <= '0';
                pulse_reg1 <= '0';
            
            elsif (count < MAX_COUNT AND en_counter = '1') then 
                count <= count + 1;
                if (count = MAX_COUNT-1) then
                    pulse_reg0 <= '1';
                else                          
                    pulse_reg0 <= '0';
                end if;
            elsif  (count = MAX_COUNT) then                
                en_counter <= '0';                          
                continuous_result_reg <= flipflop1;
                pulse_reg1 <= pulse_reg0;          
            
            else
                continuous_result_reg <= continuous_result_reg;
                
            end if;
        end if;
    end process;

continuous_result <= continuous_result_reg;
pulse_result <= pulse_reg0 and (not pulse_reg1);

end logic;
