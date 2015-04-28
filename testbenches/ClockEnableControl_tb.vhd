-- Written by Neil Schafer
-- Code 5545, US Naval Research Laboratory

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.DSP.ALL;

ENTITY ClockEnableControl_tb IS
END ClockEnableControl_tb;

ARCHITECTURE behavior OF ClockEnableControl_tb IS
	COMPONENT ClockEnableControl IS
		GENERIC(
			decimation : POSITIVE
		);
		PORT(
			clockIn  : IN  STD_LOGIC;
			reset    : IN  STD_LOGIC;
			enable   : IN  STD_LOGIC;
			clockOut : OUT STD_LOGIC
		);
	END COMPONENT;

	SIGNAL clock    : STD_LOGIC := '0';
	SIGNAL reset    : STD_LOGIC := '0';
	SIGNAL enable   : STD_LOGIC := '0';
	SIGNAL dataOut1 : STD_LOGIC;
	SIGNAL dataOut3 : STD_LOGIC;
	SIGNAL dataOut5 : STD_LOGIC;
	SIGNAL dataOut8 : STD_LOGIC;

	CONSTANT clockPeriod : TIME := 10 ns;

BEGIN
	noDec : ClockEnableControl
		GENERIC MAP(
			decimation => 1
		)
		PORT MAP(
			clockIn  => clock,
			reset    => reset,
			enable   => enable,
			clockOut => dataOut1
		);

	dec3 : ClockEnableControl
		GENERIC MAP(
			decimation => 3
		)
		PORT MAP(
			clockIn  => clock,
			reset    => reset,
			enable   => enable,
			clockOut => dataOut3
		);

	dec5 : ClockEnableControl
		GENERIC MAP(
			decimation => 5
		)
		PORT MAP(
			clockIn  => clock,
			reset    => reset,
			enable   => enable,
			clockOut => dataOut5
		);

	dec8 : ClockEnableControl
		GENERIC MAP(
			decimation => 8
		)
		PORT MAP(
			clockIn  => clock,
			reset    => reset,
			enable   => enable,
			clockOut => dataOut8
		);

	clockProcess : PROCESS
	BEGIN
		clock <= '0';
		WAIT FOR clockPeriod / 2;
		clock <= '1';
		WAIT FOR clockPeriod / 2;
	END PROCESS;

	decimatingProcess : PROCESS
		VARIABLE count : POSITIVE := 1;
	BEGIN
		reset <= '1';
		WAIT FOR 2 * clockPeriod;
		reset  <= '0';
		enable <= '1';
		LOOP
			WAIT FOR clockPeriod;
			ASSERT dataOut1 = '1';
			IF (count mod 3) = 0 THEN
				ASSERT dataOut3 = '1';
			ELSE
				ASSERT dataOut3 = '0';
			END IF;
			IF (count mod 5) = 0 THEN
				ASSERT dataOut5 = '1';
			ELSE
				ASSERT dataOut5 = '0';
			END IF;
			IF (count mod 8) = 0 THEN
				ASSERT dataOut8 = '1';
			ELSE
				ASSERT dataOut8 = '0';
			END IF;
			count := count + 1;
		END LOOP;
	END PROCESS;
END;