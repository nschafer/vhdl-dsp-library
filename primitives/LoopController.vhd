LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY LoopController IS
    GENERIC(
        bitWidth         : POSITIVE := DEFAULT_BITWIDTH;
        samplesPerSymbol : REAL     := DEFAULT_SPS
    );
    PORT(
        clock       : IN  STD_LOGIC;
        reset       : IN  STD_LOGIC;
        enable      : IN  STD_LOGIC;
        dataIn      : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        registerOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        bankEnable  : OUT STD_LOGIC
    );
END LoopController;

ARCHITECTURE Structural OF LoopController IS
    COMPONENT Reg IS
        GENERIC(
            bitWidth : POSITIVE := DEFAULT_BITWIDTH
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

    CONSTANT underflowConst : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0) := getUnderflowConst(
        bitWidth => bitWidth,
        sps => samplesPerSymbol
    );

    SIGNAL registerValue : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL sum           : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
BEGIN
    sum <= STD_LOGIC_VECTOR(signed(registerValue) + signed(dataIn) - signed(underflowConst));

    del : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => sum,
            dataOut => registerValue,
            valid   => OPEN
        );

    enableProcess : PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                bankEnable <= '0';
            ELSIF enable = '1' THEN
                IF unsigned(sum) > unsigned(registerValue) THEN
                    bankEnable  <= '1';
                    registerOut <= registerValue;
                ELSE
                    bankEnable <= '0';
                END IF;
            ELSE
                bankEnable <= '0';
            END IF;
        END IF;
    END PROCESS;
END Structural;
    