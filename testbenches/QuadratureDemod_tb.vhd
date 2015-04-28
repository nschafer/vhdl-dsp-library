-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY QuadratureDemod_tb IS
END QuadratureDemod_tb;

ARCHITECTURE behavior OF QuadratureDemod_tb IS
    COMPONENT QuadratureDemod IS
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
            demodOut     : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            valid        : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT testBitWidthIn    : POSITIVE      := 16;
    CONSTANT testPhaseBitWidth : POSITIVE      := 16;
    CONSTANT testInphase       : INTEGER_ARRAY := (

    );
    CONSTANT testQuadrature : INTEGER_ARRAY := (

    );
    CONSTANT testNumIterations : POSITIVE := 12;

    CONSTANT clockPeriod : TIME := 10 ns;

    SIGNAL clock     : STD_LOGIC := '0';
    SIGNAL reset     : STD_LOGIC := '0';
    SIGNAL enable    : STD_LOGIC := '0';
    SIGNAL valid     : STD_LOGIC := '0';
    SIGNAL realIn    : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL quadIn  : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL magOut  : STD_LOGIC_VECTOR(testBitWidthIn - 1 DOWNTO 0);
    SIGNAL demodOut  : STD_LOGIC_VECTOR(testPhaseBitWidth - 1 DOWNTO 0);

BEGIN
    quad : QuadratureDemod
        GENERIC MAP(
            bitWidth   => testBitWidthIn,
            phaseBitWidth  => testPhaseBitWidth,
            numIterations         => testNumIterations
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => valid,
            realIn  => realIn,
            imagIn => quadIn,
            magnitudeOut => magOut,
            demodOut => demodOut
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
        FOR index IN testInphase'low TO testInphase'high LOOP
            realIn <= STD_LOGIC_VECTOR(to_signed(testInphase(index), testBitWidthIn));
            quadIn <= STD_LOGIC_VECTOR(to_signed(testQuadrature(index), testBitWidthIn));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;