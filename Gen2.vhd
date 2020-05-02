-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: Gen2 - Behavioral
-- Project Name: TestTool
-- Target Devices: Nexys 4
-- Tool Versions: 1.0
-- Description: Function generator controlled by C++ interface, 
--              using RS-232 communication.
--              Include sinus,triangle,square,noise,custom generators.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity Gen2 is
    Port ( clk : in STD_LOGIC;                              -- clock
           data_in : in std_logic_vector(7 downto 0);       -- data from PC on 8 bits
           data_in_sync : in std_logic;                     -- data reception's synchronisation
           data_out : out std_logic_vector(15 downto 0);    -- signal generated on 16 bits (signed) 
           allow : in std_logic;                            -- allow Gen1 to work
           done : out std_logic                             -- end of generator set up
           );
end Gen2;

architecture Behavioral of Gen2 is

--Signal Generation
type r_state is (Waiting,PreWaiting,Sinus,Square,Triangle,Noise,Ram);

signal state_in1 : r_state :=Waiting;
signal state_out : r_state :=Waiting;


signal sig_pa : std_logic_vector(31 downto 0);        -- Phase accumulator
signal sig_m : std_logic_vector(31 downto 0);         -- according word for frequency / rising ramp according word for frequency used triangle signal / random number for noise
signal sig_n : std_logic_vector(31 downto 0);         -- falling ramp according word for frequency used for triangle signal
signal sig_c : std_logic_vector(15 downto 0);         -- coefficient for duty cycle / number of coefficient used for custom signal
signal sig_offset: std_logic_vector(15 downto 0);     -- offset
signal sig_amplitude: std_logic_vector(15 downto 0);  -- amplitude
signal sig_rom_sinus : std_logic_vector(11 downto 0); -- input on rom for sinus generation
signal sig_sel : std_logic_vector(7 downto 0);        --selection of generator's use
signal num_data : std_logic_vector (7 downto 0);      -- signal for data reception

--Singnals Genereted

signal sig_sinus : std_logic_vector(15 downto 0);
signal sig_square : std_logic_vector(15 downto 0);
signal sig_triangle : std_logic_vector(15 downto 0);
signal sig_noise : std_logic_vector(15 downto 0);
signal sig_ram : std_logic_vector(15 downto 0);

signal sig_op_1 : std_logic_vector(15 downto 0); -- signal generated after limitation
signal sig_op_2 : std_logic_vector(47 downto 0); -- signal after amplitude
signal sig_op_3 : std_logic_vector(16 downto 0); -- signal after offset
-- signals for RAM use
signal sig_wea :  std_logic_vector(0 downto 0);   
signal sig_ram_cpt : std_logic_vector(15 downto 0);
signal sig_ram_cpt_1 : std_logic_vector(15 downto 0);
signal sig_ram_cpt_2 : std_logic_vector(31 downto 0);
signal sig_ram_in : std_logic_vector(15 downto 0);
signal sig_ram_size : std_logic_vector(15 downto 0);
signal state_ram : std_logic_vector(1 downto 0);

    COMPONENT blk_mem_gen_2
    PORT (
    addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
    clka : in std_logic;
    ena : in std_logic
    );
    END COMPONENT;
     
    COMPONENT SquareGen2
    PORT (
    clk : in STD_LOGIC;
    allow : in STD_LOGIC;
    sig_m : in STD_LOGIC_VECTOR (31 downto 0);
    sig_c : in STD_LOGIC_VECTOR (15 downto 0);
    sig_out : out STD_LOGIC_VECTOR(15 downto 0)
    );
    END COMPONENT;
     
    COMPONENT TriangleGen2
    PORT (
    clk : in STD_LOGIC;
    allow : in STD_LOGIC;
    sig_m : in STD_LOGIC_VECTOR (31 downto 0);
    sig_n : in STD_LOGIC_VECTOR (31 downto 0);
    sig_out : out STD_LOGIC_VECTOR(15 downto 0)
    );
    END COMPONENT;
    
    COMPONENT NoiseGen2
    PORT (
    clk : in STD_LOGIC;
    allow : in STD_LOGIC;
    sig_m : in STD_LOGIC_VECTOR (31 downto 0);
    sig_out : out STD_LOGIC_VECTOR(15 downto 0)
    );
    END COMPONENT;
    
    COMPONENT blk_mem_gen_4
    PORT (
    clka : IN STD_LOGIC;
    ena : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
    END COMPONENT;
    
begin
	 
 Inst_blk_mem_gen_2:blk_mem_gen_2 PORT MAP(
    addra => sig_rom_sinus,
    douta => sig_sinus,
    clka => clk,
    ena => '1'
    );

  Inst_blk_mem_gen_4:blk_mem_gen_4 PORT MAP(
    clka => clk,
    ena  => '1',
    wea  => sig_wea,
    addra => sig_ram_cpt,
    dina  => sig_ram_in,
    douta  => sig_ram
    );
    
Inst_SquareGen:SquareGen2 PORT MAP(
    clk => clk,
    allow => allow,
    sig_m => sig_m,
    sig_c => sig_c,
    sig_out => sig_square
    );
    
Inst_TriangleGen:TriangleGen2 PORT MAP(
    clk => clk,
    allow => allow,
    sig_m => sig_m,
    sig_n => sig_n,
    sig_out => sig_triangle
    );
    
Inst_NoiseGen:NoiseGen2 PORT MAP(
    clk => clk,
    allow => allow,
    sig_m => sig_m,
    sig_out => sig_noise
    );
    
--Data Reception

    process(clk)
    begin
        if rising_edge(clk) then
            if state_ram="10" then -- incrementation of RAM input signal
                                sig_ram_cpt_1<=sig_ram_cpt_1+"0000000000000001"; 
                                state_ram <= "00";
                                if sig_ram_cpt_1=sig_c then -- end of data storage on RAM
                                     sig_wea<="0";
                                     num_data<="00000111";
                                     sig_ram_cpt_1<="0000000000000000";
                                end if;
            end if;
            if data_in_sync='1' then
            case state_in1 is 
                when Waiting => 
                    if data_in/="00000000" then
                        sig_sel<=data_in; -- use of generator
                        case data_in is 
                            when "00000001" => state_in1 <= Sinus;
                                               state_out <= Sinus;
                            when "00000010" => state_in1 <= Square;
                                               state_out <= Square;
                            when "00000011" => state_in1 <= Triangle;
                                               state_out <= Triangle;
                            when "00000100" => state_in1 <= Noise;
                                               state_out <= Noise;
                            when "00000101" => state_in1 <= Ram;
                                               state_out <= Ram;
                            when others => state_in1 <= Waiting;
                                           state_out <= Waiting;
                        end case;
                    end if;                
                when Sinus => -- set up of sinus generator
                    case num_data is
                        when "00000000" => sig_m(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" =>  sig_m(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => sig_m(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => sig_m(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => sig_offset(7 downto 0)<=data_in;
                                           num_data<="00000101";
                        when "00000101" => sig_offset(15 downto 8)<=data_in;
                                           num_data<="00000110";
                        when "00000110" => sig_amplitude(7 downto 0)<=data_in;
                                           num_data<="00000111";
                        when "00000111" => sig_amplitude(15 downto 8)<=data_in;
                                           state_in1 <= PreWaiting;
                                           done <= '1';
                        when others => state_in1 <= Waiting;
                    end case;                  
                when Square => -- set up of sqare generator
                     case num_data is
                        when "00000000" => sig_m(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" =>  sig_m(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => sig_m(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => sig_m(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => sig_offset(7 downto 0)<=data_in;
                                           num_data<="00000101";
                        when "00000101" => sig_offset(15 downto 8)<=data_in;
                                           num_data<="00000110";
                        when "00000110" => sig_amplitude(7 downto 0)<=data_in;
                                           num_data<="00000111";
                        when "00000111" => sig_amplitude(15 downto 8)<=data_in;
                                           num_data<="00001000";
                        when "00001000" => sig_c(7 downto 0)<=data_in;
                                           num_data<="00001001";
                        when "00001001" => sig_c(15 downto 8)<=data_in;
                                           state_in1 <= PreWaiting;
                                           done <= '1';
                        when Others => state_in1 <= Waiting;
                    end case;
                when Triangle => -- set up of triangle generator
                    case num_data is
                        when "00000000" => sig_m(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" =>  sig_m(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => sig_m(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => sig_m(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => sig_offset(7 downto 0)<=data_in;
                                           num_data<="00000101";
                        when "00000101" => sig_offset(15 downto 8)<=data_in;
                                           num_data<="00000110";
                        when "00000110" => sig_amplitude(7 downto 0)<=data_in;
                                           num_data<="00000111";
                        when "00000111" => sig_amplitude(15 downto 8)<=data_in;
                                           num_data<="00001000";
                        when "00001000" => sig_n(7 downto 0)<=data_in;
                                           num_data<="00001001";
                        when "00001001" => sig_n(15 downto 8)<=data_in;
                                           num_data<="00001010";
                        when "00001010" => sig_n(23 downto 16)<=data_in;
                                           num_data<="00001011";
                        when "00001011" => sig_n(31 downto 24)<=data_in;
                                           state_in1 <= PreWaiting;
                                           done <= '1';
                        when Others =>  state_in1 <= Waiting;
                    end case;
                when Noise => -- set up of noise generator
                    case num_data is
                        when "00000000" => sig_m(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" =>  sig_m(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => sig_m(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => sig_m(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => sig_offset(7 downto 0)<=data_in;
                                           num_data<="00000101";
                        when "00000101" => sig_offset(15 downto 8)<=data_in;
                                           num_data<="00000110";
                        when "00000110" => sig_amplitude(7 downto 0)<=data_in;
                                           num_data<="00000111";
                        when "00000111" => sig_amplitude(15 downto 8)<=data_in;
                                           state_in1 <= PreWaiting;
                                           done <= '1';
                                           
                        when Others =>  state_in1 <= Waiting;
                        end case;
                when Ram => -- set up of RAM use for custom signal
                     case num_data is
                        when "00000000" => sig_m(7 downto 0)<=data_in;
                                           num_data<="00000001";
                        when "00000001" => sig_m(15 downto 8)<=data_in;
                                           num_data<="00000010";
                        when "00000010" => sig_m(23 downto 16)<=data_in;
                                           num_data<="00000011";
                        when "00000011" => sig_m(31 downto 24)<=data_in;
                                           num_data<="00000100";
                        when "00000100" => sig_c(7 downto 0) <=data_in;
                                           num_data<="00000101";
                        when "00000101" => sig_c(15 downto 8) <=data_in;
                                           num_data<="00000110";
                                           sig_wea<="1"; -- RAM writting enable
                                           sig_ram_cpt_1<="0000000000000000";
                                           state_ram <= "00";
                        when "00000110" => case state_ram is -- 8 LSB of coefficient are stored first
                                                when "00" =>  sig_ram_in(7 downto 0) <= data_in;
                                                              state_ram <= "01";
                                                when others =>  sig_ram_in(15 downto 8) <= data_in;
                                                              state_ram <= "10";
                                           end case;
                        when "00000111" => sig_offset(7 downto 0)<=data_in;
                                           num_data<="00001000";
                        when "00001000" => sig_offset(15 downto 8)<=data_in;
                                           num_data<="00001001";
                        when "00001001" => sig_amplitude(7 downto 0)<=data_in;
                                           num_data<="00001010";
                        when "00001010" => sig_amplitude(15 downto 8)<=data_in;
                                           state_in1 <= PreWaiting;
                                           done <= '1';
                        when Others =>  state_in1 <= Waiting;
                      end case;
                when others => state_in1<=Waiting;
                               num_data<="00000000";
                               done<='0';
            end case;       
        end if;
        end if;
    end process;
    
--Phase Accumulator   
    -- Phase Accumulator used of sinus generation
    process(clk)
    begin 
        if rising_edge(clk) and allow='1' then
                 sig_pa<=sig_pa+sig_m;
        end if;
    end process;
    -- Phase Accumulator used of custom signal generation
    process(clk)
    begin 
        if rising_edge(clk) and allow='1' then
                 sig_ram_cpt_2<=sig_ram_cpt_2+sig_m;
                 if sig_ram_cpt_2(31 downto 16)=sig_c then -- limitation of RAM lecture 
                    sig_ram_cpt_2(31 downto 16)<="0000000000000000";
                 end if;
        end if;
    end process;

-- ROM (sinus signal) input

    sig_rom_sinus<=sig_pa(31 downto 20);
    
-- RAM (custom signal) input
    
    sig_ram_cpt <= sig_ram_cpt_2(31 downto 16) when allow='1' else sig_ram_cpt_1;
   
-- Signal Generator
    -- Selection of wich signal is generated
	process(clk)
	begin
	   if rising_edge(clk) and allow='1' then
	       case state_out is
	           when Sinus => sig_op_1 <= sig_sinus;
	           when Square => sig_op_1 <= sig_square;
	           when Triangle => sig_op_1 <= sig_triangle;
	           when Noise => sig_op_1 <= sig_noise;
	           when others => sig_op_1 <= sig_ram;
	       end case;
	   end if;
	end process;
-- Offset and Amplitude application on the signal
process(clk)
	begin
	   if rising_edge(clk) and allow='1' then 
            sig_op_2 <= (sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&
                         sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1(15)&sig_op_1)*sig_amplitude;
            sig_op_3 <= sig_op_2(31 downto 15)+(sig_offset(15)&sig_offset);
            -- signal limitators
            if sig_op_3(16 downto 15)="01" then 
                data_out <= "0111111111111111";
             elsif sig_op_3(16 downto 15)="10" or sig_op_3(16 downto 0) = "11000000000000000" then
                data_out <= "1000000000000001";
             else data_out <= sig_op_3(15 downto 0);  
            end if;
       end if;
    end process;
         
end Behavioral;
