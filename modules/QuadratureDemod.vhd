-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory
---------------------------------------------------------------------------------------------------------------
-- Quadrature Demodulator
--
-- Input: Signed Complex Data
-- Output One, phase (demodOut): Signed Real Data
-- Output Two, magnitude (magOut): Unsigned Real Data
-- Assumes both real and imaginary inputs are available during enable. Outputs phase and magnitude simultaneously
--
-- Parameters
-- BitWidth: Bit size of one element of input data. Also the bitwidth of the magnitude output.
-- phaseBitWidth: Size of internal representation of phase, and phase output bitwidth.
-- numIterations: The number of ATAN2 Cordic rotations. Used to find phase angle between I and Q and gauge magnitude of complex data. 
--                Defaults to 8. Each rotation adds latency. Results in a gain of roughly 1.6 that is NOT normalized out.
--
-- Behavior
-- Provides ATAN2 quadrature demodulation behavior. Output is a quantized frequency between [-pi, pi), where -pi represents the lowest possible
-- "frequency" for the sample rate and "~pi" is the highest. Magnitude of the input data is calculated at no extra cost.


LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY QuadratureDemod IS
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
        demodOut     : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
        valid        : OUT STD_LOGIC
    );
END QuadratureDemod;

ARCHITECTURE Structural OF QuadratureDemod IS
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
    END COMPONENT Reg;

    COMPONENT ClockedAdd IS
        GENERIC(
            bitWidthIn : POSITIVE := DEFAULT_BITWIDTH
        );
        PORT(
            reset  : IN  STD_LOGIC;
            clock  : IN  STD_LOGIC;
            enable : IN  STD_LOGIC;
            in1    : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            in2    : IN  STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            sum    : OUT STD_LOGIC_VECTOR(bitWidthIn - 1 DOWNTO 0);
            valid  : OUT STD_LOGIC
        );
    END COMPONENT ClockedAdd;

    SIGNAL currentPhase       : STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
    SIGNAL delayPhase         : STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
    SIGNAL negativeDelayPhase : STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
    SIGNAL magIntern          : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL demodIntern        : STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
    SIGNAL validCordicOut     : STD_LOGIC;
    SIGNAL enableDelay        : STD_LOGIC;
    SIGNAL validDelayOut      : STD_LOGIC;
    SIGNAL validDemodOut      : STD_LOGIC;
    SIGNAL enableOutputReg    : STD_LOGIC;
    SIGNAL validOutput        : STD_LOGIC;

BEGIN
    cordicDemod : CordicAtan2Pipelined
        GENERIC MAP(
            bitWidth      => bitWidth,
            phaseBitWidth => phaseBitWidth,
            numIterations => numIterations
        )
        PORT MAP(
            reset        => reset,
            enable       => enable,
            clock        => clock,
            realIn       => realIn,
            imagIn       => imagIn,
            magnitudeOut => magIntern,
            phaseOut     => currentPhase,
            valid        => validCordicOut
        );

    enableDelay <= validCordicOut;

    phaseDifference : Reg
        GENERIC MAP(
            bitWidth => phaseBitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enableDelay,
            dataIn  => currentPhase,
            dataOut => delayPhase,
            valid   => validDelayOut
        );

    negativeDelayPhase <= STD_LOGIC_VECTOR(-signed(delayPhase));

    demod : ClockedAdd
        GENERIC MAP(
            bitWidthIn => phaseBitWidth
        )
        PORT MAP(
            reset  => reset,
            clock  => clock,
            enable => enableDelay,
            in1    => currentPhase,
            in2    => negativeDelayPhase,
            sum    => demodIntern,
            valid  => validDemodOut
        );

    enableOutputReg <= validDemodOut;

    clockedMag : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enableOutputReg,
            dataIn  => magIntern,
            dataOut => magnitudeOut
        );

    clockedDemod : Reg
        GENERIC MAP(
            bitWidth => phaseBitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enableOutputReg,
            dataIn  => demodIntern,
            dataOut => demodOut,
            valid   => validOutput
        );

    valid <= validOutput;

END Structural;