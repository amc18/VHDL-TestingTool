-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 17/05/2020
-- Module Name: TestTool - Behavioral
-- Project Name: TestTool
-- Target Devices: Basys3
-- Tool Versions: 1.0
-- Description: 
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity DUT is
    Port ( clk : in STD_LOGIC;
           strb_DUT : in STD_LOGIC;
           sig_input: in STD_LOGIC_VECTOR(15 downto 0);
           sig_output: out STD_LOGIC_VECTOR(15 downto 0)
           );
end DUT;

architecture Behavioral of DUT is

signal fir1 : std_logic_vector(15 downto 0);
signal fir2 : std_logic_vector(15 downto 0);  
signal cmpt_fir : integer range 0 to 20;
signal clk_fir :std_logic;
signal clk_fir_r :std_logic;

begin
process(clk)
	begin
		if rising_edge(clk) then
		  if strb_DUT='1' then
			cmpt_fir <= cmpt_fir + 1;
			clk_fir <= '0';
			if cmpt_fir = 19 then 
				clk_fir <= '1';
				cmpt_fir <= 0;
			end if;
		  end if;
		end if;
	end process;
	
	process(clk)
	begin
	   if rising_edge(clk) then
	            clk_fir_r <= clk_fir;
	            if clk_fir_r='1' and clk_fir='0' then
	                 fir1 <= sig_input(15)&sig_input(15 downto 1);
	                 fir2 <= fir1;
	                 sig_output <= fir1 + fir2;
	       end if;
	   end if;
	end process;

end Behavioral;
