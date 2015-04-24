LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BinarySlicer_tb IS
END BinarySlicer_tb;

ARCHITECTURE behavior OF BinarySlicer_tb IS
    COMPONENT binary_slicer IS
        GENERIC(
            bitWidthIn  : POSITIVE;
            bitWidthOut : POSITIVE
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT bitWidthIn  : POSITIVE := 12;
    CONSTANT bitWidthOut : POSITIVE := 8;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL valid   : STD_LOGIC;
    SIGNAL outData : STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
    SIGNAL inData  : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);

    CONSTANT clockPeriod : TIME := 10 ns;

    CONSTANT inputValues : INTEGER_ARRAY := (
        120, 130, 800, 90, -150, -1, -90, -1000, 56, 98, -12, -1203, 99, 23, -23, 15
    );

BEGIN
    slicer : BinarySlicer
        GENERIC MAP(
            bitWidthIn  => bitWidthIn,
            bitWidthOut => bitWidthOut
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => inData,
            dataOut => outData,
            valid   => valid
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
        reset  <= '1';
        inData <= (OTHERS => '0');
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        WAIT FOR 3 ns;
        FOR I IN inputValues'low TO inputValues'high LOOP
            inData <= STD_LOGIC_VECTOR(to_signed(inputValues(I), bitWidthIn));
            WAIT FOR clockPeriod;
            IF inputValues(I) > 0 THEN
                ASSERT UNSIGNED(outData) = to_unsigned(1, bitWidthOut);
            ELSE
                ASSERT UNSIGNED(outData) = to_unsigned(0, bitWidthOut);
            END IF;
        END LOOP;
        WAIT;
    END PROCESS;
END;