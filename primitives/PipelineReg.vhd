LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

USE WORK.DSP.ALL;

ENTITY PipelineReg IS
    GENERIC(
        pipelineLength : NATURAL  := DEFAULT_DELAY;
        bitWidth       : POSITIVE := DEFAULT_BITWIDTH
    );
    PORT(
        reset   : IN  STD_LOGIC;
        clock   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END PipelineReg;

ARCHITECTURE structural OF PipelineReg IS
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

    -- length of "0" results in creation of a single register ("1" results in 2 registers, and so on)
    CONSTANT NUM_REG : POSITIVE := pipelineLength + 1;

    TYPE DATA_SIG IS ARRAY (0 TO NUM_REG) OF STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

    SIGNAL enableLines : STD_LOGIC_VECTOR(0 TO NUM_REG);
    SIGNAL dataLines   : DATA_SIG;

BEGIN
    enableLines(0) <= enable;
    dataLines(0)   <= dataIn;
    dataout        <= dataLines(NUM_REG);
    valid          <= enableLines(NUM_REG);

    registers : FOR J IN 0 TO pipeLineLength GENERATE
    BEGIN
        regJ : Reg
            GENERIC MAP(
                bitWidth => bitWidth
            )
            PORT MAP(
                reset   => reset,
                clock   => clock,
                enable  => enableLines(J),
                dataIn  => dataLines(J),
                dataOut => dataLines(J + 1),
                valid   => enableLines(J + 1)
            );
    END GENERATE registers;

END structural;
