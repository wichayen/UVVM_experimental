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

---------------------------------------------------------------------------------------------
-- Description : See library quick reference (under 'doc') and README-file(s)
---------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library uvvm_util;
context uvvm_util.uvvm_util_context;

use work.rand_tb_pkg.all;

--HDLUnit:TB
entity rand_multi_method_tb is
  generic(
    GC_TESTCASE : string
  );
end entity;

architecture func of rand_multi_method_tb is

  constant C_NUM_RAND_REPETITIONS   : natural := 7;
  constant C_NUM_WEIGHT_REPETITIONS : natural := 1000; -- Changing this value affects check_weight_distribution() C_MARGIN.
  constant C_NUM_CYCLIC_REPETITIONS : natural := 3;

begin

  --------------------------------------------------------------------------------
  -- PROCESS: p_main
  --------------------------------------------------------------------------------
  p_main : process
    variable v_rand          : t_rand;
    variable v_seeds         : t_positive_vector(0 to 1);
    variable v_int           : integer;
    variable v_prev_int      : integer := 0;
    variable v_real          : real;
    --variable v_time          : time;
    variable v_int_vec       : integer_vector(0 to 4);
    variable v_prev_int_vec  : integer_vector(0 to 4) := (others => 0);
    --variable v_real_vec      : real_vector(0 to 4);
    --variable v_time_vec      : time_vector(0 to 4);
    variable v_uns           : unsigned(3 downto 0);
    variable v_uns_long      : unsigned(127 downto 0);
    --variable v_uns_long_min  : unsigned(127 downto 0);
    --variable v_uns_long_max  : unsigned(127 downto 0);
    --variable v_prev_uns_long : unsigned(127 downto 0) := (others => '0');
    --variable v_sig           : signed(3 downto 0);
    --variable v_sig_long      : signed(127 downto 0);
    --variable v_sig_long_min  : signed(127 downto 0);
    --variable v_sig_long_max  : signed(127 downto 0);
    --variable v_prev_sig_long : signed(127 downto 0) := (others => '0');
    --variable v_slv           : std_logic_vector(3 downto 0);
    --variable v_slv_long      : std_logic_vector(127 downto 0);
    --variable v_slv_long_min  : std_logic_vector(127 downto 0);
    --variable v_slv_long_max  : std_logic_vector(127 downto 0);
    --variable v_prev_slv_long : std_logic_vector(127 downto 0) := (others => '0');
    --variable v_std           : std_logic;
    --variable v_bln           : boolean;
    variable v_value_cnt     : t_integer_cnt(-32 to 31) := (others => 0);
    variable v_num_values    : natural;
    --variable v_bit_check     : std_logic_vector(1 downto 0);
    variable v_mean          : real;
    variable v_std_deviation : real;

  begin

    -------------------------------------------------------------------------------------
    log(ID_LOG_HDR_LARGE, "Start Simulation of Randomization package - " & GC_TESTCASE);
    -------------------------------------------------------------------------------------
    enable_log_msg(ID_RAND_GEN);
    enable_log_msg(ID_RAND_CONF);

    --===================================================================================
    if GC_TESTCASE = "rand_basic" then
    --===================================================================================
      v_rand.set_name("long_string_abcdefghijklmnopqrstuvwxyz");
      check_value(v_rand.get_name(VOID), "long_string_abcdefgh", ERROR, "Checking name"); -- C_RAND_MAX_NAME_LENGTH = 20
      v_rand.set_scope("long_string_abcdefghijklmnopqrstuvwxyz");
      check_value(v_rand.get_scope(VOID), "long_string_abcdefghijklmnopqr", ERROR, "Checking scope"); -- C_LOG_SCOPE_WIDTH = 30

      v_rand.set_name("MY_RAND_GEN");
      check_value(v_rand.get_name(VOID), "MY_RAND_GEN", ERROR, "Checking name");
      v_rand.set_scope("MY SCOPE");
      check_value(v_rand.get_scope(VOID), "MY SCOPE", ERROR, "Checking scope");

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing seeds");
      ------------------------------------------------------------
      log(ID_SEQUENCER, "Check default seed values");
      v_seeds := v_rand.get_rand_seeds(VOID);
      check_value(v_seeds(0), C_RAND_INIT_SEED_1, ERROR, "Checking initial seed 1");
      check_value(v_seeds(1), C_RAND_INIT_SEED_2, ERROR, "Checking initial seed 2");

      log(ID_SEQUENCER, "Set and get seeds with vector value");
      v_seeds(0) := 500;
      v_seeds(1) := 5000;
      v_rand.set_rand_seeds(v_seeds);
      v_seeds := v_rand.get_rand_seeds(VOID);
      check_value(v_seeds(0), 500, ERROR, "Checking seed 1");
      check_value(v_seeds(1), 5000, ERROR, "Checking seed 2");

      log(ID_SEQUENCER, "Set and get seeds with positive values");
      v_seeds(0) := 800;
      v_seeds(1) := 8000;
      v_rand.set_rand_seeds(v_seeds(0), v_seeds(1));
      v_rand.get_rand_seeds(v_seeds(0), v_seeds(1));
      check_value(v_seeds(0), 800, ERROR, "Checking seed 1");
      check_value(v_seeds(1), 8000, ERROR, "Checking seed 2");

      log(ID_SEQUENCER, "Set seeds with string value");
      v_rand.set_rand_seeds(v_rand'instance_name);
      v_seeds := v_rand.get_rand_seeds(VOID);
      check_value(v_seeds(0) /= 800, ERROR, "Checking initial seed 1");
      check_value(v_seeds(1) /= 8000, ERROR, "Checking initial seed 2");

      ------------------------------------------------------------
      -- Integer
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing integer (unconstrained)");
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      log(ID_LOG_HDR, "Testing integer (range)");
      v_num_values := 5;
      v_rand.add_range(-2, 2);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 12;
      v_rand.add_range(8, 9);
      v_rand.add_range(15, 16);
      v_rand.add_range(-7, -5);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS*2 loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,9),(15,16),(-7,-5)));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (set of values)");
      v_num_values := 7;
      v_rand.add_val(10);
      v_rand.add_val(20);
      v_rand.add_val((-5,-3,4));
      v_rand.add_val((6,8));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ONLY,(-5,-3,4,6,8,10,20));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (exclude values)");
      v_rand.excl_val((-1,0,1));
      v_rand.excl_val(10);
      v_rand.excl_val(100);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,integer'right)), EXCL,(-1,0,1,10,100));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + set of values)");
      v_num_values := 4;
      v_rand.add_range(-1, 1);
      v_rand.add_val(10);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-1,1)), ADD,(0 => 10));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 9;
      v_rand.add_range(8, 9);
      v_rand.add_val((-5,-3,4));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-1,1),(8,9)), ADD,(-5,-3,4,10));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + exclude values)");
      v_num_values := 2;
      v_rand.add_range(-2, 2);
      v_rand.excl_val((-1,0,1));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)), EXCL,(-1,0,1));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 4;
      v_rand.add_range(8, 10);
      v_rand.excl_val(10);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,10)), EXCL,(-1,0,1,10));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (set of values + exclude values)");
      v_num_values := 4;
      v_rand.add_val((-6,-4,-2,0,2,4,6));
      v_rand.excl_val((-2,0,2));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ONLY,(-6,-4,4,6));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + set of values + exclude values)");
      v_num_values := 5;
      v_rand.add_range(-2, 2);
      v_rand.add_val((-5,-3,4));
      v_rand.excl_val((-5,-1,1));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)), ADD,(-5,-3,4), EXCL,(-5,-1,1));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 8;
      v_rand.add_range(8, 10);
      v_rand.add_val((20,30,40));
      v_rand.excl_val((9,30,40));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,10)), ADD,(-5,-3,4,20,30,40), EXCL,(-5,-1,1,9,30,40));
        count_rand_value(v_value_cnt, v_int);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (full range)");
      v_rand.add_range(integer'left, -1);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,-1)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      v_rand.add_range(0, integer'right);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 8);
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range(10, 0);

      -- TODO: uncomment when implemented
      v_rand.add_range(0, 2);
      v_rand.add_range_real(0.0, 2.0);
      --v_rand.add_range_time(0 ps, 2 ps);
      --v_rand.add_range(x"0", x"F");
      --v_rand.add_range(x"0", x"F");
      v_rand.clear_constraints(VOID);

      v_rand.add_val((0,2,4));
      v_rand.add_val_real((0.0,2.0,4.0));
      --v_rand.add_val_time((0 ps,2 ps,4 ps));
      --v_rand.add_val((x"0",x"A",x"F"));
      --v_rand.add_val((x"0",x"A",x"F"));
      v_rand.clear_constraints(VOID);

      v_rand.excl_val(2);
      v_rand.excl_val_real(2.0);
      --v_rand.excl_val_time(2 ps);
      --v_rand.excl_val(x"A");
      --v_rand.excl_val(x"A");
      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(1, 10);
      v_rand.add_val_weight_real(1.0, 10);
      --v_rand.add_val_weight_time(1 ps, 10);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(1, 5, 10);
      v_rand.add_range_weight_real(1.0, 5.0, 10);
      --v_rand.add_range_weight_time(1 ps, 5 ps, 10);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0, 2);
      v_int      := v_rand.randm(VOID);
      v_real     := v_rand.randm(VOID);
      --v_time     := v_rand.randm(VOID);
      v_int_vec  := v_rand.randm(v_int_vec'length);
      --v_real_vec := v_rand.randm(v_real_vec'length);
      --v_time_vec := v_rand.randm(v_time_vec'length);
      v_uns      := v_rand.randm(v_uns'length);
      --v_sig      := v_rand.randm(v_sig'length);
      --v_slv      := v_rand.randm(v_slv'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0, 2);
      v_rand.set_uniqueness(UNIQUE);
      v_int := v_rand.randm(VOID);
      v_rand.set_uniqueness(NON_UNIQUE);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(integer'left, 0);
      v_rand.add_range(0, integer'right);
      v_int := v_rand.randm(VOID);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Integer Vector
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing integer_vector (unconstrained)");
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      log(ID_LOG_HDR, "Testing integer_vector (range)");
      v_num_values := 12;
      v_rand.add_range(-2, 2);
      v_rand.add_range(8, 9);
      v_rand.add_range(15, 16);
      v_rand.add_range(-7, -5);
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS*2 loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-2,2),(8,9),(15,16),(-7,-5)));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS*2 loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-2,2),(8,9),(15,16),(-7,-5)));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (set of values)");
      v_num_values := 7;
      v_rand.add_val((-5,-3,4));
      v_rand.add_val((6,8));
      v_rand.add_val(10);
      v_rand.add_val(20);
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-5,-3,4,6,8,10,20));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-5,-3,4,6,8,10,20));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (exclude values)");
      v_rand.excl_val((-1,0,1));
      v_rand.excl_val(10);
      v_rand.excl_val(100);
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)), EXCL,(-1,0,1,10,100));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)), EXCL,(-1,0,1,10,100));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + set of values)");
      v_num_values := 9;
      v_rand.add_range(-1, 1);
      v_rand.add_val((-5,-3));
      v_rand.add_range(8, 9);
      v_rand.add_val((4,10));
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-1,1),(8,9)), ADD,(-5,-3,4,10));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-1,1),(8,9)), ADD,(-5,-3,4,10));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + exclude values)");
      v_num_values := 7;
      v_rand.add_range(-3, 4);
      v_rand.excl_val((-1,0,1));
      v_rand.add_range(8, 10);
      v_rand.excl_val(10);
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-3,4),(8,10)), EXCL,(-1,0,1,10));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-3,4),(8,10)), EXCL,(-1,0,1,10));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (set of values + exclude values)");
      v_num_values := 6;
      v_rand.add_val((-8,-6,-4,-2,0,2,4,6,8));
      v_rand.excl_val((-2,0,2));
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-8,-6,-4,4,6,8));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-8,-6,-4,4,6,8));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + set of values + exclude values)");
      v_num_values := 8;
      v_rand.add_range(-2, 2);
      v_rand.add_val((-5,-3,4));
      v_rand.excl_val((-5,-1,1));
      v_rand.add_range(8, 10);
      v_rand.add_val((20,30,40));
      v_rand.excl_val((9,30,40));
      v_rand.set_uniqueness(NON_UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-2,2),(8,10)), ADD,(-5,-3,4,20,30,40), EXCL,(-5,-1,1,9,30,40));
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.set_uniqueness(UNIQUE);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ((-2,2),(8,10)), ADD,(-5,-3,4,20,30,40), EXCL,(-5,-1,1,9,30,40));
        check_uniqueness(v_int_vec);
        count_rand_value(v_value_cnt, v_int_vec);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_rand.add_val((0,1));
      v_rand.set_uniqueness(UNIQUE);
      v_int_vec := v_rand.randm(v_int_vec'length);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Real
      -- It is impossible to verify every value within a real range
      -- is generated, so instead only the rounded values are verified.
      -- There is twice as many repetitions since the values are discrete.
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing real (unconstrained)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_real := v_rand.randm(VOID);

      log(ID_LOG_HDR, "Testing real (range)");
      v_num_values := 3;
      v_rand.add_range_real(-1.0, 1.0);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, (0 => (-1.0,1.0)));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 7;
      v_rand.add_range_real(-5.7, -5.2);
      v_rand.add_range_real(8.0, 9.0);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ((-5.7,-5.2),(-1.0,1.0),(8.0,9.0)));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (set of values)");
      v_num_values := 4;
      v_rand.add_val_real(-10.0);
      v_rand.add_val_real((-2.4,2.7));
      v_rand.add_val_real(6.64);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ONLY,(-10.0,-2.4,2.7,6.64));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (exclude values)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_rand.excl_val_real((-1.0,0.0,1.0));
      v_real := v_rand.randm(VOID);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (range + set of values)");
      v_num_values := 4;
      v_rand.add_range_real(-1.0, 1.0);
      v_rand.add_val_real(-10.0);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, (0 => (-1.0,1.0)), ADD,(0 => -10.0));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 8;
      v_rand.add_range_real(-5.7, -5.2);
      v_rand.add_val_real((-2.4,2.7));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS*2 loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ((-1.0,1.0),(-5.7,-5.2)), ADD,(-10.0,-2.4,2.7));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (range + exclude values)");
      v_num_values := 3;
      v_rand.add_range_real(-1.0, 1.0);
      v_rand.excl_val_real((-1.0,0.0,1.0));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, (0 => (-1.0,1.0)), EXCL,(-1.0,0.0,1.0));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 5;
      v_rand.add_range_real(-5.7, -5.2);
      v_rand.excl_val_real((-5.7,-5.5,-5.2));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ((-1.0,1.0),(-5.7,-5.2)), EXCL,(-1.0,0.0,1.0,-5.7,-5.5,-5.2));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (set of values + exclude values)");
      v_num_values := 3;
      v_rand.add_val_real((-10.0,-2.4,0.0,2.7,6.64));
      v_rand.excl_val_real((-2.4,0.0));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ONLY,(-10.0,2.7,6.64));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (range + set of values + exclude values)");
      v_num_values := 5;
      v_rand.add_range_real(-1.0, 1.0);
      v_rand.add_val_real((-10.0,-2.4));
      v_rand.excl_val_real((-1.0,0.0,1.0));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, (0 => (-1.0,1.0)), ADD,(-10.0,-2.4), EXCL,(-1.0,0.0,1.0));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 7;
      v_rand.add_range_real(-5.7, -5.2);
      v_rand.add_val_real((2.7,4.6));
      v_rand.excl_val_real((-2.4,2.7));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS*2 loop
        v_real := v_rand.randm(VOID);
        check_rand_value(v_real, ((-1.0,1.0),(-5.7,-5.2)), ADD,(-10.0,-2.4,2.7,4.6), EXCL,(-1.0,0.0,1.0,-2.4,2.7));
        count_rand_value(v_value_cnt, v_real);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing real (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 10);
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range_real(10.0, 10.0);
      v_rand.add_range_real(10.0, 0.0);

      -- TODO: uncomment when implemented
      v_rand.add_range_real(0.0, 2.0);
      v_rand.add_range(0, 2);
      --v_rand.add_range_time(0 ps, 2 ps);
      --v_rand.add_range(x"0", x"F");
      --v_rand.add_range(x"0", x"F");
      v_rand.clear_constraints(VOID);

      v_rand.add_val_real((0.0,2.0,4.0));
      v_rand.add_val((0,2,4));
      --v_rand.add_val_time((0 ps,2 ps,4 ps));
      --v_rand.add_val((x"0",x"A",x"F"));
      --v_rand.add_val((x"0",x"A",x"F"));
      v_rand.clear_constraints(VOID);

      v_rand.excl_val_real(2.0);
      v_rand.excl_val(2);
      --v_rand.excl_val_time(2 ps);
      --v_rand.excl_val(x"A");
      --v_rand.excl_val(x"A");
      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight_real(1.0, 10);
      v_rand.add_val_weight(1, 10);
      --v_rand.add_val_weight_time(1 ps, 10);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight_real(1.0, 5.0, 10);
      v_rand.add_range_weight(1, 5, 10);
      --v_rand.add_range_weight_time(1 ps, 5 ps, 10);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(0.0, 2.0);
      v_int      := v_rand.randm(VOID);
      v_real     := v_rand.randm(VOID);
      --v_time     := v_rand.randm(VOID);
      v_int_vec  := v_rand.randm(v_int_vec'length);
      --v_real_vec := v_rand.randm(v_real_vec'length);
      --v_time_vec := v_rand.randm(v_time_vec'length);
      v_uns      := v_rand.randm(v_uns'length);
      --v_sig      := v_rand.randm(v_sig'length);
      --v_slv      := v_rand.randm(v_slv'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(0.0, 2.0);
      v_rand.set_uniqueness(UNIQUE);
      v_real := v_rand.randm(VOID);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Unsigned
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing unsigned (length)");
      v_num_values := 2**v_uns'length;
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2**v_uns'length-1)));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      log(ID_LOG_HDR, "Testing unsigned (range)");
      v_num_values := 4;
      v_rand.add_range(0, 3);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,3)));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 8;
      v_rand.add_range(8, 9);
      v_rand.add_range(14, 15);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,3),(8,9),(14,15)));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (set of values)");
      v_num_values := 6;
      v_rand.add_val((0,1,2));
      v_rand.add_val(5);
      v_rand.add_val((7,9));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ONLY,(0,1,2,5,7,9));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (exclude)");
      v_num_values := 2**v_uns'length-10;
      v_rand.excl_val((0,1,2,3,4));
      v_rand.excl_val((5,6,7,8,9));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2**v_uns'length-1)), EXCL,(0,1,2,3,4,5,6,7,8,9));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + set of values)");
      v_num_values := 4;
      v_rand.add_range(0, 2);
      v_rand.add_val(10);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2)), ADD,(0 => 10));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 8;
      v_rand.add_range(8, 9);
      v_rand.add_val((12,15));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,2),(8,9)), ADD,(10,12,15));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + exclude values)");
      v_num_values := 2;
      v_rand.add_range(0, 3);
      v_rand.excl_val((1,2));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,3)), EXCL,(1,2));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 4;
      v_rand.add_range(8, 10);
      v_rand.excl_val(10);
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,3),(8,10)), EXCL,(1,2,10));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (set of values + exclude values)");
      v_num_values := 4;
      v_rand.add_val((0,2,4,6,8,10,12));
      v_rand.excl_val((2,6,10));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ONLY,(0,4,8,12));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + set of values + exclude values)");
      v_num_values := 3;
      v_rand.add_range(0, 2);
      v_rand.add_val((7,8));
      v_rand.excl_val((1,8));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2)), ADD,(7,8), EXCL,(1,8));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 7;
      v_rand.add_range(4, 6);
      v_rand.add_val((10,12,15));
      v_rand.excl_val((5,15));
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,2),(4,6)), ADD,(7,8,10,12,15), EXCL,(1,8,5,15));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 3);
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range(0, 2**16);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_val((2**17, 2**18));
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-4, -2);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0, 2);
      v_rand.set_uniqueness(UNIQUE);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Unsigned constraints
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing unsigned (range)");
      v_num_values := 4;
      v_rand.add_range_unsigned(x"00", x"03");
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value_long(v_uns, (0 => (x"0",x"3")));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 9;
      v_rand.add_range_unsigned(x"007", x"00B");
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value_long(v_uns, ((x"0",x"3"),(x"7",x"B")));
        count_rand_value(v_value_cnt, v_uns);
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range long vectors)");
      v_num_values := 4;
      v_rand.add_range_unsigned(x"0F000000000000000000000000000000", x"0F000000000000000000000000000003");
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns_long := v_rand.randm(v_uns_long'length);
        check_rand_value_long(v_uns_long, (0 => (x"0F000000000000000000000000000000",x"0F000000000000000000000000000003")));
        count_rand_value(v_value_cnt, v_uns_long-x"0F000000000000000000000000000000");
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_num_values := 9;
      v_rand.add_range_unsigned(x"0F000000000000000000000000000007", x"0F00000000000000000000000000000B");
      for i in 1 to v_num_values*C_NUM_RAND_REPETITIONS loop
        v_uns_long := v_rand.randm(v_uns_long'length);
        check_rand_value_long(v_uns_long, ((x"0F000000000000000000000000000000",x"0F000000000000000000000000000003"),
          (x"0F000000000000000000000000000007",x"0F00000000000000000000000000000B")));
        count_rand_value(v_value_cnt, v_uns_long-x"0F000000000000000000000000000000");
      end loop;
      check_uniform_distribution(v_value_cnt, v_num_values);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 11);
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range_unsigned(x"0", x"0");
      v_rand.add_range_unsigned(x"2", x"0");

      v_rand.add_range_unsigned(x"00000F000000000000000000000000000000", x"0F000000000000000000000000000003");
      v_rand.add_range_unsigned(x"0F000000000000000000000000000000", x"00000F000000000000000000000000000003");

      -- TODO: uncomment when implemented
      v_rand.add_range_unsigned(x"0", x"F");
      v_rand.add_range(0, 2);
      v_rand.add_range_real(0.0, 2.0);
      --v_rand.add_range_time(0 ps, 2 ps);
      --v_rand.add_range_signed(x"0", x"F");
      v_rand.clear_constraints(VOID);

      v_rand.add_range_unsigned(x"0", x"2");
      v_int      := v_rand.randm(VOID);
      v_real     := v_rand.randm(VOID);
      --v_time     := v_rand.randm(VOID);
      v_int_vec  := v_rand.randm(v_int_vec'length);
      --v_real_vec := v_rand.randm(v_real_vec'length);
      --v_time_vec := v_rand.randm(v_time_vec'length);
      v_uns      := v_rand.randm(v_uns'length);
      --v_sig      := v_rand.randm(v_sig'length);
      --v_slv      := v_rand.randm(v_slv'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_unsigned(x"0F000000000000000000000000000000", x"0F000000000000000000000000000003");
      v_uns := v_rand.randm(v_uns'length);
      v_rand.add_range_unsigned(x"0F000000000000000000000000000007", x"0F00000000000000000000000000000B");
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_unsigned(x"0", x"2");
      v_rand.set_uniqueness(UNIQUE);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);


    --===================================================================================
    elsif GC_TESTCASE = "rand_weighted" then
    --===================================================================================
      log(ID_SEQUENCER, "Reducing log messages from rand_pkg");
      disable_log_msg(ID_LOG_MSG_CTRL);

      ------------------------------------------------------------
      -- Weighted integer
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing weighted integer (single values) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val_weight(-5,1);
      v_rand.add_val_weight(10,3);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,1),(10,3)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(-5,1);
      v_rand.add_val_weight(10,0);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,1),(10,0)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(-5,10);
      v_rand.add_val_weight(0,30);
      v_rand.add_val_weight(10,60);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,10),(0,30),(10,60)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted integer (ranges w/default mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.set_range_weight_default_mode(COMBINED_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = COMBINED_WEIGHT, ERROR, "Checking range_weight_default_mode");
      v_rand.add_range_weight(-5,-3,30);
      v_rand.add_val_weight(0,20);
      v_rand.add_range_weight(9,10,50);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,10),(-4,10),(-3,10),(0,20),(9,25),(10,25)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.set_range_weight_default_mode(INDIVIDUAL_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = INDIVIDUAL_WEIGHT, ERROR, "Checking range_weight_default_mode");
      v_rand.add_range_weight(-5,-3,30);
      v_rand.add_val_weight(0,20);
      v_rand.add_range_weight(9,10,50);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,30),(-4,30),(-3,30),(0,20),(9,50),(10,50)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted integer (ranges w/explicit mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_range_weight(-5,-3,30,INDIVIDUAL_WEIGHT);
      v_rand.add_val_weight(0,20);
      v_rand.add_range_weight(9,10,50,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,30),(-4,30),(-3,30),(0,20),(9,25),(10,25)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted integer (mixed with non-weighted constraint) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val((20,30));
      v_rand.add_range_weight(-5,-3,4,INDIVIDUAL_WEIGHT);
      v_rand.add_val_weight(0,2);
      v_rand.add_range_weight(9,10,4,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_int);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,4),(-4,4),(-3,4),(0,2),(9,2),(10,2),(20,1),(30,1)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_config(VOID);

      log(ID_LOG_HDR, "Testing weighted integer (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 3);
      increment_expected_alerts(TB_WARNING, 3);
      v_rand.add_range_weight(1,1,30);
      v_rand.add_range_weight(10,5,30);

      v_rand.add_val_weight(1,0);
      v_rand.add_val_weight(2,0);
      v_int := v_rand.randm(VOID);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(-5,3,30);
      v_rand.excl_val((-4));
      v_int := v_rand.randm(VOID);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(-5,3,30);
      v_rand.set_cyclic_mode(CYCLIC);
      v_int := v_rand.randm(VOID);
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(-5,3,30);
      v_rand.set_uniqueness(UNIQUE);
      v_int := v_rand.randm(VOID);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Weighted integer vector
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing weighted integer vector (not supported)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_rand.add_range_weight(-5,-3,30);
      v_int_vec := v_rand.randm(v_int_vec'length);
      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Weighted real
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing weighted real (single values) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val_weight_real(-5.0,1);
      v_rand.add_val_weight_real(10.1,3);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,1),(10,3)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight_real(-5.0,1);
      v_rand.add_val_weight_real(10.1,0);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,1),(10,0)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight_real(-5.0,10);
      v_rand.add_val_weight_real(0.0,30);
      v_rand.add_val_weight_real(10.1,60);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,10),(0,30),(10,60)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted real (ranges w/default mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.set_range_weight_default_mode(COMBINED_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = COMBINED_WEIGHT, ERROR, "Checking range_weight_default_mode");
      v_rand.add_range_weight_real(-5.0,-3.0,30);
      v_rand.add_val_weight_real(0.0,20);
      v_rand.add_range_weight_real(9.3,10.1,50);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,-3,30),(0,0,20),(9,10,50)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.set_range_weight_default_mode(INDIVIDUAL_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = INDIVIDUAL_WEIGHT, ERROR, "Checking range_weight_default_mode");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_rand.add_range_weight_real(-5.0,-3.0,30);
      v_rand.add_val_weight_real(0.0,20);
      v_rand.add_range_weight_real(9.3,10.1,50);
      v_real := v_rand.randm(VOID);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted real (ranges w/explicit mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_range_weight_real(-5.0,-3.0,30,COMBINED_WEIGHT);
      v_rand.add_val_weight_real(0.0,20);
      v_rand.add_range_weight_real(9.3,10.1,50,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,-3,30),(0,0,20),(9,10,50)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted real (mixed with non-weighted constraint) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val_real((20.0,30.0));
      v_rand.add_range_weight_real(-5.0,-3.0,4,COMBINED_WEIGHT);
      v_rand.add_val_weight_real(0.0,2);
      v_rand.add_range_weight_real(9.0,10.0,4,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_real := v_rand.randm(VOID);
        count_rand_value(v_value_cnt, v_real);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((-5,-3,4),(0,0,2),(9,10,4),(20,20,1),(30,30,1)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_config(VOID);

      log(ID_LOG_HDR, "Testing weighted real (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 3);
      increment_expected_alerts(TB_WARNING, 3);
      v_rand.add_range_weight_real(1.0,1.0,30);
      v_rand.add_range_weight_real(10.0,5.0,30);

      v_rand.add_val_weight_real(1.0,0);
      v_rand.add_val_weight_real(2.0,0);
      v_real := v_rand.randm(VOID);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight_real(-5.0,-3.0,30);
      v_rand.excl_val_real((-4.0));
      v_real := v_rand.randm(VOID);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight_real(-5.0,-3.0,30);
      v_rand.set_cyclic_mode(CYCLIC);
      v_real := v_rand.randm(VOID);
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight_real(-5.0,-3.0,30);
      v_rand.set_uniqueness(UNIQUE);
      v_real := v_rand.randm(VOID);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);


      ------------------------------------------------------------
      -- Weighted unsigned
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing weighted unsigned (single values) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val_weight(5,1);
      v_rand.add_val_weight(10,3);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((5,1),(10,3)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(5,1);
      v_rand.add_val_weight(10,0);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((5,1),(10,0)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(0,10);
      v_rand.add_val_weight(5,30);
      v_rand.add_val_weight(10,60);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((0,10),(5,30),(10,60)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted unsigned (ranges w/default mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.set_range_weight_default_mode(COMBINED_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = COMBINED_WEIGHT, ERROR, "Checking range_weight_default_mode");
      v_rand.add_range_weight(0,2,30);
      v_rand.add_val_weight(5,20);
      v_rand.add_range_weight(9,10,50);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((0,10),(1,10),(2,10),(5,20),(9,25),(10,25)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      v_rand.set_range_weight_default_mode(INDIVIDUAL_WEIGHT);
      check_value(v_rand.get_range_weight_default_mode(VOID) = INDIVIDUAL_WEIGHT, ERROR, "Checking range_weight_default_mode");
      v_rand.add_range_weight(0,2,30);
      v_rand.add_val_weight(5,20);
      v_rand.add_range_weight(9,10,50);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((0,30),(1,30),(2,30),(5,20),(9,50),(10,50)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted unsigned (ranges w/explicit mode) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_range_weight(0,2,30,INDIVIDUAL_WEIGHT);
      v_rand.add_val_weight(5,20);
      v_rand.add_range_weight(9,10,50,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((0,30),(1,30),(2,30),(5,20),(9,25),(10,25)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing weighted unsigned (mixed with non-weighted constraint) - Generate " & to_string(C_NUM_WEIGHT_REPETITIONS) & " random values for each test");
      v_rand.add_val((14,15));
      v_rand.add_range_weight(0,2,4,INDIVIDUAL_WEIGHT);
      v_rand.add_val_weight(5,2);
      v_rand.add_range_weight(9,10,4,COMBINED_WEIGHT);
      for i in 1 to C_NUM_WEIGHT_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        count_rand_value(v_value_cnt, v_uns);
        if i = 1 then
          disable_log_msg(ID_RAND_GEN);
        end if;
      end loop;
      check_weight_distribution(v_value_cnt, ((0,4),(1,4),(2,4),(5,2),(9,2),(10,2),(14,1),(15,1)));
      enable_log_msg(ID_RAND_GEN);

      v_rand.clear_config(VOID);

      log(ID_LOG_HDR, "Testing weighted unsigned (invalid parameters)");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 3);
      increment_expected_alerts(TB_WARNING, 3);
      v_rand.add_range_weight(0,2**16,30);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight(2**17,30);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(-4,-2,30);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(0,3,30);
      v_rand.excl_val((4));
      v_uns := v_rand.randm(v_uns'length);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(0,3,30);
      v_rand.set_cyclic_mode(CYCLIC);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range_weight(0,3,30);
      v_rand.set_uniqueness(UNIQUE);
      v_uns := v_rand.randm(v_uns'length);
      v_rand.set_uniqueness(NON_UNIQUE);

      v_rand.clear_config(VOID);


    --===================================================================================
    elsif GC_TESTCASE = "rand_cyclic" then
    --===================================================================================
      ------------------------------------------------------------
      -- Random cyclic integer
      ------------------------------------------------------------
      v_rand.set_cyclic_mode(CYCLIC);

      log(ID_LOG_HDR, "Testing integer (unconstrained)");
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      log(ID_LOG_HDR, "Testing integer (range)");
      v_num_values := 5;
      v_rand.add_range(-2, 2);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 12;
      v_rand.add_range(8, 9);
      v_rand.add_range(15, 16);
      v_rand.add_range(-7, -5);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,9),(15,16),(-7,-5)));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (set of values)");
      v_num_values := 7;
      v_rand.add_val(10);
      v_rand.add_val(20);
      v_rand.add_val((-5,-3,4));
      v_rand.add_val((6,8));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ONLY,(-5,-3,4,6,8,10,20));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (exclude values)");
      v_rand.excl_val((-1,0,1));
      v_rand.excl_val(10);
      v_rand.excl_val(100);
      for i in 1 to C_NUM_RAND_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (integer'left,integer'right)), EXCL,(-1,0,1,10,100));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int /= v_prev_int, TB_ERROR, "Checking value is different than previous one");
        v_prev_int := v_int;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + set of values)");
      v_num_values := 4;
      v_rand.add_range(-1, 1);
      v_rand.add_val(10);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-1,1)), ADD,(0 => 10));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 9;
      v_rand.add_range(8, 9);
      v_rand.add_val((-5,-3,4));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-1,1),(8,9)), ADD,(-5,-3,4,10));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + exclude values)");
      v_num_values := 2;
      v_rand.add_range(-2, 2);
      v_rand.excl_val((-1,0,1));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)), EXCL,(-1,0,1));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 4;
      v_rand.add_range(8, 10);
      v_rand.excl_val(10);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,10)), EXCL,(-1,0,1,10));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (set of values + exclude values)");
      v_num_values := 4;
      v_rand.add_val((-6,-4,-2,0,2,4,6));
      v_rand.excl_val((-2,0,2));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ONLY,(-6,-4,4,6));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer (range + set of values + exclude values)");
      v_num_values := 5;
      v_rand.add_range(-2, 2);
      v_rand.add_val((-5,-3,4));
      v_rand.excl_val((-5,-1,1));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, (0 => (-2,2)), ADD,(-5,-3,4), EXCL,(-5,-1,1));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 8;
      v_rand.add_range(8, 10);
      v_rand.add_val((20,30,40));
      v_rand.excl_val((9,30,40));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_int := v_rand.randm(VOID);
        check_rand_value(v_int, ((-2,2),(8,10)), ADD,(-5,-3,4,20,30,40), EXCL,(-5,-1,1,9,30,40));
        count_rand_value(v_value_cnt, v_int);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Random cyclic integer vector
      ------------------------------------------------------------
      v_rand.set_cyclic_mode(CYCLIC);

      log(ID_LOG_HDR, "Testing integer_vector (unconstrained)");
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      log(ID_LOG_HDR, "Testing integer_vector (range)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_range(-2, 2);
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (-2,2)));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (set of values)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_val((-2,-1,0,1,2));
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-2,-1,0,1,2));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (exclude values)");
      v_rand.excl_val((-1,0,1));
      v_rand.excl_val(10);
      v_rand.excl_val(100);
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (integer'left,integer'right)), EXCL,(-1,0,1,10,100));
        -- Since range of values is too big to verify the distribution, we only check that the value is different than the previous one
        check_value(v_int_vec /= v_prev_int_vec, TB_ERROR, "Checking value is different than previous one");
        v_prev_int_vec := v_int_vec;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + set of values)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_range(-1, 2);
      v_rand.add_val(-5);
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (-1,2)), ADD,(0 => -5));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + exclude values)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_range(-3, 4);
      v_rand.excl_val((-1,0,1));
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (-3,4)), EXCL,(-1,0,1));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (set of values + exclude values)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_val((-8,-6,-4,-2,0,2,4,6,8));
      v_rand.excl_val((-2,0,2,4));
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, ONLY,(-8,-6,-4,6,8));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing integer_vector (range + set of values + exclude values)");
      v_num_values := 5; -- same as v_int_vec'length
      v_rand.add_range(-2, 2);
      v_rand.add_val(-5);
      v_rand.excl_val(1);
      for i in 1 to C_NUM_CYCLIC_REPETITIONS loop
        v_int_vec := v_rand.randm(v_int_vec'length);
        check_rand_value(v_int_vec, (0 => (-2,2)), ADD,(0 => -5), EXCL,(0 => 1));
        count_rand_value(v_value_cnt, v_int_vec);
        check_cyclic_distribution(v_value_cnt, v_num_values);
      end loop;

      log(ID_LOG_HDR, "Testing invalid parameters");
      increment_expected_alerts_and_stop_limit(TB_ERROR, 2);
      v_rand.clear_config(VOID);
      v_rand.set_uniqueness(UNIQUE);
      v_rand.set_cyclic_mode(CYCLIC);

      v_rand.clear_config(VOID);
      v_rand.set_cyclic_mode(CYCLIC);
      v_rand.set_uniqueness(UNIQUE);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Random cyclic real & real vector
      ------------------------------------------------------------
      v_rand.set_cyclic_mode(CYCLIC);

      log(ID_LOG_HDR, "Testing real (not supported)");
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range_real(-2.0, 2.0);
      v_real := v_rand.randm(VOID);
      --v_real_vec := v_rand.randm(v_real_vec'length); -- TODO

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Random cyclic unsigned
      ------------------------------------------------------------
      v_rand.set_cyclic_mode(CYCLIC);

      log(ID_LOG_HDR, "Testing unsigned (length)");
      v_num_values := 2**v_uns'length;
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2**v_uns'length-1)));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      log(ID_LOG_HDR, "Testing unsigned (range)");
      v_num_values := 4;
      v_rand.add_range(0, 3);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,3)));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 8;
      v_rand.add_range(8, 9);
      v_rand.add_range(14, 15);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,3),(8,9),(14,15)));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (set of values)");
      v_num_values := 6;
      v_rand.add_val((0,1,2));
      v_rand.add_val(5);
      v_rand.add_val((7,9));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ONLY,(0,1,2,5,7,9));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (exclude)");
      v_num_values := 2**v_uns'length-10;
      v_rand.excl_val((0,1,2,3,4));
      v_rand.excl_val((5,6,7,8,9));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2**v_uns'length-1)), EXCL,(0,1,2,3,4,5,6,7,8,9));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + set of values)");
      v_num_values := 4;
      v_rand.add_range(0, 2);
      v_rand.add_val(10);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2)), ADD,(0 => 10));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 8;
      v_rand.add_range(8, 9);
      v_rand.add_val((12,15));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,2),(8,9)), ADD,(10,12,15));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + exclude values)");
      v_num_values := 2;
      v_rand.add_range(0, 3);
      v_rand.excl_val((1,2));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,3)), EXCL,(1,2));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 4;
      v_rand.add_range(8, 10);
      v_rand.excl_val(10);
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,3),(8,10)), EXCL,(1,2,10));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (set of values + exclude values)");
      v_num_values := 4;
      v_rand.add_val((0,2,4,6,8,10,12));
      v_rand.excl_val((2,6,10));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ONLY,(0,4,8,12));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_constraints(VOID);

      log(ID_LOG_HDR, "Testing unsigned (range + set of values + exclude values)");
      v_num_values := 3;
      v_rand.add_range(0, 2);
      v_rand.add_val((7,8));
      v_rand.excl_val((1,8));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, (0 => (0,2)), ADD,(7,8), EXCL,(1,8));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_num_values := 7;
      v_rand.add_range(4, 6);
      v_rand.add_val((10,12,15));
      v_rand.excl_val((5,15));
      for i in 1 to v_num_values*C_NUM_CYCLIC_REPETITIONS loop
        v_uns := v_rand.randm(v_uns'length);
        check_rand_value(v_uns, ((0,2),(4,6)), ADD,(7,8,10,12,15), EXCL,(1,8,5,15));
        count_rand_value(v_value_cnt, v_uns);
        if i mod v_num_values = 0 then
          check_cyclic_distribution(v_value_cnt, v_num_values);
        end if;
      end loop;

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      -- Random cyclic unsigned constraints
      ------------------------------------------------------------
      v_rand.set_cyclic_mode(CYCLIC);

      log(ID_LOG_HDR, "Testing unsigned (not supported)");
      increment_expected_alerts(TB_WARNING, 1);
      v_rand.add_range_unsigned(x"00", x"03");
      v_uns := v_rand.randm(v_uns'length);

      v_rand.clear_config(VOID);


    --===================================================================================
    elsif GC_TESTCASE = "rand_report" then
    --===================================================================================
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing config report with integer constraints");
      ------------------------------------------------------------
      v_rand.set_name("RAND_INT_1");
      v_rand.add_range(10,20);
      v_rand.add_range(30,40);
      v_rand.add_range(50,60);
      v_rand.add_val(100);
      v_rand.excl_val((15,35,55));
      v_rand.set_cyclic_mode(CYCLIC);
      v_int := v_rand.randm(VOID);
      v_rand.report_config(VOID);

      v_rand.set_name("RAND_INT_2");
      v_rand.add_val_weight(200,8);
      v_rand.report_config(VOID);

      v_rand.clear_config(VOID);

      v_rand.set_name("RAND_INT_3");
      v_rand.add_range(10,20);
      v_rand.add_range_weight(30,40,5);
      v_rand.add_range_weight(50,60,10,INDIVIDUAL_WEIGHT);
      v_rand.add_val(100);
      v_rand.add_val_weight(200,8);
      v_int := v_rand.randm(VOID);
      v_rand.report_config(VOID);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing config report with real constraints");
      ------------------------------------------------------------
      v_rand.set_name("RAND_REAL_1");
      v_rand.add_range_real(10.0,20.0);
      v_rand.add_range_real(30.0,40.0);
      v_rand.add_val_real((0.0,0.1,0.2,0.3));
      v_rand.excl_val_real((15.0,35.0));
      v_real := v_rand.randm(VOID);
      v_rand.report_config(VOID);

      v_rand.set_name("RAND_REAL_2");
      v_rand.add_val_weight_real(1.0,8);
      v_rand.report_config(VOID);

      v_rand.clear_config(VOID);

      v_rand.set_name("RAND_REAL_3");
      v_rand.add_range_real(10.0,20.0);
      v_rand.add_range_weight_real(30.0,40.0,5);
      v_rand.add_range_weight_real(50.0,60.0,10);
      v_rand.add_val_real(0.0);
      v_rand.add_val_weight_real(1.0,8);
      v_real := v_rand.randm(VOID);
      v_rand.report_config(VOID);

      v_rand.clear_config(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing config report with unsigned constraints");
      ------------------------------------------------------------
      v_rand.set_name("RAND_UNS_1");
      v_rand.add_range_unsigned(x"0",x"2");
      v_rand.add_range_unsigned(x"6",x"8");
      v_uns := v_rand.randm(v_uns'length);
      v_rand.report_config(VOID);

    --===================================================================================
    elsif GC_TESTCASE = "rand_gaussian" then
    --===================================================================================
      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing Gaussian distribution config");
      ------------------------------------------------------------
      v_rand.set_rand_dist(GAUSSIAN);
      check_value(v_rand.get_rand_dist(VOID) = GAUSSIAN, ERROR, "Checking distribution");
      v_rand.set_rand_dist_mean(5.0);
      check_value(v_rand.get_rand_dist_mean(VOID), 5.0, ERROR, "Checking mean");
      v_rand.set_rand_dist_std_deviation(1.0);
      check_value(v_rand.get_rand_dist_std_deviation(VOID), 1.0, ERROR, "Checking std_deviation");

      increment_expected_alerts(TB_NOTE, 2);
      v_rand.clear_rand_dist_mean(VOID);
      check_value(v_rand.get_rand_dist_mean(VOID), 0.0, ERROR, "Checking mean config was cleared");
      v_rand.clear_rand_dist_std_deviation(VOID);
      check_value(v_rand.get_rand_dist_std_deviation(VOID), 0.0, ERROR, "Checking std_deviation config was cleared");

      disable_log_msg(ID_POS_ACK);
      disable_log_msg(ID_RAND_GEN);
      v_num_values := 5000;

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing Gaussian distribution (integer)");
      ------------------------------------------------------------
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, -10, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, 0, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, -10, 0, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.1;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.5;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 5.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 3.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 6.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      wait for 200 ns;
      v_rand.clear_rand_dist_mean(VOID);
      v_rand.clear_rand_dist_std_deviation(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing Gaussian distribution (integer_vector)");
      ------------------------------------------------------------
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, -10, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, 0, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, -10, 0, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.1;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.5;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 5.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 3.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 6.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "INT_VEC", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      wait for 200 ns;
      v_rand.clear_rand_dist_mean(VOID);
      v_rand.clear_rand_dist_std_deviation(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing Gaussian distribution (real)");
      ------------------------------------------------------------
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, -10, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, 0, 10, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, -10, 0, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.1;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.5;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 5.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 3.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 6.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "REAL", v_num_values, v_value_cnt'low, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      wait for 200 ns;
      v_rand.clear_rand_dist_mean(VOID);
      v_rand.clear_rand_dist_std_deviation(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing Gaussian distribution (unsigned)");
      ------------------------------------------------------------
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, 20, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 10, 20, multi_method => true);

      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, 10, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.1;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.5;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 5.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 3.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 6.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS", v_num_values, 0, v_value_cnt'high, false, v_mean, v_std_deviation, multi_method => true);

      wait for 200 ns;
      v_rand.clear_rand_dist_mean(VOID);
      v_rand.clear_rand_dist_std_deviation(VOID);

      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.1;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 0.5;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 5.0;
      v_std_deviation := 1.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 3.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      v_mean          := 0.0;
      v_std_deviation := 6.0;
      generate_gaussian_distribution(v_rand, v_value_cnt, "UNS_VEC", v_num_values, 0, 31, false, v_mean, v_std_deviation, multi_method => true);

      wait for 200 ns;
      v_rand.clear_rand_dist_mean(VOID);
      v_rand.clear_rand_dist_std_deviation(VOID);

      ------------------------------------------------------------
      log(ID_LOG_HDR, "Testing invalid parameters");
      ------------------------------------------------------------
      v_rand.clear_constraints(VOID);
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);
      v_rand.set_rand_dist_std_deviation(-1.0);

      -- Gaussian distribution can only be used with range
      -- constraints and cannot be combined with cyclic or unique
      -- parameters. The mean must be inside the range.
      v_rand.set_rand_dist_mean(1.0);

      ------------------------------------------------------------
      -- Integer
      ------------------------------------------------------------
      increment_expected_alerts(TB_WARNING, 11);
      increment_expected_alerts_and_stop_limit(TB_ERROR, 2);

      v_int := v_rand.randm(VOID);     -- OK

      v_rand.add_range(0,10);
      v_int := v_rand.randm(VOID);     -- OK
      v_rand.add_range(20,30);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val((-2,-1,0,1,2));
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.excl_val((-1,0,1));
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-2,2);
      v_rand.add_val(-10);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range(20,30);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-2,2);
      v_rand.excl_val((-1,0,1));
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range(20,30);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val((-3,-2,-1,0,1,2,3));
      v_rand.excl_val((-1,0,1));
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-2,2);
      v_rand.add_val(-10);
      v_rand.excl_val(0);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range(20,30);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-2,2);
      v_rand.set_cyclic_mode(CYCLIC);  -- TB_ERROR
      v_int := v_rand.randm(VOID);     -- OK

      v_rand.set_rand_dist(UNIFORM);
      v_rand.set_cyclic_mode(CYCLIC);
      v_rand.set_rand_dist(GAUSSIAN);
      v_int := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(1000, 2000);
      v_int := v_rand.randm(VOID);     -- TB_ERROR
      v_rand.clear_constraints(VOID);

      ------------------------------------------------------------
      -- Integer Vector
      ------------------------------------------------------------
      increment_expected_alerts(TB_WARNING, 5);
      increment_expected_alerts_and_stop_limit(TB_ERROR, 2);

      v_int_vec := v_rand.randm(v_int_vec'length); -- OK

      v_rand.add_range(0,10);
      v_int_vec := v_rand.randm(v_int_vec'length); -- OK
      v_rand.add_range(20,30);
      v_int_vec := v_rand.randm(v_int_vec'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val((-2,-1,0,1,2));
      v_int_vec := v_rand.randm(v_int_vec'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.excl_val((-1,0,1));
      v_int_vec := v_rand.randm(v_int_vec'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.set_rand_dist(UNIFORM);
      v_rand.set_cyclic_mode(CYCLIC);
      v_rand.set_rand_dist(GAUSSIAN);
      v_int_vec := v_rand.randm(v_int_vec'length); -- TB_WARNING
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(-2,2);
      v_rand.set_uniqueness(UNIQUE);               -- TB_ERROR
      v_int_vec := v_rand.randm(v_int_vec'length); -- OK

      v_rand.set_rand_dist(UNIFORM);
      v_rand.set_uniqueness(UNIQUE);
      v_rand.set_rand_dist(GAUSSIAN);
      v_int_vec := v_rand.randm(v_int_vec'length); -- TB_WARNING
      v_rand.set_uniqueness(NON_UNIQUE);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(1000, 2000);
      v_int_vec(0 to 0) := v_rand.randm(1);        -- TB_ERROR
      v_rand.clear_constraints(VOID);

      ------------------------------------------------------------
      -- Real
      ------------------------------------------------------------
      increment_expected_alerts(TB_WARNING, 9);
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);

      v_rand.add_range_real(0.0,10.0);
      v_real := v_rand.randm(VOID);     -- OK
      v_rand.add_range_real(20.0,30.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val_real((-2.0,-1.0,0.0,1.0,2.0));
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(-2.0,2.0);
      v_rand.add_val_real(-10.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range_real(20.0,30.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(-2.0,2.0);
      v_rand.excl_val_real((-1.0,0.0,1.0));
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range_real(20.0,30.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val_real((-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0));
      v_rand.excl_val_real((-1.0,0.0,1.0));
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(-2.0,2.0);
      v_rand.add_val_real(-10.0);
      v_rand.excl_val_real(0.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.add_range_real(20.0,30.0);
      v_real := v_rand.randm(VOID);     -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range_real(1000.0, 2000.0);
      v_real := v_rand.randm(VOID);     -- TB_ERROR
      v_rand.clear_constraints(VOID);

      ------------------------------------------------------------
      -- Unsigned
      ------------------------------------------------------------
      increment_expected_alerts(TB_WARNING, 13);
      increment_expected_alerts_and_stop_limit(TB_ERROR, 1);

      v_uns := v_rand.randm(v_uns'length); -- OK

      v_uns_long := v_rand.randm(v_uns_long'length); -- TB_WARNING

      v_rand.add_range(0,2);
      v_uns := v_rand.randm(v_uns'length); -- OK
      v_rand.add_range(10,15);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range_unsigned(x"0",x"2");
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val((0,1,2));
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.excl_val((0,1));
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0,2);
      v_rand.add_val(5);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.add_range(10,15);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0,2);
      v_rand.excl_val((0,1));
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.add_range(10,15);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val((0,1,2,3));
      v_rand.excl_val((0,1));
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0,2);
      v_rand.add_val(5);
      v_rand.excl_val(0);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.add_range(10,15);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_range(0,2);
      v_rand.set_rand_dist(UNIFORM);
      v_rand.set_cyclic_mode(CYCLIC);
      v_rand.set_rand_dist(GAUSSIAN);
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      v_rand.set_cyclic_mode(NON_CYCLIC);
      v_rand.clear_constraints(VOID);

      v_rand.add_range(10, 15);
      v_uns := v_rand.randm(v_uns'length); -- TB_ERROR
      v_rand.clear_constraints(VOID);

      increment_expected_alerts(TB_WARNING, 3); -- TODO: finish when implemented
      v_rand.add_val_weight(1,20);
      v_int := v_rand.randm(VOID);         -- TB_WARNING
      v_uns := v_rand.randm(v_uns'length); -- TB_WARNING
      --v_sig := v_rand.randm(v_sig'length); -- TB_WARNING
      --v_slv := v_rand.randm(v_slv'length); -- TB_WARNING
      v_rand.clear_constraints(VOID);

      v_rand.add_val_weight_real(1.0,20);
      v_real := v_rand.randm(VOID);        -- TB_WARNING
      v_rand.clear_constraints(VOID);

      --v_rand.add_val_weight_time(1 ps,20);
      --v_time := v_rand.randm(VOID);        -- TB_WARNING
      --v_rand.clear_constraints(VOID);

    end if;

    -----------------------------------------------------------------------------
    -- Ending the simulation
    -----------------------------------------------------------------------------
    wait for 1000 ns;             -- Allow some time for completion
    report_alert_counters(FINAL); -- Report final counters and print conclusion (Success/Fail)
    log(ID_LOG_HDR, "SIMULATION COMPLETED");
    -- Finish the simulation
    std.env.stop;
    wait;  -- to stop completely

  end process p_main;

end architecture func;