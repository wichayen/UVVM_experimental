--========================================================================================================================
-- Copyright (c) 2017 by Bitvis AS.  All rights reserved.
-- You should have received a copy of the license file (see LICENSE.TXT), if not, contact Bitvis AS <support@bitvis.no>.
-- UVVM AND ANY PART THEREOF ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
-- INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
-- WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH UVVM.
--========================================================================================================================

------------------------------------------------------------------------------------------
-- Description   : See library quick reference (under 'doc') and README-file(s)
------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

library vunit_lib;
context vunit_lib.vunit_run_context;

library uvvm_util;
context uvvm_util.uvvm_util_context;

library uvvm_vvc_framework;
use uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_axistream;
context bitvis_vip_axistream.vvc_context;
use bitvis_vip_axistream.axistream_bfm_pkg.all;

-- Test case entity
entity axistream_vvc_simple_tb is
  generic (
    GC_DATA_WIDTH    : natural := 32;  -- number of bits in the AXI-Stream IF data vector
    GC_USER_WIDTH    : natural := 1;  -- number of bits in the AXI-Stream IF tuser vector
    GC_ID_WIDTH      : natural := 1;  -- number of bits in AXI-Stream IF tID
    GC_DEST_WIDTH    : natural := 1;  -- number of bits in AXI-Stream IF tDEST
    GC_INCLUDE_TUSER : boolean := true; -- If tuser, tstrb, tid, tdest is included in DUT's AXI interface
    -- This generic is used to configure the testbench from run.py, e.g. what
    -- test case to run. The default value is used when not running from script
    -- and in that case all test cases are run.
    runner_cfg    : runner_cfg_t := runner_cfg_default);
end entity;

-- Test case architecture
architecture func of axistream_vvc_simple_tb is

--------------------------------------------------------------------------------
-- Types and constants declarations
--------------------------------------------------------------------------------
  constant C_CLK_PERIOD : time   := 10 ns;
  constant C_SCOPE      : string := C_TB_SCOPE_DEFAULT;

  constant c_max_bytes : natural   := 100;  -- max bytes per packet to send
  constant GC_DUT_FIFO_DEPTH : natural := 4;
--------------------------------------------------------------------------------
-- Signal declarations
--------------------------------------------------------------------------------
  signal   clk         : std_logic := '0';
  signal   areset      : std_logic := '0';
  signal   clock_ena   : boolean   := false;

  -- The axistream interface is gathered in one record
  signal axistream_if_m : t_axistream_if(tdata(GC_DATA_WIDTH -1 downto 0),
                                         tkeep((GC_DATA_WIDTH/8)-1 downto 0),
                                         tuser(GC_USER_WIDTH-1 downto 0),
                                         tstrb((GC_DATA_WIDTH/8)-1 downto 0),
                                         tid(GC_ID_WIDTH-1 downto 0),
                                         tdest(GC_DEST_WIDTH-1 downto 0)
                                        );
  signal axistream_if_s : t_axistream_if(tdata(GC_DATA_WIDTH -1 downto 0),
                                         tkeep((GC_DATA_WIDTH/8)-1 downto 0),
                                         tuser(GC_USER_WIDTH -1 downto 0),
                                         tstrb((GC_DATA_WIDTH/8)-1 downto 0),
                                         tid(GC_ID_WIDTH-1 downto 0),
                                         tdest(GC_DEST_WIDTH-1 downto 0)
                                         );

--------------------------------------------------------------------------------
-- Component declarations
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
begin
  -----------------------------
  -- Instantiate Testharness
  -----------------------------
  i_axistream_test_harness : entity bitvis_vip_axistream.test_harness(struct_vvc)
    generic map(
      GC_DATA_WIDTH => GC_DATA_WIDTH,
      GC_USER_WIDTH => GC_USER_WIDTH,
      GC_ID_WIDTH   => GC_ID_WIDTH,
      GC_DEST_WIDTH => GC_DEST_WIDTH,
      GC_DUT_FIFO_DEPTH => GC_DUT_FIFO_DEPTH,
      GC_INCLUDE_TUSER => GC_INCLUDE_TUSER
      )
    port map(
      clk            => clk,
      areset         => areset,
      axistream_if_m_VVC2FIFO => axistream_if_m,
      axistream_if_s_FIFO2VVC => axistream_if_s
      );

  i_ti_uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;

  -- Set up clock generator
  p_clock : clock_generator(clk, clock_ena, C_CLK_PERIOD, "axistream CLK");

  ------------------------------------------------
  -- PROCESS: p_main
  ------------------------------------------------
  p_main : process
    -- BFM config
    variable axistream_bfm_config : t_axistream_bfm_config := C_AXISTREAM_BFM_CONFIG_DEFAULT;

    variable v_cnt        : integer                          := 0;
    variable v_idx        : integer                          := 0;
    variable v_numBytes   : integer                          := 0;
    variable v_numWords   : integer                          := 0;
    variable v_data_array : t_byte_array(0 to c_max_bytes-1);
    variable v_user_array : t_user_array(v_data_array'range) := (others => (others => '0'));
    variable v_strb_array : t_strb_array(v_data_array'range) := (others => (others => '0'));
    variable v_id_array : t_id_array(v_data_array'range) := (others => (others => '0'));
    variable v_dest_array : t_dest_array(v_data_array'range) := (others => (others => '0'));

    variable v_cmd_idx : natural;
    variable v_fetch_is_accepted : boolean;
    variable v_result_from_fetch : bitvis_vip_axistream.vvc_cmd_pkg.t_vvc_result;

    variable v_alert_num_mismatch : boolean := false;

  begin

    -- To avoid that log files from different test cases (run in separate
    -- simulations) overwrite each other run.py provides separate test case
    -- directories through the runner_cfg generic (<root>/vunit_out/tests/<test case
    -- name>). When not using run.py the default path is the current directory
    -- (<root>/vunit_out/<simulator>). These directories are used by VUnit
    -- itself and these lines make sure that BVUL do to.
    set_log_file_name(join(output_path(runner_cfg), "_Log.txt"));
    set_alert_file_name(join(output_path(runner_cfg), "_Alert.txt"));

    -- Setup the VUnit runner with the input configuration.
    test_runner_setup(runner, runner_cfg);

    -- The default behavior for VUnit is to stop the simulation on a failing
    -- check when running from script but keep on running when running without
    -- script. The rationale for this and how you can change that behavior is
    -- described at the bottom of this file (see Stopping the Simulation on
    -- Failing Checks). The following if statement causes BVUL checks to behave
    -- in the same way.
    if not active_python_runner(runner_cfg) then
      set_alert_stop_limit(error, 0);
    end if;

    await_uvvm_initialization(VOID);

    -- override default config with settings for this testbench
    axistream_bfm_config.clock_period             := C_CLK_PERIOD;
    axistream_bfm_config.setup_time               := C_CLK_PERIOD/4;
    axistream_bfm_config.hold_time                := C_CLK_PERIOD/4;
    axistream_bfm_config.max_wait_cycles          := 1000;
    axistream_bfm_config.max_wait_cycles_severity := error;

    -- Default: use same config for both the master and slave VVC
    shared_axistream_vvc_config(0).bfm_config := axistream_bfm_config;  -- vvc_methods_pkg
    shared_axistream_vvc_config(1).bfm_config := axistream_bfm_config;  -- vvc_methods_pkg
    shared_axistream_vvc_config(2).bfm_config := axistream_bfm_config;  -- vvc_methods_pkg
    shared_axistream_vvc_config(3).bfm_config := axistream_bfm_config;  -- vvc_methods_pkg

    -- Print the configuration to the log
    report_global_ctrl(VOID);
    report_msg_id_panel(VOID);

    disable_log_msg(ALL_MESSAGES);
    enable_log_msg(ID_LOG_HDR);
    enable_log_msg(ID_SEQUENCER);

    disable_log_msg(AXISTREAM_VVCT, 0, ALL_MESSAGES);
    disable_log_msg(AXISTREAM_VVCT, 1, ALL_MESSAGES);
    enable_log_msg(AXISTREAM_VVCT, 0, ID_BFM);
    enable_log_msg(AXISTREAM_VVCT, 1, ID_BFM);
    enable_log_msg(AXISTREAM_VVCT, 0, ID_PACKET_INITIATE);
    enable_log_msg(AXISTREAM_VVCT, 1, ID_PACKET_INITIATE);
--    enable_log_msg(AXISTREAM_VVCT, 0, ID_PACKET_DATA);
    enable_log_msg(AXISTREAM_VVCT, 3, ID_PACKET_DATA);
    enable_log_msg(AXISTREAM_VVCT, 0, ID_PACKET_COMPLETE);
    enable_log_msg(AXISTREAM_VVCT, 1, ID_PACKET_COMPLETE);
    enable_log_msg(AXISTREAM_VVCT, 0, ID_IMMEDIATE_CMD);
    enable_log_msg(AXISTREAM_VVCT, 1, ID_IMMEDIATE_CMD);


    log(ID_LOG_HDR, "Start Simulation of AXI-Stream");
    ------------------------------------------------------------
    clock_ena <= true;  -- the axistream_reset routine assumes the clock is running
    gen_pulse(areset, 10*C_CLK_PERIOD, "Pulsing reset for 10 clock periods");

    ------------------------------------------------------------
    log("TC: axistream VVC Master (VVC_IDX=2) transmits directly to VVC Slave (VVC_IDX=3)");
    ------------------------------------------------------------

    for i in 1 to 10 loop
      v_numBytes := 96; --random(1, c_max_bytes);
      v_numWords := integer(ceil(real(v_numBytes)/(real(GC_DATA_WIDTH)/8.0)));
      for byte in 0 to v_numBytes-1 loop
        v_data_array(byte) := random(v_data_array(0)'length);
      end loop;
      for word in 0 to v_numWords-1 loop
        v_user_array(word) := random(v_user_array(0)'length); -- Note that only (GC_USER_WIDTH-1 downto 0) will be used
        v_strb_array(word) := random(v_strb_array(0)'length);
        v_id_array(word)   := random(v_id_array(0)'length);
        v_dest_array(word) := random(v_dest_array(0)'length);
      end loop;

      -- Make sure ready signal is toggled in various ways
      shared_axistream_vvc_config(3).bfm_config.ready_low_at_word_num  := random(0, v_numWords-1);
      shared_axistream_vvc_config(3).bfm_config.ready_low_duration     := random(0, 5);
      shared_axistream_vvc_config(3).bfm_config.ready_default_value    := random(VOId);
      --

      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1), "transmit VVC2VVC. Default tuser etc, i="&to_string(i));
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1), "expect  VVC2VVC. Default tuser etc, i="&to_string(i));

      log("include tuser test. VVC Master (VVC_IDX=2) transmits directly to VVC Slave (VVC_IDX=3)");
      ------------------------------------------------------------
      -- tuser = something. tstrb etc = default
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit VVC2VVC, tuser set, but default tstrb etc");
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect VVC2VVC,   tuser set, but default tstrb etc");
      -----------------------------------------------------------
      -- tuser tstrb etc is set (no defaults)
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1),
      v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
      "transmit VVC2VVC, tuser tstrb etc are set");
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1),v_strb_array(0 to v_numWords-1),v_id_array(0 to v_numWords-1),v_dest_array(0 to v_numWords-1), "expect VVC2VVC,   tuser set, but default tstrb etc");
      -----------------------------------------------------------

      -- test _receive, Check that tuser is fetched correctly
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit before receive, Check that tuser is fetched correctly,i="&to_string(i));
      axistream_receive (AXISTREAM_VVCT, 3, "test axistream_receive / fetch_result (with tuser) ");
      v_cmd_idx := get_last_received_cmd_idx(AXISTREAM_VVCT, 3);

      await_completion(AXISTREAM_VVCT, 2, 1 ms);
      await_completion(AXISTREAM_VVCT, 3, 1 ms);
      fetch_result(AXISTREAM_VVCT, 3, NA, v_cmd_idx, v_result_from_fetch, "Fetch result using the simple fetch_result overload");
      check_value(v_result_from_fetch.data_array(0 to v_numBytes-1) = v_data_array(0 to v_numBytes-1), error, "Verifying that fetched data is as expected", C_TB_SCOPE_DEFAULT);
      check_value(v_result_from_fetch.data_length, v_numBytes, error, "Verifying that fetched data_length is as expected", C_TB_SCOPE_DEFAULT);
      for i in 0 to v_numWords-1 loop
        check_value(v_result_from_fetch.user_array(i)(GC_USER_WIDTH-1 downto 0) = v_user_array(i)(GC_USER_WIDTH-1 downto 0) , error, "Verifying that fetched tuser_array("&to_string(i)&") is as expected", C_TB_SCOPE_DEFAULT);
      end loop;

      -- verify alert if the data is not as expected
      increment_expected_alerts(warning, 1);
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit, data wrogn ,i="&to_string(i));
      v_idx               := random(0, v_numBytes-1);
      v_data_array(v_idx) := not v_data_array(v_idx);
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   data wrong ,i="&to_string(i), warning);


      -- verify alert if the tuser is not what is expected
      increment_expected_alerts(warning, 1);
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "transmit, tuser wrogn ,i="&to_string(i));

      v_idx               := random(0, v_numWords-1);
      v_user_array(v_idx) := not v_user_array(v_idx); -- Provoke alert in axistream_expect()
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "expect,   tuser wrong ,i="&to_string(i), warning);

      -- verify alert if the tstrb is not what is expected
      increment_expected_alerts(warning, 1);
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "transmit, tstrb wrogn ,i="&to_string(i));
      v_idx               := random(0, v_numWords-1);
      v_strb_array(v_idx) := not v_strb_array(v_idx); -- Provoke alert in axistream_expect()
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "expect,   tstrb wrong ,i="&to_string(i), warning);

      -- verify alert if the tid is not what is expected
      increment_expected_alerts(warning, 1);
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "transmit, tid wrogn ,i="&to_string(i));
      v_idx               := random(0, v_numWords-1);
      v_id_array(v_idx) := not v_id_array(v_idx); -- Provoke alert in axistream_expect()
      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "expect,   tid wrong ,i="&to_string(i), warning);

      -- verify alert if the tdest is not what is expected
      increment_expected_alerts(warning, 1);
      axistream_transmit_bytes(AXISTREAM_VVCT, 2, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "transmit, tdest wrogn ,i="&to_string(i));
      v_idx               := random(0, v_numWords-1);
      v_dest_array(v_idx) := not v_dest_array(v_idx); -- Provoke alert in axistream_expect()

      v_id_array := (others => (others => '-')); -- also test the use of don't care

      axistream_expect_bytes (AXISTREAM_VVCT, 3, v_data_array(0 to v_numBytes-1),
        v_user_array(0 to v_numWords-1), v_strb_array(0 to v_numWords-1), v_id_array(0 to v_numWords-1), v_dest_array(0 to v_numWords-1),
        "expect,   tdest wrong ,i="&to_string(i), warning);


      await_completion(AXISTREAM_VVCT, 3, 1 ms, "Wait for receive to finish");
    end loop;  -- i



    ------------------------------------------------------------
    log("TC: axistream_receive and fetch_result ");
    ------------------------------------------------------------
    v_numBytes := random(1, c_max_bytes);
    v_numWords := integer(ceil(real(v_numBytes)/(real(GC_DATA_WIDTH)/8.0)));
    for byte in 0 to v_numBytes-1 loop
      v_data_array(byte) := random(v_data_array(0)'length);
    end loop;

    for word in 0 to v_numWords-1 loop
        v_user_array(word) := random(v_user_array(0)'length);
        v_strb_array(word) := random(v_strb_array(0)'length);
        v_id_array(word)   := random(v_id_array(0)'length);
        v_dest_array(word) := random(v_dest_array(0)'length);
    end loop;

    axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), "transmit");
    axistream_receive (AXISTREAM_VVCT, 1, "test axistream_receive / fetch_result (without tuser) ");
    v_cmd_idx := get_last_received_cmd_idx(AXISTREAM_VVCT, 1);

    await_completion(AXISTREAM_VVCT, 1, 1 ms, "Wait for receive to finish");
    fetch_result(AXISTREAM_VVCT, 1, NA, v_cmd_idx, v_result_from_fetch, "Fetch result using the simple fetch_result overload");
    check_value(v_result_from_fetch.data_array(0 to v_numBytes-1) = v_data_array(0 to v_numBytes-1), error, "Verifying that fetched data is as expected", C_TB_SCOPE_DEFAULT, ID_SEQUENCER);
    check_value(v_result_from_fetch.data_length, v_numBytes, error, "Verifying that fetched data_length is as expected", C_TB_SCOPE_DEFAULT, ID_SEQUENCER);

    ------------------------------------------------------------
    log("TC: axistream transmit when tready=0 from DUT at start of transfer  ");
    ------------------------------------------------------------

    -- Fill DUT FIFO to provoke tready=0
    v_numBytes := 1;
    for i in 0 to GC_DUT_FIFO_DEPTH - 1 loop
      v_data_array(0) := std_logic_vector(to_unsigned(i, v_data_array(0)'length));
      axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), "transmit to fill DUT,i="&to_string(i));
    end loop;
    await_completion(AXISTREAM_VVCT, 0, 1 ms);
    wait for 100 ns;


    -- DUT FIFO is now full. Schedule the transmit which will wait for tready until DUT is read from later
    v_data_array(0) := x"D0";
    axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), "start transmit while tready=0");


    -- Make DUT not full anymore. Check data from DUT equals transmitted data
    for i in 0 to GC_DUT_FIFO_DEPTH - 1 loop
      v_data_array(0) := std_logic_vector(to_unsigned(i, v_data_array(0)'length));
      axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), "expect ");
    end loop;

    v_data_array(0) := x"D0";
    axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), "expect ");

    wait for 100 ns;

    ------------------------------------------------------------
    log("TC: axistream transmits: ");
    ------------------------------------------------------------
    shared_axistream_vvc_config(0).inter_bfm_delay.delay_type := TIME_FINISH2START;
    for i in 0 to 2 loop
      -- Various delay between each transmit
      shared_axistream_vvc_config(0).inter_bfm_delay.delay_in_time := i*c_Clk_Period;

      for i in 1 to 20 loop
        v_numBytes := random(1, c_max_bytes);
        v_numWords := integer(ceil(real(v_numBytes)/(real(GC_DATA_WIDTH)/8.0)));
        -- Generate packet data
        v_cnt      := i;
        for byte in 0 to v_numBytes-1 loop
          v_data_array(byte) := std_logic_vector(to_unsigned(v_cnt, v_data_array(0)'length));
          v_user_array(byte) := std_logic_vector(to_unsigned(v_cnt, v_user_array(0)'length));
          v_strb_array(byte) := std_logic_vector(to_unsigned(v_cnt, v_strb_array(0)'length));
          v_id_array(byte)   := std_logic_vector(to_unsigned(v_cnt, v_id_array(0)'length));
          v_dest_array(byte) := std_logic_vector(to_unsigned(v_cnt, v_dest_array(0)'length));
          v_cnt              := v_cnt + 1;
        end loop;

        -- VVC call
        -- tuser, tstrb etc = default
        axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), "transmit,i="&to_string(i));
        axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), "expect,  i="&to_string(i));


        if GC_INCLUDE_TUSER then
           -- tuser = something. tstrb etc = default
           axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit, tuser set,i="&to_string(i));
           axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   tuser set,i="&to_string(i));

           -- test _receive, Check that tuser is fetched correctly
           axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit before receive, Check that tuser is fetched correctly,i="&to_string(i));
           axistream_receive (AXISTREAM_VVCT, 1, "test axistream_receive / fetch_result (with tuser) ");
           v_cmd_idx := get_last_received_cmd_idx(AXISTREAM_VVCT, 1);

           await_completion(AXISTREAM_VVCT, 0, 1 ms);
           await_completion(AXISTREAM_VVCT, 1, 1 ms);
           fetch_result(AXISTREAM_VVCT, 1, NA, v_cmd_idx, v_result_from_fetch, "Fetch result using the simple fetch_result overload");
           check_value(v_result_from_fetch.data_array(0 to v_numBytes-1) = v_data_array(0 to v_numBytes-1), error, "Verifying that fetched data is as expected", C_TB_SCOPE_DEFAULT);
           check_value(v_result_from_fetch.data_length, v_numBytes, error, "Verifying that fetched data_length is as expected", C_TB_SCOPE_DEFAULT);
           for i in 0 to v_numWords-1 loop
             check_value(v_result_from_fetch.user_array(i)(GC_USER_WIDTH-1 downto 0) = v_user_array(i)(GC_USER_WIDTH-1 downto 0) , error, "Verifying that fetched tuser_array("&to_string(i)&") is as expected", C_TB_SCOPE_DEFAULT);
           end loop;


           -- verify alert if the data is not what is expected
           increment_expected_alerts(warning, 1);
           axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit, data wrogn ,i="&to_string(i));
           v_idx               := random(0, v_numBytes-1);
           v_data_array(v_idx) := not v_data_array(v_idx);
           axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   data wrong ,i="&to_string(i), warning);


           -- verify alert if the tuser is not what is expected
           increment_expected_alerts(warning, 1);
           axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit, tuser wrogn ,i="&to_string(i));
           v_idx               := random(0, v_numWords-1);
           v_user_array(v_idx) := not v_user_array(v_idx);
           axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   tuser wrong ,i="&to_string(i), warning);
        end if;

      end loop;

      -- Await completion on both VVCs
      await_completion(AXISTREAM_VVCT, 0, 1 ms);
      await_completion(AXISTREAM_VVCT, 1, 1 ms);
      report_alert_counters(INTERMEDIATE);  -- Report final counters and print conclusion for simulation (Success/Fail)
    end loop;

    -- verify alert if the 'tlast' is not where expected
    for i in 1 to 1 loop
      if GC_INCLUDE_TUSER then
        v_numBytes := (GC_DATA_WIDTH/8) + 1; -- So that v_numBytes - 1 makes the tlast in previous clock cycle
        v_numWords := integer(ceil(real(v_numBytes)/(real(GC_DATA_WIDTH)/8.0)));

        await_completion(AXISTREAM_VVCT, 1, 1 ms);
        axistream_transmit_bytes(AXISTREAM_VVCT, 0, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "transmit, tlast wrogn ,i="&to_string(i));
        increment_expected_alerts(warning, 1);
        shared_axistream_vvc_config(1).bfm_config.protocol_error_severity := warning;
        v_numBytes                                                      := v_numBytes - 1;

        axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   tlast wrong ,i="&to_string(i), NO_ALERT);

        -- due to the premature tlast, make an extra call to read the remaining (corrupt) packet
        increment_expected_alerts(warning, 1);
        axistream_expect_bytes (AXISTREAM_VVCT, 1, v_data_array(0 to v_numBytes-1), v_user_array(0 to v_numWords-1), "expect,   tlast wrong ,i="&to_string(i), NO_ALERT);

        await_completion(AXISTREAM_VVCT, 1, 1 ms);
        -- Cleanup after test case
        shared_axistream_vvc_config(1).bfm_config.protocol_error_severity := error;
      end if;
    end loop;


    --==================================================================================================
    -- Ending the simulation
    --------------------------------------------------------------------------------------
    -- allow some time for completion
    for i in 0 to 10 loop
      wait until rising_edge(clk);
    end loop;
    report_alert_counters(VOID);  -- Report final counters and print conclusion for simulation (Success/Fail)
    log("SIMULATION COMPLETED");

    -- Cleanup VUnit. The UVVM-Util error status is imported into VUnit at this
    -- point. This is neccessary when the UVVM-Util alert stop limit is set such that
    -- UVVM-Util doesn't stop on the first error. In that case VUnit has no way of
    -- knowing the error status unless you tell it.
    for alert_level in note to t_alert_level'right loop
      if alert_level /= MANUAL_CHECK and get_alert_counter(alert_level, REGARD) /= get_alert_counter(alert_level, EXPECT) then
        v_alert_num_mismatch := true;
      end if;
    end loop;

    test_runner_cleanup(runner, v_alert_num_mismatch);
    wait;

  end process p_main;
end func;