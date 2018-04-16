--------------------------------------------------------------------------------
-- Company: <Name>
--
-- File: DAQ_FSM.vhd
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

entity DAQ_FSM is
port (
    Reset          : IN  std_logic;
	clk_USB        : IN  std_logic; 
    DAQ_En         : IN  std_logic;  
    Comparator_out : IN  std_logic;
    Int_Per_1      : IN  std_logic_vector(8 downto 0);
    Int_Per_2      : IN  std_logic_vector(8 downto 0);
    TP             : OUT  std_logic; --debug_jk
    Integrator_rst : OUT  std_logic;
    ADC_En_1       : OUT  std_logic;
    ADC_En_2       : OUT  std_logic
);
end DAQ_FSM;



architecture architecture_DAQ_FSM of DAQ_FSM is
type state_type_1 is (DAQ_Idle,Integration_state);
signal DAQ_state : state_type_1;
signal First_integr  : integer range 0 to 480:= 0;
signal Second_integr : integer range 0 to 480:= 0;
signal DAQ_cntr      : integer range 0 to 480:= 0;
signal DAQ_rst       : std_logic:= '1'; 
signal frame_rst     : std_logic:= '0'; --debug_jk

begin

First_integr   <= to_integer(unsigned(Int_per_1));
Second_integr  <= to_integer(unsigned(Int_per_2));


process(DAQ_En,Comparator_out,DAQ_rst,frame_rst)
begin
  if (DAQ_En = '1') then
    Integrator_rst <= (Comparator_out and DAQ_rst) or (frame_rst); --debug_jk       -- Comparator_out = active low ('0' when trigger, '1' when idle)
  else
    Integrator_rst <= '1';
  end if;
end process;

--===================================================================
-- Data Acquisition Sequence
--===================================================================
process(Clk_Usb)
begin

  if rising_edge(Clk_Usb) then
    if (reset = '1') then
      DAQ_state <= DAQ_idle;
    else
      case DAQ_state is

        when DAQ_idle =>         ---- DAQ_IDLE, waiting for trigger
          TP <= '0'; --debug_jk
          frame_rst <= '0'; --debug_jk
          DAQ_cntr <= 0;
          DAQ_rst  <= '1';
          ADC_en_1 <= '0';
          ADC_en_2 <= '0';
          if (DAQ_EN = '1') and (Comparator_out = '0') then -- if Data acquisition is enabled AND trigger comes
            DAQ_state <= Integration_state;                  -- go to integration state 
          else                                               -- else
            DAQ_state <= DAQ_Idle;                           -- remain in idle state
          end if;

        when Integration_state => ---- INTEGRATION_STATE
          TP <= '1'; --debug_jk
          DAQ_cntr <= DAQ_cntr +1;                          -- start DAQ_cntr
          DAQ_rst  <= '0';                                  -- integrator circuit is in operation (out of reset state)
          if (DAQ_cntr = First_integr) then                   -- if DAQ_cntr reaches first integration point
            ADC_en_1 <= '1';                                   -- signal ADC to perform first acquisition     
          elsif (DAQ_cntr = (First_integr + 3)) then           -- five pulses later
            ADC_en_1 <= '0';                                   -- reset ADC_en signal
          end if; 
          if (DAQ_cntr = Second_Integr) then                  -- if DAQ_cntr reaches second integration point  
            ADC_en_2 <= '1';                                   -- signal ADC to perform second acquisition
          elsif (DAQ_cntr = Second_Integr + 3) then            -- five pulses later
            ADC_en_2 <= '0';                                   -- reset ADC_en signal
          end if;
          if (DAQ_cntr = 450) then --debug_jk
            frame_rst <= '1';
          end if;
          if (DAQ_cntr = 470)  then                     -- if End_of_frame = '1', (ADC has completed second acquisition) --debug_jk
            DAQ_state <= DAQ_Idle;                           -- return to idle state
          else
            DAQ_state <= Integration_state; 
          end if;
      end case;
    end if;
  end if;
end process;
--===================================================================
--===================================================================

end architecture_DAQ_FSM;


----===================================================================
---- 100Mhz Counter to Control Integration Period
----===================================================================
--process(clk_100MHz)
--begin
  --if rising_edge(clk_100MHz) then
    --if (DAQ_rst = '1') then 
      --DAQ_cntr <= 0;
    --else
      --DAQ_cntr <= DAQ_cntr + 1;
    --end if;
  --end if;
--end process;
----===================================================================
----===================================================================
