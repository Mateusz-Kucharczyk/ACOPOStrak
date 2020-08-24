PROGRAM _INIT
	
	gProcessFinished := TRUE;
	gVisPower := FALSE;
   
	// Adding Shuttles for simulation
	FOR i := 1 TO NUM_SIM_SHUTTLES DO
		SimShuttlePosition[i] := 0.15 * (i - 1);
	END_FOR
	
	//   Setting init trak speed
	gTrakAsm.Parameter.Velocity := 2.0;
	gTrakAsm.Parameter.Acceleration := 20;
	gTrakAsm.Parameter.Deceleration := 20;
   
   
	//Write this value into the Size of Userdata in the Shuttle Stereotype configuration
	SizeofUserdata := SIZEOF(gShuttleUserData);
   
	//Assembly reference for init configuration
	MC_BR_AsmPowerOn_AcpTrak_0.Assembly     := ADR(gAssembly_1);
	MC_BR_AsmGetShuttle_AcpTrak_0.Assembly  := ADR(gAssembly_1);
	MC_BR_AsmPowerOff_AcpTrak_0.Assembly    := ADR(gAssembly_1);
	MC_BR_AsmReadStatus_AcpTrak_0.Assembly  := ADR(gAssembly_1);
	MC_BR_AsmReset_AcpTrak_0.Assembly       := ADR(gAssembly_1);
   
	//Enable reading of current status of the assembly
	MC_BR_AsmReadStatus_AcpTrak_0.Enable := TRUE;
   
	// Setting timer for Pouring_Down/Up and Capping
	TON_Pouring_Top.IN:=FALSE;
	TON_Pouring_Down.IN:=FALSE;
	TON_Capping.IN:=FALSE;
   
END_PROGRAM
 
PROGRAM _CYCLIC
	
		
	// Turn off Shuttle read info and execute it
	MC_BR_ShReadInfo_AcpTrak_0.Enable     :=FALSE;
	MC_BR_ShReadInfo_AcpTrak_0();
   
	
	
	
	// Turn off absolute movement of Shuttle and execute it
	MC_BR_RoutedMoveAbs_AcpTrak_0.Execute := FALSE;
	MC_BR_RoutedMoveAbs_AcpTrak_0();
	MC_BR_RoutedMoveVel_AcpTrak_0.Execute:=FALSE;
	MC_BR_RoutedMoveVel_AcpTrak_0();
	CASE Step OF
   
		// Assemply power off and waiting for power on command
		POWER_OFF:
			VisTrakStates:=0;
			// When power off is done, delete the shuttle reference
			IF EDGEPOS(MC_BR_AsmPowerOff_AcpTrak_0.Done) THEN    
				MC_BR_AsmPowerOff_AcpTrak_0.Execute := FALSE;
				brsmemset(ADR(ShuttleAxis), 0, SIZEOF(ShuttleAxis));
				// Assembly is not powered off yet
			ELSIF NOT(gTrakAsm.Status.Disabled) THEN        
				MC_BR_AsmPowerOff_AcpTrak_0.Execute := TRUE;
			ELSIF (gTrakAsm.Command.Power) THEN
				Step := POWER_ON;
			END_IF
 
			// Assembly power ON
		POWER_ON:
			VisTrakStates:=1;
			MC_BR_AsmPowerOn_AcpTrak_0.Execute := TRUE;
           
			IF EDGEPOS(MC_BR_AsmPowerOn_AcpTrak_0.Done)THEN
				CntShuttle := 1;
				VisCappingStates:=1;
				VisPouringStates[0]:=1;
				VisPouringStates[1]:=1;
				IF NOT(Shuttles_exist) THEN
					Step := ADD_SHUTTLE;
				ELSE
					Step := READY;
				END_IF
			END_IF
           
			// Adding Shuttles for simulation
		ADD_SHUTTLE:
			IF (MC_BR_SecAddShuttle_AcpTrak_0.Done) THEN
				CntShuttle := CntShuttle + 1;
               
			ELSIF (CntShuttle <= NUM_SIM_SHUTTLES) THEN
				MC_BR_SecAddShuttle_AcpTrak_0.Sector   := ADR(SectorBottleInput);
				MC_BR_SecAddShuttle_AcpTrak_0.Execute  := TRUE;
				MC_BR_SecAddShuttle_AcpTrak_0.Position := SimShuttlePosition[CntShuttle];
				MC_BR_SecAddShuttle_AcpTrak_0.AdvancedParameters.Velocity := 0.0;
			ELSE
				CntShuttle := 1;
				Step := GET_SHUTTLE;
			END_IF
       
			// Get all availableJadded ones in the simulation
		GET_SHUTTLE:
           
			MC_BR_AsmGetShuttle_AcpTrak_0.Enable := TRUE;
			IF (MC_BR_AsmGetShuttle_AcpTrak_0.Valid) THEN
				IF (MC_BR_AsmGetShuttle_AcpTrak_0.RemainingCount <> (MC_BR_AsmGetShuttle_AcpTrak_0.TotalCount - CntShuttle)) THEN
					CntShuttle := CntShuttle + 1;
					MC_BR_AsmGetShuttle_AcpTrak_0.Next := FALSE;
				ELSE
					//Save all Axis References to an array for global movement commands*)
					ShuttleAxis[CntShuttle] := MC_BR_AsmGetShuttle_AcpTrak_0.Axis;
					// Get next Shuttle reference with positive Edge on .next
					MC_BR_AsmGetShuttle_AcpTrak_0.Next := TRUE;  
               
					IF (MC_BR_AsmGetShuttle_AcpTrak_0.RemainingCount = 0) THEN
						MC_BR_AsmGetShuttle_AcpTrak_0.Enable := FALSE;
						MC_BR_AsmGetShuttle_AcpTrak_0.Next := FALSE;
						Shuttles_exist := TRUE;
						CntShuttle:=0;
						Step := READY;
					END_IF
				END_IF
			END_IF
       
			// Active track and ready for command
		READY:
			VisTrakStates:=2;
			// Power off command
			ManualShuttleReset:=0;
			CntShuttle := 1;
			IF (gTrakAsm.Command.Power = FALSE) THEN
				Step := POWER_OFF;
				// Starting main Step - process
			ELSIF VisManual=TRUE THEN
				Step := MANUAL;
			ELSIF (gTrakAsm.Command.ShuttleStart) THEN
				gTrakAsm.Command.ShuttleStart := FALSE;
				VisShuttleStart:=FALSE;
				IF gColorSum=0 THEN
					gColorSum := gOrder.bottlesPerPackage * gOrder.numberOfPackages; 
				END_IF;
				IF gColorSum<>0 THEN
					gProcessFinished := FALSE;
					Step := PROCESS;
				ELSE
					NullOrder:=TRUE;
				END_IF;

			ELSIF 	gTrakAsm.Command.ShuttleStop THEN
				Step:=STOPPING;
				
			END_IF
			IF gPartyOn THEN 
				Step:=DELTA_TURN;
				ManualShuttleReset:=0;
			END_IF;
			// Main Step, where Shattles run
		PROCESS:   

			// if station have no action, its states remain Ready
			IF TON_Pouring_Down.IN THEN
				VisPouringStates[0]:=3;
			ELSE
				VisPouringStates[0]:=2;
			END_IF;
			IF TON_Pouring_Top.IN THEN
				VisPouringStates[1]:=3;
			ELSE
				VisPouringStates[1]:=2;
			END_IF;
			IF TON_Capping.IN THEN
				VisCappingStates:=3;
			ELSE 
				VisCappingStates:=2;
			END_IF;
			VisTrakStates:=3;
			
			FOR ActiveShuttle:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
				MC_BR_ShReadInfo_AcpTrak_0.Enable:=FALSE;
				MC_BR_ShReadInfo_AcpTrak_0();
				MC_BR_ShReadInfo_AcpTrak_0.Axis:= ADR(ShuttleAxis[ActiveShuttle]); //ActiveShuttle
				MC_BR_ShReadInfo_AcpTrak_0.Enable:=TRUE;
				MC_BR_ShReadInfo_AcpTrak_0();
				MC_BR_RoutedMoveAbs_AcpTrak_0.Execute:=FALSE;
				MC_BR_RoutedMoveAbs_AcpTrak_0();
			
				// States of running shuttles
           
				IF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleInput' THEN
					Step_Sector:=Bottle_Input;
					IF NOT(Stop_With_Execution) THEN
						gShuttleInPlace_Input:=TRUE;
					END_IF;

					IF gBottleInPlace_Input=TRUE THEN
						//	BottleVisibility[ActiveShuttle-1]:=TRUE;
						Step_Sector:=WaitPour;
						gBottleInPlace_Input:=FALSE;
						gShuttleInPlace_Input:=FALSE;
					END_IF;
               
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleInput' THEN
					Step_Sector:=Bottle_Input;
               
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitPour' THEN
					Step_Sector:=WaitPour;
					// Pouring arrive
					IF Pouring_Down_Comming=FALSE AND Step_Sector=WaitPour  THEN
						Step_Sector:=Pouring_Down;
					END_IF;
					IF Pouring_Down_Comming=TRUE AND Step_Sector=WaitPour AND Pouring_Top_Comming=FALSE  THEN
						Step_Sector:=Pouring_Top;
					END_IF;
				
				ELSIF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitPour' THEN
					Step_Sector:=WaitPour;
				
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Down' 
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorPouring_Down'
					THEN
					Step_Sector:=Pouring_Down;
               
					//Pouring done and sending shuttle to capping queue
					IF   TON_Pouring_Down.Q THEN
						Pouring_Down_Busy:=FALSE;
						Pouring_Down_Comming:=FALSE;
						Step_Sector:=WaitCap;
						TON_Pouring_Down.IN:=FALSE;
					END_IF
 
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Top'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorPouring_Top'
					THEN
					Step_Sector:=Pouring_Top;
               
					//Pouring done and sending shuttle to capping queue
					IF   TON_Pouring_Top.Q THEN
						Pouring_Top_Busy:=FALSE;
						Pouring_Top_Comming:=FALSE;
						Step_Sector:=WaitCap;
						TON_Pouring_Top.IN:=FALSE;
					END_IF
               
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitCapping' THEN
					Step_Sector:=WaitCap;
      
					// Sending shuttle to capping if its idle
					IF Step_Sector=WaitCap AND Capping_Comming=FALSE AND Capping_Broken = FALSE THEN
						Step_Sector:=Capping;
					END_IF;
				ELSIF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitCapping' THEN
					Step_Sector:=WaitCap;
				
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorCapping'
					THEN
					Step_Sector:=Capping;
               
					// After capping sendig to delivery
					IF  TON_Capping.Q THEN
						Capping_Busy := FALSE;	
						Step_Sector:=Bottle_Output;
						TON_Capping.IN:=FALSE;
						Capping_Comming:=FALSE;
					END_IF
				ELSIF   MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleOutput' THEN
					Step_Sector:=Bottle_Output;
					gShuttleInPlace_Output:=TRUE;
               
					// bottle in place for delivery waiting for signal and then sending shuttle to sector input
					IF gBottleInPlace_Output=TRUE THEN
						//	BottleVisibility[ActiveShuttle-1]:=FALSE;
						Step_Sector:=Bottle_Input;
						gBottleInPlace_Output:=FALSE;
						gShuttleInPlace_Output:=FALSE;
					END_IF;
               	
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleOutput' THEN
					Step_Sector:=Bottle_Output;
				END_IF;

           
				// TON activation
				IF Pouring_Top_Busy=TRUE THEN
					TON_Pouring_Top.IN:=TRUE;
				END_IF;
				IF Pouring_Down_Busy=TRUE THEN
					TON_Pouring_Down.IN:=TRUE;
				END_IF;
				IF Capping_Busy=TRUE THEN
					TON_Capping.IN:=TRUE;
				END_IF;
				//Handling broken stations
				IF Pouring_Down_Broken THEN
					VisPouringStates[0]:=4;
					Pouring_Down_Comming:=TRUE;
					SvgTranform[3]:=2;
				END_IF
				IF EDGENEG(Pouring_Down_Broken) THEN
					Pouring_Down_Comming:=FALSE;
					SvgTranform[3]:=0;
				END_IF;
				IF Pouring_Top_Broken THEN
					VisPouringStates[1]:=4;
					Pouring_Top_Comming:=TRUE;
					SvgTranform[4]:=2;
				END_IF;
				IF EDGENEG(Pouring_Top_Broken) THEN
					Pouring_Top_Comming:=FALSE;
					SvgTranform[4]:=0;
				END_IF;
				IF Capping_Broken THEN
					VisCappingStates:=4;
					Capping_Comming:=TRUE;
					SvgTranform[2]:=2;
				END_IF
				
				
				// Step for active Shuttle
				CASE Step_Sector OF
               
					// Bottle input at Shuttel
					Bottle_Input:
						gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle]:=FALSE;
						gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorBottleInput); 
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305+3.66;
						// Wait for pouring if Pouring_A/_B are busy
					WaitPour:
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorWaitPour);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.6;
                   
						// Pouring bottle in down station  
					Pouring_Down:
						Pouring_Down_Comming:=TRUE;
						IF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Down' THEN
							Pouring_Down_Busy:=TRUE;
							IF NOT (gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle]) THEN
								CASE gOrder.drinkColor OF
									DRINK_COLOR_RED:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 2;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
									DRINK_COLOR_GREEN:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 1;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
									DRINK_COLOR_BLUE:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 3;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
								END_CASE;
							END_IF;
						END_IF;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_Down);
						CASE gOrder.drinkColor OF
							DRINK_COLOR_RED:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.05;
							DRINK_COLOR_GREEN:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.20;
							DRINK_COLOR_BLUE:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.35;
						END_CASE;
						// Pouring bottle in Top station
					Pouring_Top:
						Pouring_Top_Comming   :=TRUE;
						IF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Top' THEN
							Pouring_Top_Busy := TRUE;
							IF NOT (gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle]) THEN
								CASE gOrder.drinkColor OF
									DRINK_COLOR_RED:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 2;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
									DRINK_COLOR_GREEN:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 1;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
									DRINK_COLOR_BLUE:
										gShuttleColor[NUM_SIM_SHUTTLES-ActiveShuttle] := 3;
										gShuttleColored[NUM_SIM_SHUTTLES-ActiveShuttle] := TRUE;
								END_CASE;
							END_IF;
						END_IF;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_Top);
						CASE gOrder.drinkColor OF
							DRINK_COLOR_RED:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.05;
							DRINK_COLOR_GREEN:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.20;
							DRINK_COLOR_BLUE:
								MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.35;
						END_CASE;
                   
						// Wait for capping if Cap station is busy
					WaitCap:
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorWaitCapping);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.5;
                       
						// Capping a bottle
					Capping:
						Capping_Comming  := TRUE;
						IF  MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping' THEN
							Capping_Busy := TRUE;
						END_IF;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorCapping);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
                   
						// Take bottle from Shuttel
					Bottle_Output:
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorBottleOutput);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
				END_CASE;
           
				MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
				MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
				MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
				MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
				MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
				MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
				MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
				MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				MC_BR_RoutedMoveAbs_AcpTrak_0();
				
				IF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.RemainingDistance < 1 
					AND gColorSum=0 AND (MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorBottleInput' OR
					MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorBottleInput') THEN
					ManualShuttleReset:= ManualShuttleReset +1;		
				END_IF;
			END_FOR;
			
			IF Capping_Busy THEN
				IF Capping_Position=350 THEN
					Capping_Rotate:=Capping_Rotate+24;
					IF Capping_Rotate=360 THEN
						Capping_Rotate:=0;
					END_IF;
				ELSE
					Capping_Position:=Capping_Position-5;	
				END_IF;
			ELSE
				IF NOT(Capping_Position=450) THEN
					Capping_Position:=Capping_Position+5;
				END_IF;
			END_IF;
			IF Pouring_Top_Busy THEN
				IF NOT (Pouring_Top_Position=350) THEN
					Pouring_Top_Position:=Pouring_Top_Position-5;
				END_IF;
			ELSE
				IF NOT (Pouring_Top_Position=400) THEN
					Pouring_Top_Position:=Pouring_Top_Position+5;
				END_IF;
			END_IF;
			IF Pouring_Down_Busy THEN
				IF NOT (Pouring_Down_Position=350) THEN
					Pouring_Down_Position:=Pouring_Down_Position-5;
				END_IF;
			ELSE
				IF NOT (Pouring_Down_Position=400) THEN
					Pouring_Down_Position:=Pouring_Down_Position+5;
				END_IF;
			END_IF;
			IF Stop_With_Execution THEN
				ManualShuttleReset:=0;
				FOR ActiveShuttle:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
					MC_BR_ShReadInfo_AcpTrak_0.Enable:=FALSE;
					MC_BR_ShReadInfo_AcpTrak_0();
					MC_BR_ShReadInfo_AcpTrak_0.Axis:= ADR(ShuttleAxis[ActiveShuttle]); //ActiveShuttle
					MC_BR_ShReadInfo_AcpTrak_0.Enable:=TRUE;
					MC_BR_ShReadInfo_AcpTrak_0();
					
					IF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.RemainingDistance < 1 
						AND (MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorBottleInput' OR
						MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorBottleInput') THEN
						ManualShuttleReset:= ManualShuttleReset +1;		
					END_IF;
				END_FOR;
			END_IF;
			IF ManualShuttleReset=NUM_SIM_SHUTTLES THEN
				Step:=READY;
				gProcessFinished := TRUE;
				VisShuttleStart:=FALSE;	
				Stop_With_Execution:=FALSE;
			ELSE
				ManualShuttleReset:=0;
			END_IF
			
			// Stop command
			IF(gTrakAsm.Command.ShuttleStop) OR VisManual=TRUE THEN
				CntShuttle := 1;
				Step := STOPPING;
			END_IF
           
			// Error stop
			IF (MC_BR_RoutedMoveVel_AcpTrak_0.Error) THEN
				MC_BR_AsmReset_AcpTrak_0.Execute := TRUE;
				Step := RESET;
			END_IF
			IF gPartyOn THEN
				Step:=DELTA_TURN;
				ManualShuttleReset:=0;
			END_IF;
			// Machine States
	
	

		MANUAL:
			VisTrakStates:=5;
			IF VisManual=FALSE THEN

				FOR CntShuttle:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute:=FALSE;
					MC_BR_RoutedMoveAbs_AcpTrak_0();
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis         							:= ADR(ShuttleAxis[CntShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute      						 	:= TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector       					 		:= ADR(SectorBottleInput); 
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position     						    := 0.305+3.66;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      						:= gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  						:= gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  						:= gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          						:= 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    						:= mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0();
					MC_BR_ShReadInfo_AcpTrak_0.Enable									:=FALSE;
					MC_BR_ShReadInfo_AcpTrak_0();
					MC_BR_ShReadInfo_AcpTrak_0.Axis 									:=ADR(ShuttleAxis[CntShuttle]);
					MC_BR_ShReadInfo_AcpTrak_0.Enable									:=TRUE;
					MC_BR_ShReadInfo_AcpTrak_0();
					IF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.RemainingDistance < 1.5
						AND  (MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorBottleInput' OR
						MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorBottleInput') THEN
						ManualShuttleReset:= ManualShuttleReset +1;
					END_IF;
				END_FOR;
				IF Pouring_Down_Position<>400 THEN
					IF Pouring_Down_Position<400 THEN
						Pouring_Down_Position:=Pouring_Down_Position+5;
					END_IF;
					IF Pouring_Down_Position>400 THEN
						Pouring_Down_Position:=Pouring_Down_Position-5;
					END_IF;
				END_IF;
				IF Pouring_Top_Position<>400 THEN
					IF Pouring_Top_Position<400 THEN
						Pouring_Top_Position:=Pouring_Top_Position+5;
					END_IF;
					IF Pouring_Down_Position>400 THEN
						Pouring_Top_Position:=Pouring_Top_Position-5;
					END_IF;
				END_IF;
				IF Capping_Position<>400 THEN
					IF Capping_Position<400 THEN
						Capping_Position:=Capping_Position+5;
					END_IF;
					IF Capping_Position>400 THEN
						Capping_Position:=Capping_Position-5;
					END_IF;
				END_IF;
				IF Capping_Rotate<>0 THEN
					Capping_Rotate:=Capping_Rotate-12;
				END_IF;
				IF ManualShuttleReset=NUM_SIM_SHUTTLES AND Capping_Position=400 AND Pouring_Top_Position=400 AND Pouring_Down_Position=400 THEN
					CntShuttle:=1;
					Step := READY;
					Pouring_Top_Comming:=FALSE;
					Pouring_Down_Comming:=FALSE;
					Pouring_Top_Busy:=FALSE;
					Pouring_Down_Busy:=FALSE;
					Capping_Comming:=FALSE;
					Capping_Busy:=FALSE;
					gShuttleInPlace_Input:=FALSE;
					gShuttleInPlace_Output:=FALSE;
					TON_Pouring_Down.IN:=FALSE;
					TON_Pouring_Top.IN:=FALSE;
					
				END_IF;
			ELSE 		// MANUAL TURNED ON
				IF VisCappingRotate THEN
					Capping_Rotate:=Capping_Rotate+12;
					IF Capping_Rotate=360 THEN
						Capping_Rotate:=0;
					END_IF;
				END_IF;
				IF VisCappingAdd AND Capping_Position<500 THEN
					Capping_Position:= Capping_Position+5;
				END_IF;
				IF VisCappingSub AND Capping_Position>200 THEN
					Capping_Position:= Capping_Position-5;
				END_IF;
				IF VisPouringNumber =0 THEN
					IF VisPouringAdd AND Pouring_Top_Position<450 THEN
						Pouring_Top_Position:=Pouring_Top_Position+5;
					END_IF;
					IF VisPouringSub AND Pouring_Top_Position>200 THEN
						Pouring_Top_Position:=Pouring_Top_Position-5;
					END_IF;
				ELSIF VisPouringNumber = 1 THEN
					IF VisPouringAdd AND Pouring_Down_Position<450 THEN
						Pouring_Down_Position:=Pouring_Down_Position+5;
					END_IF;
					IF VisPouringSub AND Pouring_Down_Position>200 THEN
						Pouring_Down_Position:=Pouring_Down_Position-5;
					END_IF;
				END_IF;
				
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute		:=FALSE;
				MC_BR_RoutedMoveVel_AcpTrak_0();
				MC_BR_RoutedMoveVel_AcpTrak_0.Axis			:=ADR(ShuttleAxis[VisShuttle+1]);
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute		:=TRUE;
				IF VisManualSectorTop=TRUE THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector        := ADR(SectorManualTop);
				ELSE
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector        := ADR(SectorManualMain);
				END_IF;
				IF VisMove_Pos THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Velocity      := VisManualVelocity;
				ELSIF VisMove_Neg THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Velocity      := VisManualVelocity;
				ELSE
					MC_BR_RoutedMoveVel_AcpTrak_0.Velocity  := 0.0;
				END_IF;	
				MC_BR_RoutedMoveVel_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
				MC_BR_RoutedMoveVel_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
				MC_BR_RoutedMoveVel_AcpTrak_0.Jerk          := 0.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.BufferMode    := mcABORTING;
				IF VisMove_Pos THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
				ELSE
					MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_NEGATIVE;
				END_IF;
				MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				
				MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
			END_IF
			ManualShuttleReset:=0;

			IF gPartyOn THEN
				Step:=DELTA_TURN;
				ManualShuttleReset:=0;
			END_IF;

		STOPPING:
			VisTrakStates:=4;
			gShuttleInPlace_Input:=FALSE;
			gShuttleInPlace_Output:=FALSE;
			gShuttleInPlace_Turn:=FALSE;
			FOR CntShuttle:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
				MC_BR_ShReadInfo_AcpTrak_0.Enable									:=FALSE;
				MC_BR_ShReadInfo_AcpTrak_0();
				MC_BR_ShReadInfo_AcpTrak_0.Axis 									:=ADR(ShuttleAxis[CntShuttle]);
				MC_BR_ShReadInfo_AcpTrak_0.Enable									:=TRUE;
				MC_BR_ShReadInfo_AcpTrak_0();
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute:=FALSE;
				MC_BR_RoutedMoveVel_AcpTrak_0();
				MC_BR_RoutedMoveVel_AcpTrak_0.Axis         							:= ADR(ShuttleAxis[CntShuttle]);
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute      						 	:= TRUE;
				IF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorBottleInput'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorBottleInput'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorBottleInput); 
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorBottleOutput'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorBottleOutput'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorBottleOutput);
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorWaitPour'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorWaitPour'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorWaitPour);
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorPouring_Down'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorPouring_Down'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorPouring_Down);
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorPouring_Top'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorPouring_Top'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorPouring_Top);
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorWaitCapping'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorWaitCapping'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorWaitCapping);
				ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorCapping'
					OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorCapping'
					THEN
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorCapping);
				END_IF;
				MC_BR_RoutedMoveVel_AcpTrak_0.Position     						    := 0.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.Velocity      						:= 0.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.Acceleration  						:= 35.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.Deceleration  						:= 35.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.Jerk          						:= 0.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.BufferMode    						:= mcABORTING;
				MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
				MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
				MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
				MC_BR_RoutedMoveVel_AcpTrak_0();
			END_FOR;
			VisShuttleStop:=FALSE;
			VisShuttleStart:=FALSE;
			Pouring_Top_Comming				:=FALSE;
			Pouring_Down_Comming			:=FALSE;
			Pouring_Top_Busy				:=FALSE;
			Pouring_Down_Busy				:=FALSE;
			Capping_Comming					:=FALSE;
			Capping_Busy					:=FALSE;
			gShuttleInPlace_Input			:=FALSE;
			gShuttleInPlace_Output			:=FALSE;
			TON_Pouring_Down.IN				:=FALSE;
			TON_Pouring_Top.IN				:=FALSE;
			IF VisManual=TRUE THEN
				Step:=MANUAL;
			ELSE
				Step := READY;	
			END_IF;

			// Reset due to error
		RESET:
			IF EDGEPOS(MC_BR_AsmReset_AcpTrak_0.Done) THEN
				gTrakAsm.Command.ShuttleStart    := FALSE;
				gTrakAsm.Command.ShuttleStop     := FALSE;
				MC_BR_AsmReset_AcpTrak_0.Execute := FALSE;
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute := FALSE;
				Step := READY;
			END_IF
		
		DELTA_TURN:
			IF DeltaInit=TRUE THEN
			
			ELSE
				IF ManualShuttleReset=NUM_SIM_SHUTTLES THEN
					FOR DeltaFor:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute								:=FALSE;
						MC_BR_RoutedMoveAbs_AcpTrak_0();
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis         							:= ADR(ShuttleAxis[DeltaFor]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector       					 		:= ADR(SectorManualTop); 
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute								:= TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position     						    := 1.4*DeltaFor;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      						:= 1.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  						:= 5.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  						:= 5.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          						:= 0.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    						:= mcABORTING;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
						IF DeltaFor>8 THEN
							MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
						ELSE
							MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_NEGATIVE;
						END_IF;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
						IF TON_Delta.Q=FALSE THEN
							MC_BR_RoutedMoveAbs_AcpTrak_0();
						END_IF;
						gShuttleColor[DeltaFor] := 3;
						IF gShuttleColor[DeltaFor-1]=3 THEN
							gShuttleColor[DeltaFor] := 1;
						ELSE
							gShuttleColor[DeltaFor] := 3;
						END_IF;
					END_FOR;
					TON_Delta.IN:=TRUE;
					Step:=DELTA_MOVE;
				ELSE
					ManualShuttleReset:=0;
					FOR DeltaFor:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute								:=FALSE;
						MC_BR_RoutedMoveAbs_AcpTrak_0();
						MC_BR_RoutedMoveAbs_AcpTrak_0.Axis         							:= ADR(ShuttleAxis[DeltaFor]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute      						 	:= TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector       					 		:= ADR(SectorWaitPour); 
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position     						    := 0.5;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      						:= 4;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  						:= 40.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  						:= 40.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          						:= 0.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    						:= mcABORTING;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
						MC_BR_RoutedMoveAbs_AcpTrak_0();
						MC_BR_ShReadInfo_AcpTrak_0.Enable									:=FALSE;
						MC_BR_ShReadInfo_AcpTrak_0();
						MC_BR_ShReadInfo_AcpTrak_0.Axis 									:=ADR(ShuttleAxis[DeltaFor]);
						MC_BR_ShReadInfo_AcpTrak_0.Enable									:=TRUE;
						MC_BR_ShReadInfo_AcpTrak_0();
						IF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.RemainingDistance < 0.7
							AND (MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName='SectorWaitPour' OR
							MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorWaitPour') THEN
							ManualShuttleReset:= ManualShuttleReset +1;
						END_IF;
					END_FOR;
				END_IF;
			
			END_IF;
			// Stop command
			IF(gTrakAsm.Command.ShuttleStop) OR VisManual=TRUE THEN
				CntShuttle := 1;
				Step := STOPPING;
			END_IF
           
			// Error stop
			IF (MC_BR_RoutedMoveVel_AcpTrak_0.Error) THEN
				MC_BR_AsmReset_AcpTrak_0.Execute := TRUE;
				Step := RESET;
			END_IF
			IF NOT(gPartyOn) THEN
				Step:=MANUAL;
			END_IF;
			gVisPower:=TRUE;
		
		DELTA_MOVE:
			IF TON_Delta.Q THEN
				//		DeltaInit:=TRUE;
				FOR DeltaFor:=NUM_SIM_SHUTTLES TO 1 BY -1 DO
					MC_BR_RoutedMoveVel_AcpTrak_0.Execute								:=FALSE;
					MC_BR_RoutedMoveVel_AcpTrak_0();
					MC_BR_RoutedMoveVel_AcpTrak_0.Axis         							:= ADR(ShuttleAxis[DeltaFor]);
					MC_BR_RoutedMoveVel_AcpTrak_0.Sector       					 		:= ADR(SectorManualTop); 
					MC_BR_RoutedMoveVel_AcpTrak_0.Execute								:= TRUE;
					MC_BR_RoutedMoveVel_AcpTrak_0.Position     						    := 0.0;
					MC_BR_RoutedMoveVel_AcpTrak_0.Velocity      						:= 4.0;
					MC_BR_RoutedMoveVel_AcpTrak_0.Acceleration  						:= 0.1;
					MC_BR_RoutedMoveVel_AcpTrak_0.Deceleration  						:= gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveVel_AcpTrak_0.Jerk          						:= 0.0;
					MC_BR_RoutedMoveVel_AcpTrak_0.BufferMode    						:= mcABORTING;
					MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_NEGATIVE;
					MC_BR_RoutedMoveVel_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveVel_AcpTrak_0();
				END_FOR;
				IF gShuttleColor[Delta_Shuttle]=3 THEN
					gShuttleColor[Delta_Shuttle] := 1;
				ELSE
					gShuttleColor[Delta_Shuttle] := 3;
				END_IF;
				Delta_Shuttle:=Delta_Shuttle +1;
				IF Delta_Shuttle=NUM_SIM_SHUTTLES+2 THEN
					Delta_Shuttle:=0;
				END_IF;
			END_IF;
			IF(gTrakAsm.Command.ShuttleStop) OR VisManual=TRUE THEN
				CntShuttle := 1;
				Step := STOPPING;
			END_IF
           
			// Error stop
			IF (MC_BR_RoutedMoveVel_AcpTrak_0.Error) THEN
				MC_BR_AsmReset_AcpTrak_0.Execute := TRUE;
				Step := RESET;
			END_IF
			IF NOT(gPartyOn) THEN
				Step:=MANUAL;
			END_IF;
			gVisPower:=TRUE;
	END_CASE
   

	
	
	// Read Assembly status cyclic to Assembly interface
	gTrakAsm.Status.Disabled  := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyDisabled;
	gTrakAsm.Status.Ready     := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyReady;
	gTrakAsm.Status.Homing    := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyHoming;
	gTrakAsm.Status.Stopping  := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyStopping;
	gTrakAsm.Status.ErrorStop := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop;
   
	// Cyclic init functions execute
	MC_BR_AsmPowerOn_AcpTrak_0();
	MC_BR_AsmPowerOn_AcpTrak_0.Execute := FALSE;
	MC_BR_SecAddShuttle_AcpTrak_0();
	MC_BR_SecAddShuttle_AcpTrak_0.Execute := FALSE;
	MC_BR_AsmGetShuttle_AcpTrak_0();
	MC_BR_AsmPowerOff_AcpTrak_0();
	MC_Stop_0();
	MC_BR_RoutedMoveVel_AcpTrak_0();
	MC_BR_AsmReadStatus_AcpTrak_0();
	MC_BR_AsmReset_AcpTrak_0();
	MC_BR_RoutedMoveVel_AcpTrak_0();
   
	// Timers functions
	TON_Pouring_Top();
	TON_Pouring_Down();
	TON_Delta();
	TON_Capping();
	
	//Updating values of vel or states with actual data in Visualisation
	gTrakAsm.Command.Power					:=gVisPower;
	gTrakAsm.Command.ShuttleStart			:=VisShuttleStart;
	gTrakAsm.Command.ShuttleStop 			:=VisShuttleStop;
	Pouring_Top_Broken 						:=NOT(VisPouring_Top_Broken);
	Pouring_Down_Broken						:=NOT(VisPouring_Down_Broken);
	Capping_Broken							:=NOT(VisCapping_Broken);
	gTrakAsm.Parameter.Velocity				:=VisVelocity;
	gTrakAsm.Parameter.Acceleration			:=VisAcceleration;
	gTrakAsm.Parameter.Deceleration			:=VisDeceleration;
	
	
	
	
	CASE gOrder.bottleSize OF
		BOTTLE_SIZE_SMALL:
			TON_Pouring_Down.PT 			:=REAL_TO_TIME(1000*VisPouring_Time_Small);
			TON_Pouring_Top.PT				:=REAL_TO_TIME(1000*VisPouring_Time_Small);
		BOTTLE_SIZE_LARGE:
			TON_Pouring_Down.PT 			:=REAL_TO_TIME(1000*VisPouring_Time_Large);
			TON_Pouring_Top.PT				:=REAL_TO_TIME(1000*VisPouring_Time_Large);
	END_CASE;
	
	
	// Handling Broken stations
	IF EDGENEG(Capping_Broken) THEN
		Capping_Comming:=FALSE;
		SvgTranform[2]:=0;
	END_IF;
	IF gVisInput_Broken THEN
		SvgTranform[0]:=0;
	END_IF
	IF NOT (gVisInput_Broken) THEN
		SvgTranform[0]:=2;	
	END_IF;
	IF gVisOutput_Broken THEN
		SvgTranform[1]:=0;
	END_IF
	IF NOT (gVisOutput_Broken) THEN
		SvgTranform[1]:=2;	
	END_IF;
	
					END_PROGRAM
 
PROGRAM _EXIT
					(* Insert code here *)
     
	END_PROGRAM