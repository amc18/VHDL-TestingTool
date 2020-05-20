-----------------------------------------------------------------------------------
-- School:  ENSIL-ENSCI
-- Students : GUIGNARD Aymeric & LEGEMBLE Boris
-- Tutor : MEGHDADI Vahid
-- Create Date: 28/04/2020
-- Module Name: TestTool - Behavioral
-- Project Name: TestTool
-- Target Devices: Basys 3
-- Tool Versions: 1.0
-- Description: 2 function generators and Bode plot function, controlled by C++ interface, 
--              using RS-232 communication.
--              This program take place in a school projet from ENSIL-ENSCI.
--              This projet isn't designed for safety-critical systems.
----------------------------------------------------------------------------------

-- blk_men_gen 0,1,2 are single port ROM memory (4096 16 bits coefficients) with signed_sinus16bits.coe in it
-- blk_mem_gen 3 is single port RAM memory (65536 16 bits coefficients)
-- they are findable in IP Catalog -> Basic Elements -> Memory Element -> Block Memory Generator 

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity TestTool is
    Port ( clk : in STD_LOGIC; -- Must use 100 Mhz 
           rx : in std_logic;   -- Connected to FPGA's rx port
           tx : out std_logic;  -- Connected to FPGA's tx port
           sig_A : out std_logic_vector(15 downto 0); --Signal A Out on 16 bits  (signed)
           sig_B : out std_logic_vector(15 downto 0);  --Signal B Out on 16 bits  (signed)
           sig_from_DUT : in std_logic_vector(15 downto 0); -- Signal from DUT 16 bits (signed)
           sig_strb : out std_logic -- Strob signal, '1' when generators or Bode plot works, '0' if not
           
           );
end TestTool;

architecture Behavioral of TestTool is
--rx & tx   
--Signals used for Transmission end Reception using RS-232 protocol  
signal en_16Xrate: std_logic;
signal EN_115200 : std_logic;
signal rx_cmpt: integer range 0 to 54;
signal cpt_115200 : integer range 0 to 868;
signal rx_strb: std_logic;
signal rx_data: std_logic_vector(7 downto 0);
signal tx_strb: std_logic;
signal tx_busy: std_logic;
signal tx_data: std_logic_vector(7 downto 0);
--Gen1
--Signals used for the generator n°1 
signal allow1: std_logic;                        -- allow the generator to work
signal done1: std_logic;                         -- validation of generator n°1 set up
signal data_in_sync1: std_logic;                 -- synchronisation of received data 
signal data_in1: std_logic_vector(7 downto 0);   -- data form PC to set up the generator n°1 
signal data_out1: std_logic_vector(15 downto 0); -- signal out of generator n°1
--Gen2
--Signals used for generator n°2 
signal allow2: std_logic;                        -- allow the generator to work
signal done2: std_logic;                         -- validation of generator n°2 set up
signal data_in_sync2: std_logic;                 -- synchronisation of received data 
signal data_in2: std_logic_vector(7 downto 0);   -- data form PC to set up the generator n°2 
signal data_out2: std_logic_vector(15 downto 0); -- signal out of generator n°2
--Bode Plot
--Signals used for Bode Plot
signal allow_bode : std_logic;                       -- allow Bode plot to work
signal done_bode : std_logic;                        -- validation of Bode plot set up
signal strb_bode : std_logic;                        -- strb for data sent to DUT
signal data_in_sync_bode : std_logic;                -- synchronisation of received data
signal data_in_bode:std_logic_vector(7 downto 0);    -- data form PC to set up the Bode plot
signal data_out_plot : std_logic_vector(7 downto 0); -- data sent to the PC
signal data_dut_in : std_logic_vector(15 downto 0);  -- signal from DUT
signal data_out_bode: std_logic_vector(15 downto 0); -- signal sent to DUT
--data dispatch
type step is (Waiting,PreWaiting,Bode1,Bode2,Step1,Step2,Step3,Step4,Step5);
signal sig_step : step :=Waiting;   
signal sig_sel: std_logic_vector(7 downto 0);     -- select the use of Generators and Bode plot
signal sig_out_sel: std_logic_vector(7 downto 0); -- select the use of output
--Data Out
signal sig_AaddB: std_logic_vector(15 downto 0);  -- data_out1 + data_out2 after signal limitation
signal sig_AsubB: std_logic_vector(15 downto 0);  -- data_out1 - data_out2 after signal limitation
signal sig_BsubA: std_logic_vector(15 downto 0);  -- data_out2 - data_out1 after signal limitation
signal sig_AmulB: std_logic_vector(15 downto 0);  -- data_out1 * data_out2 after signal limitation
signal sig_AaddB2: std_logic_vector(16 downto 0); -- data_out1 + data_out2
signal sig_AsubB2: std_logic_vector(16 downto 0); -- data_out1 - data_out2
signal sig_BsubA2: std_logic_vector(16 downto 0); -- data_out2 - data_out1
signal sig_AmulB2: std_logic_vector(63 downto 0); -- data_out1 * data_out2 

--Component Definition
COMPONENT uart_rx
	 PORT(
		CLK : IN std_logic;
		EN_16xRATE : IN std_logic;
		RX : IN std_logic;          
		DOUT : OUT std_logic_vector(7 downto 0);
		STRB : OUT std_logic
		);
	 END COMPONENT;

COMPONENT rs232_tx
	 PORT(
		CLK : IN std_logic;
		EN_115200 : IN std_logic;
		TX : OUT std_logic;          
		DATA : IN std_logic_vector(7 downto 0);
		STRB : IN std_logic;
		BUSY : OUT std_logic
		);
	 END COMPONENT;

COMPONENT Bode_Plot 
Port ( clk : in std_logic;
    data_dut_in : in std_logic_vector(15 downto 0);
    data_in : in std_logic_vector(7 downto 0);
    data_in_sync : in std_logic;
    data_out : out std_logic_vector(7 downto 0); 
    data_out_bode : out std_logic_vector(15 downto 0);
    busy : in std_logic;
    done : out std_logic;
    allow : in std_logic;
    strb : out std_logic
     );
END COMPONENT ;

    COMPONENT Gen1 
    PORT(
        clk : in STD_LOGIC;
        data_in : in std_logic_vector(7 downto 0);
        data_in_sync : in std_logic;
        data_out : out std_logic_vector(15 downto 0);
        allow : in std_logic;
        done : out std_logic 
        );
    END COMPONENT;
     
    COMPONENT Gen2 
    PORT(
        clk : in STD_LOGIC;
        data_in : in std_logic_vector(7 downto 0);
        data_in_sync : in std_logic;
        data_out : out std_logic_vector(15 downto 0);
        allow : in std_logic;
        done : out std_logic
        );
    END COMPONENT;
    
    
begin

-- Component Instantiation
	 
    Inst_uart_rx: uart_rx PORT MAP(
		CLK =>clk ,
		EN_16xRATE =>en_16Xrate,
		RX => rx,
		DOUT => rx_data,
		STRB => rx_strb
	);
	
	    Inst_rs232_tx: rs232_tx PORT MAP(
		CLK =>clk ,
		EN_115200 => EN_115200,
		TX => tx,
		DATA => tx_data,
		STRB => tx_strb,
        BUSY => tx_busy
	);
	
	Inst_Bode_Plot :Bode_Plot PORT MAP(
    clk => clk,
    data_dut_in => data_dut_in,
    data_in => data_in_bode,
    data_in_sync => data_in_sync_bode,
    data_out => tx_data,
    data_out_bode => data_out_bode,
    busy => tx_busy,
    done => done_bode,
    allow => allow_bode,
    strb => tx_strb
     );

	Inst_Gen1: Gen1 PORT MAP(
	    clk => clk,
        data_in => data_in1,
        data_in_sync => data_in_sync1,
        data_out => data_out1,
        allow => allow1,
        done => done1
     );
     
     Inst_Gen2: Gen2 PORT MAP(
	    clk => clk,
        data_in => data_in2,
        data_in_sync => data_in_sync2,
        data_out => data_out2,
        allow => allow2,
        done => done2
     );
  
  data_dut_in <= sig_from_DUT;
     
--Generation of en_16Xrate for rx components

    process(clk)
	begin
		if rising_edge(clk) then
			rx_cmpt <= rx_cmpt + 1;
			en_16Xrate <= '0';
			if rx_cmpt = 54 then --115200 bauds
				en_16Xrate <= '1';
				rx_cmpt <= 0;
			end if;
		end if;
	end process;

process(clk)
	begin
		if rising_edge(clk) then
			cpt_115200 <= cpt_115200 + 1;
			EN_115200 <= '0';
			if cpt_115200 = 868 then --115200 bauds
				EN_115200 <= '1';
				cpt_115200 <= 0;
			end if;
		end if;
	end process;

--Data Dispatcher
    
    process(clk)
    begin
        if rising_edge(clk) then
             data_in_sync1 <= '0';
             data_in_sync2 <= '0';
             data_in_sync_bode <= '0';
             if rx_strb='1' then 
                  case sig_step is
                        when Waiting =>
                              if rx_data/="00000000" then -- end of Waiting
                                  sig_strb <= '0';
                                  allow1 <= '0';
                                  allow2 <= '0';
                                  allow_bode <='0';
                                  sig_sel<=rx_data; -- use of TestTool
                                  case rx_data is
                                       when "00000001" => sig_step<=Step1; -- Use of Generator n°1
                                       when "00000010" => sig_step<=Step2; -- Use of Generator n°2
                                       when "00000011" => sig_step<=Step1; -- Use of Generator n°1 and Generator n°2
                                       when "00000100" => sig_step<=Bode1; -- Use of Bode plot
                                       when others => sig_step<=Waiting;
                                  end case;
                              end if;
                        when Step1 =>   -- send data to Generator n°1
                           data_in1 <= rx_data;
                           data_in_sync1 <= rx_strb;
                           if ((done1='1') and (sig_sel(1)='1')) then sig_step<=Step2; 
                           end if;
                           if ((done1='1') and (sig_sel(1)='0')) then sig_step<=Step3;
                           end if;
                        when Step2  => -- send data to Generator n°2
                           data_in2 <= rx_data;
                           data_in_sync2 <= rx_strb;
                           if (done2='1') then sig_step<=Step3;
                           end if;
                       when Step3 => sig_out_sel <= rx_data; -- send data to select the use of output
                                     sig_step <= PreWaiting;
                                     allow1<='1';
                                     allow2<='1';
                                     sig_strb <= '1';
                       when Bode1 => -- send data to Bode plot
                                    data_in_bode <= rx_data;
                                    data_in_sync_bode <= rx_strb;
                                    if done_bode='1' then 
                                        sig_step<=Bode2;
                                    end if;
                       when Bode2 => allow_bode<='1';
                                     sig_strb <= '1';
                                     sig_step <= PreWaiting;
                       when PreWaiting => sig_step <=Waiting;                    
                       when others => sig_step <= Waiting;
                  end case;
             end if;
        end if;
    end process;
    
-- Signal limiters  
    
    process(clk)
    begin
        sig_AaddB2 <= (data_out1(15) & data_out1)+(data_out2(15) & data_out2);
        sig_AsubB2 <= (data_out1(15) & data_out1)-(data_out2(15) & data_out2);
        sig_BsubA2 <= (data_out2(15) & data_out2)-(data_out1(15) & data_out1);
        sig_AmulB2 <= (data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&
        data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1(15)&data_out1)*
        (data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&
        data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2(15)&data_out2);
        if sig_AaddB2(16 downto 15)="01" then 
             sig_AaddB <= "0111111111111111";
        elsif sig_AaddB2(16 downto 15)="10" or sig_AaddB2 = "11000000000000000" then 
            sig_AaddB <="1000000000000001";
        else sig_AaddB <= sig_AaddB2(15 downto 0);
        end if;
        if sig_AsubB2(16 downto 15)="01" then 
            sig_AsubB <= "0111111111111111";
        elsif sig_AsubB2(16 downto 15)="10" or sig_AsubB2 = "11000000000000000" then 
            sig_AsubB <="1000000000000001";
        else sig_AsubB <= sig_AsubB2(15 downto 0);
        end if;
        if sig_BsubA2(16 downto 15)="01" then 
            sig_BsubA <= "0111111111111111";
        elsif sig_BsubA2(16 downto 15)="10" or sig_BsubA2 = "11000000000000000" then 
            sig_BsubA <="1000000000000001";
        else sig_BsubA <= sig_BsubA2(15 downto 0);
        end if;
        sig_AmulB<=sig_AmulB2(30 downto 15);
    end process;
    
-- Channel selector

    process(clk)
    begin
        if rising_edge(clk) then
            if allow_bode = '1' then
                sig_A <= data_out_bode;
            else -- the 4 LSB are used for the use sig_A, the 4 MSB for the use of sig_B
                 case sig_out_sel(3 downto 0) is 
                     when "0001" => sig_A <= data_out1;
                     when "0010" => sig_A <= data_out2;
                     when "0011" => sig_A <= sig_AaddB;
                     when "0100" => sig_A <= sig_AsubB;
                     when "0101" => sig_A <= sig_BsubA;
                     when "0110" => sig_A <= sig_AmulB;
                     when others => sig_A <= "0000000000000000";
                 end case;
                 case sig_out_sel(7 downto 4) is
                     when "0001" => sig_B <= data_out2;
                     when "0010" => sig_B <= data_out1;
                     when "0011" => sig_B <= sig_AaddB;
                     when "0100" => sig_B <= sig_AsubB;
                     when "0101" => sig_B <= sig_BsubA;
                     when "0110" => sig_B <= sig_AmulB;
                     when others => sig_B <= "0000000000000000";
                 end case;
            end if;
        end if;
    end process;

end Behavioral;
