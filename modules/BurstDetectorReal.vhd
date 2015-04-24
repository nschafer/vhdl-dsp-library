LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BurstDetectorReal IS
    GENERIC(
        bitWidth              : POSITIVE      := DEFAULT_BITWIDTH;
        sampleAddressSpace    : POSITIVE      := DEFAULT_SAMPLE_ADDRESS_SPACE;
        sampleDecimation      : POSITIVE      := DEFAULT_DECIMATION;
        numTaps               : POSITIVE      := DEFAULT_NUM_BURST_TAPS;
        coefBitWidth          : POSITIVE      := DEFAULT_COEF_BITWIDTH;
        averageThresholdShift : NATURAL       := DEFAULT_SHIFT_GAIN;
        taps                  : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
        threshold             : POSITIVE      := DEFAULT_MAX_THRESHOLD;
        burstHistory          : NATURAL       := DEFAULT_HISTORY;
        burstLength           : POSITIVE      := DEFAULT_PACKET_SIZE
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC;
        dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
    );
END ENTITY BurstDetectorReal;

ARCHITECTURE rtl OF BurstDetectorReal IS
    COMPONENT PolyphaseDecimatingFirFilter IS
        GENERIC(
            NumTaps      : POSITIVE;
            Decimation   : POSITIVE;
            CoefBitWidth : POSITIVE;
            BitWidth     : POSITIVE;
            Taps         : INTEGER_ARRAY
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            valid   : OUT STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(BitWidth - 1 DOWNTO 0)
        );
    END COMPONENT PolyphaseDecimatingFirFilter;

    COMPONENT MovingAverage IS
        GENERIC(
            bitWidth           : POSITIVE;
            sampleAddressSpace : POSITIVE;
            sampleDecimation   : POSITIVE
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            inData  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            outData : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT MovingAverage;

    COMPONENT PipelineReg IS
        GENERIC(
            pipelineLength : NATURAL;
            bitWidth       : POSITIVE
        );
        PORT(
            reset   : IN  STD_LOGIC;
            clock   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            valid   : OUT STD_LOGIC
        );
    END COMPONENT PipelineReg;

    CONSTANT nonDecimation     : POSITIVE := 1;
    CONSTANT pipelineDelay     : POSITIVE := 6; -- Internals have 6 clock latency
    CONSTANT filterDelay       : POSITIVE := burstHistory + pipelineDelay;
    CONSTANT totalSamples      : POSITIVE := burstHistory + burstLength;
    SIGNAL filterResult        : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL absFilterResult     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL averageOut          : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL shiftedAverage      : STD_LOGIC_VECTOR(bitWidth + averageThresholdShift - 1 DOWNTO 0);
    SIGNAL validOut            : STD_LOGIC;
    SIGNAL counter             : NATURAL RANGE 0 TO totalSamples;
    SIGNAL validFilterOut      : STD_LOGIC;
    SIGNAL validDelayOut       : STD_LOGIC;
    SIGNAL movingAverageEnable : STD_LOGIC;
    SIGNAL validMovingAverage  : STD_LOGIC;

BEGIN
    matchedFilter : PolyphaseDecimatingFirFilter
        GENERIC MAP(
            numTaps      => numTaps,
            decimation   => nonDecimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            taps         => taps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => validFilterOut,
            dataIn  => dataIn,
            dataOut => filterResult
        );

    absFilterResult <= STD_LOGIC_VECTOR(ABS (signed(filterResult)));

    delay : PipelineReg
        GENERIC MAP(
            pipelineLength => filterDelay,
            bitWidth    => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => dataIn,
            dataOut => dataOut,
            valid   => validDelayOut
        );

    movingAverageEnable <= validFilterOut;

    avg : MovingAverage
        GENERIC MAP(
            bitWidth           => bitWidth,
            sampleAddressSpace => sampleAddressSpace,
            sampleDecimation   => sampleDecimation
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => movingAverageEnable,
            inData  => absFilterResult,
            outData => averageOut,
            valid   => validMovingAverage
        );
    shiftedAverage(shiftedAverage'high DOWNTO averageThresholdShift) <= averageOut;
    shiftedAverage(averageThresholdShift - 1 DOWNTO 0)               <= (OTHERS => '0');

    validOut <= '1' WHEN (unsigned(absFilterResult) > unsigned(shiftedAverage)) AND validMovingAverage = '1' ELSE 
                '1' WHEN (unsigned(absFilterResult) >= threshold) AND validFilterOut = '1' ELSE 
                '0';

    valid <= '1' WHEN (validDelayOut = '1' AND reset = '0' AND counter > 0) ELSE 
             '0';

    PROCESS(clock)
    BEGIN
        IF (rising_edge(clock)) THEN
            IF (reset = '1') THEN
                counter <= 0;
            ELSIF (validDelayOut = '1') THEN
                IF (validOut = '1' AND counter = 0) THEN
                    counter <= totalSamples;
                ELSIF (counter > 0) THEN
                    counter <= counter - 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    
END ARCHITECTURE rtl;
