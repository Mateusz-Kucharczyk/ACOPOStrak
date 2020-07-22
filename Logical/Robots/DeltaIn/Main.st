PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaA); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 
	DeltaParameters.ProgramName := 'RoboticIn.st';    //File stored on FileDevice
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;
	Step := Init;
END_PROGRAM

PROGRAM _CYCLIC
    
	MpDelta3Axis_0();
	IF diStop THEN
		Step := Stop;
	END_IF;
	
	CASE Step OF
		Init:
			IF diStart THEN
	  			Step := Power;
			END_IF;
		Power:
			MpDelta3Axis_0.Power := TRUE;
			IF MpDelta3Axis_0.PowerOn THEN
	  			Step := Home;
			END_IF;
		Home:
			MpDelta3Axis_0.Home := TRUE;
			IF MpDelta3Axis_0.IsHomed THEN
	  			Step := Choose;
			END_IF;
		Choose:
		WaitShuttle:
		MovePrg:
		Interrupt:
		Stop:
		

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
