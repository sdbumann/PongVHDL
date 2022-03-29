--=============================================================================
-- @file rgb_fade.vhdl
--=============================================================================
-- Standard library
library IEEE;
-- Standard packages
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- rgb_fade
--
-- @brief This component implements a nice looking rgb fadeout algorithm
--        Inspired by https://codepen.io/Codepixl/pen/ogWWaK (27.12.2021)
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity rgb_fade is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    VSYNCxSI : in std_logic;
    GameStatexSI : in gameState;

    -- Ball and plate coordinates
    RedxDO  : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxDO  : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexDO : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end rgb_fade;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of rgb_fade is
signal RedxDN, RedxDP, GreenxDN, GreenxDP, BluexDN, BluexDP : unsigned(COLOR_BW - 1 downto 0);
signal CounterxDN, CounterxDP : unsigned(4-1 downto 0);

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
    ColorReg: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            RedxDP <= (others => '1');
            GreenxDP <= (others => '0');
            BluexDP <= (others => '0');
            CounterxDP <= (others => '0');
        elsif CLKxCI'event and CLKxCI = '1' then
            RedxDP <= RedxDN;
            GreenxDP <= GreenxDN;
            BluexDP <= BluexDN;
            CounterxDP <= CounterxDN;
        end if;
    end process;

    updateCounter: process(all) is
    begin
        if VSYNCxSI = '1' and GameStatexSI = running then
            CounterxDN <= CounterxDP + 1;
        else
            CounterxDN <= CounterxDP;
        end if;
    end process;

    updateColor: process(all) is
    begin
        --Default assignments
        RedxDN <= RedxDP;
        GreenxDN <= GreenxDP;
        BluexDN <= BluexDP;
        if CounterxDP = to_unsigned(0,CounterxDP'length) and VSYNCxSI = '1' and GameStatexSI = running then
            if RedxDP > 0 and BluexDP = 0 then
                RedxDN <= RedxDP - 1;
                GreenxDN <= GreenxDP + 1;
            end if;
            if GreenxDP > 0 and RedxDP = 0 then
                GreenxDN <= GreenxDP - 1;
                BluexDN <= BluexDP + 1;
            end if;
            if BluexDP > 0 and GreenxDP = 0 then
                BluexDN <= BluexDP - 1;
                RedxDN <= RedxDP + 1;
            end if;
        end if;
    end process;

    RedxDO <= std_logic_vector(RedxDP);
    GreenxDO <= std_logic_vector(GreenxDP);
    BluexDO <= std_logic_vector(BluexDP);

end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
