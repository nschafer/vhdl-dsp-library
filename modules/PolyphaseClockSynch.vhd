-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
------------------------------------------------------------------------------------------------------------
-- Polyphase Clock Synch
-- [Based on "Multirate Digital Filters for Symbol Timing Synchronization in Software Defined Radios"
-- by fred harris and Michael Rice, - IEEE Journal on Selected Areas in Communications, Vol. 19, No 12, Dec 2001.
-- Some implementation details derived from "Interpolation in Digital Modems - Part I: Fundamentals"
-- by Floyd Gardner - IEEE Transaction on Communications, Vol. 41, No 3, March 1993]
--
-- Input: Real valued Oversampled Signed Data
-- Output: Real valued Symbol rate Signed Data
--
-- Parameters
-- BitWidth: Bit size of one element of data.
-- coefBitWidth: Size of filter coefficients.
-- numSubFilters: The number of sub filters used by the synchronizer to perform interpolation of the data.
--                Defaults to 32. Higher values help reduce quantization error, but require matched filters with
--                enough coefficients to be properly split into sub filters. For instance, a 128 coefficient filter will
--                be split into 32 sub filters of four coefficients each.
-- samplesPerSymbol: The number of samples per symbol for the incoming data. Defaults to 4.0, which results in 1 output sample
--                   for every 4 input samples. Synchronizer is designed to only operate properly under the assumption of one 
--                   output sample per symbol. Trying to output many samples per symbol will likely result in significant timing 
--                   error estimations (unless your filter coefficients are really clever). No oversampling is untested.
--                   Quantizes into a register of size <bitWidth>.
-- alpha: Provides phase adjustement and damping in the loop filter. Assumes a fixed point signed fraction from [-1, 1) of size <coefBitWidth>.
--        Defaults to 6784, which is calculated from a damping rate of .707 and a loop bandwidth of pi/50, multiplied into a 
--        fixed point fraction of 18 bits. This will probably work ok for most use cases.
-- beta:  Provides damping in the loop filter. Assumes a fixed point fraction from [-1, 1) of size <coefBitWidth>.
--        Defaults to 601, again calculated from a damping rate of .707 and a loop bandwidth of pi/50. Will work ok for most cases.
-- taps:   The symbol matched filter. In most cases this will likely be a root raised cosine or a gaussian filter. This needs to
--         be designed at the interpolated rate (samplesPerSymbol * numSubFilters). Assumes fixed point fraction coefficients from
--         [-1, 1) of size <coefBitWidth>. These taps need to be scaled by the user to account for gain losses from interpolation. 
--         As in, the taps should be scaled up by a factor of 32 if 32 sub filters are used.
--
-- Behavior
-- This component will attempt to synchronize symbol timing. Input is oversampled baseband data, and output is the maximum likelihood
-- estimate for the symbol at one sample per symbol. Component uses a polyphase filter bank to interpolate incoming data, and a 
-- derivative filter bank to identify timing error. A symbol matched filter MUST be provided or this component will not function properly.
-- The derivative filter bank is generated automatically.
-- Although output is one sample per symbol, the output clock is not constant. Output data can be accelerated when the loop controller estimates
-- that data is oversampled, and output data can be retarded when the loop controller estimates that data has been undersampled. However, valid data
-- samples are always accompanied by a "valid" flag, regardless of timing.
-- Due to the polyphase nature of this component, large filters do not require many resources. For instance, a 128 tap filter with 32 subfilters
-- will only require 4 multipliers for the matched filter, 4 multipliers for the derivative filter, 1 multiplier for the timing error, 
-- and 2 multipliers for the loop filter. Resource utilization is improved with increased number of sub filters.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseClockSynch IS
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
END PolyphaseClockSynch;

ARCHITECTURE Structural OF PolyphaseClockSynch IS
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

    COMPONENT LoopController IS
        GENERIC(
            bitWidth         : POSITIVE;
            samplesPerSymbol : REAL
        );
        PORT(
            clock       : IN  STD_LOGIC;
            reset       : IN  STD_LOGIC;
            enable      : IN  STD_LOGIC;
            dataIn      : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            registerOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            bankEnable  : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT FilterBankIndexComputer IS
        GENERIC(
            bitWidth         : POSITIVE;
            samplesPerSymbol : REAL;
            numFilterBanks   : POSITIVE
        );
        PORT(
            clock    : IN  STD_LOGIC;
            reset    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            indexOut : OUT NATURAL RANGE 0 TO numFilterBanks - 1;
            valid    : OUT STD_LOGIC
        );
    END COMPONENT;

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

    CONSTANT subFilterLength : POSITIVE := INTEGER(ceil(real(taps'length) / real(numSubFilters)));

    CONSTANT matchedCoefBank : COEFFICIENT_BANK(0 TO numSubFilters - 1, 0 TO subFilterLength - 1) := generateCoefBank(
        coefBitWidth => coefBitWidth,
        decimation => numSubFilters,
        filterCoefficients => taps
    );

    CONSTANT diffTaps : INTEGER_ARRAY := getDiffTaps(
        taps => taps
    );

    CONSTANT normalizeDiffTaps : INTEGER_ARRAY := tapsGainMultiply(
        multiplicand => numSubFilters,
        taps         => diffTaps
    );

    CONSTANT diffMatchedCoefBank : COEFFICIENT_BANK(0 TO numSubFilters - 1, 0 TO subFilterLength - 1) := generateCoefBank(
        coefBitWidth => coefBitWidth,
        decimation => numSubFilters,
        filterCoefficients => normalizeDiffTaps
    );

    -- internal signals
    SUBTYPE ROM_BUS IS STD_LOGIC_VECTOR(coefBitWidth - 1 DOWNTO 0);
    SUBTYPE DATA_BUS IS STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SUBTYPE MULT_BUS IS STD_LOGIC_VECTOR(coefBitWidth + bitWidth - 1 DOWNTO 0);

    TYPE ROM_SIG IS ARRAY (0 TO subFilterLength - 1) OF ROM_BUS;
    TYPE MULT_SIG IS ARRAY (0 TO subFilterLength - 1) OF MULT_BUS;
    TYPE DATA_SIG IS ARRAY (0 TO subFilterLength - 1) OF DATA_BUS;
    TYPE ADD_SIG IS ARRAY (1 TO subFilterLength - 1) OF MULT_BUS;

    SIGNAL matchedRomSig                 : ROM_SIG;
    SIGNAL diffMatchedRomSig             : ROM_SIG;
    SIGNAL matchedProdSig                : MULT_SIG;
    SIGNAL diffMatchedProdSig            : MULT_SIG;
    SIGNAL dataSig                       : DATA_SIG;
    SIGNAL romAddress                    : NATURAL RANGE 0 TO numSubfilters - 1;
    SIGNAL intermediateMatchedResult     : ADD_SIG;
    SIGNAL intermediateDiffMatchedResult : ADD_SIG;
    SIGNAL matchedResult                 : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL diffMatchedResult             : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL decimatedClock                : STD_LOGIC;
    SIGNAL timingError                   : STD_LOGIC_VECTOR(2 * bitWidth - 1 DOWNTO 0);
    SIGNAL truncatedTimingError          : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL interpolatedTimingError       : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL filterOut                     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL controllerRegister            : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL validTimingError              : STD_LOGIC;
    SIGNAL validLoopFilter               : STD_LOGIC;

BEGIN
    ASSERT samplesPerSymbol > 1.0 REPORT "input samples per symbol must be greater than 1!";

    dataSig(0) <= dataIn;

    GenerateFilterBanks : FOR J IN 0 TO subFilterLength - 1 GENERATE
    BEGIN
        matchedRomSig(J)     <= STD_LOGIC_VECTOR(to_signed(matchedCoefBank(romAddress, J), coefBitWidth));
        diffMatchedRomSig(J) <= STD_LOGIC_VECTOR(to_signed(diffMatchedCoefBank(romAddress, J), coefBitWidth));

        matchedCoef_j : ClockedMultiply
            GENERIC MAP(
                bitWidthIn1 => bitWidth,
                bitWidthIn2 => coefBitWidth
            )
            PORT MAP(
                reset  => reset,
                clock  => clock,
                enable => enable,
                in1    => dataSig(J),
                in2    => matchedRomSig(J),
                prod   => matchedProdSig(J)
            );

        diffMatchedCoef_j : ClockedMultiply
            GENERIC MAP(
                bitWidthIn1 => bitWidth,
                bitWidthIn2 => coefBitWidth
            )
            PORT MAP(
                reset  => reset,
                clock  => clock,
                enable => enable,
                in1    => dataSig(J),
                in2    => diffMatchedRomSig(J),
                prod   => diffMatchedProdSig(J)
            );

        delays : IF J < subFilterLength - 1 GENERATE
        BEGIN
            del_j : Reg
                GENERIC MAP(
                    bitWidth => bitWidth
                )
                PORT MAP(
                    reset   => reset,
                    clock   => clock,
                    enable  => enable,
                    dataIn  => dataSig(J),
                    dataOut => dataSig(J + 1)
                );
        END GENERATE delays;

        firstAdd : IF J = 1 GENERATE
        BEGIN
            intermediateMatchedResult(J)     <= STD_LOGIC_VECTOR(signed(matchedProdSig(J - 1)) + signed(matchedProdSig(J)));
            intermediateDiffMatchedResult(J) <= STD_LOGIC_VECTOR(signed(diffMatchedProdSig(J - 1)) + signed(diffMatchedProdSig(J)));
        END GENERATE firstAdd;

        remainingAdds : IF J > 1 GENERATE
        BEGIN
            intermediateMatchedResult(J)     <= STD_LOGIC_VECTOR(signed(intermediateMatchedResult(J - 1)) + signed(matchedProdSig(J)));
            intermediateDiffMatchedResult(J) <= STD_LOGIC_VECTOR(signed(intermediateDiffMatchedResult(J - 1)) + signed(diffMatchedProdSig(J)));
        END GENERATE remainingAdds;

    END GENERATE GenerateFilterBanks;

    -- Assuming coefficient taps are fixed point representations of [-1, 1) and accounting for multiplier sign extension
    matchedResult     <= intermediateMatchedResult(subFilterLength - 1)(bitWidth + coefBitWidth - 2 DOWNTO coefBitWidth - 1);
    diffMatchedResult <= intermediateDiffMatchedResult(subFilterLength - 1)(bitWidth + coefBitWidth - 2 DOWNTO coefBitWidth - 1);

    timingErrorEstimator : ClockedMultiply
        GENERIC MAP(
            bitWidthIn1 => bitWidth,
            bitWidthIn2 => bitWidth
        )
        PORT MAP(
            reset  => reset,
            clock  => clock,
            enable => decimatedClock,
            in1    => matchedResult,
            in2    => diffMatchedResult,
            prod   => timingError,
            valid  => validTimingError
        );

    truncatedTimingError    <= timingError(2 * bitWidth - 2 DOWNTO bitWidth - 1);
    interpolatedTimingError <= truncatedTimingError WHEN validTimingError = '1' ELSE (OTHERS => '0');

    filter : LoopFilter
        GENERIC MAP(
            bitWidth     => bitWidth,
            coefBitWidth => coefBitWidth,
            alpha        => alpha,
            beta         => beta
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => interpolatedTimingError,
            dataOut => filterOut,
            valid   => validLoopFilter
        );

    controller : LoopController
        GENERIC MAP(
            bitWidth         => bitWidth,
            samplesPerSymbol => samplesPerSymbol
        )
        PORT MAP(
            clock       => clock,
            reset       => reset,
            enable      => validLoopFilter,
            dataIn      => filterOut,
            registerOut => controllerRegister,
            bankEnable  => decimatedClock
        );

    computer : FilterBankIndexComputer
        GENERIC MAP(
            bitWidth         => bitWidth,
            samplesPerSymbol => samplesPerSymbol,
            numFilterBanks   => numSubFilters
        )
        PORT MAP(
            clock    => clock,
            reset    => reset,
            enable   => decimatedClock,
            dataIn   => controllerRegister,
            indexOut => romAddress
        );

    clockedOutput : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => decimatedClock,
            dataIn  => matchedResult,
            dataOut => dataOut,
            valid   => valid
        );

END Structural;        
