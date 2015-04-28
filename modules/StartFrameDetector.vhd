-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
---------------------------------------------------------------------------------------------------------------------
-- Start Frame Detector
--
-- Input: Signed Data
-- Output: Signed Data
--
-- Parameters
-- bitWidth: Bit size of one element of data.
-- packetSize: The number of data elements to pass through after a pattern is detected, including pattern itself.
-- searchSequence: The pattern being searched for a match. Can be signed integers. 
--
-- Behavior
-- Searches incoming data for an exact match of a pattern, blocking output until the pattern is identified.
-- Once the pattern is matched, (packetSize) data elements are passed out, starting with the first pattern element.
-- The pattern must be an exact match.
-- If a pattern is detected a second time within a single "packet" it is ignored.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY StartFrameDetector IS
    GENERIC(
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
            bitWidth : POSITIVE;
            sequence : INTEGER_ARRAY
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

    CONSTANT delayLength : POSITIVE := searchSequence'length;

    SIGNAL detected : STD_LOGIC;
    SIGNAL counter  : NATURAL RANGE 0 TO packetSize;

BEGIN
    seq_det : SequenceDetector
        GENERIC MAP(
            bitWidth => bitWidth,
            sequence => searchSequence
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
            delayLength => delayLength,
            bitWidth    => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut
        );

    validOut <= '1' WHEN counter > 0 AND enable = '1'
        ELSE '0';

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
