PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaA_SI); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(MpDelta3AxisPar_0); 

	MpDelta3Axis_0.Override := 100.0; 

	
	MpDelta3AxisPar_0.Velocity := 5.0;
	MpDelta3AxisPar_0.Acceleration := 50.0;
	
	MpDelta3AxisPar_0.ProgramName := 'SI.st';
	
END_PROGRAM

PROGRAM _CYCLIC
	
	//DeltaParameters.ProgramName := PName;
	MpDelta3Axis_0();
	
	IF EDGEPOS(MpDelta3Axis_0.Error) THEN
		Step := ERROR;
	END_IF;
	
	CASE Step OF
		INIT:
			MpDelta3Axis_0.Power := FALSE;
			MpDelta3Axis_0.Home := FALSE;
			MpDelta3Axis_0.MoveProgram := FALSE;
			
			IF gVisPower THEN
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
				
			IF diPartyOn THEN
				Step := MOVE_PROGRAM;
			ELSE
				x := 0;
				y := 0;
				z := 0;
			END_IF;
			//RecipeBottlesPerPack := gOrder.bottlesPerPackage;
		MOVE_PROGRAM:
			MpDelta3Axis_0.MoveProgram := TRUE;
			
			IF gdiInterrupt THEN
				Step := INTERRUPT;
				MpDelta3Axis_0.Continue := FALSE;
			END_IF;	
			
			IF MpDelta3Axis_0.MoveDone THEN
				MpDelta3Axis_0.MoveProgram := FALSE;
				Step := WAIT_SHUTTLE;
			END_IF;
			
			IF x=360 THEN
	  			y := y+1;
				IF y=360 THEN
					z := 360;
					IF z=360 THEN
						x := 0;
						y := 0;
						z := 0;
					END_IF;
				END_IF;
			ELSE
				x := x+8;
			END_IF;
			
		INTERRUPT:
			MpDelta3Axis_0.Interrupt := TRUE;
			
			IF gdiContinue OR EDGEPOS (gVisOutput_Broken) THEN
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
