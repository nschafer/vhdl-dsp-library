-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BurstDetectorReal_tb IS
END BurstDetectorReal_tb;

ARCHITECTURE behavior OF BurstDetectorReal_tb IS
    COMPONENT BurstDetectorReal IS
        GENERIC(
            bitWidth              : POSITIVE;
            sampleAddressSpace    : POSITIVE;
            sampleDecimation      : POSITIVE;
            coefBitWidth          : POSITIVE;
            averageThresholdShift : NATURAL;
            taps                  : INTEGER_ARRAY;
            threshold             : POSITIVE;
            burstHistory          : NATURAL;
            burstLength           : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC;
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT BurstDetectorReal;

    CONSTANT testCoefBitWidth       : POSITIVE      := 18;
    CONSTANT testBitWidth           : POSITIVE      := 16;
    CONSTANT testTaps               : INTEGER_ARRAY := (10000, 20000, 30000);
    CONSTANT testNumTaps            : POSITIVE      := testTaps'length;
    CONSTANT testSampleAddressSpace : POSITIVE      := 3;
    CONSTANT testSampleDecimation   : POSITIVE      := 1;
    CONSTANT averageThresholdShift  : NATURAL       := 2;
    CONSTANT maxThreshold           : NATURAL       := 2047;
    CONSTANT testHistory            : NATURAL       := 0;
    CONSTANT testBurstLength        : POSITIVE      := 6;
    CONSTANT testInput              : INTEGER_ARRAY := (1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 400, 1);
    CONSTANT clockPeriod            : TIME          := 10 ns;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL valid   : STD_LOGIC := '0';
    SIGNAL dataIn  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL dataOut : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);

BEGIN
    burst1 : BurstDetectorReal
        GENERIC MAP(
            bitWidth              => testBitWidth,
            sampleAddressSpace    => testSampleAddressSpace,
            sampleDecimation      => testSampleDecimation,
            coefBitWidth          => testCoefBitWidth,
            averageThresholdShift => averageThresholdShift,
            taps                  => testTaps,
            threshold             => maxThreshold,
            burstHistory          => testHistory,
            burstLength           => testBurstLength
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid,
            dataIn  => dataIn,
            dataOut => dataOut
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
            dataIn <= STD_LOGIC_VECTOR(to_signed(testInput(index), testBitWidth));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;