LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY FilterBankIndexComputer_tb IS
END FilterBankIndexComputer_tb;

ARCHITECTURE behavior OF FilterBankIndexComputer_tb IS
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

    CONSTANT testBitWidthIn     : POSITIVE := 16;
    CONSTANT testSps            : REAL     := 4.0;
    CONSTANT testNumFilterBanks : POSITIVE := 16;

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock    : STD_LOGIC := '0';
    SIGNAL reset    : STD_LOGIC := '0';
    SIGNAL enable   : STD_LOGIC := '0';
    SIGNAL dataIn   : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL indexOut : NATURAL RANGE 0 TO testNumFilterBanks - 1;
    SIGNAL valid    : STD_LOGIC;

BEGIN
    computer : FilterBankIndexComputer
        GENERIC MAP(
            bitWidth         => testBitWidthIn,
            samplesPerSymbol => testSps,
            numFilterBanks   => testNumFilterBanks
        )
        PORT MAP(
            clock    => clock,
            reset    => reset,
            enable   => enable,
            dataIn   => dataIn,
            indexOut => indexOut,
            valid    => valid
        );

    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    sequenceProcess : PROCESS
        VARIABLE count : NATURAL RANGE 0 TO 2 ** (testBitWidthIn) - 1 := 0;
    BEGIN
        reset <= '1';
        WAIT FOR 2 * clockPeriod;
        WAIT FOR 2 ns;
        reset  <= '0';
        enable <= '1';
        FOR index IN 0 TO 3000 LOOP
            dataIn <= STD_LOGIC_VECTOR(to_signed(count, testBitWidthIn));
            WAIT FOR clockPeriod;
            count := count + 100;
        END LOOP;
        WAIT;
    END PROCESS;
END;