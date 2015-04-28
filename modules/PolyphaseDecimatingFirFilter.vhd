-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
---------------------------------------------------------------------------------------------------
--Polyphase Decimating FIR Filter Real
--
--Input: Signed Data 
--Output: Signed Data
--
--Parameters
--BitWidth: Bit size of one element of data.
--coefBitWidth: Size of filter coefficients.
--decimation: The decimation rate. Sets output rate.
--taps:   The filter coefficients. Assumes these are fixed point signed fractions from [-1, 1) of size <coefBitWidth>.
--        To decimate without filtering, a single coefficient of 
--        "2^(bitwidth -1) -1" should be provided. This will act as a multiply of ~1. 
--
-- Behavior
-- Combines filtering and decimation into one operation. Will accept any filter coefficients, although low pass filters are
-- typical. Provides resource savings at the decimation rate. For instance, a 100 tap filter with a decimation of 10 requires
-- only 10 multiplies. The same filter with a decimation of 20 requires 5 multiplies.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseDecimatingFirFilter IS
    GENERIC(
        decimation   : POSITIVE      := DEFAULT_DECIMATION;
        coefBitWidth : POSITIVE      := DEFAULT_COEF_BITWIDTH;
        bitWidth     : POSITIVE      := DEFAULT_BITWIDTH;
        taps         : INTEGER_ARRAY := DEFAULT_TAPS
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        valid   : OUT STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
    );
END PolyphaseDecimatingFirFilter;

ARCHITECTURE Structural OF PolyphaseDecimatingFirFilter IS
    COMPONENT Decrementer IS
        GENERIC(
            maxCount : NATURAL := DEFAULT_COUNT
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataOut : OUT NATURAL RANGE 0 TO maxCount;
            valid   : OUT STD_LOGIC
        );
    END COMPONENT decrementer;

    COMPONENT ClockedMultiply
        GENERIC(
            bitWidthIn1 : POSITIVE;
            bitWidthIn2 : POSITIVE
        );
        PORT(
            reset  : IN  STD_LOGIC;
            clock  : IN  STD_LOGIC;
            enable : IN  STD_LOGIC;
            in1    : IN  STD_LOGIC_VECTOR(bitWidthIn1 - 1 DOWNTO 0);
            in2    : IN  STD_LOGIC_VECTOR(bitWidthIn2 - 1 DOWNTO 0);
            prod   : OUT STD_LOGIC_VECTOR((bitWidthIn1 + BitWidthIn2) - 1 DOWNTO 0);
            valid  : OUT STD_LOGIC
        );
    END COMPONENT ClockedMultiply;

    COMPONENT DecimatingAccumulator
        GENERIC(
            decimation  : POSITIVE;
            shiftGain   : NATURAL;
            bitWidthIn  : POSITIVE;
            bitWidthOut : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT DecimatingAccumulator;

    COMPONENT ClockEnableControl IS
        GENERIC(
            Decimation : POSITIVE
        );
        PORT(
            clockIn  : IN  STD_LOGIC;
            reset    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            clockOut : OUT STD_LOGIC
        );
    END COMPONENT ClockEnableControl;

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
    END COMPONENT Reg;

    CONSTANT subFilterLength : POSITIVE := INTEGER(ceil(real(taps'length) / real(decimation)));

    CONSTANT coefBank : COEFFICIENT_BANK(0 TO decimation - 1, 0 TO subFilterLength - 1) := generateCoefBank(
        coefBitWidth => coefBitWidth,
        decimation => decimation,
        filterCoefficients => Taps
    );

    -- internal signals
    SUBTYPE ROM_BUS IS STD_LOGIC_VECTOR(coefBitWidth - 1 DOWNTO 0);
    SUBTYPE MULT_OUT IS STD_LOGIC_VECTOR(coefBitWidth + bitWidth - 1 DOWNTO 0);
    SUBTYPE ACC_OUT IS STD_LOGIC_VECTOR(CoefBitWidth + bitWidth - 1 DOWNTO 0);

    TYPE ROM_SIG IS ARRAY (0 TO subFilterLength - 1) OF ROM_BUS;
    TYPE MULT_SIG IS ARRAY (0 TO subFilterLength - 1) OF MULT_OUT;
    TYPE ACC_SIG IS ARRAY (0 TO subFilterLength - 1) OF ACC_OUT;
    TYPE ADD_SIG IS ARRAY (0 TO subFilterLength - 1) OF ACC_OUT;

    SIGNAL intrnRomSig      : ROM_SIG;
    SIGNAL intrnMultSig     : MULT_SIG;
    SIGNAL intrnAccSig      : ACC_SIG;
    SIGNAL intrnDelayAccSig : ACC_SIG;
    SIGNAL intrnAddSig      : ADD_SIG;
    SIGNAL romAddress       : NATURAL RANGE 0 TO decimation - 1;
    SIGNAL decimatedClock   : STD_LOGIC;
    SIGNAL slowClock        : STD_LOGIC;
    SIGNAL regDataIn        : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL outData          : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

    -- These signals help ensure all the internal primitives are synchronized
    SIGNAL validOutput            : STD_LOGIC;
    SIGNAL validOutputEnable      : STD_LOGIC;
    SIGNAL delayedValid           : STD_LOGIC;
    SIGNAL validInput             : STD_LOGIC;
    SIGNAL validInputEnable       : STD_LOGIC;
    SIGNAL validTapProduct        : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);
    SIGNAL enableAccumulator      : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);
    SIGNAL validAccumulator       : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);
    SIGNAL enableDelayAccumulator : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);
    SIGNAL validDelayAccumulator  : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);
    SIGNAL enableAdder            : STD_LOGIC_VECTOR(0 TO subFilterLength - 1);

BEGIN
    outData <= intrnAddSig(0)(bitWidth + coefBitWidth - 2 DOWNTO coefBitWidth - 1); -- shift back down to original bitwidth, taking into account sign extension

    romAddr : Decrementer
        GENERIC MAP(
            maxCount => decimation - 1
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataOut => romAddress,
            valid   => OPEN
        );

    input_reg : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => regDataIn,
            valid   => validInput
        );

    validInputEnable <= validInput;

    slow_clock : ClockEnableControl
        GENERIC MAP(
            decimation => decimation
        )
        PORT MAP(
            clockIn  => clock,
            reset    => reset,
            enable   => validInputEnable,
            clockOut => decimatedClock
        );

    validOutputEnable <= validOutput;

    output_reg : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => validOutputEnable,
            dataIn  => outData,
            dataOut => dataOut,
            valid   => delayedValid
        );

    GenerateFilterBank : FOR J IN 0 TO subFilterLength - 1 GENERATE
    BEGIN
        intrnRomSig(J) <= STD_LOGIC_VECTOR(to_signed(coefBank(romAddress, J), coefBitWidth));

        mult_j : ClockedMultiply
            GENERIC MAP(
                bitWidthIn1 => bitWidth,
                bitWidthIn2 => coefBitWidth
            )
            PORT MAP(
                reset  => reset,
                clock  => clock,
                enable => validInputEnable,
                in1    => regDataIn,
                in2    => intrnRomSig(J),
                prod   => intrnMultSig(J),
                valid  => validTapProduct(J)
            );

        enableAccumulator(J) <= validTapProduct(J);

        acc_j : DecimatingAccumulator
            GENERIC MAP(
                decimation  => decimation,
                shiftGain   => 0,
                bitWidthIn  => coefBitWidth + bitWidth,
                bitWidthOut => coefBitWidth + bitWidth
            )
            PORT MAP(
                clock   => clock,
                reset   => reset,
                enable  => enableAccumulator(J),
                dataIn  => intrnMultSig(J),
                dataOut => intrnAccSig(J),
                valid   => validAccumulator(J)
            );

        enableDelayAccumulator(J) <= validAccumulator(J);

        del_j : Reg
            GENERIC MAP(
                bitWidth => coefBitWidth + bitWidth
            )
            PORT MAP(
                reset   => reset,
                clock   => clock,
                enable  => enableDelayAccumulator(J),
                dataIn  => intrnAccSig(J),
                dataOut => intrnDelayAccSig(J),
                valid   => validDelayAccumulator(J)
            );

        enableAdder(J) <= validDelayAccumulator(J);

        with_adders : IF J < subFilterLength - 1 GENERATE
        BEGIN
            add_j : ClockedAdd
                GENERIC MAP(
                    bitWidthIn => coefBitWidth + bitWidth
                )
                PORT MAP(
                    reset  => reset,
                    clock  => clock,
                    enable => enableAdder(J),
                    in1    => intrnDelayAccSig(J),
                    in2    => intrnAddSig(J + 1),
                    sum    => intrnAddSig(J)
                );
        END GENERATE with_adders;

        no_adders : IF J = subFilterLength - 1 GENERATE
        BEGIN
            no_add_del_j : Reg
                GENERIC MAP(
                    bitWidth => coefBitWidth + bitWidth
                )
                PORT MAP(
                    reset   => reset,
                    clock   => clock,
                    enable  => enableAdder(J),
                    dataIn  => intrnDelayAccSig(J),
                    dataOut => intrnAddSig(J),
                    valid   => validOutput
                );
        END GENERATE no_adders;

    END GENERATE GenerateFilterBank;

    slowClock <= decimatedClock;
    valid     <= delayedValid;

END Structural;        
