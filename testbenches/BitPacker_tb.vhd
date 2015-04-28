-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY bit_packer_tb IS
END bit_packer_tb;

ARCHITECTURE behavior OF bit_packer_tb IS
    COMPONENT bit_packer IS
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

    CONSTANT bitWidthIn  : POSITIVE := 1;
    CONSTANT bitWidthOut : POSITIVE := 8;

    SIGNAL clock   : STD_LOGIC := '0';
    SIGNAL reset   : STD_LOGIC := '0';
    SIGNAL enable  : STD_LOGIC := '0';
    SIGNAL valid   : STD_LOGIC;
    SIGNAL outData : STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
    SIGNAL inData  : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);

    CONSTANT clockPeriod : TIME := 10 ns;

    CONSTANT inputValues : INTEGER_ARRAY := (
        0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 1, 0
    );

BEGIN
    packer : bit_packer
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
        VARIABLE packedNumber : INTEGER;
    BEGIN
        reset  <= '1';
        inData <= (OTHERS => '0');
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        WAIT FOR 3 ns;
        FOR I IN inputValues'low TO inputValues'high LOOP
            inData <= STD_LOGIC_VECTOR(to_unsigned(inputValues(I), bitWidthIn));
            WAIT FOR clockPeriod;
            IF valid = '1' THEN
                packedNumber := 0;
                FOR J IN 0 TO bitWidthOut - 1 LOOP
                    IF inputValues(I - J) = 1 THEN
                        packedNumber := packedNumber + 2 ** (J);
                    END IF;
                END LOOP;
                ASSERT to_integer(UNSIGNED(outData)) = packedNumber;
            END IF;
        END LOOP;
        WAIT;
    END PROCESS;
END;