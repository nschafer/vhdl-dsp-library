LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY PolyphaseClockSynch IS
    GENERIC(
        numTaps          : POSITIVE      := DEFAULT_NUM_TAPS;
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

    CONSTANT subFilterLength : POSITIVE := INTEGER(ceil(real(NumTaps) / real(numSubFilters)));

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
