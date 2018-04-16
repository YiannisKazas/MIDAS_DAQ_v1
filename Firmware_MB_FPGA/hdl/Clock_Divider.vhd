--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: Clock_Divider.vhd
-- File history:
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--      <Revision number>: <Date>: <Comments>
--
-- Description: 
--  Clock Divider to produce TX_RDY signal that controls transfer sequence.
--  Generates a signal with 100KHz frequency by dividing 48MHz clock from USB.
--
-- Targeted device: <Family::IGLOO> <Die::AGLN020V5> <Package::68 QFN>
-- Author: <Name>
--
--------------------------------------------------------------------------------

library IEEE;

use IEEE.std_logic_1164.all;

entity Clock_Divider is
port (
    RESET       : IN  std_logic;
    --ADC_Sclk_En : IN  std_logic;
    --Clk_100MHz  : IN  std_logic;
	CLK_USB     : IN  std_logic; 
    --ADC_Sclk    : OUT std_logic;
    TX_RDY      : OUT std_logic
);
end Clock_Divider;

architecture architecture_Clock_Divider of Clock_Divider is
signal clk_100Khz  : std_logic := '1';
signal cntr_100KHz : integer range 1 to 240 := 1 ; 
--signal clk_25MHz   : std_logic := '0';
--signal cntr_25MHz  : integer range 1 to 4 := 1 ; 

begin

--===================================================================
-- 100Khz clock generation from  USB 48Mhz clock
--===================================================================
process(reset, clk_usb)
begin
  if (reset = '0') then
    cntr_100KHz <= 1;
    clk_100Khz  <= '0';
  else
    if rising_edge(clk_usb) then
      if (cntr_100KHz = 240) then
        clk_100Khz  <= not clk_100Khz;
        cntr_100KHz <= 1;
      else
        cntr_100KHz <= cntr_100KHz + 1;
      end if;
    end if;
  end if;
TX_RDY <= clk_100Khz;
end process;
--===================================================================
--===================================================================
end architecture_Clock_Divider;
