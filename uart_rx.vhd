--------------------------------------------------------------------------------
-- interface port série
-- Pour utiliser cette interface, il faut lui donner une horloge et un signal "clk enable"
-- il rend sur DOUT les 8 bits reçu plus un signal STRB
-- le DOUT est à échantillonné quand, sur le front montant de l'horloge, STRB est '1' 
-- UART: 
-- RS232, 8 bit whitout parity
-- EN_16xRATE = bit_rate*16 (pour 19200, il doit etre à 307200)
-- exemple d'un process à écrire dans le programme principale pour générer le signa EN_16xRATE
-- Baud rate = 19200 et CLK à 100 MHz
--
--	process(MCLK)
--	begin
--		if MCLK'event and MCLK='1' then
--			cmpt <= cmpt + 1;
--			EN_16xRATE <= '0';
--			if cmpt = 325 then
--				EN_16xRATE <= '1';
--				cmpt <= 0;
--			end if;
--		end if;
--	end process;
--
--
-- Vahid Meghdadi 
-- Mars 2006
-- Révision 2012
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_rx is
    Port ( CLK : in std_logic;
           EN_16xRATE : in std_logic;
           RX : in std_logic;
           DOUT : out std_logic_vector(7 downto 0);
           STRB : out std_logic);
end uart_rx;

architecture Behavioral of uart_rx is
	type t_etat is (attente, start_bit, recevoir, done);
	signal etat : t_etat;
	signal cmpt, cmpt_bit : integer range 0 to 15;
	signal r_reg : std_logic_vector(8 downto 0);
begin
	process(CLK)
	begin
		if CLK'event and CLK='1' then
			STRB <= '0';
			if EN_16xRATE = '1' then
				case etat is
				when attente =>
					cmpt <= 0;
					cmpt_bit <= 0;
					STRB <= '0';
					if RX='1' then etat <= attente;
					else etat <= start_bit;
					end if;
				when start_bit =>
					cmpt <= cmpt + 1;
					if cmpt = 6 then -- c'est sur le 8 ieme front montant que l'on echantillone
						cmpt <= 0;
						etat <= recevoir;
					else
						etat <= start_bit;
					end if;
				when recevoir =>
					cmpt <= cmpt + 1;
					if cmpt = 15 then	-- echantillonne tous les 16 fronts montant
						r_reg <= RX & r_reg(8 downto 1);
						cmpt <= 0;
						cmpt_bit <= cmpt_bit + 1;
						if cmpt_bit = 8 then	-- recuperer 9 bits
							etat <= done;
						else
							etat <= recevoir;
						end if;
					else
						etat <= recevoir;
					end if;
				when done =>
					if r_reg(8)='1' then
						STRB <= '1';
						DOUT <= r_reg(7 downto 0);
						etat <= attente;
					else
						etat <= attente;
					end if;
				when others =>
					etat <= attente;
				end case;
			end if;
		end if;
	end process;

end Behavioral;