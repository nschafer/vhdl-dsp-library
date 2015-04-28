-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY LoopFilter_tb IS
END LoopFilter_tb;

ARCHITECTURE behavior OF LoopFilter_tb IS
    COMPONENT LoopFilter IS
        GENERIC(
            bitWidth     : POSITIVE;
            coefBitWidth : POSITIVE;
            alpha        : INTEGER;
            beta         : INTEGER
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT testBitWidthIn   : POSITIVE      := 12;
    CONSTANT testCoefBitWidth : POSITIVE      := 18;
    CONSTANT testInput        : INTEGER_ARRAY := (
        1200, 1177, 1109, 998, 849, 667, 459, 234, 0, -234, -459, -667, -849, -998, -1109, -1177,
        -1200, -1177, -1109, -998, -849, -667, -459, -234, 0, 234, 459, 667, 849, 998, 1109, 1177, 0
    );
    CONSTANT testShift : INTEGER := testCoefBitWidth;
    CONSTANT testAlpha : INTEGER := 6784;
    CONSTANT testBeta  : INTEGER := 601;

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL dataIn  : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL dataOut : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL valid   : STD_LOGIC;

BEGIN
    filter : LoopFilter
        GENERIC MAP(
            bitWidth     => testBitWidthIn,
            coefBitWidth => testCoefBitWidth,
            alpha        => testAlpha,
            beta         => testBeta
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut,
            valid   => valid
        );

    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    sequenceProcess : PROCESS
    BEGIN
        reset <= '1';
        WAIT FOR 2 * clockPeriod;
        WAIT FOR 2 ns;
        reset  <= '0';
        enable <= '1';
        FOR index IN testInput'low TO testInput'high LOOP
            dataIn <= STD_LOGIC_VECTOR(to_signed(testInput(index), testBitWidthIn));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;