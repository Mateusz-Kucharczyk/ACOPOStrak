PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaAOut); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0; 

	DeltaParameters.ProgramName:='RoboticOut.st';
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;
	BottleOutStage:=0;
END_PROGRAM

PROGRAM _CYCLIC
	IF gProcessFinished THEN
		FOR i:=5 TO 0 BY -1 DO
			StashBottleVis[i]:=FALSE;
		END_FOR;
		Bottle:=1;
		BottlesPerPack:=1;
	END_IF;
	MpDelta3Axis_0.Override:=gDeltaVelocity;
	//DeltaParameters.ProgramName := PName;
	MpDelta3Axis_0.ErrorReset := diErrorReset;
	
	IF EDGEPOS(MpDelta3Axis_0.Error) THEN
		Step := ERROR;
	END_IF;
	IF VisManual THEN
		Step:=MANUAL;
	END_IF

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
			VisDeltaOutState:=1;
			IF MpDelta3Axis_0.PowerOn THEN
				Step := HOME;
			END_IF;
		HOME:
			MpDelta3Axis_0.Home := TRUE;
			
			IF MpDelta3Axis_0.IsHomed THEN
				Step := WAIT_SHUTTLE;
			END_IF;
		WAIT_SHUTTLE:
			BottleOutStage:=0;
			IF MpDelta3Axis_0.Home=FALSE  THEN
				MpDelta3Axis_0.Home:=TRUE;
			END_IF;
			VisDeltaOutState:=2;
			IF ProgressBar > 99 AND diStart THEN
				gBottlesDone := 0;
				ProgressBar := 0;
			END_IF;
			
			IF gShuttleInPlace_Output THEN
				Step := MOVE_PROGRAM;
				BottleOutStage:=1;
				gBottlesDone := gBottlesDone+1;
				ProgressBar := 100*gBottlesDone/gOrder.bottlesPerPackage/gOrder.numberOfPackages;
			END_IF;
			IF gTrakAsm.Command.Power=FALSE THEN
				Step:=STOP;
			END_IF;
		MOVE_PROGRAM:
			IF MpDelta3Axis_0.Z=-700 AND MpDelta3Axis_0.Y=200 AND BottleOutStage=1 THEN
				BottleOutStage:=2;
			END_IF;
			IF NOT(MpDelta3Axis_0.Z=-700 AND MpDelta3Axis_0.Y=200) AND MpDelta3Axis_0.PathVelocity=0 AND BottleOutStage=2 THEN
				BottleOutStage:=3;
			END_IF;
			IF Bottle=gOrder.bottlesPerPackage THEN
				BottleInvisible:=TRUE;
			END_IF;
			diStart := FALSE;
			VisDeltaOutState:=3;
			IF gVisOutput_Broken THEN
				IF gOrder.bottlesPerPackage = 4 THEN
					CASE BottlesPerPack OF
						
						1:	Bottle:=1;
							
						2:	Bottle:=2;
						
						3:	Bottle:=5;
						
						4:	Bottle:=4;
						
					END_CASE;
				ELSE
					CASE BottlesPerPack OF
						
						1:	Bottle:=1;
								
						2:	Bottle:=2;
							
						3:	Bottle:=3;
							
						4:	Bottle:=4;
							
						5:	Bottle:=5;
							
						6:	Bottle:=6;
						
					END_CASE;
				END_IF;
				MpDelta3Axis_0.MoveProgram := TRUE;			
				IF MpDelta3Axis_0.MoveDone THEN
					BottlesPerPack:=BottlesPerPack+1;
					MpDelta3Axis_0.MoveProgram := FALSE;
					Step := WAIT_SHUTTLE;
					gBottleInPlace_Output:=TRUE;
					BottleOutStage:=0;
					IF BottleInvisible THEN
						BottleInvisible:=FALSE;
						BottlesPerPack:=1;
						Bottle:=1;
						FOR i:=5 TO 0 BY -1 DO
							StashBottleVis[i]:=FALSE;
						END_FOR;
					END_IF;
				END_IF;
			ELSE
				Step := INTERRUPT;
				MpDelta3Axis_0.Continue := FALSE;
			END_IF;
			IF gTrakAsm.Command.Power=FALSE THEN
				Step:=STOP;
			END_IF;
		INTERRUPT:
			MpDelta3Axis_0.Interrupt := TRUE;
			VisDeltaOutState:=4;
			IF EDGEPOS (gVisOutput_Broken) THEN
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
		
			MpDelta3Axis_0.MoveProgram := FALSE;
			MpDelta3Axis_0.ErrorReset := TRUE;
			
			IF NOT(MpDelta3Axis_0.Error) THEN
				Step := WAIT_SHUTTLE;
				MpDelta3Axis_0.ErrorReset := FALSE;
			END_IF;
			
		MANUAL:
			MpDelta3Axis_0.Override:=100;
			gDeltaVelocity:=100;
			MpDelta3Axis_0.Jog:=TRUE;
			IF VisDeltaNumber = 1 THEN
				IF VisDeltaInJogXAdd THEN
					DeltaParameters.Jog.Velocity[0]:=VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogXAdd) THEN
					DeltaParameters.Jog.Velocity[0]:=0.0;
				END_IF;
				IF VisDeltaInJogXSub THEN
					DeltaParameters.Jog.Velocity[0]:=-VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogXSub) THEN
					DeltaParameters.Jog.Velocity[0]:=0.0;
				END_IF;
				IF VisDeltaInJogYAdd THEN
					DeltaParameters.Jog.Velocity[1]:=VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogYAdd) THEN
					DeltaParameters.Jog.Velocity[1]:=0.0;
				END_IF;
				IF VisDeltaInJogYSub THEN
					DeltaParameters.Jog.Velocity[1]:=-VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogYSub) THEN
					DeltaParameters.Jog.Velocity[1]:=0.0;
				END_IF;
				IF VisDeltaInJogZAdd THEN
					DeltaParameters.Jog.Velocity[2]:=VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogZAdd) THEN
					DeltaParameters.Jog.Velocity[2]:=0.0;
				END_IF;
				IF VisDeltaInJogZSub THEN
					DeltaParameters.Jog.Velocity[2]:=-VisDeltaVelocity;
				END_IF;
				IF EDGENEG(VisDeltaInJogZSub) THEN
					DeltaParameters.Jog.Velocity[2]:=0.0;
				END_IF;
			END_IF;
			IF gTrakAsm.Command.Power=FALSE THEN
				Step:=STOP;
			END_IF;
		
	END_CASE;
	IF MpDelta3Axis_0.PathVelocity>0 AND BottleOutStage=3 THEN
		BottleOutStage:=0;
	END_IF;
	CASE BottleOutStage OF
		0:DeltaOutBottleVisibility:=FALSE;
			DeltaOutBottleShutVis:=FALSE;
		1:DeltaOutBottleVisibility:=FALSE;
			DeltaOutBottleShutVis:=TRUE;
		2:DeltaOutBottleVisibility:=TRUE;
			DeltaOutBottleShutVis:=FALSE;			
		3:DeltaOutBottleVisibility:=FALSE;
			StashBottleVis[Bottle-1]:=TRUE;				

	END_CASE;
	IF Step=MANUAL AND VisManual=FALSE THEN
		MpDelta3Axis_0.Jog:=FALSE;
		IF MpDelta3Axis_0.Home=FALSE THEN
			//MpDelta3Axis_0.Home:=TRUE;
			Step:=WAIT_SHUTTLE;
		ELSE
			MpDelta3Axis_0.Home:=FALSE;
		END_IF;
	END_IF;
	ZOffset:=MpDelta3Axis_0.Info.JointAxisPosition[2] -160;		
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
