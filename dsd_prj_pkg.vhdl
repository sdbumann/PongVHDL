
--=============================================================================
-- @file dsd_prj_pkg.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- dsd_prj_pkg
--
-- @brief This file specifies the parameters used for the VGA controller, pong and mandelbrot circuits
--
-- The parameters are given here http://tinyvga.com/vga-timing/1024x768@70Hz
-- with a more elaborate explanation at https://projectf.io/posts/video-timings-vga-720p-1080p/
--=============================================================================

package dsd_prj_pkg is

-------------------------------------------------------------------------------
-- Display and VGA-Controller parameters
-------------------------------------------------------------------------------

  -- Bitwidths for screen coordinate and colors
  constant COLOR_BW : natural := 4;
  constant COORD_BW : natural := 12;
  constant PULSE_BW : natural := 13;

  -- Horizontal timing parameters
  constant HS_DISPLAY     : natural   := 1024;
  constant HS_FRONT_PORCH : natural   := 24+80;-- +80 is to center image on screen (in CO4, CO5 and CO6)
  constant HS_PULSE       : natural   := 136;
  constant HS_BACK_PORCH  : natural   := 144;
  constant HS_POLARITY    : std_logic := '0';

  -- Vertical timing parameters
  constant VS_DISPLAY     : natural   := 768;
  constant VS_FRONT_PORCH : natural   := 3+80;-- +80 is to center image on screen (in CO4, CO5 and CO6)
  constant VS_PULSE       : natural   := 6;
  constant VS_BACK_PORCH  : natural   := 29;
  constant VS_POLARITY    : std_logic := '0';

-------------------------------------------------------------------------------
-- Memory parameters
-------------------------------------------------------------------------------

  constant MEM_ADDR_BW : natural := 16;
  constant MEM_DATA_BW : natural := 12; -- 3 * COLOR_BW

-------------------------------------------------------------------------------
-- Pong parameters
-------------------------------------------------------------------------------

  CONSTANT BALL_STEP_X    : natural := 2;
  CONSTANT BALL_STEP_Y    : natural := 2;
  constant BALL_X_INIT    : natural := HS_DISPLAY/2;
  constant BALL_Y_INIT    : natural := VS_DISPLAY/2;
  constant BALL_HALF_LEN  : natural := 15;
  constant CIRCLE_SIZE    : natural := 2;
  constant BALL_SPEED_INC : natural := 1;

  CONSTANT PLATE_WIDTH      : natural := 70;
  CONSTANT PLATE_HEIGHT     : natural := 10;
  constant PLATE_STEP_X     : natural := 10;
  constant PLATE_X_INIT     : natural := HS_DISPLAY/2;
  constant PLATE_X_HALF_LEN : natural := 70;
  constant PLATE_Y_HALF_LEN : natural := 10;
  constant PLATE_Y          : natural := VS_DISPLAY-PLATE_Y_HALF_LEN;
  constant BORDER_SIZE      : natural := 2;

  type gameState is (stopped, running);
  type ballDirX is (left, right);
  type ballDirY is (up, down);

-------------------------------------------------------------------------------
-- Mandelbrot parameters
-------------------------------------------------------------------------------

  constant N_INT  : natural := 2;   -- # Integer bits (minus sig-bit)
  constant N_FRAC : natural := 15;  -- # Fractional bits
  constant N_BITS : natural := N_INT + N_FRAC;

  constant ITER_LIM : natural := 2**(2 + N_FRAC); -- Represents 2^2 in Q3.15
  constant MAX_ITER : natural := 100;             -- Maximum iteration bumber before stopping

  constant C_RE_0 : signed(N_BITS + 1 - 1 downto 0) := to_signed(-2 * (2**N_FRAC), N_BITS + 1); -- Q2.15 + one signe bit
  constant C_IM_0 : signed(N_BITS + 1 - 1 downto 0) := to_signed(-1 * (2**N_FRAC), N_BITS + 1); -- Q2.15

  -- REVISIT: What is the starting point supposed to be?
  constant C_RE_INC : signed(N_BITS + 1 - 1 downto 0) := to_signed(3 * 2**(-10 + N_FRAC), N_BITS + 1); -- Q2.15
  constant C_IM_INC : signed(N_BITS + 1 - 1 downto 0) := to_signed(5 * 2**(-11 + N_FRAC), N_BITS + 1); -- Q2.15

end package dsd_prj_pkg;
