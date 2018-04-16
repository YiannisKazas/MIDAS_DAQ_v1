----------------------------------------------------------------------
-- Created by SmartDesign Wed Dec 06 11:28:58 2017
-- Version: v11.8 SP2 11.8.2.4
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Libraries
----------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library igloo;
use igloo.all;
----------------------------------------------------------------------
-- MARS_MB_rev1_top entity declaration
----------------------------------------------------------------------
entity MARS_MB_rev1_top is
    -- Port list
    port(
        -- Inputs
        ADC_SDO        : in  std_logic;
        Clk_USB        : in  std_logic;
        Comparator_out : in  std_logic;
        DAQ_En         : in  std_logic;
        SPI_CS         : in  std_logic;
        SPI_MOSI       : in  std_logic;
        SPI_SCLK       : in  std_logic;
        -- Outputs
        ADC_CS         : out std_logic;
        ADC_Conv       : out std_logic;
        ADC_SCLK       : out std_logic;
        DAC_CS         : out std_logic;
        DAC_DIN        : out std_logic;
        DAC_SCLK       : out std_logic;
        DATA_OUT       : out std_logic_vector(7 downto 0);
        Integrator_rst : out std_logic;
        Sl_fifo_wr_en  : out std_logic;
        TP1            : out std_logic;
        TP2            : out std_logic;
        TP4            : out std_logic;
        TP5            : out std_logic;
        TP6            : out std_logic;
        TP7            : out std_logic
        );
end MARS_MB_rev1_top;
----------------------------------------------------------------------
-- MARS_MB_rev1_top architecture body
----------------------------------------------------------------------
architecture RTL of MARS_MB_rev1_top is
----------------------------------------------------------------------
-- Component declarations
----------------------------------------------------------------------
-- ADC_Interface
component ADC_Interface
    -- Port list
    port(
        -- Inputs
        ADC_Sdo      : in  std_logic;
        ADC_en_1     : in  std_logic;
        ADC_en_2     : in  std_logic;
        Clk_USB      : in  std_logic;
        Clr_Hit_flag : in  std_logic;
        Sw_rst       : in  std_logic;
        -- Outputs
        ADC_Conv     : out std_logic;
        ADC_Cs       : out std_logic;
        ADC_Sclk     : out std_logic;
        ADC_buf      : out std_logic_vector(23 downto 0);
        Hit_flag     : out std_logic;
        TP           : out std_logic
        );
end component;
-- Clock_Divider
component Clock_Divider
    -- Port list
    port(
        -- Inputs
        CLK_USB : in  std_logic;
        RESET   : in  std_logic;
        -- Outputs
        TX_RDY  : out std_logic
        );
end component;
-- DAQ_FSM
component DAQ_FSM
    -- Port list
    port(
        -- Inputs
        Comparator_out : in  std_logic;
        DAQ_En         : in  std_logic;
        Int_Per_1      : in  std_logic_vector(8 downto 0);
        Int_Per_2      : in  std_logic_vector(8 downto 0);
        Reset          : in  std_logic;
        clk_USB        : in  std_logic;
        -- Outputs
        ADC_En_1       : out std_logic;
        ADC_En_2       : out std_logic;
        Integrator_rst : out std_logic;
        TP             : out std_logic
        );
end component;
-- SPI_Interface
component SPI_Interface
    -- Port list
    port(
        -- Inputs
        DAQ_EN    : in  std_logic;
        SPI_CS    : in  std_logic;
        SPI_MOSI  : in  std_logic;
        SPI_SCLK  : in  std_logic;
        -- Outputs
        DAC_CS    : out std_logic;
        DAC_DIN   : out std_logic;
        DAC_SCLK  : out std_logic;
        INT_PER_1 : out std_logic_vector(8 downto 0);
        INT_PER_2 : out std_logic_vector(8 downto 0)
        );
end component;
-- TX_Interface
component TX_Interface
    -- Port list
    port(
        -- Inputs
        ADC_buffer    : in  std_logic_vector(23 downto 0);
        Clk_USB       : in  std_logic;
        DAQ_En        : in  std_logic;
        Hit_flag      : in  std_logic;
        TX_rdy        : in  std_logic;
        -- Outputs
        Clr_Hit_flag  : out std_logic;
        DATA_OUT      : out std_logic_vector(7 downto 0);
        Sl_fifo_wr_en : out std_logic
        );
end component;
----------------------------------------------------------------------
-- Signal declarations
----------------------------------------------------------------------
signal ADC_Conv_net_0              : std_logic;
signal ADC_CS_net_0                : std_logic;
signal ADC_Interface_0_ADC_buf     : std_logic_vector(23 downto 0);
signal ADC_SCLK_1                  : std_logic;
signal DAC_CS_net_0                : std_logic;
signal DAC_DIN_net_0               : std_logic;
signal DAC_SCLK_net_0              : std_logic;
signal DATA_OUT_net_0              : std_logic_vector(7 downto 0);
signal Integrator_rst_net_0        : std_logic;
signal Sl_fifo_wr_en_net_0         : std_logic;
signal SPI_Interface_0_INT_PER_1_1 : std_logic_vector(8 downto 0);
signal SPI_Interface_0_INT_PER_2_1 : std_logic_vector(8 downto 0);
signal TP1_net_0                   : std_logic;
signal TP2_net_0                   : std_logic;
signal TP4_net_0                   : std_logic;
signal TP5_1                       : std_logic;
signal TP6_0                       : std_logic;
signal TP7_1                       : std_logic;
signal ADC_Conv_net_1              : std_logic;
signal Sl_fifo_wr_en_net_1         : std_logic;
signal ADC_CS_net_1                : std_logic;
signal Integrator_rst_net_1        : std_logic;
signal ADC_SCLK_1_net_0            : std_logic;
signal DAC_CS_net_1                : std_logic;
signal DAC_SCLK_net_1              : std_logic;
signal DAC_DIN_net_1               : std_logic;
signal TP1_net_1                   : std_logic;
signal TP2_net_1                   : std_logic;
signal TP4_net_1                   : std_logic;
signal TP5_1_net_0                 : std_logic;
signal TP6_0_net_0                 : std_logic;
signal TP7_1_net_0                 : std_logic;
signal DATA_OUT_net_1              : std_logic_vector(7 downto 0);
----------------------------------------------------------------------
-- TiedOff Signals
----------------------------------------------------------------------
signal VCC_net                     : std_logic;

begin
----------------------------------------------------------------------
-- Constant assignments
----------------------------------------------------------------------
 VCC_net <= '1';
----------------------------------------------------------------------
-- Top level output port assignments
----------------------------------------------------------------------
 ADC_Conv_net_1       <= ADC_Conv_net_0;
 ADC_Conv             <= ADC_Conv_net_1;
 Sl_fifo_wr_en_net_1  <= Sl_fifo_wr_en_net_0;
 Sl_fifo_wr_en        <= Sl_fifo_wr_en_net_1;
 ADC_CS_net_1         <= ADC_CS_net_0;
 ADC_CS               <= ADC_CS_net_1;
 Integrator_rst_net_1 <= Integrator_rst_net_0;
 Integrator_rst       <= Integrator_rst_net_1;
 ADC_SCLK_1_net_0     <= ADC_SCLK_1;
 ADC_SCLK             <= ADC_SCLK_1_net_0;
 DAC_CS_net_1         <= DAC_CS_net_0;
 DAC_CS               <= DAC_CS_net_1;
 DAC_SCLK_net_1       <= DAC_SCLK_net_0;
 DAC_SCLK             <= DAC_SCLK_net_1;
 DAC_DIN_net_1        <= DAC_DIN_net_0;
 DAC_DIN              <= DAC_DIN_net_1;
 TP1_net_1            <= TP1_net_0;
 TP1                  <= TP1_net_1;
 TP2_net_1            <= TP2_net_0;
 TP2                  <= TP2_net_1;
 TP4_net_1            <= TP4_net_0;
 TP4                  <= TP4_net_1;
 TP5_1_net_0          <= TP5_1;
 TP5                  <= TP5_1_net_0;
 TP6_0_net_0          <= TP6_0;
 TP6                  <= TP6_0_net_0;
 TP7_1_net_0          <= TP7_1;
 TP7                  <= TP7_1_net_0;
 DATA_OUT_net_1       <= DATA_OUT_net_0;
 DATA_OUT(7 downto 0) <= DATA_OUT_net_1;
----------------------------------------------------------------------
-- Component instances
----------------------------------------------------------------------
-- ADC_Interface_0
ADC_Interface_0 : ADC_Interface
    port map( 
        -- Inputs
        Sw_rst       => SPI_CS,
        Clk_USB      => Clk_USB,
        ADC_en_1     => TP2_net_0,
        ADC_en_2     => TP4_net_0,
        ADC_Sdo      => ADC_SDO,
        Clr_Hit_flag => TP1_net_0,
        -- Outputs
        Hit_flag     => TP7_1,
        ADC_Conv     => ADC_Conv_net_0,
        ADC_Cs       => ADC_CS_net_0,
        ADC_Sclk     => ADC_SCLK_1,
        TP           => TP5_1,
        ADC_buf      => ADC_Interface_0_ADC_buf 
        );
-- Clock_Divider_0
Clock_Divider_0 : Clock_Divider
    port map( 
        -- Inputs
        RESET   => VCC_net,
        CLK_USB => Clk_USB,
        -- Outputs
        TX_RDY  => TP6_0 
        );
-- DAQ_FSM_0
DAQ_FSM_0 : DAQ_FSM
    port map( 
        -- Inputs
        Reset          => SPI_CS,
        clk_USB        => Clk_USB,
        DAQ_En         => DAQ_En,
        Comparator_out => Comparator_out,
        Int_Per_1      => SPI_Interface_0_INT_PER_1_1,
        Int_Per_2      => SPI_Interface_0_INT_PER_2_1,
        -- Outputs
        TP             => OPEN,
        Integrator_rst => Integrator_rst_net_0,
        ADC_En_1       => TP2_net_0,
        ADC_En_2       => TP4_net_0 
        );
-- SPI_Interface_0
SPI_Interface_0 : SPI_Interface
    port map( 
        -- Inputs
        SPI_CS    => SPI_CS,
        SPI_SCLK  => SPI_SCLK,
        SPI_MOSI  => SPI_MOSI,
        DAQ_EN    => DAQ_En,
        -- Outputs
        DAC_CS    => DAC_CS_net_0,
        DAC_SCLK  => DAC_SCLK_net_0,
        DAC_DIN   => DAC_DIN_net_0,
        INT_PER_1 => SPI_Interface_0_INT_PER_1_1,
        INT_PER_2 => SPI_Interface_0_INT_PER_2_1 
        );
-- TX_Interface_0
TX_Interface_0 : TX_Interface
    port map( 
        -- Inputs
        Clk_USB       => Clk_USB,
        DAQ_En        => DAQ_En,
        TX_rdy        => TP6_0,
        ADC_buffer    => ADC_Interface_0_ADC_buf,
        Hit_flag      => TP7_1,
        -- Outputs
        Sl_fifo_wr_en => Sl_fifo_wr_en_net_0,
        DATA_OUT      => DATA_OUT_net_0,
        Clr_Hit_flag  => TP1_net_0 
        );

end RTL;
