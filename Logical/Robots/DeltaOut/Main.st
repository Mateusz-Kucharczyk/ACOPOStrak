PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaAOut); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 

	DeltaParameters.ProgramName := 'Robotic1.st';
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;

END_PROGRAM

PROGRAM _CYCLIC
	
	
	MpDelta3Axis_0.ErrorReset := diErrorReset;
	
	IF EDGEPOS(MpDelta3Axis_0.Error) THEN
	  Step := ERROR;
	END_IF;
	
	CASE Step OF
		INIT:
			MpDelta3Axis_0.Power := FALSE;
			MpDelta3Axis_0.Home := FALSE;
			MpDelta3Axis_0.MoveProgram := FALSE;
			
			IF diStart THEN
	  			Step := POWER;
			END_IF;
		POWER:
			MpDelta3Axis_0.Power := TRUE;
			
			IF MpDelta3Axis_0.PowerOn THEN
	  			Step := HOME;
			END_IF;
		HOME:
			MpDelta3Axis_0.Home := TRUE;
			
			IF MpDelta3Axis_0.IsHomed THEN
	  			Step := WAIT_SHUTTLE;
			END_IF;
		WAIT_SHUTTLE:
			MpDelta3Axis_0.Continue := FALSE;
			
			IF EDGEPOS(gShuttleInPlace_Output) THEN
	  			Step := MOVE_PROGRAM;
			END_IF;
		MOVE_PROGRAM:
			MpDelta3Axis_0.MoveProgram := TRUE;
			
			IF diInterrupt THEN
				Step := INTERRUPT;
			END_IF;
			
			IF MpDelta3Axis_0.MoveDone THEN
				MpDelta3Axis_0.MoveProgram := FALSE;
				Step := WAIT_SHUTTLE;
				gBottleInPlace_Output:=TRUE;
			END_IF;
		INTERRUPT:
			MpDelta3Axis_0.Interrupt := TRUE;
			
			IF diResume THEN
				MpDelta3Axis_0.Interrupt := FALSE;
				MpDelta3Axis_0.Continue := TRUE;
				Step := MOVE_PROGRAM;				
			END_IF;
		STOP:
		
		ERROR:
		
			IF NOT(MpDelta3Axis_0.Error) THEN
	  			Step := INIT;
			END_IF;
		
		
	END_CASE;
    
	MpDelta3Axis_0();
     
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
