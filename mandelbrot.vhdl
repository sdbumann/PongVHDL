--=============================================================================
-- @file mandelbrot.vhdl
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
-- mandelbrot
--
-- @brief This file specifies a basic circuit for mandelbrot
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR MANDELBROT
--=============================================================================
entity mandelbrot is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    PlateXxDI : in unsigned(COORD_BW - 1 downto 0);
    BallXdirxDI : ballDirX;
    BallYdirxDI : ballDirY;

    WExSO   : out std_logic;
    XxDO    : out unsigned(COORD_BW - 1 downto 0);
    YxDO    : out unsigned(COORD_BW - 1 downto 0);
    ITERxDO : out unsigned(MEM_DATA_BW - 1 downto 0)
  );
end entity mandelbrot;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of mandelbrot is

   signal CrxSN, CrxSP : signed(N_BITS + 1 - 1 downto 0);
   signal CixSN, CixSP : signed(N_BITS + 1 - 1 downto 0);
   signal WExS : std_logic;
   signal H_COUNTxSN, H_COUNTxSP : unsigned(MEM_DATA_BW - 1 downto 0);
   signal H_RSTxS : std_logic;
   signal V_COUNTxSN, V_COUNTxSP : unsigned(MEM_DATA_BW - 1 downto 0);
   signal V_RSTxS : std_logic;
   signal ALGO_COUNTxSN, ALGO_COUNTxSP : unsigned(MEM_DATA_BW - 1 downto 0);

   signal ZR_NxD, ZI_NxD, ZR_N1xDP, ZR_N1xDN, ZI_N1xDP, ZI_N1xDN, C_RxD, C_IxD, SQUARED_SHORTxD, ZR_ZI_SHORTxD : signed(N_BITS downto 0);  -- Q2.15 + one singe bit
   signal ZR_SQxD, ZI_SQxD : signed(2*(N_BITS)+1 downto 0); --Q5.30
   signal SQUARED_LONGxD : signed(2*(N_BITS)+1 downto 0); -- Q5.30
   signal ZR_ZI_LONGxD : signed(2*(N_BITS)+1 downto 0); --Q6.29 (after multiplication by 2)
   signal STOP_CRITERIONxD : signed(2*(N_INT+1)-1 downto 0); -- SC=StopCriterion; Q5.0
   signal ZR_SQ_SCxD, ZI_SQ_SCxD, SQUARED_LONG_SCxD : signed(2*(N_BITS)+1 downto 0); -- SC=StopCriterion; Q5.30

   -- signals for Pseudo Random Number Generator (PRNG)
   signal PRNG_IndexxDP, PRNG_IndexxDN : unsigned(3 - 1 downto 0);
   signal PRNG_ValxDP, PRNG_ValxDN : signed(N_BITS + 1 - 1 downto 0);
   signal BallXdirxDN, BallXdirxDP : ballDirX;
   signal BallYdirxDN, BallYdirxDP : ballDirY;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
  -- --------------------------------------------------------------------------
  -- algorithm
  -- --------------------------------------------------------------------------
  ZR_SQxD <= ZR_NxD * ZR_NxD;
  ZI_SQxD <= ZI_NxD * ZI_NxD;
  ZR_ZI_LONGxD <= ZR_NxD * ZI_NxD;

  SQUARED_LONGxD <= ZR_SQxD - ZI_SQxD;

  SQUARED_SHORTxD <= SQUARED_LONGxD(2*N_BITS+1) & SQUARED_LONGxD(2*N_BITS-N_INT - 1 downto N_FRAC);
  ZR_ZI_SHORTxD <= ZR_ZI_LONGxD(2*N_BITS+1) & ZR_ZI_LONGxD(2*N_BITS-N_INT - 2 downto N_FRAC-1);

  ZR_N1xDN <= SQUARED_SHORTxD + C_RxD;
  ZI_N1xDN <= ZR_ZI_SHORTxD + C_IxD;

  ZR_ZI_reg: process (all) is
  begin
    if RSTxRI = '1' then
      ZR_N1xDP <= TO_SIGNED(0, ZR_N1xDP'length);
      ZI_N1xDP <= TO_SIGNED(0, ZI_N1xDP'length);
    elsif CLKxCI'event and CLKxCI = '1' then
      ZR_N1xDP <= ZR_N1xDN;
      ZI_N1xDP <= ZI_N1xDN;
    end if;
  end process ZR_ZI_reg;

  -- --------------------------------------------------------------------------
  -- control
  -- --------------------------------------------------------------------------
  algo_control: process (all) is
  begin
    if RSTxRI = '1' then
      ALGO_COUNTxSP <= TO_UNSIGNED(0, ALGO_COUNTxSP'length);
    elsif CLKxCI'event and CLKxCI = '1' then
      ALGO_COUNTxSP <= ALGO_COUNTxSN;
    end if;
  end process algo_control;


  ALGO_COUNTxSN <=  to_unsigned(0, ALGO_COUNTxSN'length) when ALGO_COUNTxSP >= to_unsigned(MAX_ITER, ALGO_COUNTxSP'length) or WExS='1' else
                    ALGO_COUNTxSP + to_unsigned(1, ALGO_COUNTxSN'length);

  ITERxDO <=    ALGO_COUNTxSP when ALGO_COUNTxSP<to_unsigned(MAX_ITER, ALGO_COUNTxSP'length) else
                to_unsigned(0, ALGO_COUNTxSP'length);

  -- inputs to algorithm (either initial value or ZI and ZR calculated in iteration before)
  ZR_NxD <= C_RxD when ALGO_COUNTxSP = to_unsigned(0, ALGO_COUNTxSP'length) else
            ZR_N1xDP;
  ZI_NxD <= C_IxD when ALGO_COUNTxSP = to_unsigned(0, ALGO_COUNTxSP'length) else
            ZI_N1xDP;

  -- stop criterion for algorithm
  ZR_SQ_SCxD <= ZR_N1xDN * ZR_N1xDN;
  ZI_SQ_SCxD <= ZI_N1xDN * ZI_N1xDN;
  SQUARED_LONG_SCxD <= ZR_SQ_SCxD + ZI_SQ_SCxD;
  STOP_CRITERIONxD <= SQUARED_LONG_SCxD(2*N_BITS+1) & SQUARED_LONG_SCxD(2*N_BITS downto 2*N_BITS - 4);
  WExS <=   '1' when ALGO_COUNTxSP = to_unsigned(MAX_ITER, ALGO_COUNTxSP'length) else
            '1' when (STOP_CRITERIONxD(2*N_INT downto 0) >= to_signed(4, STOP_CRITERIONxD(2*N_INT downto 0)'length)) and (STOP_CRITERIONxD(2*N_INT)='0') else
            '0';

  WExSO <= WExS;

  -- --------------------------------------------------------------------------
  -- pixel COUNT
  -- --------------------------------------------------------------------------
  H_pixel_count: process (all) is
  begin
    if RSTxRI = '1' then
      H_COUNTxSP <= TO_UNSIGNED(0, H_COUNTxSP'length);
    elsif CLKxCI'event and CLKxCI = '1' then
      H_COUNTxSP <= H_COUNTxSN;
    end if;
  end process H_pixel_count;
  H_RSTxS <=    '1' when H_COUNTxSP = to_unsigned(HS_DISPLAY-1, H_COUNTxSP'length) and WExS='1' else
                '0';
  H_COUNTxSN <=  to_unsigned(0, H_COUNTxSN'length) when H_RSTxS='1' else
                 H_COUNTxSP + to_unsigned(1, H_COUNTxSN'length) when WExS = '1' else
                 H_COUNTxSP;
  XxDO <= H_COUNTxSP;

  V_pixel_count: process (all) is
  begin
    if RSTxRI = '1' then
      V_COUNTxSP <= TO_UNSIGNED(0, V_COUNTxSP'length);
    elsif CLKxCI'event and CLKxCI = '1' then
      V_COUNTxSP <= V_COUNTxSN;
    end if;
  end process V_pixel_count;
  V_RSTxS <=    '1' when V_COUNTxSP = to_unsigned(VS_DISPLAY-1, V_COUNTxSP'length) and H_RSTxS='1' else
                '0';
  V_COUNTxSN <=  to_unsigned(0, V_COUNTxSN'length) when V_RSTxS='1' else
                 V_COUNTxSP + to_unsigned(1, V_COUNTxSN'length) when H_RSTxS='1' else
                 V_COUNTxSP;
  YxDO <= V_COUNTxSP;

  -- --------------------------------------------------------------------------
  -- cr & ci count
  -- --------------------------------------------------------------------------
  cr_count: process (all) is
  begin
    if RSTxRI = '1' then
      CrxSP <= C_RE_0;
    elsif CLKxCI'event and CLKxCI = '1' then
      CrxSP <= CrxSN;
    end if;
  end process cr_count;

  CrxSN <=  --C_RE_0 when H_RSTxS='1' else -- add this line to get mandelbrot without randomness (and remove line after this one)
            signed(std_logic_vector(C_RE_0) xor std_logic_vector(PRNG_ValxDN)) when H_RSTxS='1' else -- with randomenss
            CrxSP + C_RE_INC when WExS = '1' else
            CrxSP;
  C_RxD <= CrxSP;

  ci_count: process (all) is
  begin
    if RSTxRI = '1' then
      CixSP <= C_IM_0;
    elsif CLKxCI'event and CLKxCI = '1' then
      CixSP <= CixSN;
    end if;
  end process ci_count;

  CixSN <=  --C_IM_0  when V_RSTxS='1' else -- add this line to get mandelbrot without randomness (and remove line after this one)
            signed(std_logic_vector(C_IM_0) xor std_logic_vector(PRNG_ValxDN)) when V_RSTxS='1' else -- with randomenss
            CixSP + C_IM_INC when H_RSTxS='1' else
            CixSP;
  C_IxD <= CixSP;

  -- --------------------------------------------------------------------------
  --Pseudo Random Number Generator (PRNG) depending on user input
  -- --------------------------------------------------------------------------
  -- shift register that depends on user input (position of plate) and itself (see presentation for more info)
  PRNG_reg : process (CLKxCI, RSTxRI) is
  begin
    if RSTxRI = '1' then
      PRNG_IndexxDP <= "101"; -- random number/seed
      PRNG_ValxDP <= (others => '0');
    elsif CLKxCI'event and CLKxCI = '1' then
      PRNG_IndexxDP <= PRNG_IndexxDN;
      PRNG_ValxDP <= PRNG_ValxDN;
    end if;
  end process PRNG_reg;
  PRNG_IndexxDN <=  PlateXxDI(TO_INTEGER(PRNG_IndexxDP)+4) & PRNG_IndexxDP(2 downto 1) when BallXdirxDP/=BallXdirxDN or BallYdirxDP/=BallYdirxDN else
                    PRNG_IndexxDP;
  PRNG_ValxDN <=    PlateXxDI(TO_INTEGER(PRNG_IndexxDP)+4) & PRNG_ValxDP(N_BITS downto 1) when BallXdirxDP/=BallXdirxDN or BallYdirxDP/=BallYdirxDN else
                    PRNG_ValxDP;

  direction_reg : process (CLKxCI, RSTxRI) is
  begin
    if RSTxRI = '1' then
      BallXdirxDP <= left;
      BallYdirxDP <= down;
    elsif CLKxCI'event and CLKxCI = '1' then
      BallXdirxDP <= BallXdirxDN;
      BallYdirxDP <= BallYdirxDN;
    end if;
  end process direction_reg;

  BallXdirxDN <= BallXdirxDI;
  BallYdirxDN <= BallYdirxDI;

end architecture rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
