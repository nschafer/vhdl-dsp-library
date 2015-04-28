-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY LoopController_tb IS
END LoopController_tb;

ARCHITECTURE behavior OF LoopController_tb IS
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

    CONSTANT testBitWidthIn : POSITIVE      := 16;
    CONSTANT testSps        : REAL      := 4.0;
    CONSTANT testInput      : INTEGER_ARRAY := (
        1, 2, 3, 4, 5, 6
    );

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock      : STD_LOGIC := '0';
    SIGNAL reset      : STD_LOGIC := '0';
    SIGNAL enable     : STD_LOGIC := '0';
    SIGNAL dataIn     : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL dataOut    : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL bankEnable : STD_LOGIC;

BEGIN
    controller : LoopController
        GENERIC MAP(
            bitWidth         => testBitWidthIn,
            samplesPerSymbol => testSps
        )
        PORT MAP(
            clock       => clock,
            reset       => reset,
            enable      => enable,
            dataIn      => dataIn,
            registerOut => dataOut,
            bankEnable  => bankEnable
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
        reset  <= '0';
        enable <= '1';
        FOR index IN testInput'low TO testInput'high LOOP
            dataIn <= STD_LOGIC_VECTOR(to_signed(testInput(index), testBitWidthIn));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;