-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY MovingAverage_tb IS
END MovingAverage_tb;

ARCHITECTURE behavior OF MovingAverage_tb IS
    COMPONENT MovingAverage IS
        GENERIC(
            bitWidth           : POSITIVE;
            sampleAddressSpace : POSITIVE;
            sampleDecimation   : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            inData  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            outData : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT testDataBitWidth     : POSITIVE      := 8;
    CONSTANT testSampleSpace      : POSITIVE      := 3;
    CONSTANT testSampleDecimation : POSITIVE      := 3;
    CONSTANT clockPeriod          : TIME          := 10 ns;
    CONSTANT inputValues          : INTEGER_ARRAY := (
        1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
        11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
        21, 22, 23, 24, 25, 26, 27, 28, 29, 30
    );

    SIGNAL clock  : STD_LOGIC := '0';
    SIGNAL enable : STD_LOGIC := '0';
    SIGNAL reset  : STD_LOGIC := '0';

    SIGNAL inData  : STD_LOGIC_VECTOR(testDataBitWidth - 1 DOWNTO 0);
    SIGNAL outData : STD_LOGIC_VECTOR(testDataBitWidth - 1 DOWNTO 0);
    SIGNAL valid   : STD_LOGIC;

BEGIN
    avg : MovingAverage
        GENERIC MAP(
            bitWidth           => testDataBitWidth,
            sampleAddressSpace => testSampleSpace,
            sampleDecimation   => testSampleDecimation
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            inData  => inData,
            outData => outData,
            valid => valid
        );

    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    averageProcess : PROCESS
    BEGIN
        reset  <= '1';
        inData <= (OTHERS => '0');
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        WAIT FOR 3 ns;
        FOR I IN inputValues'low TO inputValues'high LOOP
            inData <= STD_LOGIC_VECTOR(TO_SIGNED(inputValues(I), testDataBitWidth));
            WAIT FOR clockPeriod;
        END LOOP;
        WAIT;
    END PROCESS;
END;