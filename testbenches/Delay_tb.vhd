LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY Delay_tb IS
END Delay_tb;

ARCHITECTURE behavior OF Delay_tb IS
    COMPONENT Delay IS
        GENERIC(
            delayLength : NATURAL;
            bitWidth    : POSITIVE
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT;

    SIGNAL clock    : STD_LOGIC                    := '0';
    SIGNAL reset    : STD_LOGIC                    := '0';
    SIGNAL enable   : STD_LOGIC                    := '0';
    SIGNAL dataIn   : STD_LOGIC_VECTOR(0 DOWNTO 0) := (OTHERS => '0');
    SIGNAL valid0   : STD_LOGIC;
    SIGNAL valid1   : STD_LOGIC;
    SIGNAL valid5   : STD_LOGIC;
    SIGNAL dataOut0 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    SIGNAL dataOut1 : STD_LOGIC_VECTOR(0 DOWNTO 0);
    SIGNAL dataOut5 : STD_LOGIC_VECTOR(0 DOWNTO 0);

    CONSTANT clockPeriod : TIME := 10 ns;

    CONSTANT inputValues : STD_LOGIC_VECTOR := B"1011100111001101010101";

BEGIN
    noDelay : delay
        GENERIC MAP(
            delayLength => 0,
            bitwidth    => 1
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut0,
            valid   => valid0
        );

    delayOne : delay
        GENERIC MAP(
            delayLength => 1,
            bitwidth    => 1
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut1,
            valid   => valid1
        );

    delayFive : delay
        GENERIC MAP(
            delayLength => 5,
            bitwidth    => 1
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut5,
            valid   => valid5
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
        dataIn <= B"0";
        WAIT FOR 2 * clockPeriod;
        reset  <= '0';
        enable <= '1';
        WAIT FOR 3 ns;
        FOR I IN inputValues'low TO inputValues'high LOOP
            dataIn(0) <= inputValues(I);
            WAIT FOR clockPeriod;
            ASSERT dataOut0(0) = inputValues(I);
            IF I >= 1 THEN
                ASSERT dataOut1(0) = inputValues(I - 1);
            END IF;
            IF I >= 5 THEN
                ASSERT dataOut5(0) = inputValues(I - 5);
            END IF;
        END LOOP;
        FOR I IN inputValues'low TO inputValues'high LOOP
            dataIn(0) <= inputValues(I);
            WAIT FOR clockPeriod;
            IF (I MOD 3 = 0) THEN
                enable <= '0';
            ELSE
                enable <= '1';
            END IF;
        END LOOP;
        WAIT;
    END PROCESS;
END;