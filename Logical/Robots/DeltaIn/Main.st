PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaA); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0;
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;
	Step := INIT;
END_PROGRAM

PROGRAM _CYCLIC
    
	MpDelta3Axis_0();
	
	IF gdiInstantStop THEN
		Step:=STOP;
	END_IF;
	
	MpDelta3Axis_0.ErrorReset := diErrorReset;
	IF EDGEPOS(MpDelta3Axis_0.Error) THEN
		Step := ERROR;
	END_IF;
	
	CASE Step OF
		INIT:
			IF gVisPower THEN
				Step := POWER;
			END_IF;
		POWER:
			MpDelta3Axis_0.Power := TRUE;
			IF MpDelta3Axis_0.PowerOn THEN
				Step:= HOME;
			END_IF;
		HOME:
			MpDelta3Axis_0.Home := TRUE;
			IF MpDelta3Axis_0.IsHomed THEN
				Step := WAIT_SHUTTLE;
			END_IF;
		WAIT_SHUTTLE:
			MpDelta3Axis_0.MoveProgram := 0;
			IF gShuttleInPlace_Input AND NOT gdiStop THEN
				Step := MOVE_PROGRAM;
				DeltaParameters.ProgramName := 'RoboticIn.st';    //File stored on FileDevice
			END_IF;
			
		MOVE_PROGRAM:
			IF gVisInput_Broken THEN
				IF gColorSum >0 THEN
				MpDelta3Axis_0.MoveProgram :=TRUE;
				IF MpDelta3Axis_0.MoveDone THEN
					gColorSum := gColorSum - 1;
					Step:= WAIT_SHUTTLE;
					gBottleInPlace_Input:=TRUE;
				END_IF;
				IF gdiInterrupt THEN
					Step := INTERRUPT;
				END_IF;
				END_IF;
			ELSE
				Step := INTERRUPT;
			END_IF;
			

		INTERRUPT:
			MpDelta3Axis_0.Interrupt := TRUE;
			IF gdiContinue OR EDGEPOS (gVisInput_Broken) THEN
				MpDelta3Axis_0.Interrupt := FALSE;
				MpDelta3Axis_0.Continue := TRUE;
				Step := MOVE_PROGRAM;
			END_IF;	
					
		STOP:
			MpDelta3Axis_0.Stop := TRUE;
			IF (NOT gdiInstantStop) AND MpDelta3Axis_0.Stopped THEN
				
				MpDelta3Axis_0.Home := FALSE;
				MpDelta3Axis_0.Interrupt := FALSE;
				MpDelta3Axis_0.Continue := FALSE;
				MpDelta3Axis_0.MoveProgram := FALSE;
				MpDelta3Axis_0.Stop := FALSE;
				
	  			Step := INIT;
			END_IF;
		ERROR:
			
			IF NOT(MpDelta3Axis_0.Error) THEN
				Step := INIT;
			END_IF;


	END_CASE;
	
	END_PROGRAM

	PROGRAM _EXIT


				MpDelta3Axis_0.Power  := FALSE;
				MpDelta3Axis_0.Home   := FALSE;
				MpDelta3Axis_0.MoveDirect := FALSE; 
				MpDelta3Axis_0.MoveLinear := FALSE; 
				MpDelta3Axis_0();

				MpDelta3Axis_0.Enable := FALSE;
				MpDelta3Axis_0();
	
				END_PROGRAM
