-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY SequenceDetector IS
    GENERIC(
        bitWidth : POSITIVE      := DEFAULT_BITWIDTH;
        sequence : INTEGER_ARRAY := DEFAULT_SEQUENCE
    );
    PORT(
        reset    : IN  STD_LOGIC;
        clock    : IN  STD_LOGIC;
        enable   : IN  STD_LOGIC;
        dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        detected : OUT STD_LOGIC
    );
END SequenceDetector;

ARCHITECTURE behavioral OF SequenceDetector IS
    TYPE SEQUENCE_VECTOR IS ARRAY (sequence'range) OF STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

    FUNCTION INT_ARRAY_TO_SEQ_VECTOR RETURN SEQUENCE_VECTOR IS
        VARIABLE seqVector : SEQUENCE_VECTOR;
    BEGIN
        FOR index IN sequence'range LOOP
            ASSERT inRange(bitWidth => bitWidth, input => sequence(index));
            IF sequence(index) < 2 ** (bitWidth - 1) THEN
                seqVector(index) := STD_LOGIC_VECTOR(to_signed(sequence(index), bitWidth));
            ELSE
                seqVector(index) := STD_LOGIC_VECTOR(to_unsigned(sequence(index), bitWidth));
            END IF;
        END LOOP;
        RETURN seqVector;
    END INT_ARRAY_TO_SEQ_VECTOR;

    SIGNAL prevData  : SEQUENCE_VECTOR;
    SIGNAL seqVector : SEQUENCE_VECTOR := INT_ARRAY_TO_SEQ_VECTOR;

BEGIN
    detected <= '1' WHEN ((prevData = seqVector) AND (enable = '1')) ELSE '0';

    PROCESS(clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF (reset = '1') THEN
                FOR I IN prevData'range LOOP
                    prevData(I) <= (OTHERS => '0');
                END LOOP;
            END IF;
            IF (enable = '1') THEN
                IF sequence'length = 1 THEN
                    prevData(0) <= dataIn;
                ELSE
                    prevData <= prevData(1 TO prevData'high) & dataIn;
                END IF;
            END IF;
        END IF;
    END PROCESS;
END behavioral;
