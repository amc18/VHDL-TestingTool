-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: TriangleGen2 - Behavioral
-- Project Name: TestTool
-- Target Devices: Basys 3
-- Tool Versions: 1.0
-- Description: Triangle signal generator controlled by C++ interface, 
--              using RS-232 communication.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity TriangleGen2 is
    Port ( clk : in STD_LOGIC;                           -- clock
           allow : in STD_LOGIC;                         -- allow generator to work
           sig_m : in STD_LOGIC_VECTOR (31 downto 0);    -- rising ramp according word for frequency 
           sig_n : in STD_LOGIC_VECTOR (31 downto 0);    -- falling ramp according word for frequency
           sig_out : out STD_LOGIC_VECTOR(15 downto 0)); -- generated signal (signed) 
end TriangleGen2;

architecture Behavioral of TriangleGen2 is

    signal sig_pa : std_logic_vector(32 downto 0);

    
begin
    -- Phase accumulator
    process(clk)
    begin 
        if rising_edge(clk) then   
            if allow='1' then
                 if sig_pa(32)='0' then
                     sig_pa<=sig_pa+('0'&sig_m); 
                     sig_out<=not(sig_pa(31)) & sig_pa(30 downto 16); -- rising ramp
                 else 
                     sig_pa<=sig_pa+('0'&sig_n); 
                     sig_out<=sig_pa(31) & not(sig_pa(30 downto 16)); -- falling ramp
               end if; 
            else 
                 sig_pa <= (others => '0');
            end if;
        end if;
    end process;

end Behavioral;