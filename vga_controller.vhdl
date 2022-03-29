--=============================================================================
-- @file vga_controller.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Data/color input
    RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Coordinate output
    XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
    YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Timing output
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    VSYNCxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is

  SIGNAL COL_CNTxDP, COL_CNTxDN, LINE_CNTxDP, LINE_CNTxDN : signed(COORD_BW - 1 DOWNTO 0);
  SIGNAL HSxSN, HSxSP, VSxSN, VSxSP, VSYNCxSN, VSYNCxSP : std_logic;
  SIGNAL RedxSN, GreenxSN, BluexSN, RedxSP, GreenxSP, BluexSP  : std_logic_vector(COLOR_BW - 1 DOWNTO 0);
  SIGNAL ACTIVE_DISPxS : std_logic;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

  reg : PROCESS (CLKxCI, RSTxRI) IS
  BEGIN  -- PROCESS reg
    IF RSTxRI = '1' THEN                -- asynchronous reset (active high)
      COL_CNTxDP    <= to_signed(-HS_FRONT_PORCH, COORD_BW);
      LINE_CNTxDP   <= to_signed(-VS_FRONT_PORCH, COORD_BW);
      HSxSP         <= NOT HS_POLARITY;
      VSxSP         <= NOT VS_POLARITY;
      RedxSP        <= (OTHERS => '0');
      GreenxSP      <= (OTHERS => '0');
      BluexSP       <= (OTHERS => '0');
      VSYNCxSP      <= '0';
    ELSIF CLKxCI'event AND CLKxCI = '1' THEN  -- rising clock edge
      COL_CNTxDP    <= COL_CNTxDN;
      LINE_CNTxDP   <= LINE_CNTxDN;
      HSxSP         <= HSxSN;
      VSxSP         <= VSxSN;
      RedxSP        <= RedxSN;
      GreenxSP      <= GreenxSN;
      BluexSP       <= BluexSN;
      VSYNCxSP      <= VSYNCxSN;
    END IF;
  END PROCESS reg;

  -- output assignements
  HSxSO             <= HSxSP;
  VSxSO             <= VSxSP;
  RedxSO            <= RedxSP;
  GreenxSO          <= GreenxSP;
  BluexSO           <= BluexSP;
  VSYNCxSO          <= VSYNCxSP;

  -- column & line counters
  COL_CNTxDN <= to_signed(-HS_FRONT_PORCH, COORD_BW) WHEN COL_CNTxDP = to_signed(HS_DISPLAY + HS_BACK_PORCH + HS_PULSE - 1, COORD_BW) ELSE
                COL_CNTxDP + to_signed(1, COORD_BW);

  LINE_CNTxDN <= LINE_CNTxDP WHEN COL_CNTxDP /= to_signed(HS_DISPLAY + HS_BACK_PORCH + HS_PULSE - 1, COORD_BW) ELSE
                 to_signed(-VS_FRONT_PORCH, COORD_BW) WHEN LINE_CNTxDP = to_signed(VS_DISPLAY + VS_BACK_PORCH + VS_PULSE - 1, COORD_BW) ELSE
                 LINE_CNTxDP + to_signed(1, COORD_BW);

  --Horizontal & Vertical sync
  HSxSN <= HS_POLARITY WHEN COL_CNTxDP >= HS_DISPLAY + HS_BACK_PORCH ELSE
           NOT HS_POLARITY;

  VSxSN <= VS_POLARITY WHEN LINE_CNTxDP >= VS_DISPLAY + VS_BACK_PORCH ELSE
           NOT VS_POLARITY;

  -- Rising edge detector on VSxSN for pong_fsm and rgb_fade
  VSYNCxSN <= (NOT VSxSP) AND VSxSN;

  -- ACTIVE_DISPxS='1' when line & column counter are in active display and not in (back nor front) porches
  ACTIVE_DISPxS <= '1' WHEN LINE_CNTxDP >= 0 AND LINE_CNTxDP < VS_DISPLAY AND COL_CNTxDP >= 0 AND COL_CNTxDP < HS_DISPLAY ELSE
                   '0';

  -- RGB signals
  RedxSN <= RedxSI WHEN ACTIVE_DISPxS = '1' ELSE
            (OTHERS => '0');

  GreenxSN <= GreenxSI WHEN ACTIVE_DISPxS = '1' ELSE
              (OTHERS => '0');

  BluexSN <= BluexSI WHEN ACTIVE_DISPxS = '1' ELSE
             (OTHERS => '0');

  -- Output of displayed pixel coordinates
  XCoordxDO <= unsigned(COL_CNTxDP) WHEN COL_CNTxDP >= to_signed(0, COORD_BW) ELSE
               (OTHERS => '1');
  YCoordxDO <= unsigned(LINE_CNTxDP) WHEN LINE_CNTxDP >= to_signed(0, COORD_BW) ELSE
               (OTHERS => '1');

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
