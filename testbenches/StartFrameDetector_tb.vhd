-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY StartFrameDetector_tb IS
END StartFrameDetector_tb;

ARCHITECTURE behavior OF StartFrameDetector_tb IS
	COMPONENT StartFrameDetector
		GENERIC(
			bitWidth       : POSITIVE;
			packetSize     : POSITIVE;
			searchSequence : INTEGER_ARRAY
		);
		PORT(
			reset    : IN  STD_LOGIC;
			clock    : IN  STD_LOGIC;
			enable   : IN  STD_LOGIC;
			dataIn   : IN  STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0);
			validOut : OUT STD_LOGIC;
			dataOut  : OUT STD_LOGIC_VECTOR(bitWidth - 1 DOWNTO 0)
		);
	END COMPONENT;

	SIGNAL clock    : STD_LOGIC                    := '0';
	SIGNAL reset    : STD_LOGIC                    := '0';
	SIGNAL enable   : STD_LOGIC                    := '0';
	SIGNAL dataIn   : STD_LOGIC_VECTOR(3 DOWNTO 0) := X"0";
	SIGNAL dataOut  : STD_LOGIC_VECTOR(3 DOWNTO 0);
	SIGNAL validOut : STD_LOGIC;

	CONSTANT clockPeriod : TIME := 10 ns;

	CONSTANT inputValues : INTEGER_ARRAY := (
		1, 15, 14, 13, 12, 2, 2, 0, 2, 2, 
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 
		11, 12, 13, 14, 15, 0, 1, 2, 3
	);

BEGIN
	uut : StartFrameDetector
		GENERIC MAP(
			bitWidth       => 4,
			packetSize     => 10,
			searchSequence => (2, 2, 0, 2, 2)
		)
		PORT MAP(
			clock    => clock,
			reset    => reset,
			enable   => enable,
			dataIn   => dataIn,
			validOut => validOut,
			dataOut  => dataOut
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
		dataIn <= X"1";
		WAIT FOR 2 * clockPeriod;
		reset  <= '0';
		enable <= '1';
		WAIT FOR 3 ns;
		FOR index IN inputValues'low TO inputValues'high LOOP
			dataIn <= STD_LOGIC_VECTOR(to_unsigned(inputValues(index), dataIn'length));
			WAIT FOR clockPeriod;
			IF index = 8 THEN
				enable <= '0';
			ELSIF index = 11 THEN
				enable <= '1';
			END IF;
			IF index >= 13 AND index < 23 THEN
				ASSERT validOut = '1';
			ELSE
				ASSERT validOut = '0';
			END IF;
		END LOOP;
		WAIT;
	END PROCESS;
END;