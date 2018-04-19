--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: TX_Interface.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--
-- <Description here>
--
-- Targeted device: <Family::IGLOO> <Die::AGLN020V5> <Package::68 QFN>
-- Author: <Name>
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity TX_Interface is
port (
  -- Signals to/from CyUSB --
	Clk_USB       : IN  std_logic;
    DAQ_En        : IN  std_logic;                    -- Data Acquisition Enable
    Sl_fifo_wr_en : OUT  std_logic;                   -- Slave fifo write enable
    DATA_OUT      : OUT std_logic_vector(7 downto 0); -- Slave fifo Data bus
  -- Internal FPGA signals --   
    TX_rdy        : IN  std_logic;                    -- 100Khz clock controlling transfer cycles
    ADC_buffer    : IN  std_logic_vector(23 downto 0);
    Hit_flag      : IN  std_logic;
    Clr_Hit_flag  : OUT std_logic
);
end TX_Interface;


architecture architecture_TX_Interface of TX_Interface is
signal TX_cntr     : integer range 0 to 12 := 0 ; -- Counter controlling transfer sequence
signal TX_cntr_rst : std_logic:= '1';
signal TX_data     : std_logic_vector(23 downto 0):=(others=>'0');

begin
--===================================================================
-- TX_cntr reset & Data buffers reset
--===================================================================
process(TX_RDY)
begin
  if falling_edge(TX_RDY) then
    if (Hit_flag = '1') then
      TX_data <= ADC_buffer;
    else
      TX_data <= (others=>'0');
    end if;
    --if (DAQ_En = '0') then
      --TX_cntr_rst <= '1';
    --else
      --TX_cntr_rst <= '0';
    --end if;
  end if;
end process;

process(TX_RDY)
begin
  if rising_edge(TX_RDY) then
    if (DAQ_EN = '0') then
      TX_cntr_rst <= '1';
    else
      TX_cntr_rst <= '0';
    end if;
  end if;
end process;
--===================================================================
--===================================================================

--===================================================================
-- Counter that controls TX sequence
--===================================================================
process (CLK_USB)
begin
  if falling_edge(CLK_USB) then
    if (TX_cntr_rst = '1') then   -- DAQ not active, reset counter
      TX_cntr <= 0;
    else
      if (TX_RDY='1') then       --if TX_RDY='1', reset counter   
        TX_cntr <= 0;
      elsif (TX_cntr= 10) then   --if TX_counter = 7, do nothing
        TX_cntr <= TX_cntr;
      else
        TX_cntr <= TX_cntr + 1;  --increment counter @ low cycle of clk_100KHz
      end if;
    end if;
  end if;
end process;
--===================================================================
--===================================================================


--===================================================================
-- Process for TX sequence
--===================================================================
process (TX_cntr,TX_data,Hit_flag)
begin
  case TX_cntr is
    when 0 =>
      Sl_fifo_wr_en <= '1'; --active low
      Clr_Hit_flag  <= '0';
      Data_out      <= (others=>'0');--TX_data(23 downto 16);--(others=>'0');
    when 1 =>
      Sl_fifo_wr_en <= '1'; --active low
      Clr_Hit_flag  <= '0';
      Data_out      <= "11111111";--TX_data(23 downto 16);
    when 2 => --Place 1st byte to data bus (Header)
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '1'; --active low
      Data_out      <= "11111111";--TX_data(23 downto 16);
    when 3 => --Send 1st byte
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '0'; 
      Data_out      <= "11111111";--TX_data(23 downto 16);--Data_out;
    when 4 => --Place 2nd byte to data bus
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '1'; 
      Data_out      <= TX_data(23 downto 16);
    when 5 => --Send 2nd byte
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '0'; 
      Data_out      <= TX_data(23 downto 16);--Data_out;
    when 6 => --Place 3rd byte to data bus
      Clr_Hit_flag  <= '1';
      Sl_fifo_wr_en <= '1'; 
      Data_out      <= TX_data(15 downto 8);
    when 7 => --Send 3rd byte
      Clr_Hit_flag  <= '1';
      Sl_fifo_wr_en <= '0'; 
      Data_out      <= TX_data(15 downto 8);--Data_out;
    when 8 => --Place 4th byte to data bus
      Clr_Hit_flag  <= '1';
      Sl_fifo_wr_en <= '1'; 
      Data_out      <= TX_data(7 downto 0);
    when 9 => --Send 4th byte
      Clr_Hit_flag  <= '1';
      Sl_fifo_wr_en <= '0'; 
      Data_out      <= TX_data(7 downto 0);--Data_out;
    when 10 => --End of transfer
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '1'; 
      Data_out      <= TX_data(7 downto 0);--Data_out;
    when others =>
      Clr_Hit_flag  <= '0';
      Sl_fifo_wr_en <= '1';
      Data_out      <= (others=>'0');--TX_data(7 downto 0);--Data_out;
  end case;
end process;
--===================================================================
--===================================================================





end architecture_TX_Interface;
