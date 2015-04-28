-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseDecimatingFirFilter_tb IS
END PolyphaseDecimatingFirFilter_tb;

ARCHITECTURE behavior OF PolyphaseDecimatingFirFilter_tb IS
    COMPONENT PolyphaseDecimatingFirFilter IS
        GENERIC(
            decimation   : POSITIVE;
            coefBitWidth : POSITIVE;
            bitWidth     : POSITIVE;
            taps         : INTEGER_ARRAY
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

    CONSTANT testDecimation1  : POSITIVE      := 1;
    CONSTANT testDecimation2  : POSITIVE      := 2;
    CONSTANT testDecimation3  : POSITIVE      := 3;
    CONSTANT testDecimation4  : POSITIVE      := 4;
    CONSTANT testDecimation5  : POSITIVE      := 5;
    CONSTANT testDecimation6  : POSITIVE      := 6;
    CONSTANT testDecimation7  : POSITIVE      := 7;
    CONSTANT testDecimation8  : POSITIVE      := 8;
    CONSTANT testDecimation9  : POSITIVE      := 9;
    CONSTANT testDecimation10 : POSITIVE      := 10;
    CONSTANT testCoefBitWidth : POSITIVE      := 16;
    CONSTANT testBitWidthIn   : POSITIVE      := 16;
    CONSTANT testBitWidthOut  : POSITIVE      := 16;
    CONSTANT testTaps         : INTEGER_ARRAY := (
        3276, 6551, 9828, 13105, 16382, 19659, 22936, 26213, 29490, 32767,
        29490, 26213, 22936, 19659, 16382, 13105, 9828, 6551, 3276
    );

    CONSTANT testInput : INTEGER_ARRAY := (200, 400, 800, 1000, 1000, 200, 0); --always want trailing 0 for test bench case

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock     : STD_LOGIC := '0';
    SIGNAL reset     : STD_LOGIC := '0';
    SIGNAL enable    : STD_LOGIC := '0';
    SIGNAL valid1    : STD_LOGIC := '0';
    SIGNAL valid2    : STD_LOGIC := '0';
    SIGNAL valid3    : STD_LOGIC := '0';
    SIGNAL valid4    : STD_LOGIC := '0';
    SIGNAL valid5    : STD_LOGIC := '0';
    SIGNAL valid6    : STD_LOGIC := '0';
    SIGNAL valid7    : STD_LOGIC := '0';
    SIGNAL valid8    : STD_LOGIC := '0';
    SIGNAL valid9    : STD_LOGIC := '0';
    SIGNAL valid10   : STD_LOGIC := '0';
    SIGNAL dataIn    : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL dataOut1  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut2  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut3  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut4  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut5  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut6  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut7  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut8  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut9  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOut10 : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);

BEGIN
    noDec : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation1,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid1,
            dataIn  => dataIn,
            dataOut => dataOut1
        );

    dec2 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation2,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid2,
            dataIn  => dataIn,
            dataout => dataOut2
        );

    dec3 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation3,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid3,
            dataIn  => dataIn,
            dataOut => dataOut3
        );

    dec4 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation4,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid4,
            dataIn  => dataIn,
            dataOut => dataOut4
        );

    dec5 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation5,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid5,
            dataIn  => dataIn,
            dataOut => dataOut5
        );

    dec6 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation6,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid6,
            dataIn  => dataIn,
            dataOut => dataOut6
        );

    dec7 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation7,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid7,
            dataIn  => dataIn,
            dataOut => dataOut7
        );

    dec8 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation8,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid8,
            dataIn  => dataIn,
            dataOut => dataOut8
        );

    dec9 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation9,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid9,
            dataIn  => dataIn,
            dataOut => dataOut9
        );

    dec10 : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => testDecimation10,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            taps         => testTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid10,
            dataIn  => dataIn,
            dataOut => dataOut10
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