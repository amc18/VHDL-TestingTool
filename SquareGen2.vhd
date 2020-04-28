-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: SquareGen2 - Behavioral
-- Project Name: TestTool
-- Target Devices: Nexys 4
-- Tool Versions: 1.0
-- Description: Square signal generator controlled by C++ interface, 
--              using RS-232 communication.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity SquareGen2 is
    Port ( clk : in STD_LOGIC;                           -- clock
           allow : in STD_LOGIC;                         -- allow generator to work
           sig_m : in STD_LOGIC_VECTOR (31 downto 0);    -- according word for frequency
           sig_c : in STD_LOGIC_VECTOR (15 downto 0);    -- duty cycle coefficient
           sig_out : out STD_LOGIC_VECTOR(15 downto 0)); -- generated signal (signed) 
end SquareGen2;

architecture Behavioral of SquareGen2 is
    signal sig_pa : std_logic_vector(31 downto 0);
    
begin
    --Phase accumulator
    process(clk)
    begin 
        if rising_edge(clk) and allow='1' then
             sig_pa<=sig_pa+sig_m;
             if (sig_pa(31 downto 16)) > sig_c then -- comparation with duty cycle coeffient
                sig_out<="1000000000000001";        
             else sig_out<="0111111111111111";
             end if;
        end if;
    end process;

end Behavioral;