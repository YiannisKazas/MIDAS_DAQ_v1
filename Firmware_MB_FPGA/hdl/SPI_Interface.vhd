--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: SPI_Interface.vhd
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

entity SPI_Interface is
port (
	SPI_CS    : IN  std_logic; 
    SPI_SCLK  : IN  std_logic;
    SPI_MOSI  : IN  std_logic;
    DAQ_EN    : IN  std_logic;
    --TP1       : OUT  std_logic;
    --TP2       : OUT  std_logic;
    --TP4       : OUT  std_logic;
    --TP5       : OUT  std_logic;
    --TP6       : OUT  std_logic;
    --TP7       : OUT  std_logic;
    DAC_CS    : OUT  std_logic;
    DAC_SCLK  : OUT  std_logic;
    DAC_DIN   : OUT  std_logic;
    INT_PER_1 : OUT  std_logic_vector(8 downto 0);  
    INT_PER_2 : OUT  std_logic_vector(8 downto 0)
);
end SPI_Interface;

architecture architecture_SPI_Interface of SPI_Interface is
signal SPI_REG : std_logic_vector(31 downto 0); 
signal SPI_SCLK_buf : std_logic := '0';


begin

-- ==================================================
-- Process to control incoming data from SPI pins --
--===================================================
--process(SPI_CS, SPI_SCLK,SPI_MOSI,SPI_REG)
--begin
  --if (SPI_CS = '0') then -- bridge SPI signals directly to DAC
    --DAC_SCLK <= SPI_SCLK;
    --DAC_DIN  <= SPI_MOSI;
  --else                   -- store data to shift register 
    --if rising_edge(SPI_SCLK) then
      --SPI_REG <= SPI_REG(30 downto 0) & SPI_MOSI;
    --end if;
  --end if;
--end process;
--===================================================
--===================================================
process(SPI_CS,SPI_SCLK)
begin
  if (SPI_CS = '0') then
    SPI_SCLK_buf <= SPI_SCLK;
  else 
    SPI_SCLK_buf <= '0';
  end if;
end process;


process(SPI_CS,SPI_SCLK_buf,SPI_MOSI,SPI_REG)
begin
  if (SPI_CS = '0') then
    if rising_edge(SPI_SCLK_buf) then
      SPI_REG <= SPI_REG(30 downto 0) & SPI_MOSI;
    end if;
  end if;
end process;
      

DAC_CS   <= not SPI_CS;
DAC_SCLK <= SPI_SCLK;
DAC_DIN  <= SPI_MOSI;

INT_PER_1 <= SPI_REG(24 downto 16); -- 1st integration duration in us (relative to comparator trigger)
INT_PER_2 <= SPI_REG(8 downto 0);  -- 2nd integration duration in us (relative to comparator trigger)

----===================================================
----===================================================
--process(DAQ_En,SPI_REG)
--begin
--if DAQ_En = '0' then
--TP1 <= SPI_REG(16);
--TP2 <= SPI_REG(17);
--TP4 <= SPI_REG(18);
--TP5 <= SPI_REG(19);
--TP6 <= SPI_REG(20);
--TP7 <= SPI_REG(21);
--else
--TP1 <= SPI_REG(22);
--TP2 <= SPI_REG(23);
--TP4 <= SPI_REG(24);
--TP5 <= SPI_REG(25);
--TP6 <= '0';
--TP7 <= '0';
--end if;
--end process;
----===================================================
----===================================================





end architecture_SPI_Interface;
