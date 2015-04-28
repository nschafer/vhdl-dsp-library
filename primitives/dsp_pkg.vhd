-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE IEEE.MATH_COMPLEX.ALL;

PACKAGE DSP IS
    TYPE INTEGER_ARRAY IS ARRAY (NATURAL RANGE <>) OF INTEGER;
    TYPE REAL_ARRAY IS ARRAY (NATURAL RANGE <>) OF REAL;
    TYPE COEFFICIENT_BANK IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF INTEGER;

    CONSTANT DEFAULT_DELAY : NATURAL := 5;

    CONSTANT DEFAULT_BITWIDTH : POSITIVE := 12;

    CONSTANT DEFAULT_SEQUENCE_LENGTH : POSITIVE := 5;

    CONSTANT DEFAULT_PACKET_SIZE : POSITIVE := 10;

    CONSTANT DEFAULT_SEQUENCE : INTEGER_ARRAY := (1, 0, 0, 1, 1);

    CONSTANT DEFAULT_SAMPLE_ADDRESS_SPACE : POSITIVE := 10;

    CONSTANT DEFAULT_STAGGER_SIZE : POSITIVE := 10;

    CONSTANT DEFAULT_SUM_BITWIDTH : POSITIVE := 22;

    CONSTANT DEFAULT_NUM_TAPS : POSITIVE := 128;

    CONSTANT DEFAULT_HILBERT_ORDER : POSITIVE := 21;

    CONSTANT DEFAULT_NUM_INTERP_TAPS : POSITIVE := 40;

    CONSTANT DEFAULT_COEF_BITWIDTH : POSITIVE := 18;

    CONSTANT DEFAULT_DECIMATION : POSITIVE := 5;

    CONSTANT DEFAULT_INTERPOLATION : POSITIVE := 2;

    CONSTANT DEFAULT_COUNT : NATURAL := 5;

    CONSTANT DEFAULT_SHIFT_GAIN : NATURAL := 0;

    CONSTANT DEFAULT_NUM_BURST_TAPS : POSITIVE := 16;

    CONSTANT DEFAULT_MIN_THRESHOLD : POSITIVE := 100;

    CONSTANT DEFAULT_MAX_THRESHOLD : POSITIVE := 2047;

    CONSTANT DEFAULT_CORDIC_ROTATIONS : POSITIVE := 10;

    CONSTANT DEFAULT_HISTORY : NATURAL := 0;

    CONSTANT DEFAULT_ALPHA : INTEGER := 6784;

    CONSTANT DEFAULT_BETA : INTEGER := 601;

    CONSTANT DEFAULT_SPS : REAL := 4.0;

    CONSTANT DEFAULT_NUM_FILTERS : POSITIVE := 32;

    CONSTANT DEFAULT_MAX_LATENCY : NATURAL := 63;

    CONSTANT DEFAULT_BURST_TAPS : INTEGER_ARRAY := (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
    );

    CONSTANT DEFAULT_TAPS : INTEGER_ARRAY := (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1,
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
        16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1
    );

    FUNCTION max(L, R : INTEGER) RETURN INTEGER;

    FUNCTION inRange(
        bitWidth : POSITIVE;
        input    : INTEGER
        ) RETURN BOOLEAN;

    FUNCTION generateCoefBank(
        coefBitWidth, decimation : POSITIVE;
        filterCoefficients       : INTEGER_ARRAY
        ) RETURN COEFFICIENT_BANK;

    FUNCTION decrement(
        input, max : NATURAL
        ) RETURN NATURAL;

    FUNCTION getRealTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY;

    FUNCTION getImagTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY;

    FUNCTION getPhaseChange(
        iteration : NATURAL;
        bitWidth  : POSITIVE
        ) RETURN STD_LOGIC_VECTOR;

    FUNCTION getDiffTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY;

    FUNCTION getUnderflowConst(
        bitWidth : POSITIVE;
        sps      : REAL
        ) RETURN STD_LOGIC_VECTOR;

    FUNCTION getFilterIndex(
        bitWidth, filters : POSITIVE;
        sps               : REAL;
        registerVal       : STD_LOGIC_VECTOR
        ) RETURN NATURAL;

    FUNCTION realToInteger(
        bitWidth  : POSITIVE;
        realArray : REAL_ARRAY
        ) RETURN INTEGER_ARRAY;

    FUNCTION tapsGainMultiply(
        multiplicand : POSITIVE;
        taps         : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY;

    FUNCTION getDiffCoefBank(
        numSubFilters, subFilterLength : POSITIVE;
        matchedCoefBank                : COEFFICIENT_BANK
        ) RETURN COEFFICIENT_BANK;

    COMPONENT Delay IS
        GENERIC(
            delayLength : NATURAL;
            bitWidth    : POSITIVE
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT StartFrameDetector
        GENERIC(
            bitWidth       : POSITIVE      := DEFAULT_BITWIDTH;
            packetSize     : POSITIVE      := DEFAULT_PACKET_SIZE;
            searchSequence : INTEGER_ARRAY := DEFAULT_SEQUENCE
        );
        PORT(
            reset    : IN  STD_LOGIC;
            clock    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            validOut : OUT STD_LOGIC;
            dataOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT PolyphaseDecimatingFirFilter IS
        GENERIC(
            Decimation   : POSITIVE      := DEFAULT_DECIMATION;
            CoefBitWidth : POSITIVE      := DEFAULT_COEF_BITWIDTH;
            BitWidth     : POSITIVE      := DEFAULT_BITWIDTH;
            Taps         : INTEGER_ARRAY := DEFAULT_TAPS
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

    COMPONENT PolyphaseDecimatingFirFilterComplex IS
        GENERIC(
            decimation   : POSITIVE      := DEFAULT_DECIMATION;
            coefBitWidth : POSITIVE      := DEFAULT_COEF_BITWIDTH;
            bitWidth     : POSITIVE      := DEFAULT_BITWIDTH;
            realTaps     : INTEGER_ARRAY := DEFAULT_TAPS;
            imagTaps     : INTEGER_ARRAY := DEFAULT_TAPS
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

    COMPONENT BurstDetectorReal IS
        GENERIC(
            bitWidth              : POSITIVE      := DEFAULT_BITWIDTH;
            sampleAddressSpace    : POSITIVE      := DEFAULT_SAMPLE_ADDRESS_SPACE;
            sampleDecimation      : POSITIVE      := DEFAULT_DECIMATION;
            coefBitWidth          : POSITIVE      := DEFAULT_COEF_BITWIDTH;
            averageThresholdShift : NATURAL       := DEFAULT_SHIFT_GAIN;
            taps                  : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
            threshold             : POSITIVE      := DEFAULT_MAX_THRESHOLD;
            burstHistory          : NATURAL       := DEFAULT_HISTORY;
            burstLength           : POSITIVE      := DEFAULT_PACKET_SIZE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC;
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT BurstDetectorComplex IS
        GENERIC(
            bitWidth              : POSITIVE      := DEFAULT_BITWIDTH;
            sampleAddressSpace    : POSITIVE      := DEFAULT_SAMPLE_ADDRESS_SPACE;
            sampleDecimation      : POSITIVE      := DEFAULT_DECIMATION;
            coefBitWidth          : POSITIVE      := DEFAULT_COEF_BITWIDTH;
            averageThresholdShift : NATURAL       := DEFAULT_SHIFT_GAIN;
            realTaps              : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
            imagTaps              : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
            threshold             : POSITIVE      := DEFAULT_MAX_THRESHOLD;
            burstLength           : POSITIVE      := DEFAULT_PACKET_SIZE;
            burstHistory          : NATURAL       := DEFAULT_HISTORY;
            numCordicRotations    : POSITIVE      := DEFAULT_CORDIC_ROTATIONS
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
    END COMPONENT;

    COMPONENT QuadratureDemod IS
        GENERIC(
            bitWidth      : POSITIVE := DEFAULT_BITWIDTH;
            phaseBitWidth : POSITIVE := DEFAULT_BITWIDTH;
            numIterations : NATURAL  := DEFAULT_CORDIC_ROTATIONS
        );
        PORT(
            reset        : IN  STD_LOGIC;
            clock        : IN  STD_LOGIC;
            enable       : IN  STD_LOGIC;
            realIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            magnitudeOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            demodOut     : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            valid        : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT PolyphaseClockSynch IS
        GENERIC(
            numSubfilters    : POSITIVE      := DEFAULT_DECIMATION;
            coefBitWidth     : POSITIVE      := DEFAULT_COEF_BITWIDTH;
            bitWidth         : POSITIVE      := DEFAULT_BITWIDTH;
            samplesPerSymbol : REAL          := DEFAULT_SPS;
            taps             : INTEGER_ARRAY := DEFAULT_TAPS;
            alpha            : INTEGER       := DEFAULT_ALPHA;
            beta             : INTEGER       := DEFAULT_BETA
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

    COMPONENT BinarySlicer IS
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
    END COMPONENT;

    COMPONENT BitPacker IS
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
    END COMPONENT;

END PACKAGE DSP;
