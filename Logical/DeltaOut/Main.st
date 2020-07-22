PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaAOut); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 
	DeltaParameters.ProgramName := 'Robotic1.st';    //File stored on FileDevice
	GroupPosition.AxesGroup := ADR(g3AxDeltaAOut);
	GroupPosition.Enable := TRUE;
	GroupPosition.CoordSystem := 0;
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;

END_PROGRAM

PROGRAM _CYCLIC
    
	MpDelta3Axis_0();
	GroupPosition ();
     
END_PROGRAM

PROGRAM _EXIT

	GroupPosition.Enable := FALSE;
	MpDelta3Axis_0.Power  := FALSE;
	MpDelta3Axis_0.Home   := FALSE;
	MpDelta3Axis_0.MoveDirect := FALSE; 
	MpDelta3Axis_0.MoveLinear := FALSE; 
	MpDelta3Axis_0();

	MpDelta3Axis_0.Enable := FALSE;
	MpDelta3Axis_0();
	
END_PROGRAM
