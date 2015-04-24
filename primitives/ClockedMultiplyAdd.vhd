LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY ClockedMultiplyAdd IS
    GENERIC(
        bitWidthMult1 : POSITIVE := DEFAULT_BITWIDTH;
        bitWidthMult2 : POSITIVE := DEFAULT_BITWIDTH;
        bitWidthAdd   : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        multIn1 : IN  STD_LOGIC_VECTOR(bitWidthMult1 - 1 DOWNTO 0);
        multIn2 : IN  STD_LOGIC_VECTOR(bitWidthMult2 - 1 DOWNTO 0);
        addIn   : IN  STD_LOGIC_VECTOR(bitWidthAdd - 1 DOWNTO 0);
        prodSum : OUT STD_LOGIC_VECTOR(bitWidthMult1 + bitWidthMult2 - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END ClockedMultiplyAdd;

ARCHITECTURE Behavioral OF ClockedMultiplyAdd IS
    SIGNAL multIn1Sig : STD_LOGIC_VECTOR(bitWidthMult1 - 1 DOWNTO 0);
    SIGNAL multIn2Sig : STD_LOGIC_VECTOR(bitWidthMult2 - 1 DOWNTO 0);
    SIGNAL addInSig   : STD_LOGIC_VECTOR(bitWidthAdd - 1 DOWNTO 0);
    SIGNAL output     : STD_LOGIC_VECTOR(bitWIdthMult1 + bitWidthMult2 - 1 DOWNTO 0);
    SIGNAL validBit   : STD_LOGIC;
BEGIN
    multIn1Sig <= multIn1;
    multIn2Sig <= multIn2;
    addInSig   <= addIn;
    prodSum    <= output;
    valid      <= validBit;

    mult : PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                output   <= (OTHERS => '0');
                validBit <= '0';
            ELSIF enable = '1' THEN
                output   <= STD_LOGIC_VECTOR((signed(multIn1Sig) * signed(multIn2Sig)) + signed(addInSig));
                validBit <= '1';
            ELSE
                validBit <= '0';
            END IF;
        END IF;
    END PROCESS mult;
END Behavioral;

    