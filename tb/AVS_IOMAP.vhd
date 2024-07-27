	library		ieee,std;
	use			ieee.std_logic_1164.all	;
	use			ieee.std_logic_unsigned.all;
	use			ieee.std_logic_arith.all;
	use			ieee.std_logic_misc.all;

--	------------------------------------------------------------------	--
	entity	AVS_IOMAP	is
		port	(
				csi_CLK								:	in	std_logic								; -- csi_CLK
				rsi_RST_L							:	in	std_logic								; -- Reset 
				
				--	avalon slave		
				avs_s0_address						:	in	std_logic_vector(9 downto 2)			;
				avs_s0_read							:	in	std_logic								;
				avs_s0_readdata						:	out	std_logic_vector(31 downto 0)			;
				avs_s0_write						:	in	std_logic								;
				avs_s0_writedata					:	in	std_logic_vector(31 downto 0)			;
				avs_s0_chipselect					:	in	std_logic								
				
				);
	end	AVS_IOMAP;

	architecture	arcAVS_IOMAP	of	AVS_IOMAP	is
	
	signal		wReg0								:	std_logic_vector(31 downto 0)			;
	signal		wReg1								:	std_logic_vector(31 downto 0)			;
	
--	------------------------------------------------------------------	--
	begin
--	------------------------------------------------------------------	--

--	------------------------------------------------------------------	--
--	*																	--
--	------------------------------------------------------------------	--
	--	-->>	read cyclye
	process(csi_CLK , rsi_RST_L)
	begin
		if (rsi_RST_L = '0') then
			avs_s0_readdata	<=	(others => '0')	;
		elsif(csi_CLK'event and csi_CLK = '1')then
			if((avs_s0_chipselect = '1') and (avs_s0_read = '1'))then
				case (avs_s0_address) is
					when	x"00"	=>
						avs_s0_readdata	<=	wReg0	;
						
					when	x"01"	=>
						avs_s0_readdata	<=	wReg1	;
						
					when	others	=>
						avs_s0_readdata	<=	x"00000000"	;
						
				end case	;
			end if;
		end if;
	end process;
	--	<<--	read cyclye
	
	--	-->>	write cyclye
	process(csi_CLK, rsi_RST_L)
	begin
		if(rsi_RST_L = '0')then
			wReg0			<=	x"00000000"		;
			wReg1			<=	x"00000000"		;
		elsif(csi_CLK'event and csi_CLK = '1')then
			if((avs_s0_chipselect = '1') and (avs_s0_write = '1'))then	--	config avalon bus write signal as one short
				case (avs_s0_address) is
					when	x"00"	=>
						wReg0			<=	avs_s0_writedata(31 downto 0)	;
					when	x"01"	=>
						wReg1			<=	avs_s0_writedata(31 downto 0)	;
					when	others	=>
						null;
				end case	;
			end if;
		end if;
	end process;
	
	end	arcAVS_IOMAP;

