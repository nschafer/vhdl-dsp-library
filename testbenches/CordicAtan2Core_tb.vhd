-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY CordicAtan2Core_tb IS
END CordicAtan2Core_tb;

ARCHITECTURE behavior OF CordicAtan2Core_tb IS
    COMPONENT CordicAtan2Core IS
        GENERIC(
            bitWidth      : POSITIVE;
            phaseBitWidth : POSITIVE;
            iteration     : NATURAL
        );
        PORT(
            reset    : IN  STD_LOGIC;
            clock    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            realIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            accumIn  : IN  STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            realOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            accumOut : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            valid    : OUT STD_LOGIC
        );
    END COMPONENT CordicAtan2Core;

    CONSTANT testBitWidth      : POSITIVE := 12;
    CONSTANT testPhaseBitWidth : POSITIVE := 12;
    CONSTANT numIterations     : POSITIVE := 10;
    CONSTANT testRealIn        : INTEGER  := 921;
    CONSTANT testImagIn        : INTEGER  := 391;
    CONSTANT clockPeriod       : TIME     := 10 ns;

    SIGNAL clock  : STD_LOGIC := '0';
    SIGNAL reset  : STD_LOGIC := '0';
    SIGNAL enable : STD_LOGIC := '0';

    TYPE dataSig IS ARRAY (0 TO numIterations + 1) OF STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    TYPE phaseSig IS ARRAY (0 TO numIterations + 1) OF STD_LOGIC_VECTOR(testPhaseBitWidth - 1 DOWNTO 0);

    SIGNAL realIn   : dataSig;
    SIGNAL imagIn   : dataSig;
    SIGNAL accumIn  : phaseSig;
    SIGNAL realOut  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL imagOut  : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL accumOut : STD_LOGIC_VECTOR(testPhaseBitWidth - 1 DOWNTO 0);
    SIGNAL valids   : STD_LOGIC_VECTOR(0 TO numIterations + 1);

BEGIN
    valids(0) <= enable;
    generateCordicChain : FOR J IN 0 TO numIterations GENERATE
    BEGIN
        notLast : IF J < numIterations GENERATE
            cordic_j : CordicAtan2Core
                GENERIC MAP(
                    bitWidth      => testBitWidth,
                    phaseBitWidth => testPhaseBitWidth,
                    iteration     => J
                )
                PORT MAP(
                    reset    => reset,
                    clock    => clock,
                    enable   => valids(J),
                    realIn   => realIn(J),
                    imagIn   => imagIn(J),
                    accumIn  => accumIn(J),
                    realOut  => realIn(J + 1),
                    imagOut  => imagIn(J + 1),
                    accumOut => accumIn(J + 1),
                    valid    => valids(J + 1)
                );
        END GENERATE notLast;

        last : IF J = numIterations GENERATE
            lastCordic : CordicAtan2Core
                GENERIC MAP(
                    bitWidth      => testBitWidth,
                    phaseBitWidth => testPhaseBitWidth,
                    iteration     => J
                )
                PORT MAP(
                    reset    => reset,
                    clock    => clock,
                    enable   => valids(J),
                    realIn   => realIn(J),
                    imagIn   => imagIn(J),
                    accumIn  => accumIn(J),
                    realOut  => realOut,
                    imagOut  => imagOut,
                    accumOut => accumOut,
                    valid    => valids(J + 1)
                );
        END GENERATE last;
    END GENERATE generateCordicChain;

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
        reset      <= '0';
        enable     <= '1';
        realIn(0)  <= STD_LOGIC_VECTOR(to_signed(testRealIn, testBitWidth));
        imagIn(0)  <= STD_LOGIC_VECTOR(to_signed(testImagIn, testBitWidth));
        accumIn(0) <= (OTHERS => '0');
        WAIT;
    END PROCESS;
END;