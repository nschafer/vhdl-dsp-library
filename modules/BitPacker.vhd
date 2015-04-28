-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
------------------------------------------------------------------------------------------------------------------------------
-- Bit Packer
--
-- Parameters
-- BitWidthIn : Number of bits of incoming data
-- BitWidthOut : Number of bits of outgoing data
--
-- Behavior
-- Incoming data is "packed" together, until <bitWidthOut> number of bits are placed together, then the packed output is sent.
-- Data is packed big-endian. BitWidthIn must divide evenly into BitWidthOut.

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BitPacker IS
    GENERIC(
        bitWidthIn  : POSITIVE := DEFAULT_BITWIDTH;
        bitWidthOut : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END BitPacker;

ARCHITECTURE Behavioral OF BitPacker IS
    SIGNAL validOutput : STD_LOGIC;
    SIGNAL output      : STD_LOGIC_VECTOR(bitWidthOut - 1 DOWNTO 0);
    SIGNAL input       : STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
BEGIN
    ASSERT bitWidthOut >= bitWidthIn REPORT "This component can only pack bits, it cannot unpack them.";
    ASSERT bitWidthOut MOD bitWidthIn = 0 REPORT "Input data size must divide evenly into output size.";

    pack : PROCESS(clock)
        VARIABLE count : NATURAL RANGE 0 TO bitWidthOut := bitWidthOut;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                output      <= (OTHERS => '0');
                validOutput <= '0';
                count       := bitWidthOut - 1;
            ELSIF enable = '1' THEN
                output(count DOWNTO count - bitWidthIn + 1) <= input;
                IF count = 0 THEN
                    validOutput <= '1';
                    count       := bitWidthOut - 1;
                ELSE
                    validOutput <= '0';
                    count       := count - bitWidthIn;
                END IF;
            ELSE
                validOutput <= '0';
            END IF;
        END IF;
    END PROCESS pack;

    valid   <= validOutput;
    input   <= dataIn;
    dataOut <= output;

END Behavioral;

    