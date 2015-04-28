-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY LoopFilter IS
    GENERIC(
        bitWidth     : POSITIVE := DEFAULT_BITWIDTH;
        coefBitWidth : POSITIVE := DEFAULT_COEF_BITWIDTH;
        alpha        : INTEGER  := DEFAULT_ALPHA;
        beta         : INTEGER  := DEFAULT_BETA
    );
    PORT(
        clock   : IN  STD_LOGIC;
        reset   : IN  STD_LOGIC;
        enable  : IN  STD_LOGIC;
        dataIn  : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        dataOut : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        valid   : OUT STD_LOGIC
    );
END LoopFilter;

ARCHITECTURE Structural of LoopFilter IS
    COMPONENT ClockedMultiply IS
        GENERIC(
            bitWidthIn1 : POSITIVE;
            bitWidthIn2 : POSITIVE
        );
        PORT(
            reset  : IN  STD_LOGIC;
            clock  : IN  STD_LOGIC;
            enable : IN  STD_LOGIC;
            in1    : IN  STD_LOGIC_VECTOR(bitWidthIn1 - 1 DOWNTO 0);
            in2    : IN  STD_LOGIC_VECTOR(bitWidthIn2 - 1 DOWNTO 0);
            prod   : OUT STD_LOGIC_VECTOR(bitWidthIn1 + bitWidthIn2 - 1 DOWNTO 0);
            valid  : OUT STD_LOGIC
        );
    END COMPONENT;

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

    CONSTANT alphaVector : STD_LOGIC_VECTOR(coefBitWidth - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_signed(alpha, coefBitWidth));
    CONSTANT betaVector  : STD_LOGIC_VECTOR(coefBitWidth - 1 DOWNTO 0) := STD_LOGIC_VECTOR(to_signed(beta, coefBitWidth));

    SIGNAL regOut     : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL alphaOut   : STD_LOGIC_VECTOR(coefBitWidth + bitWidth - 1 DOWNTO 0);
    SIGNAL betaOut    : STD_LOGIC_VECTOR(coefBitWidth + bitWidth - 1 DOWNTO 0);
    SIGNAL truncAlpha : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL truncBeta  : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL adder1Out  : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
    SIGNAL adder2Out  : STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);

BEGIN
    alphaMult : ClockedMultiply
        GENERIC MAP(
            bitWidthIn1 => bitWidth,
            bitWidthIn2 => coefBitWidth
        )
        PORT MAP(
            reset  => reset,
            clock  => clock,
            enable => enable,
            in1    => regOut,
            in2    => alphaVector,
            prod   => alphaOut
        );

    truncAlpha <= alphaOut(alphaOut'high - 1 DOWNTO alphaOut'high - bitWidth);

    adder1 : adder1Out <= STD_LOGIC_VECTOR(SIGNED(dataIn) + SIGNED(truncAlpha));

    integrator : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => adder1Out,
            dataOut => regOut
        );

    betaMult : ClockedMultiply
        GENERIC MAP(
            bitWidthIn1 => bitWidth,
            bitWidthIn2 => coefBitWidth
        )
        PORT MAP(
            reset  => reset,
            clock  => clock,
            enable => enable,
            in1    => regOut,
            in2    => betaVector,
            prod   => betaOut
        );

    truncBeta <= betaOut(betaOut'high - 1 DOWNTO betaOut'high - bitWidth);

    adder2 : adder2Out <= STD_LOGIC_VECTOR(SIGNED(adder1Out) + SIGNED(truncBeta));

    clockedOut : Reg
        GENERIC MAP(
            bitWidth => bitWidth
        )
        PORT MAP(
            reset   => reset,
            clock   => clock,
            enable  => enable,
            dataIn  => adder2Out,
            dataOut => dataOut,
            valid   => valid
        );

END Structural;
