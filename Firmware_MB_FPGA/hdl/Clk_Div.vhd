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

entity Clk_Div is
port (
    Divider     : in  integer range 1 to 480;
    Clk_Rst     : IN  std_logic;
	Clk_In      : IN  std_logic; 
    Clk_Divided : OUT std_logic
);
end Clk_Div;

architecture architecture_Clk_Div of Clk_Div is
signal clk_temp  : std_logic:= '0';
signal cntr      : integer:= 1 ; 

begin

--===================================================================
-- 100Khz clock generation from  USB 48Mhz clock
--===================================================================
process(Clk_rst,clk_in)
begin
  if (clk_rst = '1') then
    cntr     <= 1;
    clk_temp <= '0';
  else
    if rising_edge(clk_in) then
      if (cntr = Divider) then
        clk_temp  <= not clk_temp;
        cntr      <= 1;
      else
        cntr      <= cntr + 1;
      end if;
    end if;
  end if;
Clk_Divided <= clk_temp;
end process;
--===================================================================
--===================================================================
end architecture_Clk_Div;



----===================================================================
---- 25MHz clock generation from 100MHz clock
----===================================================================
--process(clk_100MHz)
--begin
--if (ADC_Sclk_En = '0') then
  --cntr_25MHz <= 1;
  --clk_25MHz  <= '0';
  --if rising_edge(clk_100MHz) then
    --if (cntr_25MHz = 4) then
      --clk_25MHz  <= not clk_25MHz;
      --cntr_25MHz      <= 1;
    --else
      --cntr_25MHz <= cntr_25MHz + 1;
    --end if;
  --end if;
--end if;
--ADC_Sclk <= clk_25MHz;
--end process;
----===================================================================
----===================================================================  
