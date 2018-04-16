--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: ADC_Interface.vhd
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
USE ieee.numeric_std.ALL;

entity ADC_Interface is
port (
    Sw_rst       : IN  std_logic; -- active low
    Clk_USB      : IN  std_logic;
	ADC_en_1     : IN  std_logic;
	ADC_en_2     : IN  std_logic;
    ADC_Sdo      : IN  std_logic;
    Clr_Hit_flag : IN  std_logic;
    Hit_flag     : OUT std_logic;
    ADC_Conv     : OUT std_logic;
    ADC_Cs       : OUT std_logic;
    ADC_Sclk     : OUT std_logic;
    TP           : OUT std_logic; --debug_jk
    ADC_buf      : OUT std_logic_vector(23 downto 0) 
);
end ADC_Interface;



architecture architecture_ADC_Interface of ADC_Interface is
type state_type is (ADC_idle,ADC_rst,ADC_sampling);
signal ADC_state   : state_type;
signal ADC_Sclk_en : std_logic:= '0';
signal ADC_MUX     : std_logic:= '0';
signal ADC_cntr    : integer range 0 to 90:= 0;
signal ADC_sreg     : std_logic_vector(23 downto 0):= (others=> '0');

begin

ADC_Sclk <= CLK_USB and ADC_Sclk_En;
TP <= ADC_MUX; --debug_jk
--===================================================================
-- ADC Sequence
--===================================================================
process(Clk_USB)
begin
  if rising_edge(Clk_USB) then
    case ADC_state is
      when ADC_idle =>
        ADC_Conv     <= '1';
        ADC_CS       <= '1';
        ADC_Sclk_En  <= '0';
        ADC_cntr     <= 0;
        if (Clr_Hit_flag = '1') then
          Hit_flag <= '0';
        else
          Hit_flag <= Hit_flag;
        end if;
        if (sw_rst = '1') then 
          ADC_state <= ADC_rst;        -- ADC software reset
          ADC_MUX   <= '0';
        elsif (ADC_En_1 = '1') then
          ADC_state <= ADC_sampling; -- First Integration Acquisition
          ADC_MUX   <= '0';
        elsif (ADC_En_2 = '1') then 
          ADC_state <= ADC_sampling; -- Second Integration Acquisition
          ADC_MUX   <= '1';
        else
          ADC_state <= ADC_idle;
          ADC_MUX   <= '0';
        end if;

      when ADC_rst =>
        ADC_cntr <= ADC_cntr +1;
        ADC_buf  <= (others=> '0');
        ADC_sreg <= (others=> '0');
        ADC_MUX  <= '0';
        Hit_flag <= '0';
        case ADC_cntr is
          when 0 to 20 =>
            ADC_Conv    <= '0';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
          when 21 =>
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
          when 32 =>
            ADC_Conv    <= '1';
            ADC_CS      <= '0';
            ADC_Sclk_en <= '0'; 
          when 33 to 40 =>
            ADC_Conv    <= '1';
            ADC_CS      <= '0';
            ADC_Sclk_en <= '1'; 
          when 41 =>
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0';
          when 50 to 69 =>
            ADC_Conv    <= '0';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
          when 70 =>
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
          when others =>
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0';
        end case;
        if (ADC_cntr =  82) then
          ADC_state <= ADC_idle;
        else
          ADC_state <= ADC_rst;
        end if;

      when ADC_sampling => --First Integration Acquisition
        ADC_cntr <= ADC_cntr + 1;
        case ADC_cntr is 
          when 0 to 20 =>       -- pull adc_conv low to start conversion
            ADC_Conv    <= '0';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0';
          when 21 =>            -- pull adc_conv high before end of conversion for normal operation
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
          when 32 =>            -- pull adc_cs low at end of conversion to transfer data
            ADC_Conv    <= '1';
            ADC_CS      <= '0';
            ADC_Sclk_en <= '1'; 
          when 33 to 44 =>      -- send adc_sclk and receive data for the next 12 clk_cycles
            ADC_Conv    <= '1';
            ADC_CS      <= '0';
            ADC_Sclk_en <= '1'; 
            ADC_sreg     <= ADC_sreg (22 downto 0) & ADC_sdo; 
          when 45 =>            -- End of ADC operation
            ADC_Conv    <= '1';
            ADC_CS      <= '1';
            ADC_Sclk_en <= '0'; 
            if (ADC_MUX = '0') then
              Hit_flag <= Hit_flag;
              ADC_buf  <= ADC_buf; 
              ADC_sreg <= ADC_sreg; 
            else
              Hit_flag <= '1';
              ADC_buf  <= ADC_sreg;
              ADC_sreg <= (others=>'0');
            end if;
          when others =>
            null;
        end case;
        if (ADC_cntr = 46) then
          ADC_state <= ADC_idle;
        else 
          ADC_state <= ADC_sampling;
        end if;

      --when ADC_sampling_2 => -- Second Integration Acquisition
        --ADC_cntr <= ADC_cntr + 1;
        --case ADC_cntr is 
          --when 0 to 20 =>       -- pull adc_conv low to start conversion
            --ADC_Conv    <= '0';
            --ADC_CS      <= '1';
            --ADC_Sclk_en <= '0';
            --ADC_buf    <= (others => '0'); 
          --when 21 =>            -- pull adc_conv high before end of conversion for normal operation
            --ADC_Conv    <= '1';
            --ADC_CS      <= '1';
            --ADC_Sclk_en <= '0'; 
            --ADC_buf    <= (others => '0'); 
          --when 32 =>            -- pull adc_cs low at end of conversion to transfer data
            --ADC_Conv    <= '1';
            --ADC_CS      <= '0';
            --ADC_Sclk_en <= '1'; 
            --ADC_buf    <= (others => '0'); 
          --when 33 to 44 =>      -- send adc_sclk and receive data for the next 12 clk_cycles
            --ADC_Conv    <= '1';
            --ADC_CS      <= '0';
            --ADC_Sclk_en <= '1'; 
            --ADC_buf    <= ADC_buf (10 downto 0) & ADC_sdo; 
          --when 45 =>            -- End of ADC operation
            --ADC_Conv    <= '1';
            --ADC_CS      <= '1';
            --ADC_Sclk_en <= '0'; 
            --End_of_frame <= '1';
            --ADC_sreg (23 downto 12) <= ADC_buf(11 downto 0);
          --when others =>
            --null;
        --end case;
        --if (ADC_cntr = 46) then
          --ADC_state <= ADC_idle;
        --else 
          --ADC_state <= ADC_sampling_2;
        --end if;

    end case;
  end if;
end process;
--===================================================================
--===================================================================
   -- architecture body
end architecture_ADC_Interface;
