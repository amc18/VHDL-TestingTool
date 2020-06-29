The following files are made for Basys_3 implementation. 
This imply that Ram memory is removed in Gen2.vhd due to a shortage of Bram for this model of Artix-7 FPGA.


Those project files are constitued by a main.vhd exemple that connect a DUT (a simple averaging filter) with the TestTool component. A PmodDA2 must be connected to Basys 3 Pmod Header JA (top pins)
to see signal generated with an oscilloscop (as for exemple digilent analog discovery 2). Warning : PmodDA2 sample frequency 
must cause problem to see too high frequency signal.
 


Memory (ROM and RAM) must be instantiated thanks IP Catalog
-- blk_men_gen 0,1,2 are single port ROM memory (4096 16 bits coefficients) with signed_sinus16bits.coe loaded in it
-- blk_mem_gen 3 is single port RAM memory (65536 16 bits coefficients)
-- they are findable in IP Catalog -> Basic Elements -> Memory Element -> Block Memory Generator 

Project Hierarchy

Design Sources	
	main.vhd
		TestTool.vhd
			uart_rx.vhd
			rs232_tx.vhd
			Bode_Plot.vhd
				blk_mem_gen_0
			Gen1.vhd
				blk_mem_gen_1
				blk_mem_gen_3
				SquareGen.vhd
				TriangleGen.vhd
				NoiseGen.vhd
			Gen2.vhd
				blk_mem_gen_2
				SquareGen2.vhd
				TriangleGen2.vhd
				NoiseGen2.vhd
		DUT.vhd
		Int_Pmod_DA2.vhd

Coefficient Files
	signed_sinus_16_bits.coe
	
Constraints
	Basys3_Master.xdc
