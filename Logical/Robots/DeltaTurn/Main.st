
PROGRAM _INIT
	(* Insert code here *)
	MpDelta4Axis_0.MpLink := ADR(g4AxDeltaA); 
	MpDelta4Axis_0.Enable := TRUE; 
	MpDelta4Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta4Axis_0.Override := 100.0; 
	DeltaParameters.ProgramName := 'RoboticDown.st';    //File stored on FileDevice
	
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;
	
	DeltaParameters.Jog.Velocity[3] := 100;	
	
	Step :=INIT;
	
END_PROGRAM

PROGRAM _CYCLIC
	(* Insert code here *)
	MpDelta4Axis_0();
	
	IF gdiInstantStop THEN
		Step:=STOP;
	END_IF;
	
	MpDelta4Axis_0.ErrorReset := diErrorReset;
	IF EDGEPOS(MpDelta4Axis_0.Error) THEN
		Step := ERROR;
	END_IF;
	
	CASE Step OF
		INIT:
			IF gVisPower THEN
				Step := POWER;
			END_IF;
		POWER:
			MpDelta4Axis_0.Power := TRUE;
			IF MpDelta4Axis_0.PowerOn THEN
				Step:= HOME;
			END_IF;
		HOME:
			MpDelta4Axis_0.Home := TRUE;
			IF MpDelta4Axis_0.IsHomed THEN
				Step := WAIT_SHUTTLE;
			END_IF;
		WAIT_SHUTTLE:
			MpDelta4Axis_0.MoveProgram := FALSE;
			IF EDGEPOS(gShuttleInPlace_Turn) THEN
				Step := MOVE_PROGRAM;
			END_IF;
			turned := 0;
			
		MOVE_PROGRAM:
			IF NOT(gVisTurn_Broken) THEN
					MpDelta4Axis_0.MoveProgram :=TRUE;
				
				IF turned<240 THEN
					turned := turned+8;
				END_IF;
				
				IF MpDelta4Axis_0.MoveDone THEN
					Step:= WAIT_SHUTTLE;
					gBottleInPlace_Turn:=TRUE;
					gShuttleInPlace_Turn := FALSE;
				END_IF;
				IF gdiInterrupt THEN
					Step := INTERRUPT;
					MpDelta4Axis_0.Continue := FALSE;
				END_IF;
			ELSE
				Step := INTERRUPT;
				MpDelta4Axis_0.Continue := FALSE;
			END_IF;
		INTERRUPT:
			MpDelta4Axis_0.Interrupt := TRUE;
			IF gdiContinue AND EDGEPOS(gVisTurn_Broken) THEN
				MpDelta4Axis_0.Interrupt := FALSE;
				MpDelta4Axis_0.Continue := TRUE;
				Step := MOVE_PROGRAM;
			END_IF;	
					
		STOP:
			MpDelta4Axis_0.Stop := TRUE;
			IF (NOT gdiInstantStop) AND MpDelta4Axis_0.Stopped THEN
				
				MpDelta4Axis_0.Home := FALSE;
				MpDelta4Axis_0.Interrupt := FALSE;
				MpDelta4Axis_0.Continue := FALSE;
				MpDelta4Axis_0.MoveProgram := FALSE;
				MpDelta4Axis_0.Stop := FALSE;
				
				Step := INIT;
			END_IF;
		ERROR:
			
			IF NOT(MpDelta4Axis_0.Error) THEN
				Step := INIT;
			END_IF;


	END_CASE;
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	MpDelta4Axis_0.Power  := FALSE;
	MpDelta4Axis_0.Home   := FALSE;
	MpDelta4Axis_0.MoveDirect := FALSE; 
	MpDelta4Axis_0.MoveLinear := FALSE; 
	MpDelta4Axis_0();

	MpDelta4Axis_0.Enable := FALSE;
	MpDelta4Axis_0();
END_PROGRAM

