LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY DecimatingAccumulator IS
    GENERIC(
        decimation  : POSITIVE := DEFAULT_DECIMATION;
        shiftGain   : NATURAL  := DEFAULT_SHIFT_GAIN;
        bitWidthIn  : POSITIVE := DEFAULT_BITWIDTH;
        bitWidthOut : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END DecimatingAccumulator;

ARCHITECTURE Behavioral OF DecimatingAccumulator IS
    SIGNAL input     : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
    SIGNAL output    : STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
    SIGNAL enableBit : STD_LOGIC;
    SIGNAL validBit  : STD_LOGIC;
BEGIN
    input     <= dataIn;
    enableBit <= enable;
    valid     <= validBit;
    dataOut   <= output;

    accum : PROCESS(clock)
        CONSTANT accumWidth  : POSITIVE := max(bitWidthIn, bitWidthOut);
        CONSTANT outWidth    : POSITIVE := shiftGain + bitWidthOut;
        VARIABLE accumulator : STD_LOGIC_VECTOR(accumWidth - 1 DOWNTO 0);
        VARIABLE count       : NATURAL RANGE 0 TO decimation;
    BEGIN
        ASSERT outWidth <= accumWidth REPORT "Shift Gain Out of Bounds";
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                accumulator := (OTHERS => '0');
                count       := 0;
                output      <= (OTHERS => '0');
                validBit    <= '0';
            ELSIF enableBit = '1' THEN
                accumulator := STD_LOGIC_VECTOR(signed(accumulator) + signed(input));
                output      <= accumulator(outWidth - 1 DOWNTO shiftGain);
                count       := count + 1;
                IF count = decimation THEN
                    accumulator := (OTHERS => '0');
                    count       := 0;
                    validBit    <= '1';
                ELSE
                    validBit <= '0';
                END IF;
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS accum;
END Behavioral;