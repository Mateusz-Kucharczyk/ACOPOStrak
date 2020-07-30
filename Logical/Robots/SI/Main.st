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
				
			IF gPartyOn THEN
				Step := MOVE_PROGRAM;
			ELSE
				x := 0;
				y := 0;
				z := 0;
			END_IF;
			//RecipeBottlesPerPack := gOrder.bottlesPerPackage;
		MOVE_PROGRAM:
			MpDelta3Axis_0.MoveProgram := TRUE;
									
			IF MpDelta3Axis_0.MoveDone THEN
				MpDelta3Axis_0.MoveProgram := FALSE;
				Step := WAIT_SHUTTLE;
			END_IF;
			
			IF x=360 THEN
	  			
				IF y=360 THEN
					z := z+4;
					IF z=360 THEN
						x := 0;
						y := 0;
						z := 0;
					END_IF;
				ELSE
					y := y+4;
				END_IF;
			ELSE
				x := x+4;
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
