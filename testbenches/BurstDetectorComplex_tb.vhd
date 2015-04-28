-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BurstDetectorComplex_tb IS
END BurstDetectorComplex_tb;

ARCHITECTURE behavior OF BurstDetectorComplex_tb IS
    COMPONENT BurstDetectorComplex IS
        GENERIC(
            bitWidth              : POSITIVE;
            sampleAddressSpace    : POSITIVE;
            sampleDecimation      : POSITIVE;
            coefBitWidth          : POSITIVE;
            averageThresholdShift : NATURAL;
            realTaps              : INTEGER_ARRAY;
            imagTaps              : INTEGER_ARRAY;
            threshold             : POSITIVE;
            burstLength           : POSITIVE;
            burstHistory          : NATURAL;
            numCordicRotations    : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            realIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC;
            realOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT BurstDetectorComplex;

    CONSTANT testCoefBitWidth    : POSITIVE      := 18;
    CONSTANT testBitWidth        : POSITIVE      := 16;
    CONSTANT testAddressSpace    : POSITIVE      := 3;
    CONSTANT testRealTaps        : INTEGER_ARRAY := (10000, 20000, 30000);
    CONSTANT testImagTaps        : INTEGER_ARRAY := (30000, 20000, 10000);
    CONSTANT testNumTaps         : POSITIVE      := testRealTaps'length;
    CONSTANT testDecimation      : POSITIVE      := 1;
    CONSTANT tapsShiftGain       : NATURAL       := 0;
    CONSTANT testThresholdShift  : NATURAL       := 2;
    CONSTANT minThreshold        : NATURAL       := 100;
    CONSTANT maxThreshold        : NATURAL       := 2047;
    CONSTANT testBurstLength     : POSITIVE      := 6;
    CONSTANT testBurstHistory    : NATURAL       := 0;
    CONSTANT testCordicRotations : POSITIVE      := 8;
    CONSTANT testRealInput       : INTEGER_ARRAY := (1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 30, 1);
    CONSTANT testImagInput       : INTEGER_ARRAY := (0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, -90, 0);
    CONSTANT clockPeriod         : TIME          := 10 ns;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL valid   : STD_LOGIC := '0';
    SIGNAL realIn  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL imagIn  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL realOut : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL imagOut : STD_LOGIC_VECTOR(testBItWidth - 1 DOWNTO 0);

BEGIN
    burst1 : BurstDetectorComplex
        GENERIC MAP(
            bitWidth              => testBitWidth,
            sampleAddressSpace    => testAddressSpace,
            sampleDecimation      => testDecimation,
            coefBitWidth          => testCoefBitWidth,
            averageThresholdShift => testThresholdShift,
            realTaps              => testRealTaps,
            imagTaps              => testImagTaps,
            threshold             => maxThreshold,
            burstLength           => testBurstLength,
            burstHistory          => testBurstHistory,
            numCordicRotations    => testCordicRotations
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid,
            realIn  => realIn,
            imagIn  => imagIn,
            realOut => realOut,
            imagOut => imagOut
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
        ASSERT testRealInput'length = testImagInput'length;
        reset <= '1';
        WAIT FOR 2 * clockPeriod;
        WAIT FOR 2 ns;
        reset  <= '0';
        enable <= '1';
        FOR index IN testRealInput'low TO testRealInput'high LOOP
            realIn <= STD_LOGIC_VECTOR(to_signed(testRealInput(index), testBitWidth));
            imagIn <= STD_LOGIC_VECTOR(to_signed(testImagInput(index), testBitWidth));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;