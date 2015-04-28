-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseClockSynch_tb IS
END PolyphaseClockSynch_tb;

ARCHITECTURE behavior OF PolyphaseClockSynch_tb IS
    COMPONENT PolyphaseClockSynch IS
        GENERIC(
            numSubfilters    : POSITIVE;
            coefBitWidth     : POSITIVE;
            bitWidth         : POSITIVE;
            samplesPerSymbol : REAL;
            taps             : INTEGER_ARRAY;
            alpha            : INTEGER;
            beta             : INTEGER
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            valid   : OUT STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0)
        );
    END COMPONENT;

    CONSTANT testNumSubFilters    : POSITIVE      := 32;
    CONSTANT testCoefBitWidth     : POSITIVE      := 18;
    CONSTANT testBitWidth         : POSITIVE      := 12;
    CONSTANT testSamplesPerSymbol : REAL          := 4.0;
    CONSTANT testAlpha            : INTEGER       := 6784;
    CONSTANT testBeta             : INTEGER       := 601;
    CONSTANT testInput            : INTEGER_ARRAY := (
    );

    CONSTANT realTaps : REAL_ARRAY := (
    );

    CONSTANT intTaps : INTEGER_ARRAY(realTaps'range) := realToInteger(
        bitWidth => testCoefBitWidth,
        realArray => realTaps
    );

    CONSTANT testTaps : INTEGER_ARRAY(intTaps'range) := tapsGainMultiply(
        multiplicand => testNumSubFilters,
        taps => intTaps
    );

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL valid   : STD_LOGIC := '0';
    SIGNAL dataIn  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL dataOut : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);

BEGIN
    synch : PolyphaseClockSynch
        GENERIC MAP(
            numSubFilters    => testNumSubFilters,
            coefBitWidth     => testCoefBitWidth,
            bitWidth         => testBitWidth,
            samplesPerSymbol => testSamplesPerSymbol,
            taps             => testTaps,
            alpha            => testAlpha,
            beta             => testBeta
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