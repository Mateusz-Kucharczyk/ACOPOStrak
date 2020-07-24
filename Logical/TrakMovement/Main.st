
PROGRAM _INIT
	
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
	TON_Pouring_Top.PT:=T#5s;
	TON_Pouring_Top.IN:=FALSE;
	TON_Pouring_Down.PT:=T#5s;
	TON_Pouring_Down.IN:=FALSE;
	TON_Capping.PT:=T#2s;
	TON_Capping.IN:=FALSE;
	
END_PROGRAM

PROGRAM _CYCLIC
	
	// Turn off Shuttle read info and execute it 
	MC_BR_ShReadInfo_AcpTrak_0.Enable	  :=FALSE;
	MC_BR_ShReadInfo_AcpTrak_0();
	
	// Turn off absolute movement of Shuttle and execute it 
	MC_BR_RoutedMoveAbs_AcpTrak_0.Execute := FALSE;
	MC_BR_RoutedMoveAbs_AcpTrak_0();
	
	CASE Step OF
    
		// Assemply power off and waiting for power on command
		POWER_OFF:
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
			
			MC_BR_AsmPowerOn_AcpTrak_0.Execute := TRUE;
            
			IF EDGEPOS(MC_BR_AsmPowerOn_AcpTrak_0.Done)THEN
				CntShuttle := 1;
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
						Step := READY;
					END_IF
				END_IF
			END_IF
        
		// Active track and ready for command
		READY:
			// Power off command
			IF (gTrakAsm.Command.Power = FALSE) THEN
				Step := POWER_OFF;
			// Starting main Step - process 
			ELSIF (gTrakAsm.Command.ShuttleStart) THEN 
				gTrakAsm.Command.ShuttleStart := FALSE;
				CntShuttle := 1;
				Step := PROCESS;
			END_IF
   
		// Main Step, where Shattles run
		PROCESS:	
			
			MC_BR_ShReadInfo_AcpTrak_0.Axis:= ADR(ShuttleAxis[ActiveShuttle]); //ActiveShuttle
			MC_BR_ShReadInfo_AcpTrak_0.Enable:=TRUE;
			MC_BR_ShReadInfo_AcpTrak_0();
			
			// States of running shuttles
			
			IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleInput' THEN
				Step_Sector:=Bottle_Input;
				ShuttleInPlace_Input:=TRUE;
				IF BottleInPlace_Input=TRUE THEN
					Step_Sector:=WaitPour;
					BottleInPlace_Input:=FALSE;
					ShuttleInPlace_Input:=FALSE;
				END_IF;
				
			ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleInput' THEN
				Step_Sector:=Bottle_Input;
				
			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitPour'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitPour'
				THEN
				Step_Sector:=WaitPour;
				
				// Pouring arrive
				IF Pouring_Down_Comming=FALSE AND Step_Sector=WaitPour  THEN 
					Step_Sector:=Pouring_Down;
				END_IF;
				IF Pouring_Down_Comming=TRUE AND Step_Sector=WaitPour AND Pouring_Top_Comming=FALSE  THEN 
					Step_Sector:=Pouring_Top;
				END_IF;
			
			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Down'
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

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Top'
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
				
			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitCapping'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitCapping'
				THEN
				Step_Sector:=WaitCap;
				
				// Sending shuttle to capping if its idle
				IF Step_Sector=WaitCap AND Capping_Comming=FALSE AND Capping_Broken = FALSE THEN
					Step_Sector:=Capping;
				END_IF;

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorCapping'
				THEN
				Step_Sector:=Capping;
				
				// After capping sendig to delivery
				IF   TON_Capping.Q THEN
					Capping_Busy := FALSE;
					Step_Sector:=Bottle_Output;
					TON_Capping.IN:=FALSE;
					Capping_Comming:=FALSE;
				END_IF

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleOutput' THEN
				Step_Sector:=Bottle_Output;
				ShuttleInPlace_Output:=TRUE;
				
				// bottle in place for delivery waiting for signal and then sending shuttle to sector input
				IF BottleInPlace_Output=TRUE THEN
					Step_Sector:=Bottle_Input;
					BottleInPlace_Output:=FALSE;
					ShuttleInPlace_Output:=FALSE;
				END_IF;
				
			ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleOutput' THEN
				Step_Sector:=Bottle_Output;
			END_IF;
			
			// Handling Broken stations
			IF Pouring_Down_Broken THEN
				Pouring_Down_Comming:=TRUE;
			END_IF
			IF EDGENEG(Pouring_Down_Broken) THEN
				Pouring_Down_Comming:=FALSE;
			END_IF;
			IF Pouring_Top_Broken THEN
				Pouring_Top_Comming:=TRUE;
			END_IF;
			IF EDGENEG(Pouring_Down_Broken) THEN
				Pouring_Down_Comming:=FALSE;
			END_IF;
			IF Capping_Broken THEN
				Capping_Comming:=TRUE;
			END_IF
			IF EDGENEG(Capping_Broken) THEN
				Capping_Comming:=FALSE;
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
			
			// Step for active Shuttle 
			CASE Step_Sector OF
				
				// Bottle input at Shuttel
				Bottle_Input:
					gShuttleColor[10-ActiveShuttle] := 0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorBottleInput);	
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305+3.66;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
				// Wait for pouring if Pouring_A/_B are busy
				WaitPour:
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorWaitPour);	
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.6;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
				// Pouring bottle in down station	
				Pouring_Down:
					Pouring_Down_Comming:=TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Down' THEN
						Pouring_Down_Busy:=TRUE;
						IF gColorGreen > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 1;
							gColorGreen := gColorGreen - 1;
						ELSIF gColorRed > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 2;
							gColorRed := gColorRed - 1;
						ELSIF gColorBlue > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 3;
							gColorBlue := gColorBlue - 1;
						END_IF;
					END_IF;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_Down);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
				// Pouring bottle in Top station
				Pouring_Top:
					Pouring_Top_Comming   :=TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_Top' THEN
						Pouring_Top_Busy := TRUE;
						IF gColorGreen > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 1;
							gColorGreen := gColorGreen - 1;
						ELSIF gColorRed > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 2;
							gColorRed := gColorRed - 1;
						ELSIF gColorBlue > 0 THEN
							gShuttleColor[10-ActiveShuttle] := 3;
							gColorBlue := gColorBlue - 1;
						END_IF;
					END_IF;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_Top);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
				// Wait for capping if Cap station is busy
				WaitCap:
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorWaitCapping);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.5;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
						
				// Capping a bottle
				Capping:
					Capping_Comming  := TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping' THEN
						Capping_Busy := TRUE;
					END_IF;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorCapping);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
				// Take bottle from Shuttel
				Bottle_Output:
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorBottleOutput);
					MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
					MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
					MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
			END_CASE;
			
			// Stop command
			IF(gTrakAsm.Command.ShuttleStop) AND (ActiveShuttle > NUM_SIM_SHUTTLES) THEN
				CntShuttle := 1;
				Step := STOPPING;
			END_IF
            
			// Error stop
			IF (MC_BR_RoutedMoveVel_AcpTrak_0.Error) THEN
				MC_BR_AsmReset_AcpTrak_0.Execute := TRUE;
				Step := RESET;
			END_IF

		STOPPING:
			IF EDGEPOS(MC_Stop_0.Done) THEN
				CntShuttle := CntShuttle + 1;
				MC_Stop_0.Execute := FALSE;
			ELSIF (ShuttleAxis[CntShuttle].controlif <> 0) AND NOT(MC_Stop_0.Busy) THEN
				MC_Stop_0.Axis         := ADR(ShuttleAxis[CntShuttle]);
				MC_Stop_0.Execute      := TRUE;
				MC_Stop_0.Deceleration := 20;
				MC_Stop_0.Jerk         := 0.0;
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute := FALSE;
			END_IF
        
			IF EDGEPOS(MC_Stop_0.Done) AND (CntShuttle > NUM_SIM_SHUTTLES) THEN (* Back to ready, after every shuttle on the trak has stopped *)
				gTrakAsm.Command.ShuttleStop := FALSE;
				Step := READY;
			END_IF
        
		// Reset due to error
		RESET:
			IF EDGEPOS(MC_BR_AsmReset_AcpTrak_0.Done) THEN
				gTrakAsm.Command.ShuttleStart    := FALSE;
				gTrakAsm.Command.ShuttleStop     := FALSE;
				MC_BR_AsmReset_AcpTrak_0.Execute := FALSE;
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute := FALSE;
				Step := READY;
			END_IF
        
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
	MC_BR_RoutedMoveAbs_AcpTrak_0();
	
	// Timers functions
	TON_Pouring_Top();
	TON_Pouring_Down();
	TON_Capping();
	


	
	// Decrease acctual running shuttle
	ActiveShuttle:=ActiveShuttle-1;	
	IF ActiveShuttle=0 THEN
		ActiveShuttle:=NUM_SIM_SHUTTLES;
	END_IF;
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

