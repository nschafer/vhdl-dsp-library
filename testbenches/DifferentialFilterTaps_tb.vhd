-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY DifferentialFilterTaps IS
END DifferentialFilterTaps;

ARCHITECTURE behavior OF DifferentialFilterTaps IS
    CONSTANT testTaps : INTEGER_ARRAY := (
        1200, 1177, 1109, 998, 849, 667, 459, 234, 0, -234, -459, -667, -849, -998, -1109, -1177, 
        -1200, -1177, -1109, -998, -849, -667, -459, -234, 0, 234, 459, 667, 849, 998, 1109, 1177
    );
    
    CONSTANT numFilterBanks : POSITIVE := 8;
    
    CONSTANT subFilterLength       : POSITIVE := INTEGER(ceil(real(testTaps'length) / real(numFilterBanks)));
    
    CONSTANT coefBank : COEFFICIENT_BANK(0 TO numFilterBanks - 1, 0 TO subFilterLength - 1) := generateCoefBank(
        coefBitWidth => 18,
        decimation => numFilterBanks,
        filterCoefficients => testTaps
    );

    CONSTANT testDiffTaps : INTEGER_ARRAY := getDiffTaps(testTaps);
    
    CONSTANT diffCoefBank : COEFFICIENT_BANK(0 TO numFilterBanks - 1, 0 TO subFilterLength - 1) := generateCoefBank(
        coefBitWidth => 18,
        decimation => numFilterBanks,
        filterCoefficients => testDiffTaps
    );

    SIGNAL clock : STD_LOGIC := '0';

    SIGNAL signalTaps     : INTEGER;
    SIGNAL signalDiffTaps : INTEGER;

    CONSTANT clockPeriod : TIME := 10 ns;

BEGIN
    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    loadProcess : PROCESS
        VARIABLE count : INTEGER := 0;
    BEGIN
        WAIT FOR clockPeriod;
        signalTaps     <= testTaps(count MOD testTaps'length);
        signalDiffTaps <= testDiffTaps(count MOD testTaps'length);
        count          := count + 1;
    END PROCESS;

END;