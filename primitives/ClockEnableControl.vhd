-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY ClockEnableControl IS
    GENERIC(
        decimation : POSITIVE := DEFAULT_DECIMATION
    );
    PORT(
        clockIn  : IN  STD_LOGIC;
        reset    : IN  STD_LOGIC;
        enable   : IN  STD_LOGIC;
        clockOut : OUT STD_LOGIC
    );
END ClockEnableControl;

ARCHITECTURE Behavioral OF ClockEnableControl IS
    CONSTANT MAX_COUNT : NATURAL := decimation - 1;
    SIGNAL count       : NATURAL RANGE 0 TO MAX_COUNT;
    SIGNAL valid       : STD_LOGIC;

BEGIN
    clockOut <= valid;
    
    ce_count : PROCESS(clockIn)
    BEGIN
        IF rising_edge(clockIn) THEN
            IF reset = '1' THEN
                count    <= 0;
                valid <= '0';
            ELSIF enable = '1' THEN
                IF count < MAX_COUNT THEN
                    valid <= '0';
                    count    <= count + 1;
                ELSE
                    valid <= '1';
                    count    <= 0;
                END IF;
            ELSE
                valid <= '0';
            END IF;
        END IF;
    END PROCESS ce_count;
END Behavioral;

