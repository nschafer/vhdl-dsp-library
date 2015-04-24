LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY Decrementer_tb IS
END Decrementer_tb;

ARCHITECTURE behavior OF Decrementer_tb IS
    COMPONENT Decrementer IS
        GENERIC(
            maxCount : NATURAL := DEFAULT_COUNT
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataOut : OUT NATURAL RANGE 0 TO maxCount;
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    CONSTANT maxCount0 : NATURAL := 0;
    CONSTANT maxCount1 : NATURAL := 1;
    CONSTANT maxCount2 : NATURAL := 2;
    CONSTANT maxCount3 : NATURAL := 3;

    SIGNAL clock    : STD_LOGIC := '0';
    SIGNAL reset    : STD_LOGIC := '0';
    SIGNAL enable   : STD_LOGIC := '0';
    SIGNAL valid0   : STD_LOGIC;
    SIGNAL valid1   : STD_LOGIC;
    SIGNAL valid2   : STD_LOGIC;
    SIGNAL valid3   : STD_LOGIC;
    SIGNAL dataOut0 : NATURAL;
    SIGNAL dataOut1 : NATURAL;
    SIGNAL dataOut2 : NATURAL;
    SIGNAL dataOut3 : NATURAL;

    CONSTANT clockPeriod : TIME := 10 ns;

BEGIN
    noCount : Decrementer
        GENERIC MAP(
            maxCount => maxCount0
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataOut => dataOut0,
            valid   => valid0
        );

    count1 : Decrementer
        GENERIC MAP(
            maxCount => maxCount1
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataOut => dataOut1,
            valid   => valid1
        );

    count2 : Decrementer
        GENERIC MAP(
            maxCount => maxCount2
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataOut => dataOut2,
            valid   => valid2
        );

    count3 : Decrementer
        GENERIC MAP(
            maxCount => maxCount3
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataOut => dataOut3,
            valid   => valid3
        );

    clockProcess : PROCESS
    BEGIN
        clock <= '0';
        WAIT FOR clockPeriod / 2;
        clock <= '1';
        WAIT FOR clockPeriod / 2;
    END PROCESS;

    sequenceProcess : PROCESS
        VARIABLE enableCheck : NATURAL := 0;
        VARIABLE tempOut0    : NATURAL := 0;
        VARIABLE tempOut1    : NATURAL := 0;
        VARIABLE tempOut2    : NATURAL := 0;
        VARIABLE tempOut3    : NATURAL := 0;
    BEGIN
        reset <= '1';
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        WAIT FOR 3 ns;
        LOOP
            WAIT FOR clockPeriod;
            IF enable = '1' THEN
                tempOut0 := decrement(tempOut0, maxCount0);
                tempOut1 := decrement(tempOut1, maxCount1);
                tempOut2 := decrement(tempOut2, maxCount2);
                tempOut3 := decrement(tempOut3, maxCount3);
            END IF;
            ASSERT tempOut0 = dataOut0 report "dataOut0 bad";
            ASSERT tempOut1 = dataOut1 report "dataOut1 bad";
            ASSERT tempOut2 = dataOut2 report "dataOut2 bad";
            ASSERT tempOut3 = dataOut3 report "dataOut3 bad";
            IF enableCheck MOD 3 = 0 THEN
                enable <= '0';
            ELSIF enableCheck MOD 4 = 0 THEN
                enable <= '1';
            END IF;
            enableCheck := enableCheck + 1;
        END LOOP;
    END PROCESS;
END;