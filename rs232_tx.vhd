-- The User must define the clock (100Mhz) and the baud rate (en_115200) 
--  process(clk)
--	begin
--		if rising_edge(clk) then
--			cpt_115200 <= cpt_115200 + 1;
--			EN_115200 <= '0';
--			if cpt_115200 = 868 then --115200 bauds
--				EN_115200 <= '1';
--				cpt_115200 <= 0;
--			end if;
--		end if;
--	end process;
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity rs232_tx is
    Port ( CLK : in  STD_LOGIC;
           DATA : in  STD_LOGIC_VECTOR (7 downto 0);
           STRB : in  STD_LOGIC;
           EN_115200 : in std_logic;
           TX : out  STD_LOGIC;
           BUSY : out std_logic);
end rs232_tx ;

architecture Behavioral of rs232_tx  is
    signal cmp : integer range 0 to 8191:=0;
    signal cmpt_bit : integer range 0 to 15:=0;
    type T_ETAT is (attente, envoi);
    signal etat, next_etat : T_ETAT := attente;
    signal cmpt_rst : std_logic:='0';
    signal reg : std_logic_vector(11 downto 0):="000000000001";
begin

    TX <= reg(cmpt_bit);
    cmpt_rst <= '1' when etat = attente else '0';
    BUSY <= '0' when etat = attente else '1';
    
    process(CLK)
    begin
        if CLK'event and CLK='1' then
            if STRB = '1' then 
                reg <= "11" & DATA & "01";
            end if;    
        end if;
    end process;

    
    compteur_bit:process(CLK)
    begin
        if CLK'event and CLK='1' then
            if cmpt_rst = '1' then 
                cmpt_bit <= 0;
            elsif en_115200 = '1' then
                cmpt_bit <= cmpt_bit + 1;
            end if;
        end if;
    end process;

    process(etat, cmpt_bit, STRB)
    begin
        case etat is
        when attente =>
            if STRB = '1' then
                next_etat <= envoi;
            else
                next_etat <= attente;
            end if;
        when others => -- envoie
            if cmpt_bit = 11 then
                next_etat <= attente;
            else 
                next_etat <= envoi;
            end if;
        end case;        
    end process;
    
    process(CLK)
    begin
        if CLK'event and CLK='1' then
            etat <= next_etat;
        end if;
    end process;


end Behavioral;