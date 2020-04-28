-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: Bode_Plot - Behavioral
-- Project Name: TestTool
-- Target Devices: Nexys 4
-- Tool Versions: 1.0
-- Description: Bode plot function controlled by C++ interface, 
--              using RS-232 communication.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity Bode_Plot is
    Port ( clk : in std_logic;
    data_dut_in : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_in_sync : in std_logic;
    data_out : out std_logic_vector(7 downto 0); 
    data_out_bode: out std_logic_vector(15 downto 0);
    busy : in std_logic;
    done : out std_logic;
    allow : in std_logic;
    strb: out std_logic
     );
end Bode_Plot;

architecture Behavioral of Bode_Plot is

type r_state is (Waiting,PreWaiting,Start); -- states of the reception machine
type bode_state is (Waiting,PreWaiting,Ending,Send_Data,Measure,Pre_Measure); -- states of the Bode plot machine

signal state_in : r_state :=Waiting;
signal b_state : bode_state:=Waiting;
signal num_data : std_logic_vector(7 downto 0); -- signal used for data's reception
signal bode_begin : std_logic_vector(31 downto 0); -- starting frequencu
signal bode_step : std_logic_vector(31 downto 0); -- step frequency
signal bode_end : std_logic_vector(31 downto 0); -- ending frequency

signal sig_pa : std_logic_vector(36 downto 0); -- phase accumulator
signal sig_m : std_logic_vector(31 downto 0); -- step incrementation of phase accumulator
signal sig_rom_sinus : std_logic_vector(11 downto 0);  -- choosing register of rom (sinus)
signal sig_sinus : std_logic_vector(15 downto 0);  -- sinus signal
signal sig_sinus_r: std_logic_vector(15 downto 0); -- retarded sinus of 1 clock stroke

signal allow_r :std_logic; -- retarded allow signal of 1 clock stroke
signal num_byte: std_logic_vector(3 downto 0); -- signal used for data's emission

signal amplitude_dut : std_logic_vector(15 downto 0); -- amplitude of dut signal
signal phase : std_logic_vector(31 downto 0);         -- phase of dut signal
signal data_dut_in_r: std_logic_vector(15 downto 0);  -- retarded sinus of 1 clock stroke
signal done_phase : std_logic_vector(1 downto 0);     -- 
signal phase1 :std_logic_vector(31 downto 0);         -- 
signal phase2 :std_logic_vector(31 downto 0);         --

    COMPONENT blk_mem_gen_0
    PORT (
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clka : in std_logic;
    ena : in std_logic
    );
    END COMPONENT;

begin
    
    Inst_blk_mem_gen_0:blk_mem_gen_0 PORT MAP(
    addra => sig_rom_sinus,
    douta => sig_sinus,
    clka => clk,
    ena => '1'
    );
    
    sig_rom_sinus<=sig_pa(31 downto 20);
    
    -- reception of data
    
    process(clk)
    begin
        if rising_edge(clk) and data_in_sync='1' then
            case state_in is 
                when Waiting => 
                    if data_in/="00000000" then
                        state_in <= Start;
                    end if;
                when Start =>
                    case num_data is
                        when "00000000" => bode_begin(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" => bode_begin(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => bode_begin(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => bode_begin(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => bode_step(7 downto 0)<=data_in;
                                           num_data<="00000101";
                        when "00000101" => bode_step(15 downto 8)<=data_in;
                                           num_data<="00000110";
                        when "00000110" => bode_step(23 downto 16)<=data_in;
                                           num_data<="00000111";
                        when "00000111" => bode_step(31 downto 24)<=data_in;
                                           num_data<="00001000";
                        when "00001000" => bode_end(7 downto 0)<=data_in;
                                           num_data<="00001001";
                        when "00001001" => bode_end(15 downto 8)<=data_in;
                                           num_data<="00001010";
                        when "00001010" => bode_end(23 downto 16)<=data_in;
                                           num_data<="00001011";
                        when "00001011" => bode_end(31 downto 24)<=data_in;
                                           state_in <= PreWaiting;
                                           done <= '1';
                        when Others =>  state_in <= Waiting;
                    end case;
             when Others =>state_in <= Waiting;
                           done<='0';
                           num_data<="00000000";
             end case;
         end if;
    end process;   


    process(clk)
    begin
        if rising_edge(clk) then 
             sig_sinus_r<=sig_sinus; -- retarded sinus of 1 clock stroke
             data_dut_in_r<=data_dut_in; -- retarded signal from dut of 1 clock stroke
             strb <= '0';
             allow_r <= allow;
             if sig_pa(36 downto 32)="10100" then
                 b_state <= Measure;                -- start of measurement at 20th sinus periode
             end if;
             if sig_pa(36 downto 32)="10110" then   
                 b_state<= Send_Data;               -- end of measurement and start of data sending at 22th sinus periode
             end if;
             case b_state is
                 when Waiting => if allow='1' and allow_r='0' then b_state <= Pre_Measure; -- after authorization initialisation of sig_m 
                                                                  sig_m <= bode_begin;     -- frequency and start of sinus generation
                                 end if;
                 when Pre_Measure => sig_pa<=sig_pa+("00000"&sig_m); -- phase accumulator incrementation 
                 when Measure => sig_pa<=sig_pa+("00000"&sig_m); -- phase accumulator incrementation 
                                if ((sig_sinus(15)='0' and sig_sinus_r(15)='1') and done_phase="00") then -- search of sign inversion on sinus signal (negative to positive)
                                            phase1<=sig_pa(31 downto 0);    -- saving in phase1 the moment of the sign inversion of sinus signal
                                            done_phase(0) <= '1';           -- end of search on sinus signal
                                elsif ((data_dut_in(15)='0' and data_dut_in_r(15)='1') and done_phase="01") then -- search of sign inversion on dut signal(negative to positive) after finding it on the sinus
                                            phase2<=sig_pa(31 downto 0);    -- saving in phase2 the moment of the sign inversion of dut signal
                                            done_phase(1) <= '1';           -- end of search on dut signal
                                 else phase<=phase2-phase1; -- time between sign inversion of sinus and dut signals calculation
                                 end if;  
                                 if data_dut_in(15)='0' then -- search of maximum amplitude : case if signal is positive
                                    if (data_dut_in(14 downto 0)>amplitude_dut(14 downto 0)) then 
                                         amplitude_dut<=data_dut_in;
                                    end if;
                                 else -- search of maximum amplitude : case if signal is negative
                                    if (not(data_dut_in(14 downto 0))>amplitude_dut(14 downto 0)) then
                                         amplitude_dut<='0'&not(data_dut_in(14 downto 0));
                                    end if;
                                end if;
                  when Send_Data => if busy='0' then -- data emission
                                        strb <= '1'; -- 1 byte is send 2 times each measered data for a good PC reception 
                                         case num_byte is 
                                            when "0000" => data_out <= amplitude_dut(7 downto 0);
                                                           num_byte <= "0001";
                                            when "0001" => data_out <= amplitude_dut(7 downto 0);
                                                           num_byte <= "0010"; 
                                            when "0010" => data_out <= amplitude_dut(15 downto 8);
                                                           num_byte <= "0011";                                            
                                            when "0011" => data_out <= amplitude_dut(15 downto 8);
                                                           num_byte <= "0100";
                                            when "0100" => data_out <= phase(7 downto 0);
                                                           num_byte <= "0101";
                                            when "0101" => data_out <= phase(7 downto 0);
                                                           num_byte <= "0110";
                                            when "0110" => data_out <= phase(15 downto 8);
                                                           num_byte <= "0111";
                                            when "0111" => data_out <= phase(15 downto 8);
                                                           num_byte <= "1000";
                                            when "1000" => data_out <= phase(23 downto 16);
                                                           num_byte <= "1001";
                                            when "1001" => data_out <= phase(23 downto 16);
                                                           num_byte <= "1010";
                                            when "1010" => data_out <= phase(31 downto 24);
                                                           num_byte <= "1011";
                                            when others => data_out <= phase(31 downto 24);
                                                           num_byte <= "0000";
                                                           b_state <= PreWaiting;
                                       end case;
                                   end if;
                     when PreWaiting => sig_pa <= "0000000000000000000000000000000000000"; --reset of signals
                                        phase<="00000000000000000000000000000000";
                                        phase1<="00000000000000000000000000000000";
                                        phase2<="00000000000000000000000000000000"; 
                                        amplitude_dut<="0000000000000000"; 
                                        done_phase<="00";
                                        sig_m <= sig_m+bode_step; -- incremention of sig_m with bode_step
                                        b_state <= Ending;
                    when Ending => if (sig_m>bode_end) then b_state<=Waiting; -- if ending Bode plot if sig_m is bigger than the maximum frequency wanted
                                   else b_state <= Pre_Measure;               -- else restarting of analysis for the next frequency
                                   end if;
             end case; 
        end if;  
    end process;
    
data_out_bode<=sig_sinus;

end Behavioral;