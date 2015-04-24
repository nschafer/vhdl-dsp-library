LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY BurstDetectorComplex IS
    GENERIC(
        bitWidth              : POSITIVE      := DEFAULT_BITWIDTH;
        sampleAddressSpace    : POSITIVE      := DEFAULT_SAMPLE_ADDRESS_SPACE;
        sampleDecimation      : POSITIVE      := DEFAULT_DECIMATION;
        numTaps               : POSITIVE      := DEFAULT_NUM_BURST_TAPS;
        coefBitWidth          : POSITIVE      := DEFAULT_COEF_BITWIDTH;
        averageThresholdShift : NATURAL       := DEFAULT_SHIFT_GAIN;
        realTaps              : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
        imagTaps              : INTEGER_ARRAY := DEFAULT_BURST_TAPS;
        threshold             : POSITIVE      := DEFAULT_MAX_THRESHOLD;
        burstLength           : POSITIVE      := DEFAULT_PACKET_SIZE;
        burstHistory          : NATURAL       := DEFAULT_HISTORY;
        numCordicRotations    : POSITIVE      := DEFAULT_CORDIC_ROTATIONS
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        realIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        imagIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC;
        realOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        imagOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
    );
END ENTITY BurstDetectorComplex;

ARCHITECTURE rtl OF BurstDetectorComplex IS
    COMPONENT PolyphaseDecimatingFirFilterComplex IS
        GENERIC(
            numTaps      : POSITIVE;
            decimation   : POSITIVE;
            coefBitWidth : POSITIVE;
            bitWidth     : POSITIVE;
            realTaps     : INTEGER_ARRAY;
            imagTaps     : INTEGER_ARRAY
        );
        PORT(
            clock   : IN  STD_LOGIC;
            reset   : IN  STD_LOGIC;
            enable  : IN  STD_LOGIC;
            valid   : OUT STD_LOGIC;
            realIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            realOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
            imagOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
        );
    END COMPONENT PolyphaseDecimatingFirFilterComplex;

    COMPONENT CordicAtan2Pipelined IS
        GENERIC(
            bitWidth      : POSITIVE;
            phaseBitWidth : POSITIVE;
            numIterations : NATURAL
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
    END COMPONENT CordicAtan2Pipelined;

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

    CONSTANT nonDecimation   : POSITIVE := 1;
    CONSTANT pipelineDelay   : POSITIVE := 6; -- Polyphase filter has a 6 clock latency
    CONSTANT filterDelay     : POSITIVE := burstHistory + pipelineDelay;
    CONSTANT cordicDelay     : POSITIVE := numCordicRotations + 2; -- One initial 90 degree shift plus final clock
    CONSTANT totalDelay      : POSITIVE := filterDelay + cordicDelay;
    CONSTANT totalSamples    : POSITIVE := burstHistory + burstLength;
    CONSTANT wideBitWidth    : POSITIVE := bitWidth + 2; --for overflow and signed bit
    SIGNAL filterOutReal     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL filterOutImag     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL wideFilterOutReal : STD_LOGIC_VECTOR(wideBitWidth - 1 DOWNTO 0);
    SIGNAL wideFilterOutImag : STD_LOGIC_VECTOR(wideBitWidth - 1 DOWNTO 0);
    SIGNAL magnitude         : STD_LOGIC_VECTOR(wideBitWidth - 1 DOWNTO 0);
    SIGNAL averageOut        : STD_LOGIC_VECTOR(wideBitWidth - 1 DOWNTO 0);
    SIGNAL shiftedAverage    : STD_LOGIC_VECTOR(wideBitWidth + averageThresholdShift - 1 DOWNTO 0);
    SIGNAL validOut          : STD_LOGIC;
    SIGNAL counter           : NATURAL RANGE 0 TO totalSamples;

    SIGNAL validFilterOut        : STD_LOGIC;
    SIGNAL enableCordic          : STD_LOGIC;
    SIGNAL validCordicOut        : STD_LOGIC;
    SIGNAL enableMovingAverage   : STD_LOGIC;
    SIGNAL validMovingAverageOut : STD_LOGIC;
    SIGNAL validDelayOut         : STD_LOGIC;

BEGIN
    matchedFilter : PolyphaseDecimatingFirFilterComplex
        GENERIC MAP(
            numTaps      => numTaps,
            decimation   => nonDecimation,
            coefBitWidth => coefBitWidth,
            bitWidth     => bitWidth,
            realTaps     => realTaps,
            imagTaps     => imagTaps
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enable,
            valid   => validFilterOut,
            realIn  => realIn,
            imagIn  => imagIn,
            realOut => filterOutReal,
            imagOut => filterOutImag
        );

    wideFilterOutReal(wideBitWidth - 1 DOWNTO bitWidth) <= (OTHERS => filterOutReal(bitWidth - 1));
    wideFilterOutReal(bitWidth - 1 DOWNTO 0)            <= filterOutReal;
    wideFilterOutImag(wideBitWidth - 1 DOWNTO bitWidth) <= (OTHERS => filterOutImag(bitWidth - 1));
    wideFilterOutImag(bitWidth - 1 DOWNTO 0)            <= filterOutImag;

    enableCordic <= validFilterOut;

    findMagnitude : CordicAtan2Pipelined
        GENERIC MAP(
            bitWidth      => wideBitWidth,
            phaseBitWidth => wideBitWidth,
            numIterations => numCordicRotations
        )
        PORT MAP(
            reset        => reset,
            clock        => clock,
            enable       => enableCordic,
            realIn       => wideFilterOutReal,
            imagIn       => wideFilterOutImag,
            magnitudeOut => magnitude,
            phaseOut     => OPEN,
            valid        => validCordicOut
        );

    delayReal : PipelineReg
        GENERIC MAP(
            pipelineLength => totalDelay,
            bitWidth       => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => realIn,
            dataOut => realOut,
            valid   => validDelayOut
        );

    delayImag : PipelineReg
        GENERIC MAP(
            pipelineLength => totalDelay,
            bitWidth       => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => imagIn,
            dataOut => imagOut,
            valid   => OPEN
        );

    enableMovingAverage <= validCordicOut;

    avg : MovingAverage
        GENERIC MAP(
            bitWidth           => wideBitWidth,
            sampleAddressSpace => sampleAddressSpace,
            sampleDecimation   => sampleDecimation
        )
        PORT MAP(
            clock   => clock,
            reset   => reset,
            enable  => enableMovingAverage,
            inData  => magnitude,
            outData => averageOut,
            valid   => validMovingAverageout
        );

    shiftedAverage(shiftedAverage'high DOWNTO averageThresholdShift) <= averageOut;
    shiftedAverage(averageThresholdShift - 1 DOWNTO 0)               <= (OTHERS => '0');

    validOut <= '1' WHEN unsigned(magnitude) > unsigned(shiftedAverage) AND validMovingAverageOut = '1' ELSE 
                '1' WHEN unsigned(magnitude) >= threshold AND validCordicOut = '1' ELSE 
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
