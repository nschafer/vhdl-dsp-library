-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY CordicAtan2Pipelined_tb IS
END CordicAtan2Pipelined_tb;

ARCHITECTURE behavior OF CordicAtan2Pipelined_tb IS
    COMPONENT CordicAtan2Pipelined IS
        GENERIC(
            bitWidth      : POSITIVE;
            phaseBitWidth : POSITIVE;
            numIterations : NATURAL
        );
        PORT(
            reset        : IN  STD_LOGIC;
            clock        : IN  STD_LOGIC;
            enable       : IN  STD_LOGIC;
            realIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            magnitudeOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            phaseOut     : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            valid        : OUT STD_LOGIC
        );
    END COMPONENT CordicAtan2Pipelined;

    CONSTANT testBitWidth      : POSITIVE := 12;
    CONSTANT testPhaseBitWidth : POSITIVE := 16;
    CONSTANT testNumIterations : POSITIVE := 10;
    CONSTANT testRealInInt     : INTEGER  := 921;
    CONSTANT testImagInInt     : INTEGER  := -391;
    CONSTANT clockPeriod       : TIME     := 10 ns;

    SIGNAL clock  : STD_LOGIC := '0';
    SIGNAL reset  : STD_LOGIC := '0';
    SIGNAL enable : STD_LOGIC := '0';

    SIGNAL testRealIn : STD_LOGIC_VECTOR(testbitWidth - 1 DOWNTO 0);
    SIGNAL testImagIn : STD_LOGIC_VECTOR(testbitWidth - 1 DOWNTO 0);
    SIGNAL magOut     : STD_LOGIC_VECTOR(testBitWidth - 1 DOWNTO 0);
    SIGNAL phaseOut   : STD_LOGIC_VECTOR(testPhaseBitWidth - 1 DOWNTO 0);
    SIGNAL validOut   : STD_LOGIC;

BEGIN
    pipeline1 : CordicAtan2Pipelined
        GENERIC MAP(
            bitWidth      => testBitWidth,
            phaseBitWidth => testPhaseBitWidth,
            numIterations => testNumIterations
        )
        PORT MAP(
            reset        => reset,
            clock        => clock,
            enable       => enable,
            realIn       => testRealIn,
            imagIn       => testImagIn,
            magnitudeOut => magOut,
            phaseOut     => phaseOut,
            valid        => validOut
        );

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
        testRealIn <= STD_LOGIC_VECTOR(to_signed(testRealInInt, testBitWidth));
        testImagIn <= STD_LOGIC_VECTOR(to_signed(testImagInInt, testBitWidth));
        WAIT FOR clockPeriod;
        testRealIn <= STD_LOGIC_VECTOR(to_signed(testImagInInt, testBitWidth));
        testImagIn <= STD_LOGIC_VECTOR(to_signed(testRealInInt, testBitWidth));
        WAIT FOR clockPeriod;
        testRealIn <= STD_LOGIC_VECTOR(to_signed(testRealInInt, testBitWidth));
        testImagIn <= STD_LOGIC_VECTOR(to_signed(testImagInInt, testBitWidth));
        WAIT;
    END PROCESS;
END;