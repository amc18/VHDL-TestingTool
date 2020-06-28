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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main is
    Port ( clk : in STD_LOGIC;
           rx : in STD_LOGIC;
           tx : out STD_LOGIC;
           cs : out std_logic;
           d1 : out  std_logic;
           d2 : out std_logic;
           sclk : out std_logic);
end main;
    
architecture Behavioral of main is

       signal sig_for_DUT_1 : std_logic_vector(15 downto 0);
       signal sig_for_DUT_2 :std_logic_vector(15 downto 0);
       signal sig_from_DUT : std_logic_vector(15 downto 0);
       signal sig_from_DUT_1 : std_logic_vector(15 downto 0); 
       signal sig_from_DUT_2 : std_logic_vector(15 downto 0);
       signal strb_DUT : std_logic;
       signal data1 : std_logic_vector(11 downto 0); -- output signal 1 for Pmod CNA (unsigned)
       signal data2 : std_logic_vector(11 downto 0); -- output signal 1 for Pmod CNA (unsigned)
       signal cnt : integer range 0 to 63;
       signal strb_pmodda2 : std_logic;
       
COMPONENT TestTool is
	  Port ( clk : in STD_LOGIC; 
           rx : in std_logic;   
           tx : out std_logic;  
           sig_A : out std_logic_vector(15 downto 0); 
           sig_B : out std_logic_Vector(15 downto 0); 
           sig_from_DUT : in std_logic_vector(15 downto 0);
           sig_strb : out std_logic 
           );
	 END COMPONENT;

COMPONENT DUT is	 
	 Port ( clk : in STD_LOGIC;
           strb_DUT : in STD_LOGIC;
           sig_input: in STD_LOGIC_VECTOR(15 downto 0);
           sig_output: out STD_LOGIC_VECTOR(15 downto 0)
           );
     END COMPONENT;

COMPONENT Int_Pmod_DA2
	PORT(
	   CLK : in  STD_LOGIC;
           CS : out  STD_LOGIC;
	   D1 : out std_logic;
	   D2 : out std_logic;
           SCLK : out  STD_LOGIC;
           DATA1 : in  STD_LOGIC_VECTOR (11 downto 0);
           DATA2 : in  STD_LOGIC_VECTOR (11 downto 0);
	   STRB : IN STD_LOGIC);
 END COMPONENT;
 
begin
    
    Inst_TestTool: TestTool PORT MAP(
 	clk => clk, 
        rx => rx,   
        tx => tx,   
        sig_A => sig_for_DUT_1, 
        sig_B => sig_for_DUT_2, 
        sig_from_DUT => sig_from_DUT, 
        sig_strb => strb_DUT 
    );
    
    Inst_DUT: DUT PORT MAP(
        clk => clk,
        strb_DUT => strb_DUT,
        sig_input => sig_for_DUT_1,
        sig_output => sig_from_DUT
     );
    
    Inst_Int_Pmod_DA2: Int_Pmod_DA2 PORT MAP(
	CLK => clk,
        CS => cs,
	D1 => d1,
        D2 => d2,
        SCLK => sclk,
        DATA1 => data1,
        DATA2 => data2,
		STRB => strb_pmodda2
	 );
	
    process(clk)
	begin
		if rising_edge(clk) then
			cnt <= cnt + 1;
			strb_pmodda2 <= '0';
			if cnt = 0 then
				strb_pmodda2 <= '1';
		        data1 <= not(sig_for_DUT_1(15)) & sig_for_DUT_1(14 downto 4);
			    data2 <= not(sig_from_DUT(15)) & sig_from_DUT(14 downto 4);
			end if;
		end if;
	end process;

end Behavioral;
