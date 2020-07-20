PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaA); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 
	DeltaParameters.ProgramName := 'Robotic.st';    //File stored on FileDevice
	DeltaParameters.Velocity := 500.0;
	DeltaParameters.Acceleration := 5000.0;
	DeltaParameters.Deceleration := 5000.0;
	
	groupReadActualPos.AxesGroup := ADR(g3AxDeltaA);
	groupReadActualPos.Enable := TRUE;
	groupReadActualPos.CoordSystem := 0;

END_PROGRAM

PROGRAM _CYCLIC

	groupReadActualPos();	
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