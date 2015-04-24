
PACKAGE BODY DSP IS
    FUNCTION max(L, R : INTEGER) RETURN INTEGER IS
        VARIABLE result : INTEGER := L;
    BEGIN
        IF R > result THEN
            result := R;
        END IF;
        return result;
    END max;

    FUNCTION inRange(
        bitWidth : POSITIVE;
        input    : INTEGER
        ) RETURN BOOLEAN IS
    BEGIN
        RETURN (input >= -2 ** (BitWidth - 1)) AND (input <= (2 ** (BitWidth - 1) - 1));
    END inRange;

    FUNCTION decrement(
        input, max : NATURAL
        ) RETURN NATURAL IS
        VARIABLE result : NATURAL := input;
    BEGIN
        IF result > 0 THEN
            result := result - 1;
        ELSE
            result := max;
        END IF;
        RETURN result;
    END decrement;

    FUNCTION generateCoefBank(
        coefBitWidth, decimation : POSITIVE;
        filterCoefficients       : INTEGER_ARRAY
        ) RETURN COEFFICIENT_BANK IS
        CONSTANT subFilterLength : POSITIVE := INTEGER(ceil(real(filterCoefficients'length) / real(decimation)));
        VARIABLE result          : COEFFICIENT_BANK(0 TO decimation - 1, 0 TO subFilterLength - 1);
    BEGIN
        FOR assertIndex IN filterCoefficients'low TO filterCoefficients'high LOOP
            ASSERT inRange(bitWidth => coefBitWidth, input => filterCoefficients(assertIndex)) REPORT "Filter coefficients out of bounds";
        END LOOP;
        FOR coefIndex IN 0 TO subFilterLength - 1 LOOP
            FOR bankIndex IN 0 TO decimation - 1 LOOP
                IF (bankIndex + decimation * coefIndex) < filterCoefficients'length THEN
                    result(bankIndex, coefIndex) := filterCoefficients(bankIndex + decimation * coefIndex);
                ELSE
                    result(bankIndex, coefIndex) := 0;
                END IF;
            END LOOP;
        END LOOP;
        RETURN result;
    END generateCoefBank;

    FUNCTION getRealTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY IS
        CONSTANT realTapsLength : POSITIVE := taps'length / 2;
        VARIABLE result         : INTEGER_ARRAY(0 TO realTapsLength - 1);
    BEGIN
        ASSERT taps'length MOD 2 = 0 REPORT "Number of taps must be even: expect interleaved real and imaginary taps";
        FOR index IN taps'low TO taps'high LOOP
            IF index MOD 2 = 0 THEN
                result(index / 2) := taps(index);
            END IF;
        END LOOP;
        RETURN result;
    END getRealTaps;

    FUNCTION getImagTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY IS
        CONSTANT imagTapsLength : POSITIVE := taps'length / 2;
        VARIABLE result         : INTEGER_ARRAY(0 TO imagTapsLength - 1);
    BEGIN
        ASSERT taps'length MOD 2 = 0 REPORT "Number of taps must be even: expect interleaved real and imaginary taps";
        FOR index IN taps'low TO taps'high LOOP
            IF index MOD 2 = 1 THEN
                result((index - 1) / 2) := taps(index);
            END IF;
        END LOOP;
        RETURN result;
    END getImagTaps;

    FUNCTION getPhaseChange(
        iteration : NATURAL;
        bitWidth  : POSITIVE
        ) RETURN STD_LOGIC_VECTOR IS
        VARIABLE phase           : REAL;
        VARIABLE normalizedPhase : NATURAL;
        VARIABLE result          : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    BEGIN
        IF iteration = 0 THEN
            phase := MATH_PI_OVER_2;
        ELSE
            phase := arctan(REAL(1.0 / (2.0 ** REAL(iteration - 1))));
        END IF;
        normalizedPhase := INTEGER(round((phase / MATH_PI_OVER_2) * REAL((2 ** (bitWidth - 2)))));
        result          := STD_LOGIC_VECTOR(to_signed(normalizedPhase, bitWidth));
        RETURN result;
    END getPhaseChange;

    FUNCTION getUnderflowConst(
        bitWidth : POSITIVE;
        sps      : REAL
        ) RETURN STD_LOGIC_VECTOR IS
        VARIABLE result           : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        CONSTANT maxNumber        : REAL := (2 ** REAL(bitWidth)) - 1.0;
        CONSTANT fractionalNumber : REAL := round(maxNumber / sps);
    BEGIN
        result := STD_LOGIC_VECTOR(to_unsigned(INTEGER(fractionalNumber), bitWidth));
        RETURN result;
    END getUnderflowConst;

    FUNCTION getFilterIndex(
        bitWidth, filters : POSITIVE;
        sps               : REAL;
        registerVal       : STD_LOGIC_VECTOR
        ) RETURN NATURAL IS
        CONSTANT maxValue : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0) := getUnderflowConst(
            bitWidth => bitWidth,
            sps => sps
        );
        CONSTANT quantizedValue : NATURAL := to_integer(unsigned(maxValue)) / filters;
        CONSTANT registerInt    : NATURAL := to_integer(unsigned(registerVal));
        VARIABLE result         : NATURAL RANGE 0 TO filters - 1;
    BEGIN
        FOR index IN 1 TO filters LOOP
            IF registerInt < index * quantizedValue THEN
                result := index - 1;
                EXIT;
            END IF;
            result := filters - 1;
        END LOOP;
        RETURN result;
    END getFilterIndex;

    FUNCTION realToInteger(
        bitWidth  : POSITIVE;
        realArray : REAL_ARRAY
        ) RETURN INTEGER_ARRAY IS
        VARIABLE result          : INTEGER_ARRAY(realArray'range);
        VARIABLE convertedNumber : REAL;
    BEGIN
        FOR index IN result'low TO result'high LOOP
            convertedNumber := (realArray(index)) * (2.0 ** (real(bitWidth - 1)));
            result(index)   := INTEGER(round(convertedNumber));
        END LOOP;
        RETURN result;
    END realToInteger;

    FUNCTION tapsGainMultiply(
        multiplicand : POSITIVE;
        taps         : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY IS
        VARIABLE result : INTEGER_ARRAY(taps'range);
    BEGIN
        FOR index IN result'low TO result'high LOOP
            result(index) := taps(index) * multiplicand;
        END LOOP;
        RETURN result;
    END tapsGainMultiply;

    FUNCTION getDiffTaps(
        taps : INTEGER_ARRAY
        ) RETURN INTEGER_ARRAY IS
        VARIABLE result : INTEGER_ARRAY(taps'range);
    BEGIN
        -- corner cases
        result(0)               := taps(1) - taps(taps'length - 1);
        result(taps'length - 1) := taps(0) - taps(taps'length - 2);

        FOR index IN 1 TO taps'length - 2 LOOP
            result(index) := taps(index + 1) - taps(index - 1);
        END LOOP;
        RETURN result;
    END getDiffTaps;

    FUNCTION getDiffCoefBank(
        numSubFilters, subFilterLength : POSITIVE;
        matchedCoefBank                : COEFFICIENT_BANK
        ) RETURN COEFFICIENT_BANK IS
        VARIABLE result : COEFFICIENT_BANK(0 TO numSubFilters - 1, 0 TO subFilterLength - 1);
    BEGIN
        FOR tap IN 0 TO subFilterLength - 1 LOOP
            result(0, tap)                 := matchedCoefBank(1, tap) - matchedCoefBank(numSubFilters - 1, tap);
            result(numSubFilters - 1, tap) := matchedCoefBank(0, tap) - matchedCoefBank(numSubFilters - 2, tap);
        END LOOP;
        FOR subFilter IN 1 TO numSubFilters - 2 LOOP
            FOR tap IN 0 TO subFilterLength - 1 LOOP
                result(subFilter, tap) := matchedCoefBank(subFilter + 1, tap) - matchedCoefBank(subFilter - 1, tap);
            END LOOP;
        END LOOP;
        RETURN result;
    END getDiffCoefBank;

END PACKAGE BODY DSP;
