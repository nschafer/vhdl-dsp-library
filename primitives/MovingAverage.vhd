LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY MovingAverage IS
    GENERIC(
        bitWidth           : POSITIVE := DEFAULT_BITWIDTH;
        sampleAddressSpace : POSITIVE := DEFAULT_SAMPLE_ADDRESS_SPACE;
        sampleDecimation   : POSITIVE := DEFAULT_DECIMATION
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        inData  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        outData : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END MovingAverage;

ARCHITECTURE behavioral OF MovingAverage IS
    CONSTANT ramSize     : POSITIVE := 2 ** sampleAddressSpace;
    CONSTANT sumBitWidth : POSITIVE := sampleAddressSpace + bitWidth;
    TYPE RAM IS ARRAY (0 TO ramSize - 1) OF STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL sampleData : RAM := (OTHERS => (OTHERS => '0'));
    SIGNAL count      : POSITIVE RANGE 1 TO sampleDecimation;
    SIGNAL output     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL validBit   : STD_LOGIC;

BEGIN
    getRAM : BLOCK
    BEGIN
        -- This infers RAM successfully in both Xilinx and Altera, don't muck with it
        sampleData <= inData & sampleData(0 to ramSize - 2) WHEN rising_edge(clock) AND count = sampleDecimation AND enable = '1' ELSE sampleData;
    END BLOCK;

    PROCESS(clock)
        VARIABLE sum      : STD_LOGIC_VECTOR(sumBitWidth - 1 DOWNTO 0);
        VARIABLE validSum : NATURAL RANGE 0 TO ramSize;
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                count    <= 1;
                sum      := (OTHERS => '0');
                validBit <= '0';
                validSum := 0;
            ELSIF enable = '1' THEN
                IF count = sampleDecimation THEN
                    count <= 1;
                    sum   := STD_LOGIC_VECTOR(signed(sum) + signed(inData) - signed(sampleData(ramSize - 1)));
                    IF validSum < ramSize THEN
                        validSum := validSum + 1;
                        validBit <= '0';
                    ELSE
                        validBit <= '1';
                    END IF;
                ELSE
                    count <= count + 1;
                END IF;
            ELSE
                validBit <= '0';
            END IF;
            output <= sum(sum'high DOWNTO sampleAddressSpace);
        END IF;
    END PROCESS;

    outData <= output;
    valid   <= validBit;
END behavioral;
	