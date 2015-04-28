-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY DecimatingAccumulator_tb IS
END DecimatingAccumulator_tb;

ARCHITECTURE behavior OF DecimatingAccumulator_tb IS
    COMPONENT DecimatingAccumulator IS
        GENERIC(
            decimation  : POSITIVE;
            bitWidthIn  : POSITIVE;
            bitWidthOut : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clock    : STD_LOGIC := '0';
    SIGNAL reset    : STD_LOGIC := '0';
    SIGNAL enable   : STD_LOGIC := '0';
    SIGNAL valid1   : STD_LOGIC;
    SIGNAL valid2   : STD_LOGIC;
    SIGNAL valid3   : STD_LOGIC;
    SIGNAL valid4   : STD_LOGIC;
    SIGNAL dataOut1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL dataOut2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL dataOut3 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL dataOut4 : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL accIn    : STD_LOGIC_VECTOR(3 DOWNTO 0);

    CONSTANT clockPeriod : TIME := 10 ns;

BEGIN
    noDec : DecimatingAccumulator
        GENERIC MAP(
            decimation  => 1,
            bitWidthIn  => 4,
            bitWidthOut => 4
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => accIn,
            dataOut => dataOut1,
            valid   => valid1
        );

    dec2 : DecimatingAccumulator
        GENERIC MAP(
            decimation  => 2,
            bitWidthIn  => 4,
            bitWidthOut => 4
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => accIn,
            dataOut => dataOut2,
            valid   => valid2
        );

    dec3 : DecimatingAccumulator
        GENERIC MAP(
            decimation  => 3,
            bitWidthIn  => 4,
            bitWidthOut => 4
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => accIn,
            dataOut => dataOut3,
            valid   => valid3
        );

    dec4 : DecimatingAccumulator
        GENERIC MAP(
            decimation  => 4,
            bitWidthIn  => 4,
            bitWidthOut => 4
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => accIn,
            dataOut => dataOut4,
            valid   => valid4
        );

    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    sequenceProcess : PROCESS
        VARIABLE count    : NATURAL                      := 0;
        VARIABLE tempOut2 : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
        VARIABLE tempOut3 : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
        VARIABLE tempOut4 : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
    BEGIN
        reset <= '1';
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        accIn  <= X"3";
        LOOP
            count := count + 1;
            WAIT FOR clockPeriod;
            tempOut2 := STD_LOGIC_VECTOR(signed(tempOut2) + signed(accIn));
            tempOut3 := STD_LOGIC_VECTOR(signed(tempOut3) + signed(accIn));
            tempOut4 := STD_LOGIC_VECTOR(signed(tempOut4) + signed(accIn));
            ASSERT dataOut1 = accIn;
            ASSERT dataOut2 = tempOut2;
            ASSERT dataOut3 = tempOut3;
            ASSERT dataOut4 = tempOut4;
            IF count MOD 2 = 0 THEN
                tempOut2 := X"0";
            END IF;
            IF count MOD 3 = 0 THEN
                tempOut3 := X"0";
            END IF;
            IF count MOD 4 = 0 THEN
                tempOut4 := X"0";
            END IF;
        END LOOP;
    END PROCESS;
END;