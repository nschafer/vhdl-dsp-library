-- AccumOut is the actual phase of the signal thus far, NOT the amount of rotation
-- (The amount of rotation to get to phase 0 is the OPPOSITE sign of the actual phase)
-- AccumOut should allow for a quantized, normalized range of [-pi, pi)

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.DSP.ALL;

ENTITY CordicAtan2Core IS
    GENERIC(
        bitWidth      : POSITIVE := DEFAULT_BITWIDTH;
        phaseBitWidth : POSITIVE := DEFAULT_BITWIDTH;
        iteration     : NATURAL  := DEFAULT_CORDIC_ROTATIONS
    );
    PORT(
        reset    : IN  STD_LOGIC;
        clock    : IN  STD_LOGIC;
        enable   : IN  STD_LOGIC;
        realIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        imagIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        accumIn  : IN  STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
        realOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        imagOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
        accumOut : OUT STD_LOGIC_VECTOR(phaseBitWidth - 1 DOWNTO 0);
        valid    : OUT STD_LOGIC
    );
END CordicAtan2Core;

ARCHITECTURE Behavioral OF CordicAtan2Core IS
    SIGNAL rotateEnable : STD_LOGIC;
BEGIN
    rotateEnable <= enable;
    rotate : PROCESS(clock)
        CONSTANT phaseRotation : SIGNED(phaseBitWidth - 1 DOWNTO 0) := SIGNED(getPhaseChange(
                iteration => iteration,
                bitWidth => phaseBitWidth
            ));
        VARIABLE signedReal : SIGNED(bitWidth - 1 DOWNTO 0);
        VARIABLE signedImag : SIGNED(bitWidth - 1 DOWNTO 0);
    BEGIN
        IF rising_edge(clock) THEN
            IF reset = '1' THEN
                realOut  <= (OTHERS => '0');
                imagOut  <= (OTHERS => '0');
                accumOut <= (OTHERS => '0');
                valid    <= '0';
            ELSIF rotateEnable = '1' THEN
                signedReal := SIGNED(realIn);
                signedImag := SIGNED(imagIn);
                valid      <= '1';
                IF iteration = 0 THEN
                    IF signedImag > 0 THEN
                        realOut  <= STD_LOGIC_VECTOR(signedImag);
                        imagOut  <= STD_LOGIC_VECTOR(-signedReal);
                        accumOut <= STD_LOGIC_VECTOR(-phaseRotation);
                    ELSE
                        realOut  <= STD_LOGIC_VECTOR(-signedImag);
                        imagOut  <= STD_LOGIC_VECTOR(signedReal);
                        accumOut <= STD_LOGIC_VECTOR(phaseRotation);
                    END IF;
                ELSE
                    IF signedImag > 0 THEN
                        realOut  <= STD_LOGIC_VECTOR(signedReal + shift_right(signedImag, iteration - 1));
                        imagOut  <= STD_LOGIC_VECTOR(signedImag - shift_right(signedReal, iteration - 1));
                        accumOut <= STD_LOGIC_VECTOR(SIGNED(accumIn) - phaseRotation);
                    ELSE
                        IF (signedImag = -1) THEN
                            -- prevents consecutively adding "1" since a shifted -1 remains -1 forever
                            signedImag := (OTHERS => '0');
                        END IF;
                        realOut  <= STD_LOGIC_VECTOR(signedReal - shift_right(signedImag, iteration - 1));
                        imagOut  <= STD_LOGIC_VECTOR(signedImag + shift_right(signedReal, iteration - 1));
                        accumOut <= STD_LOGIC_VECTOR(SIGNED(accumIn) + phaseRotation);
                    END IF;
                END IF;
            ELSE
                valid <= '0';
            END IF;
        END IF;
    END PROCESS rotate;
END Behavioral;