PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaAOut); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 

	
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;

END_PROGRAM

PROGRAM _CYCLIC
	
	//DeltaParameters.ProgramName := PName;
	MpDelta3Axis_0.ErrorReset := diErrorReset;
	
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
			MpDelta3Axis_0.Continue := FALSE;
			
			
			IF EDGEPOS(gShuttleInPlace_Output) THEN
				Step := MOVE_PROGRAM;
			END_IF;
			//RecipeBottlesPerPack := gOrder.bottlesPerPackage;
		MOVE_PROGRAM:
			IF gVisOutput_Broken THEN
				IF gOrder.bottlesPerPackage = 4 THEN
				CASE BottlesPerPack OF
				
					1:	DeltaParameters.ProgramName := 'RoboticOut1.st';
					
					2:	DeltaParameters.ProgramName := 'RoboticOut2.st';
				
					3:	DeltaParameters.ProgramName := 'RoboticOut5.st';
				
					4:	DeltaParameters.ProgramName := 'RoboticOut4.st';
				
				END_CASE;
			ELSE
			CASE BottlesPerPack OF
				
				1:	DeltaParameters.ProgramName := 'RoboticOut1.st';
					
				2:	DeltaParameters.ProgramName := 'RoboticOut2.st';
				
				3:	DeltaParameters.ProgramName := 'RoboticOut3.st';
				
				4:	DeltaParameters.ProgramName := 'RoboticOut4.st';
				
				5:	DeltaParameters.ProgramName := 'RoboticOut5.st';
				
				6:	DeltaParameters.ProgramName := 'RoboticOut6.st';
				
				END_CASE;
			END_IF;
			MpDelta3Axis_0.MoveProgram := TRUE;
			
			IF gdiInterrupt THEN
				Step := INTERRUPT;
			END_IF;
			
			IF MpDelta3Axis_0.MoveDone THEN
				MpDelta3Axis_0.MoveProgram := FALSE;
				Step := WAIT_SHUTTLE;
				gBottleInPlace_Output:=TRUE;
				BottlesPerPack:=BottlesPerPack+1;
				IF BottlesPerPack>gOrder.bottlesPerPackage THEN
					BottlesPerPack:=1;
				END_IF;
				END_IF;
			ELSE
					Step := INTERRUPT;
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
