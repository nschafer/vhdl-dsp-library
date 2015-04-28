-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseDecimatingFirFilterComplex_tb IS
END PolyphaseDecimatingFirFilterComplex_tb;

ARCHITECTURE behavior OF PolyphaseDecimatingFirFilterComplex_tb IS
    COMPONENT PolyphaseDecimatingFirFilterComplex IS
        GENERIC(
            decimation   : POSITIVE;
            coefBitWidth : POSITIVE;
            bitWidth     : POSITIVE;
            realTaps     : INTEGER_ARRAY;
            imagTaps     : INTEGER_ARRAY
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            valid   : OUT STD_LOGIC;
            realIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            realOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
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
    CONSTANT testRealTaps     : INTEGER_ARRAY := (
        3276, 6551, 9828, 13105, 16382, 19659, 22936, 26213, 29490, 32767,
        29490, 26213, 22936, 19659, 16382, 13105, 9828, 6551, 3276
    );
    CONSTANT testImagTaps : INTEGER_ARRAY := (
        -3276, -6551, -9828, -13105, -16382, -19659, -22936, -26213, -29490, -32767,
        -29490, -26213, -22936, -19659, -16382, -13105, -9828, -6551, -3276
    );
    CONSTANT testNumTaps   : POSITIVE := testRealTaps'length;

    CONSTANT testRealInput : INTEGER_ARRAY := (20, 40, 80, 100, 100, 20, 0); --always want trailing 0 for test bench case
    CONSTANT testImagInput : INTEGER_ARRAY := (50, 40, 30, 10, 200, 30, 0);

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock         : STD_LOGIC := '0';
    SIGNAL reset         : STD_LOGIC := '0';
    SIGNAL enable        : STD_LOGIC := '0';
    SIGNAL valid1        : STD_LOGIC := '0';
    SIGNAL valid2        : STD_LOGIC := '0';
    SIGNAL valid3        : STD_LOGIC := '0';
    SIGNAL valid4        : STD_LOGIC := '0';
    SIGNAL valid5        : STD_LOGIC := '0';
    SIGNAL valid6        : STD_LOGIC := '0';
    SIGNAL valid7        : STD_LOGIC := '0';
    SIGNAL valid8        : STD_LOGIC := '0';
    SIGNAL valid9        : STD_LOGIC := '0';
    SIGNAL valid10       : STD_LOGIC := '0';
    SIGNAL dataInReal    : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL dataInImag    : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL dataOutReal1  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag1  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal2  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag2  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal3  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag3  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal4  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag4  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal5  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag5  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal6  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag6  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal7  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag7  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal8  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag8  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal9  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag9  : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutReal10 : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);
    SIGNAL dataOutImag10 : STD_LOGIC_VECTOR(testBitWidthOut - 1 DOWNTO 0);

BEGIN
    noDec : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation1,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid1,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal1,
            imagOut => dataOutImag1
        );

    dec2 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation2,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid2,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal2,
            imagOut => dataOutImag2
        );

    dec3 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation3,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid3,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal3,
            imagOut => dataOutImag3
        );

    dec4 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation4,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid4,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal4,
            imagOut => dataOutImag4
        );

    dec5 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation5,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid5,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal5,
            imagOut => dataOutImag5
        );

    dec6 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation6,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid6,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal6,
            imagOut => dataOutImag6
        );

    dec7 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation7,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid7,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal7,
            imagOut => dataOutImag7
        );

    dec8 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation8,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid8,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal8,
            imagOut => dataOutImag8
        );

    dec9 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation9,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid9,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal9,
            imagOut => dataOutImag9
        );

    dec10 : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            decimation   => testDecimation10,
            coefBitWidth => testCoefBitWidth,
            bitWidth     => testBitWidthIn,
            realTaps     => testRealTaps,
            imagTaps     => testImagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid10,
            realIn  => dataInReal,
            imagIn  => dataInImag,
            realOut => dataOutReal10,
            imagOut => dataOutImag10
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
        ASSERT testRealInput'length = testImagInput'length;
        FOR index IN testRealInput'low TO testRealInput'high LOOP
            dataInReal <= STD_LOGIC_VECTOR(to_signed(testRealInput(index), testBitWidthIn));
            dataInImag <= STD_LOGIC_VECTOR(to_signed(testImagInput(index), testBitWidthIn));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;