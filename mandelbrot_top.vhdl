--=============================================================================
-- @file mandelbrot_top.vhdl
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
-- mandelbrot_top
--
-- @brief This file specifies the toplevel of the pong game with the Mandelbrot
-- to generate the background.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT_TOP
--=============================================================================
entity mandelbrot_top is
  port (
    CLK125xCI : in std_logic;
    RSTxRI    : in std_logic;

    -- Button inputs
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Timing outputs
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end mandelbrot_top;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot_top is

--=============================================================================
-- SIGNAL (COMBINATIONAL) DECLARATIONS
--=============================================================================;

  -- clk_wiz_0
  signal CLK75xC : std_logic;

  -- blk_mem_gen_0
  signal WrAddrAxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal RdAddrBxD : std_logic_vector(MEM_ADDR_BW - 1 downto 0);
  signal ENAxS     : std_logic;
  signal WEAxS     : std_logic_vector(0 downto 0);
  signal ENBxS     : std_logic;
  signal DINAxD    : std_logic_vector(MEM_DATA_BW - 1 downto 0);
  signal DOUTBxD   : std_logic_vector(MEM_DATA_BW - 1 downto 0);

  -- vga_controller
  signal RedxS   : std_logic_vector(COLOR_BW - 1 downto 0); -- Color to VGA controller
  signal GreenxS : std_logic_vector(COLOR_BW - 1 downto 0);
  signal BluexS  : std_logic_vector(COLOR_BW - 1 downto 0);

  signal XCoordxD : unsigned(COORD_BW - 1 downto 0); -- Coordinates from VGA controller
  signal YCoordxD : unsigned(COORD_BW - 1 downto 0);

  signal VSYNCxS : std_logic; -- If 1, row counter resets (new frame). HIGH for 1 CC, when vertical sync starts

  -- pong_fsm
  signal BallXxD  : unsigned(COORD_BW - 1 downto 0); -- Coordinates of ball and plate
  signal BallYxD  : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxD : unsigned(COORD_BW - 1 downto 0);
  signal BallXdirxD : ballDirX;
  signal BallYdirxD : ballDirY;
  signal GameStatexS : gameState;

  -- rbg_fade for ball
  signal RedFadexD, BlueFadexD, GreenFadexD : std_logic_vector(COLOR_BW - 1 downto 0);

  signal DrawBallInsidexS, DrawBallCirclexS  : std_logic; -- If 1, draw the ball resp. ballframe
  signal DrawPlatexS : std_logic; -- If 1, draw the plate

  -- circle generation
  signal CheckXxD, CheckYxD : unsigned(2*COORD_BW -1 downto 0);

  -- mandelbrot
  signal MandelbrotWExS   : std_logic; -- If 1, Mandelbrot writes
  signal MandelbrotXxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotYxD    : unsigned(COORD_BW - 1 downto 0);
  signal MandelbrotITERxD : unsigned(MEM_DATA_BW - 1 downto 0);    -- Iteration number from Mandelbrot (chooses colour)
  signal PlateXxDI        : unsigned(COORD_BW - 1 downto 0); -- needed for randomness
  signal BallXdirxDI : ballDirX; -- needed to know when to change image
  signal BallYdirxDI : ballDirY; -- needed to know when to change image


--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================
  component clk_wiz_0 is
    port (
      clk_out1 : out std_logic;
      reset    : in  std_logic;
      locked   : out std_logic;
      clk_in1  : in  std_logic
    );
  end component clk_wiz_0;

  component blk_mem_gen_0
    port (
      clka  : in std_logic;
      ena   : in std_logic;
      wea   : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(15 downto 0);
      dina  : in std_logic_vector(11 downto 0);

      clkb  : in std_logic;
      enb   : in std_logic;
      addrb : in std_logic_vector(15 downto 0);
      doutb : out std_logic_vector(11 downto 0)
    );
  end component;

  component vga_controller is
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
  end component vga_controller;

  component pong_fsm is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Controls from push buttons
      LeftxSI  : in std_logic;
      RightxSI : in std_logic;

      -- Coordinate from VGA
      VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
      VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

      -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
      VSYNCxSI : in std_logic;

      -- Ball and plate coordinates
      BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
      BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
      PlateXxDO : out unsigned(COORD_BW - 1 downto 0);
      BallXdirxDO : out ballDirX;
      BallYdirxDO : out ballDirY;
      GameStatexSO : out gameState
    );
  end component pong_fsm;

  component mandelbrot is
    port (
      CLKxCI : in  std_logic;
      RSTxRI : in  std_logic;

      PlateXxDI : in unsigned(COORD_BW - 1 downto 0);
      BallXdirxDI : ballDirX;
      BallYdirxDI : ballDirY;

      WExSO   : out std_logic;
      XxDO    : out unsigned(COORD_BW - 1 downto 0);
      YxDO    : out unsigned(COORD_BW - 1 downto 0);
      ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
    );
  end component mandelbrot;

  component rgb_fade is
    port (
      CLKxCI : in  std_logic;
      RSTxRI : in  std_logic;

      VSYNCxSI : in std_logic;
      GameStatexSI : in gameState;

      RedxDO  : out std_logic_vector(COLOR_BW - 1 downto 0);
      GreenxDO  : out std_logic_vector(COLOR_BW - 1 downto 0);
      BluexDO : out std_logic_vector(COLOR_BW - 1 downto 0)
    );
   end component rgb_fade;
--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
  i_clk_wiz_0 : clk_wiz_0
    port map (
      clk_out1 => CLK75xC,
      reset    => RSTxRI,
      locked   => open,
      clk_in1  => CLK125xCI
    );

  i_blk_mem_gen_0 : blk_mem_gen_0
    port map (
      clka  => CLK75xC,
      ena   => ENAxS,
      wea   => WEAxS,
      addra => WrAddrAxD,
      dina  => DINAxD,

      clkb  => CLK75xC,
      enb   => ENBxS,
      addrb => RdAddrBxD,
      doutb => DOUTBxD
    );

  i_vga_controller: vga_controller
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RedxSI   => RedxS,
      GreenxSI => GreenxS,
      BluexSI  => BluexS,

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      VSYNCxSO => VSYNCxS,

      XCoordxDO => XCoordxD,
      YCoordxDO => YCoordxD,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

  i_pong_fsm : pong_fsm
    port map (
      CLKxCI => CLK75xC,
      RSTxRI => RSTxRI,

      RightxSI => RightxSI,
      LeftxSI  => LeftxSI,

      VgaXxDI => XCoordxD,
      VgaYxDI => YCoordxD,

      VSYNCxSI => VSYNCxS,

      BallXxDO  => BallXxD,
      BallYxDO  => BallYxD,
      PlateXxDO => PlateXxD,
      BallXdirxDO => BallXdirxD,
      BallYdirxDO => BallYdirxD,
      GameStatexSO => GameStatexS
    );

  i_mandelbrot : mandelbrot
    port map (
      CLKxCI  => CLK75xC,
      RSTxRI  => RSTxRI,

      PlateXxDI => PlateXxD,
      BallXdirxDI => BallXdirxD,
      BallYdirxDI => BallYdirxD,

      WExSO   => MandelbrotWExS,
      XxDO    => MandelbrotXxD,
      YxDO    => MandelbrotYxD,
      ITERxDO => MandelbrotITERxD
    );

   i_rgb_fade : rgb_fade
    port map (
      CLKxCI  => CLK75xC,
      RSTxRI  => RSTxRI,

      VSYNCxSI => VSYNCxS,
      GameStatexSI => GameStatexS,

      RedxDO => RedFadexD,
      GreenxDO => GreenFadexD,
      BluexDO => BlueFadexD
    );

--=============================================================================
-- MEMORY SIGNAL MAPPING
--=============================================================================

-- Port A
ENAxS     <= MandelbrotWExS;
WEAxS     <= (others => MandelbrotWExS);
WrAddrAxD <=    std_logic_vector(shift_right("0000"&MandelbrotXxD, 2) + shift_left(shift_right("0000"&MandelbrotYxD, 2), 8)) when MandelbrotXxD >= TO_UNSIGNED(0, MandelbrotXxD'length) and
                                                                                                                                  MandelbrotXxD <= TO_UNSIGNED(HS_Display - 1, MandelbrotXxD'length) and
                                                                                                                                  MandelbrotYxD >= TO_UNSIGNED(0, MandelbrotYxD'length) and
                                                                                                                                  MandelbrotYxD <= TO_UNSIGNED(VS_Display - 1, MandelbrotYxD'length) else
                (others => '0');
DINAxD    <= std_logic_vector(MandelbrotITERxD);

-- Port B
ENBxS     <= '1';
RdAddrBxD <= std_logic_vector(shift_right("0000"&XCoordxD, 2) + shift_left(shift_right("0000"&YCoordxD, 2), 8)) when XCoordxD >= TO_UNSIGNED(0, XCoordxD'length) and
                                                                                                                     XCoordxD <= TO_UNSIGNED(HS_Display - 1, XCoordxD'length) and
                                                                                                                     YCoordxD >= TO_UNSIGNED(0, XCoordxD'length) and
                                                                                                                     YCoordxD <= TO_UNSIGNED(VS_Display - 1, XCoordxD'length) else
             (others => '0');

--=============================================================================
-- SPRITE SIGNAL MAPPING
--=============================================================================

CheckXxD <= unsigned((signed(XCoordxD) - signed(BallXxD))*(signed(XCoordxD) - signed(BallXxD)));
CheckYxD <= unsigned((signed(YCoordxD) - signed(BallYxD))*(signed(YCoordxD) - signed(BallYxD)));
DrawBallInsidexS <= '1' when CheckXxD + CheckYxD <= (BALL_HALF_LEN-CIRCLE_SIZE)*(BALL_HALF_LEN-CIRCLE_SIZE) else
                    '0';
DrawBallCirclexS  <= '1' when CheckXxD + CheckYxD <= BALL_HALF_LEN*BALL_HALF_LEN and
                        CheckXxD + CheckYxD > (BALL_HALF_LEN-CIRCLE_SIZE)*(BALL_HALF_LEN-CIRCLE_SIZE) else
                    '0';

DrawPlatexS <= '1' when XCoordxD<=(PLATE_X_HALF_LEN+PlateXxD) and XCoordxD>=(PlateXxD-PLATE_X_HALF_LEN) and
                        YCoordxD<=(PLATE_Y_HALF_LEN+PLATE_Y) and YCoordxD>=(PLATE_Y-PLATE_Y_HALF_LEN) else
               '0';

RedxS   <= "1111" when DrawPlatexS = '1' or DrawBallCirclexS = '1' else
           RedFadexD when DrawBallInsidexS = '1' else
           DOUTBxD(3 * COLOR_BW - 1 downto 2 * COLOR_BW);
GreenxS <= "1111" when DrawPlatexS = '1' or DrawBallCirclexS = '1' else
           GreenFadexD when DrawBallInsidexS = '1' else
           DOUTBxD(2 * COLOR_BW - 1 downto 1 * COLOR_BW);
BluexS  <= "1111" when DrawPlatexS = '1' or DrawBallCirclexS = '1' else
           BlueFadexD when DrawBallInsidexS = '1' else
           DOUTBxD(1 * COLOR_BW - 1 downto 0 * COLOR_BW);


end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
