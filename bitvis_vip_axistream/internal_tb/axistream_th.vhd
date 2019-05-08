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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Include Verification IPs
library bitvis_vip_axistream;
use bitvis_vip_axistream.axistream_bfm_pkg.all;

--=================================================================================================
entity test_harness is
  generic(
    constant GC_DATA_WIDTH     : natural := 32;
    constant GC_USER_WIDTH     : natural := 1;
    constant GC_ID_WIDTH       : natural := 1;
    constant GC_DEST_WIDTH     : natural := 1;
    constant GC_DUT_FIFO_DEPTH : natural := 4;
    CONSTANT GC_INCLUDE_TUSER  : boolean := true  -- If tuser is used in AXI interface
  );
  port(
    signal clk          : in std_logic;
    signal areset       : in std_logic;

    -- BFM
    signal axistream_if_m_VVC2FIFO : inout t_axistream_if( tdata(  GC_DATA_WIDTH   -1 downto 0),
                                                tkeep( (GC_DATA_WIDTH/8)-1 downto 0),
                                                tuser(  GC_USER_WIDTH   -1 downto 0),
                                                tstrb(  GC_DATA_WIDTH/8 -1 downto 0),
                                                tid(    GC_ID_WIDTH     -1 downto 0),
                                                tdest(  GC_DEST_WIDTH   -1 downto 0)
                                              );
    signal axistream_if_s_FIFO2VVC : inout t_axistream_if( tdata(  GC_DATA_WIDTH   -1 downto 0),
                                                tkeep( (GC_DATA_WIDTH/8)-1 downto 0),
                                                tuser(  GC_USER_WIDTH   -1 downto 0),
                                                tstrb(  GC_DATA_WIDTH/8 -1 downto 0),
                                                tid(    GC_ID_WIDTH     -1 downto 0),
                                                tdest(  GC_DEST_WIDTH   -1 downto 0)
                                              );

    signal axistream_if_m_VVC2VVC : inout t_axistream_if( tdata(  GC_DATA_WIDTH   -1 downto 0),
                                                tkeep( (GC_DATA_WIDTH/8)-1 downto 0),
                                                tuser(  GC_USER_WIDTH   -1 downto 0),
                                                tstrb(  GC_DATA_WIDTH/8 -1 downto 0),
                                                tid(    GC_ID_WIDTH     -1 downto 0),
                                                tdest(  GC_DEST_WIDTH   -1 downto 0)
                                              );
    signal axistream_if_s_VVC2VVC : inout t_axistream_if( tdata(  GC_DATA_WIDTH   -1 downto 0),
                                                tkeep( (GC_DATA_WIDTH/8)-1 downto 0),
                                                tuser(  GC_USER_WIDTH   -1 downto 0),
                                                tstrb(  GC_DATA_WIDTH/8 -1 downto 0),
                                                tid(    GC_ID_WIDTH     -1 downto 0),
                                                tdest(  GC_DEST_WIDTH   -1 downto 0)
                                              )
  );


end entity test_harness;
--=================================================================================================
architecture struct_simple of test_harness is



begin
  -----------------------------
  -- Instantiate a DUT model : a self-made AXI-Stream FIFO
  -- (I tried using a Xilinx FIFO IP between the BFMs but could only get verilog files, causing Modelsim licencing issues)
  -----------------------------
   i_axis_fifo : entity work.axis_fifo
   generic map (
      GC_DATA_WIDTH => GC_DATA_WIDTH ,
      GC_USER_WIDTH => GC_USER_WIDTH ,
      GC_FIFO_DEPTH => GC_DUT_FIFO_DEPTH
   )
   PORT MAP (
     rst     => areset,
     clk        => clk,
     s_axis_tready      => axistream_if_m_VVC2FIFO.tready,
     s_axis_tvalid      => axistream_if_m_VVC2FIFO.tvalid,
     s_axis_tdata       => axistream_if_m_VVC2FIFO.tdata,
     s_axis_tuser       => axistream_if_m_VVC2FIFO.tuser,
     s_axis_tkeep       => axistream_if_m_VVC2FIFO.tkeep,
     s_axis_tlast       => axistream_if_m_VVC2FIFO.tlast,
     m_axis_tready      => axistream_if_s_FIFO2VVC.tready,
     m_axis_tvalid      => axistream_if_s_FIFO2VVC.tvalid,
     m_axis_tdata       => axistream_if_s_FIFO2VVC.tdata,
     m_axis_tuser       => axistream_if_s_FIFO2VVC.tuser,
     m_axis_tkeep       => axistream_if_s_FIFO2VVC.tkeep,
     m_axis_tlast       => axistream_if_s_FIFO2VVC.tlast,
     empty              => open
   );

end struct_simple;

--=================================================================================================
architecture struct_vvc of test_harness is

begin
  -----------------------------
  -- Instantiate a DUT model : a self-made AXI-Stream FIFO
  -- (I tried using a Xilinx FIFO IP between the BFMs but could only get verilog files, causing Modelsim licencing issues)
  -----------------------------
   i_axis_fifo : entity work.axis_fifo
   generic map (
      GC_DATA_WIDTH => GC_DATA_WIDTH ,
      GC_USER_WIDTH => GC_USER_WIDTH ,
      GC_FIFO_DEPTH => GC_DUT_FIFO_DEPTH
   )
   PORT MAP (
     rst     => areset,
     clk        => clk,
     s_axis_tready      => axistream_if_m_VVC2FIFO.tready,
     s_axis_tvalid      => axistream_if_m_VVC2FIFO.tvalid,
     s_axis_tdata       => axistream_if_m_VVC2FIFO.tdata,
     s_axis_tuser       => axistream_if_m_VVC2FIFO.tuser,
     s_axis_tkeep       => axistream_if_m_VVC2FIFO.tkeep,
     s_axis_tlast       => axistream_if_m_VVC2FIFO.tlast,
     m_axis_tready      => axistream_if_s_FIFO2VVC.tready,
     m_axis_tvalid      => axistream_if_s_FIFO2VVC.tvalid,
     m_axis_tdata       => axistream_if_s_FIFO2VVC.tdata,
     m_axis_tuser       => axistream_if_s_FIFO2VVC.tuser,
     m_axis_tkeep       => axistream_if_s_FIFO2VVC.tkeep,
     m_axis_tlast       => axistream_if_s_FIFO2VVC.tlast,
     empty              => open
   );

   -- This is not necessary, the BFM can receive 'U' without problems
   -- axistream_if_s_FIFO2VVC.tstrb   <= (others => '0');
   -- axistream_if_s_FIFO2VVC.tid   <= (others => '0');
   -- axistream_if_s_FIFO2VVC.tdest   <= (others => '0');
   -- g_Not_Include_tuser: if (not GC_INCLUDE_TUSER) generate
   --    axistream_if_s_FIFO2VVC.tuser <= (others => '0');
   -- end generate;

  -----------------------------
  -- vvc/executors
  -----------------------------
  -- master vvc that transmit to FIFO
  i_axistream_vvc_master_VVC2FIFO : entity work.axistream_vvc
    generic map(
      GC_VVC_IS_MASTER => true,
      GC_DATA_WIDTH   => GC_DATA_WIDTH,
      GC_USER_WIDTH   => GC_USER_WIDTH,
      GC_ID_WIDTH     => GC_ID_WIDTH,
      GC_DEST_WIDTH   => GC_DEST_WIDTH,
      GC_INSTANCE_IDX => 0
      )
    port map(
      clk               => clk,
      axistream_vvc_if  => axistream_if_m_VVC2FIFO
      );

  -- slave vvc that receive from FIFO
  i_axistream_vvc_slave_FIFO2VVC : entity work.axistream_vvc
    generic map(
      GC_VVC_IS_MASTER => false,
      GC_DATA_WIDTH   => GC_DATA_WIDTH,
      GC_USER_WIDTH   => GC_USER_WIDTH,
      GC_ID_WIDTH     => GC_ID_WIDTH,
      GC_DEST_WIDTH   => GC_DEST_WIDTH,
      GC_INSTANCE_IDX => 1
      )
    port map(
      clk              => clk,
      axistream_vvc_if => axistream_if_s_FIFO2VVC
    );

  --------------------------------------------------------------------

  -- master vvc that transmit directly to Slave VVC
  i_axistream_vvc_master_VVC2VVC : entity work.axistream_vvc
    generic map(
      GC_VVC_IS_MASTER => true,
      GC_DATA_WIDTH   => GC_DATA_WIDTH,
      GC_USER_WIDTH   => GC_USER_WIDTH,
      GC_ID_WIDTH     => GC_ID_WIDTH,
      GC_DEST_WIDTH   => GC_DEST_WIDTH,
      GC_INSTANCE_IDX => 2
      )
    port map(
      clk               => clk,
      axistream_vvc_if  => axistream_if_m_VVC2VVC
      );

  -- slave vvc that receive directly from Master VVC
  i_axistream_vvc_slave_VVC2VVC : entity work.axistream_vvc
    generic map(
      GC_VVC_IS_MASTER => false,
      GC_DATA_WIDTH   => GC_DATA_WIDTH,
      GC_USER_WIDTH   => GC_USER_WIDTH,
      GC_ID_WIDTH     => GC_ID_WIDTH,
      GC_DEST_WIDTH   => GC_DEST_WIDTH,
      GC_INSTANCE_IDX => 3
      )
    port map(
      clk              => clk,
      axistream_vvc_if => axistream_if_m_VVC2VVC
    );

end struct_vvc;

architecture struct_multiple_vvc of test_harness is
begin
  -----------------------------
  -- Multiple VVCs just to test await_any_completion
  -----------------------------
  gen_axistream_vvc_master : for i in 0 to 7 generate
    signal axistream_if_m_local : t_axistream_if( tdata(  GC_DATA_WIDTH   -1 downto 0),
                                                tkeep( (GC_DATA_WIDTH/8)-1 downto 0),
                                                tuser(  GC_USER_WIDTH   -1 downto 0),
                                                tstrb(  GC_DATA_WIDTH/8 -1 downto 0),
                                                tid(    GC_ID_WIDTH     -1 downto 0),
                                                tdest(  GC_DEST_WIDTH   -1 downto 0)
                                              );
  begin
    axistream_if_m_local.tready <= '1';

    i_axistream_vvc_master : entity work.axistream_vvc
      generic map(
        GC_VVC_IS_MASTER => true,
        GC_DATA_WIDTH    => GC_DATA_WIDTH,
        GC_USER_WIDTH    => GC_USER_WIDTH,
        GC_ID_WIDTH      => GC_ID_WIDTH,
        GC_DEST_WIDTH    => GC_DEST_WIDTH,
        GC_INSTANCE_IDX  => i
        )
      port map(
        clk               => clk,
        axistream_vvc_if  => axistream_if_m_local
        );
  end generate gen_axistream_vvc_master;

end struct_multiple_vvc;

