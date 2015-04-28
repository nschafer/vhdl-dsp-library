-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
----------------------------------------------------------------------------------------------------------------------------
-- Polyphase Decimating FIR Filter Complex
--
-- Input: Signed Complex Data
-- Output: Signed Complex Data
-- Assumes both real and imaginary inputs are available during enable. Outputs real and imaginary simultaneously.
--
-- Parameters 
-- BitWidth: Bit size of one element of data.
-- coefBitWidth: Size of filter coefficients.
-- decimation: The decimation rate. Sets output rate.
-- realTaps: The real filter coefficients. Assumes these are fixed point signed fractions from [-1, 1) of size <coefBitWidth>.
--           To decimate without filtering, a single coefficient of "2^(bitwidth -1) -1, 0" should be provided. This will act as a multiply by 1. 
--           Must be the same length as imagTaps.
-- imagTaps: The imaginary filter coefficients. Assumes these are fixed point signed fractions from [-1, 1) of size <coefBitWidth>.
--           To perform a real filter on complex data, set all imagTaps to "0."
--
-- Behavior
-- Combines filtering and decimation into one operation. Will accept any filter coefficients, although low pass filters are
-- typical. Provides resource savings at the decimation rate. For instance, a 100 tap filter with a decimation of 10 requires
-- only 10 multiplies. The same filter with a decimation of 20 requires 5 multiplies.
-- Since this uses complex multiplies, actual DSP block usage is typically number of multiplies * 4.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseDecimatingFirFilterComplex IS
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
END PolyphaseDecimatingFirFilterComplex;

ARCHITECTURE Structural OF PolyphaseDecimatingFirFilterComplex IS
    COMPONENT PolyphaseDecimatingFirFilter IS
        GENERIC(
            Decimation   : POSITIVE;
            CoefBitWidth : POSITIVE;
            BitWidth     : POSITIVE;
            Taps         : INTEGER_ARRAY
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            valid   : OUT STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0)
        );
    END COMPONENT PolyphaseDecimatingFirFilter;

    COMPONENT ClockedAdd
        GENERIC(
            bitWidthIn : POSITIVE
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
    END COMPONENT ClockedAdd;

    COMPONENT Reg IS
        GENERIC(
            bitWidth : POSITIVE := DEFAULT_BITWIDTH
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL slowClock    : STD_LOGIC;
    SIGNAL valid1       : STD_LOGIC;
    SIGNAL realReal     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL realImag     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL imagReal     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL imagImag     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL negativeImag : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

    SIGNAL realIntern : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL imagIntern : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

    SIGNAL validOutput : STD_LOGIC;

BEGIN
    negativeImag <= STD_LOGIC_VECTOR(-signed(imagImag));

    realInRealFilter : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => decimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            taps         => realTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid1,
            dataIn  => realIn,
            dataOut => realReal
        );

    realInImagFilter : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => decimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            taps         => imagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => OPEN,
            dataIn  => realIn,
            dataOut => realImag
        );

    imagInRealFilter : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => decimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            taps         => realTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => OPEN,
            dataIn  => imagIn,
            dataOut => imagReal
        );

    imagInImagFilter : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            decimation   => decimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            taps         => imagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => OPEN,
            dataIn  => imagIn,
            dataOut => imagImag
        );

    realIntern <= STD_LOGIC_VECTOR(signed(realReal) + signed(negativeImag));
    imagIntern <= STD_LOGIC_VECTOR(signed(realImag) + signed(imagReal));

    clockedRealOut : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => slowClock,
            dataIn  => realIntern,
            dataOut => realOut
        );

    clockedImagOut : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => slowClock,
            dataIn  => imagIntern,
            dataOut => imagOut,
            valid   => validOutput
        );

    slowClock <= valid1;
    valid     <= validOutput;

END Structural;        
