-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY ClockedAdd IS
    GENERIC(
        bitWidthIn : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset  : IN  STD_LOGIC;
        clock  : IN  STD_LOGIC;
        enable : IN  STD_LOGIC;
        in1    : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        in2    : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        sum    : OUT STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        valid  : OUT STD_LOGIC
    );
END ClockedAdd;

ARCHITECTURE Behavioral OF ClockedAdd IS
    SIGNAL input1   : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
    SIGNAL input2   : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
    SIGNAL output   : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
    SIGNAL validBit : STD_LOGIC;
BEGIN
    sum    <= output;
    input1 <= in1;
    input2 <= in2;
    valid  <= validBit;

    add : PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                output   <= (OTHERS => '0');
                validBit <= '0';
            ELSIF enable = '1' THEN
                output   <= STD_LOGIC_VECTOR(signed(input1) + signed(input2));
                validBit <= '1';
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS add;
END Behavioral;

    