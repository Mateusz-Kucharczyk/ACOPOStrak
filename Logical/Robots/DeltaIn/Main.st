PROGRAM _INIT

	MpDelta3Axis_0.MpLink := ADR(g3AxDeltaA); 
	MpDelta3Axis_0.Enable := TRUE; 
	MpDelta3Axis_0.Parameters := ADR(DeltaParameters); 

	MpDelta3Axis_0.Override := 100.0;
	DeltaParameters.Velocity := 5.0;
	DeltaParameters.Acceleration := 50.0;
	Step := INIT;
	VisManual:=FALSE;
	BottleInStage:=0;
END_PROGRAM

PROGRAM _CYCLIC
    
	MpDelta3Axis_0.Override:=gDeltaVelocity;
	
	IF gdiInstantStop THEN
		Step:=STOP;
	END_IF;
	
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
			VisDeltaInState:=1;
			IF MpDelta3Axis_0.PowerOn THEN
				Step:= HOME;
			END_IF;
		HOME:
			MpDelta3Axis_0.Home := TRUE;
			IF MpDelta3Axis_0.IsHomed THEN
				Step := WAIT_SHUTTLE;

			END_IF;
		WAIT_SHUTTLE:	
			BottleInStage:=0;
			IF MpDelta3Axis_0.Home=FALSE  THEN
				MpDelta3Axis_0.Home:=TRUE;
			END_IF;
			VisDeltaInState:=2;
			MpDelta3Axis_0.MoveProgram := 0;
			IF gShuttleInPlace_Input AND NOT gdiStop  THEN
				Step := MOVE_PROGRAM;
				DeltaParameters.ProgramName := 'RoboticIn.st';    //File stored on FileDevice
			END_IF;
			
		MOVE_PROGRAM:
			IF MpDelta3Axis_0.Z=-700 AND MpDelta3Axis_0.Y=-200 THEN
	  			BottleInStage:=1;
			END_IF;
			IF MpDelta3Axis_0.Z=-700 AND MpDelta3Axis_0.Y=200 THEN
				BottleInStage:=2;
			END_IF;
			VisDeltaInState:=3;
			IF gVisInput_Broken THEN
				IF gColorSum >0 THEN
					MpDelta3Axis_0.MoveProgram :=TRUE;
					IF MpDelta3Axis_0.MoveDone THEN
						gColorSum := gColorSum - 1;
						Step:= WAIT_SHUTTLE;
						gBottleInPlace_Input:=TRUE;

					END_IF;
					IF diInterrupt THEN
						Step := INTERRUPT;
						MpDelta3Axis_0.Continue := FALSE;
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
			VisDeltaInState:=4;
			MpDelta3Axis_0.Interrupt := TRUE;
			IF NOT (diInterrupt) OR EDGEPOS(gVisInput_Broken) THEN
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
			IF VisDeltaNumber = 0 THEN
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
	IF Step=MANUAL AND VisManual=FALSE THEN
		MpDelta3Axis_0.Jog:=FALSE;
		IF MpDelta3Axis_0.Home=FALSE THEN
			//MpDelta3Axis_0.Home:=TRUE;
			Step:=WAIT_SHUTTLE;
		ELSE
			MpDelta3Axis_0.Home:=FALSE;
		END_IF;
	END_IF;
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
