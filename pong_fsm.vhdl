--=============================================================================
-- @file pong_fsm.vhdl
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
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
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

    -- Ball directions and game state for rgb_fade and randomness for mandelbrot
    BallXdirxDO : out ballDirX;
    BallYdirxDO : out ballDirY;
    GameStatexSO : out gameState
    );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is

signal GameStatexDN, GameStatexDP : gameState;
signal BallXxDN, BallXxDP, BallYxDN, BallYxDP, PlateXxDN, PlateXxDP :  unsigned(COORD_BW - 1 downto 0);
signal BallXdirxDN, BallXdirxDP : ballDirX;
signal BallYdirxDN, BallYdirxDP : ballDirY;
signal BallStepxDN, BallStepxDP : unsigned(COORD_BW - 1 downto 0);
signal LeftxSN, LeftxSP, RightxSN, RightxSP : std_logic;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
    gameStateReg: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            GameStatexDP <= stopped;
        elsif CLKxCI'event and CLKxCI = '1' then
            GameStatexDP <= GameStatexDN;
        end if;
    end process;

    input_reg : process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            LeftxSP <= '0';
            RightxSP <= '0';
        elsif CLKxCI'event and CLKxCI = '1' then
            LeftxSP <= LeftxSN;
            RightxSP <= RightxSN;
        end if;
    end process;
    LeftxSN <= LeftxSI;
    RightxSN <= RightxSI;

    gameElemReg: process(CLKxCI, RSTxRI) is
    begin
        if RSTxRI = '1' then
            BallXxDP <= to_unsigned(BALL_X_INIT,BallXxDP'length);
            BallYxDP <= to_unsigned(BALL_Y_INIT,BallYxDP'length);
            PlateXxDP <= to_unsigned(PLATE_X_INIT,PlateXxDP'length);
            BallStepxDP <= to_unsigned(BALL_STEP_X, BallStepxDP'length);
            BallXdirxDP <= left;
            BallYdirxDP <= down;
        elsif CLKxCI'event and CLKxCI = '1' then
            BallXxDP <= BallXxDN;
            BallYxDP <= BallYxDN;
            PlateXxDP <= PlateXxDN;
            BallStepxDP <= BallStepxDN;
            BallXdirxDP <= BallXdirxDN;
            BallYdirxDP <= BallYdirxDN;
        end if;
    end process;



    gameStateFSM: process(all) is
    begin
        --default assignments
        GameStatexDN <= GameStatexDP;

        case GameStatexDP is
            when stopped =>
                if LeftxSP = '1' and RightxSP = '1' then
                    GameStatexDN <= running;
                end if;
            when running =>
              if BallYxDP >= PLATE_Y - PLATE_Y_HALF_LEN - BALL_HALF_LEN
                 and (BallXxDP < PlateXxDP - PLATE_X_HALF_LEN
                 or BallXxDP > PlateXxDP + PLATE_X_HALF_LEN) then
                    GameStatexDN <= stopped;
                end if;
            when others =>
        end case;
    end process;

    gameElemUpdate: process(all) is
    begin
        --default assignments
        BallXxDN <= BallXxDP;
        BallYxDN <= BallYxDP;
        PlateXxDN <= PlateXxDP;
        if GameStatexDP = running and VSYNCxSI = '1' then
            --update BallX
            if ballXdirxDP = left then
                if BallXxDP > BallStepxDP then --avoid "negative" values
                    BallXxDN <= BallXxDP - BallStepxDP;
                else
                    BallXxDN <= (others=>'0');
                end if;
            else  -- ballXdirXP = right
                BallXxDN <= BallXxDP + BallStepxDP;
            end if;

            --update BallY
            if ballYdirXDP = up then
                if BallYxDP > BallStepxDP then --avoid "negative" values
                    BallYxDN <= BallYxDP - BallStepxDP;
                else
                    BallYxDN <= (others=>'0');
                end if;
            else  -- ballYdirXP = down
                BallYxDN <= BallYxDP + BallStepxDP;
            end if;

            --update PlateX
            if LeftxSP = '1' and RightxSP = '0' then -- no movement of plate if both left and right are pressed
                if PlateXxDP <= PLATE_X_HALF_LEN + PLATE_STEP_X then
                    PlateXxDN <= to_unsigned(PLATE_X_HALF_LEN, PlateXxDN'length);
                else
                    PlateXxDN <= PlateXxDP - PLATE_STEP_X;
                end if;
            elsif RightxSP = '1' and LeftxSP = '0' and PlateXxDP <= HS_DISPLAY - PLATE_X_HALF_LEN then
                PlateXxDN <= PlateXxDP + PLATE_STEP_X; -- no movement of plate if both left and right are pressed
            end if;

        elsif GameStatexDP = stopped then
            BallXxDN <= to_unsigned(BALL_X_INIT,BallXxDP'length);
            BallYxDN <= to_unsigned(BALL_Y_INIT,BallYxDP'length);
            PlateXxDN <= to_unsigned(PLATE_X_INIT,PlateXxDP'length);
        end if;
    end process;

    dirAndSpeedUpdate: process(all) is
    begin
        --default assignments
        BallXdirxDN <= BallXdirxDP;
        BallYdirxDN <= BallYdirxDP;
        BallStepxDN <= BallStepxDP;
        --Ball X collision
        if BallXxDP <= BALL_HALF_LEN then
            BallXdirxDN <= right;
        elsif BallXxDP >= HS_DISPLAY - BALL_HALF_LEN then
            BallXdirxDN <= left;
        end if;

        --Ball Y collision
        if BallYxDP <= BALL_HALF_LEN then
            BallYdirxDN <= down;
        elsif BallYxDP >= PLATE_Y - PLATE_Y_HALF_LEN - BALL_HALF_LEN
              and BallXxDP >= PlateXxDP - PLATE_X_HALF_LEN
              and BallXxDP <= PlateXxDP + PLATE_X_HALF_LEN then
            BallYdirxDN <= up;
        end if;

        --update BallStep if collision with plate
        if GameStatexDP = stopped then -- only reset velocity and not direction to get "different" games with different initial directions
            BallStepxDN <= to_unsigned(BALL_STEP_X, BallStepxDP'length);
        elsif BallYdirxDP = down and BallYdirxDN = up then
            BallStepxDN <= BallStepxDP + BALL_SPEED_INC;
        end if;
    end process;

    BallXxDO <= BallXxDP;
    BallYxDO <= BallYxDP;
    PlateXxDO <= PlateXxDP;
    BallXdirxDO <= BallXdirxDP;
    BallYdirxDO <= BallYdirxDP;
    GameStatexSO <= GameStatexDP;


end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
