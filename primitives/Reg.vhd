-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.DSP.ALL;

ENTITY Reg IS
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
END Reg;

ARCHITECTURE behavioral OF Reg IS
BEGIN
    PROCESS(clock)
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                dataOut <= (OTHERS => '0');
                valid   <= '0';
            ELSIF (enable = '1') THEN
                dataOut <= dataIn;
                valid   <= '1';
            ELSE
                valid <= '0';
            END IF;
        END IF;
    END PROCESS;
END behavioral;
