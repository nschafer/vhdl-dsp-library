-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY SequenceDetector_tb IS
END SequenceDetector_tb;

ARCHITECTURE behavior OF SequenceDetector_tb IS
	COMPONENT SequenceDetector
		GENERIC(
			sequenceLength : INTEGER;
			bitWidth       : INTEGER;
			sequence       : INTEGER_ARRAY
		);
		PORT(
			reset    : IN  STD_LOGIC;
			clock    : IN  STD_LOGIC;
			enable   : IN  STD_LOGIC;
			dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
			detected : OUT STD_LOGIC
		);
	END COMPONENT;

	SIGNAL clock    : STD_LOGIC                    := '0';
	SIGNAL reset    : STD_LOGIC                    := '0';
	SIGNAL enable   : STD_LOGIC                    := '0';
	SIGNAL dataIn   : STD_LOGIC_VECTOR(0 DOWNTO 0) := B"0";
	SIGNAL detected : STD_LOGIC;

	CONSTANT clockPeriod : TIME := 10 ns;

	CONSTANT inputValues : STD_LOGIC_VECTOR := B"1011100111001101010101";

BEGIN
	uut : SequenceDetector
		GENERIC MAP(
			sequenceLength => 5,
			bitWidth       => 1,
			sequence       => (1, 0, 0, 1, 1)
		)
		PORT MAP(
			clock    => clock,
			reset    => reset,
			enable   => enable,
			dataIn   => dataIn,
			detected => detected
		);

	clockProcess : PROCESS
	BEGIN
		clock <= '0';
		WAIT FOR clockPeriod / 2;
		clock <= '1';
		WAIT FOR clockPeriod / 2;
	END PROCESS;

	sequenceProcess : PROCESS
	BEGIN
		reset  <= '1';
		dataIn <= B"1";
		WAIT FOR 2 * clockPeriod;
		reset <= '0';
		enable <= '1';
		WAIT FOR 3 ns;
		FOR I IN inputValues'low TO inputValues'high LOOP
			dataIn(0) <= inputValues(I);
			WAIT FOR clockPeriod;
		END LOOP;
		WAIT;
	END PROCESS;
END;