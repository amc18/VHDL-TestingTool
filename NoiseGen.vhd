-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: NoiseGen - Behavioral
-- Project Name: TestTool
-- Target Devices: Basys 3
-- Tool Versions: 1.0
-- Description: Noise generator controlled by C++ interface, 
--              using RS-232 communication.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity NoiseGen is
    Port(  clk : in STD_LOGIC;                           -- clock
           allow : in STD_LOGIC;                         -- allow generator to work
           sig_m : in STD_LOGIC_VECTOR (31 downto 0);    -- random number
           sig_out : out STD_LOGIC_VECTOR(15 downto 0)); -- generated signal (signed)  
end NoiseGen;

architecture Behavioral of NoiseGen is
    
    signal a : std_logic_vector (31 downto 0);
    signal b : std_logic_vector (31 downto 0);
    signal c : std_logic_vector (31 downto 0);
    
begin
    -- VHDL implemention of Xorshift pseudorandom number generator
    process(clk)
    begin
        if rising_edge(clk) then
            case allow is
                when '0' => a <= (sig_m XOR (sig_m(18 downto 0)&"0000000000000")); -- Xorshift set up
                            b <= (a XOR ("00000000000000000"&a(31 downto 17)));
                            c <= sig_m;               
                when others => a <= (c XOR (c(18 downto 0)&"0000000000000"));
                               b <= (a XOR ("00000000000000000"&a(31 downto 17)));
                               c <= (b XOR (b(26 downto 0)&"00000"));
                               sig_out<=c(15 downto 0);
            end case;
        end if;
    end process;

end Behavioral;
