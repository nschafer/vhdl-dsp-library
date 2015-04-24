LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.DSP.ALL;

ENTITY Delay IS
    GENERIC(
        delayLength : NATURAL  := DEFAULT_DELAY;
        bitWidth    : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END Delay;

ARCHITECTURE behavioral OF Delay IS
    TYPE REGISTERS IS ARRAY (delayLength DOWNTO 0) OF STD_LOGIC_VECTOR(bitwidth - 1 DOWNTO 0);
    SIGNAL validBit : STD_LOGIC;
    SIGNAL input    : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL output   : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL count    : NATURAL RANGE 0 TO delayLength;
BEGIN
    valid   <= validBit;
    input   <= dataIn;
    dataOut <= output;

    PROCESS(clock)
        VARIABLE delayData : REGISTERS;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                FOR I IN delayData'range LOOP
                    delayData(I) := (OTHERS => '0');
                END LOOP;
                output   <= (OTHERS => '0');
                count    <= 0;
                validBit <= '0';
            ELSIF enable = '1' THEN
                IF delayLength = 0 THEN
                    delayData(0) := input;
                ELSE
                    delayData := delayData(delayLength - 1 DOWNTO 0) & input;
                END IF;
                IF count < delayLength THEN
                    count <= count + 1;
                ELSE
                    validBit <= '1';
                END IF;
                output <= delayData(delayLength);
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS;
END behavioral;
