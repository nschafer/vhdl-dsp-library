LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY CordicAtan2Pipelined IS
    GENERIC(
        bitWidth      : POSITIVE := DEFAULT_BITWIDTH;
        phaseBitWidth : POSITIVE := DEFAULT_BITWIDTH;
        numIterations : NATURAL  := DEFAULT_CORDIC_ROTATIONS
    );
    PORT(
        reset        : IN  STD_LOGIC;
        clock        : IN  STD_LOGIC;
        enable       : IN  STD_LOGIC;
        realIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        imagIn       : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        magnitudeOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        phaseOut     : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
        valid        : OUT STD_LOGIC
    );
END CordicAtan2Pipelined;

ARCHITECTURE Structural OF CordicAtan2Pipelined IS
    COMPONENT CordicAtan2Core IS
        GENERIC(
            bitWidth      : POSITIVE;
            phaseBitWidth : POSITIVE;
            iteration     : NATURAL
        );
        PORT(
            reset    : IN  STD_LOGIC;
            clock    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            realIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            accumIn  : IN  STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            realOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            accumOut : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
            valid    : OUT STD_LOGIC
        );
    END COMPONENT CordicAtan2Core;

    CONSTANT busSize : POSITIVE := numIterations + 1;

    TYPE DATA_SIG IS ARRAY (0 TO busSize) OF STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    TYPE PHASE_SIG IS ARRAY (0 TO busSize) OF STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);

    SIGNAL internalRealIn : DATA_SIG;
    SIGNAL internalImagIn : DATA_SIG;
    SIGNAL accumIn        : PHASE_SIG;
    SIGNAL enableLines    : STD_LOGIC_VECTOR(0 TO busSize);

BEGIN
    internalRealIn(0) <= realIn;
    internalImagIn(0) <= imagIn;
    accumIn(0)        <= (OTHERS => '0');
    enableLines(0)    <= enable;

    magnitudeOut <= internalRealIn(busSize);
    phaseOut     <= accumIn(busSize);
    valid        <= enableLines(busSize);

    cordicPipeline : FOR J IN 0 TO numIterations GENERATE
    BEGIN
        enables : IF (J > 0) GENERATE
        BEGIN
        END GENERATE;

        cordic_j : CordicAtan2Core
            GENERIC MAP(
                bitWidth      => bitWidth,
                phaseBitWidth => phaseBitWidth,
                iteration     => J
            )
            PORT MAP(
                reset    => reset,
                clock    => clock,
                enable   => enableLines(J),
                realIn   => internalRealIn(J),
                imagIn   => internalImagIn(J),
                accumIn  => accumIn(J),
                realOut  => internalRealIn(J + 1),
                imagOut  => internalImagIn(J + 1),
                accumOut => accumIn(J + 1),
                valid    => enableLines(J + 1)
            );

    END GENERATE cordicPipeline;

END Structural;