--================================================================================================================================
-- Copyright 2020 Bitvis
-- Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and in the provided LICENSE.TXT.
--
-- Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
-- an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and limitations under the License.
--================================================================================================================================
-- Note : Any functionality not explicitly described in the documentation is subject to change at any time
----------------------------------------------------------------------------------------------------------------------------------

------------------------------------------------------------------------------------------
-- Description   : See library quick reference (under 'doc') and README-file(s)
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library bitvis_vip_sbi;
library bitvis_vip_uart;
library bitvis_uart;
library bitvis_vip_avalon_mm;
library bitvis_vip_clock_generator;

use bitvis_vip_avalon_mm.avalon_mm_bfm_pkg.all;


-- Test harness entity
entity avalon_vvc_th is
end entity avalon_vvc_th;

-- Test harness architecture
architecture struct of avalon_vvc_th is

  -- DSP interface and general control signals
  signal clk  : std_logic := '0';
  signal arst : std_logic := '0';
  signal arst_l : std_logic;
  
  
	signal	begintransfer	:	std_logic	;
	signal	byte_enable		:	std_logic_vector(3 downto 0)	;
	signal	lock			:	std_logic	;
	
	
  
  signal	avs_reset	:	std_logic	;
  
		signal		response      : std_logic_vector(1 downto 0); -- Set use_response_signal to false if not in use
		signal		waitrequest   : std_logic;
		signal		readdatavalid : std_logic;          -- might be used, might not.. If not used, fixed latency is a given
		
		signal		irq           : std_logic;
  -- -- SBI VVC signals
  -- signal cs    : std_logic;
  -- signal addr  : unsigned(2 downto 0);
  -- signal wr    : std_logic;
  -- signal rd    : std_logic;
  -- signal wdata : std_logic_vector(7 downto 0);
  -- signal rdata : std_logic_vector(7 downto 0);
  -- signal ready : std_logic;
	
	
	
	signal		avs_s0_address			:	std_logic_vector(9 downto 2)			;
	signal		avs_s0_read				:	std_logic								;
	signal		avs_s0_readdata			:	std_logic_vector(31 downto 0)			;
	signal		avs_s0_write			:	std_logic								;
	signal		avs_s0_writedata		:	std_logic_vector(31 downto 0)			;
	signal		avs_s0_chipselect		:	std_logic								;
	
	
  -- -- UART VVC signals
  -- signal uart_vvc_rx : std_logic := '1';
  -- signal uart_vvc_tx : std_logic := '1';

  constant C_CLK_PERIOD : time    := 10 ns; -- 100 MHz
  constant C_CLOCK_GEN  : natural := 1;


	constant MY_C_AVALON_MM_BFM_CONFIG_DEFAULT : t_avalon_mm_bfm_config := (
		max_wait_cycles          => 10,
		max_wait_cycles_severity => TB_FAILURE,
		clock_period             => -1 ns,
		clock_period_margin      => 0 ns,
		clock_margin_severity    => TB_ERROR,
		setup_time               => -1 ns,
		hold_time                => -1 ns,
		bfm_sync                 => SYNC_ON_CLOCK_ONLY,
		match_strictness         => MATCH_EXACT,
		num_wait_states_read     => 0,
		num_wait_states_write    => 0,
		use_waitrequest          => false,
		use_readdatavalid        => false,
		use_response_signal      => false,
		use_begintransfer        => false,
		id_for_bfm               => ID_BFM,
		id_for_bfm_wait          => ID_BFM_WAIT,
		id_for_bfm_poll          => ID_BFM_POLL
	);

begin

	arst_l	<=	not	arst	;
  -----------------------------------------------------------------------------
  -- Instantiate the concurrent procedure that initializes UVVM
  -----------------------------------------------------------------------------
  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  -----------------------------------------------------------------------------
  -- Instantiate DUT
  -----------------------------------------------------------------------------
  -- i_uart : entity work.uart
    -- port map(
      -- -- DSP interface and general control signals
      -- clk   => clk,
      -- arst  => arst,
      -- -- CPU interface
      -- cs    => cs,
      -- addr  => addr,
      -- wr    => wr,
      -- rd    => rd,
      -- wdata => wdata,
      -- rdata => rdata,
      -- -- UART signals
      -- rx_a  => uart_vvc_tx,
      -- tx    => uart_vvc_rx
    -- );
	
	AVS_IOMAP_DUT	:	entity work.AVS_IOMAP
		port map	(
				csi_CLK								=>	clk							,
				rsi_RST_L							=>	arst_l						,
				
				--	avalon slave
				avs_s0_address						=>	avs_s0_address				,
				avs_s0_read							=>	avs_s0_read					,
				avs_s0_readdata						=>	avs_s0_readdata				,
				avs_s0_write						=>	avs_s0_write				,
				avs_s0_writedata					=>	avs_s0_writedata			,
				avs_s0_chipselect					=>	avs_s0_chipselect			
				
				);

  -----------------------------------------------------------------------------
  -- SBI VVC
  -----------------------------------------------------------------------------
  i1_sbi_vvc : entity bitvis_vip_avalon_mm.avalon_mm_vvc
    generic map(
		GC_ADDR_WIDTH                            =>	8											,
		GC_DATA_WIDTH                            =>	32											,
		GC_INSTANCE_IDX                          =>	1											,
		GC_AVALON_MM_CONFIG                      =>	MY_C_AVALON_MM_BFM_CONFIG_DEFAULT			,
		GC_CMD_QUEUE_COUNT_MAX                   =>	C_CMD_QUEUE_COUNT_MAX						,
		GC_CMD_QUEUE_COUNT_THRESHOLD             =>	C_CMD_QUEUE_COUNT_THRESHOLD					,
		GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY    =>	C_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY		,
		GC_RESULT_QUEUE_COUNT_MAX                =>	C_RESULT_QUEUE_COUNT_MAX					,
		GC_RESULT_QUEUE_COUNT_THRESHOLD          =>	C_RESULT_QUEUE_COUNT_THRESHOLD				,
		GC_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY =>	C_RESULT_QUEUE_COUNT_THRESHOLD_SEVERITY		
		
    )
	
    port map(
		clk                     => clk,

		-- Avalon MM BFM to DUT signals
		avalon_mm_vvc_master_if.reset         		=>	avs_reset				,
		avalon_mm_vvc_master_if.address       		=>	avs_s0_address			,
		avalon_mm_vvc_master_if.begintransfer 		=>	begintransfer					,
		avalon_mm_vvc_master_if.byte_enable   		=>	byte_enable					,
		avalon_mm_vvc_master_if.chipselect    		=>	avs_s0_chipselect		,
		avalon_mm_vvc_master_if.write         		=>	avs_s0_write			,
		avalon_mm_vvc_master_if.writedata     		=>	avs_s0_writedata		,
		avalon_mm_vvc_master_if.read          		=>	avs_s0_read				,
		avalon_mm_vvc_master_if.lock          		=>	lock					,

		-- Avalon MM DUT to BFM signals
		avalon_mm_vvc_master_if.readdata      		=>	avs_s0_readdata			,
		avalon_mm_vvc_master_if.response      		=>	response      		,
		avalon_mm_vvc_master_if.waitrequest   		=>	waitrequest   		,
		avalon_mm_vvc_master_if.readdatavalid 		=>	readdatavalid 		,
                                                        
		avalon_mm_vvc_master_if.irq           		=>	irq           		
	
    );
	
	response	<=	(others => '0')	;
	waitrequest	<=	'0'	;
	readdatavalid	<=	'0'	;
	irq				<=	'0'	;
	
  -----------------------------------------------------------------------------
  -- UART VVC
  -----------------------------------------------------------------------------
  -- i1_uart_vvc : entity bitvis_vip_uart.uart_vvc
    -- generic map(
      -- GC_INSTANCE_IDX => 1
    -- )
    -- port map(
      -- uart_vvc_rx => uart_vvc_rx,
      -- uart_vvc_tx => uart_vvc_tx
    -- );

  -- -- Static '1' ready signal for the SBI VVC
  -- ready <= '1';

  -- Toggle the reset after 5 clock periods
  p_arst : arst <= '1', '0' after 5 * C_CLK_PERIOD;

  -----------------------------------------------------------------------------
  -- Clock Generator VVC
  -----------------------------------------------------------------------------
  i_clock_generator_vvc : entity bitvis_vip_clock_generator.clock_generator_vvc
    generic map(
      GC_INSTANCE_IDX    => C_CLOCK_GEN,
      GC_CLOCK_NAME      => "Clock",
      GC_CLOCK_PERIOD    => C_CLK_PERIOD,
      GC_CLOCK_HIGH_TIME => C_CLK_PERIOD / 2
    )
    port map(
      clk => clk
    );

end struct;
