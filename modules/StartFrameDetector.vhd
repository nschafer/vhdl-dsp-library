LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY StartFrameDetector IS
    GENERIC(
        sequenceLength : POSITIVE      := DEFAULT_SEQUENCE_LENGTH;
        bitWidth       : POSITIVE      := DEFAULT_BITWIDTH;
        packetSize     : POSITIVE      := DEFAULT_PACKET_SIZE;
        searchSequence : INTEGER_ARRAY := DEFAULT_SEQUENCE
    );
    PORT(
        reset    : IN  STD_LOGIC;
        clock    : IN  STD_LOGIC;
        enable   : IN  STD_LOGIC;
        dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        validOut : OUT STD_LOGIC;
        dataOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
    );
END StartFrameDetector;

ARCHITECTURE structural OF StartFrameDetector IS
    COMPONENT SequenceDetector IS
        GENERIC(
            sequenceLength : POSITIVE;
            bitWidth       : POSITIVE;
            sequence       : INTEGER_ARRAY
        );
        PORT(
            reset    : IN  STD_LOGIC;
            clock    : IN  STD_LOGIC;
            enable   : IN  STD_LOGIC;
            dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            detected : OUT STD_LOGIC
        );
    END COMPONENT;

    COMPONENT Delay IS
        GENERIC(
            delayLength : INTEGER;
            bitWidth    : INTEGER
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL detected : STD_LOGIC;
    SIGNAL counter  : NATURAL RANGE 0 TO packetSize;

BEGIN
    seq_det : SequenceDetector
        GENERIC MAP(
            sequenceLength => sequenceLength,
            bitWidth       => bitWidth,
            sequence       => searchSequence
        )
        PORT MAP(
            reset    => reset,
            clock    => clock,
            enable   => enable,
            dataIn   => dataIn,
            detected => detected
        );
    del : Delay
        GENERIC MAP(
            delayLength => sequenceLength,
            bitWidth    => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut
        );

    validOut <= '1' WHEN counter > 0 AND enable = '1' ELSE '0';

    PROCESS(clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF (reset = '1') THEN
                counter <= 0;
            ELSIF (enable = '1') THEN
                IF (detected = '1' AND counter = 0) THEN
                    counter <= packetSize;
                ELSIF (counter > 0) THEN
                    counter <= counter - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END structural;
