-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY Decrementer IS
    GENERIC(
        maxCount : NATURAL := DEFAULT_COUNT
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataOut : OUT NATURAL RANGE 0 TO maxCount;
        valid   : OUT STD_LOGIC
    );
END Decrementer;

ARCHITECTURE behavioral OF Decrementer IS
    SIGNAL output   : NATURAL RANGE 0 TO maxCount;
    SIGNAL validBit : STD_LOGIC;
BEGIN
    dataOut <= output;
    valid   <= validBit;

    PROCESS(clock)
        VARIABLE count : NATURAL RANGE 0 TO maxCount;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                count    := maxCount;
                validBit <= '0';
            ELSIF enable = '1' THEN
                output   <= count;
                validBit <= '1';
                IF count > 0 THEN
                    count := count - 1;
                ELSE
                    count := maxCount;
                END IF;
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS;
END behavioral;
