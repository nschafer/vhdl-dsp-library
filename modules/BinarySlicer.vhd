LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BinarySlicer IS
    GENERIC(
        bitWidthIn  : POSITIVE := DEFAULT_BITWIDTH;
        bitWidthOut : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END BinarySlicer;

ARCHITECTURE Behavioral OF BinarySlicer IS
    SIGNAL output    : STD_LOGIC;
    SIGNAL input     : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
    SIGNAL enableBit : STD_LOGIC;
    signal validBit  : STD_LOGIC;
BEGIN
    valid                             <= validBit;
    enableBit                         <= enable;
    input                             <= dataIn;
    dataOut(bitWidthOut - 1 DOWNTO 1) <= (OTHERS => '0');
    dataOut(0)                        <= output;

    slice : PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                output   <= '0';
                validBit <= '0';
            ELSIF enableBit = '1' THEN
                output   <= NOT input(bitWidthIn - 1);
                validBit <= '1';
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS slice;
END Behavioral;

    