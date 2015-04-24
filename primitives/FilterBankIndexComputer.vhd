LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY FilterBankIndexComputer IS
    GENERIC(
        bitWidth         : POSITIVE := DEFAULT_BITWIDTH;
        samplesPerSymbol : REAL     := DEFAULT_SPS;
        numFilterBanks   : POSITIVE := DEFAULT_NUM_FILTERS
    );
    PORT(
        clock    : IN  STD_LOGIC;
        reset    : IN  STD_LOGIC;
        enable   : IN  STD_LOGIC;
        dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        indexOut : OUT NATURAL RANGE 0 TO numFilterBanks - 1;
        valid    : OUT STD_LOGIC
    );
END FilterBankIndexComputer;

ARCHITECTURE Behavioral OF FilterBankIndexComputer IS
BEGIN
    PROCESS(clock)
        CONSTANT midPoint : NATURAL := NATURAL(floor(real(numFilterBanks) / 2.0));
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                indexOut <= midPoint;
                valid    <= '0';
            ELSIF enable = '1' THEN
                indexOut <= getFilterIndex(
                        bitWidth    => bitWidth,
                        sps         => samplesPerSymbol,
                        filters     => numFilterBanks,
                        registerVal => dataIn
                    );
                valid <= '1';
            ELSE
                valid <= '0';
            END IF;
        END IF;
    END PROCESS;
END Behavioral;
    