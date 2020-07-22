
PROGRAM _INIT
	(* Insert code here *)
	FOR i := 1 TO NUM_SIM_SHUTTLES DO
		SimShuttlePosition[i] := 0.15 * (i - 1);
	END_FOR
	
	//   Trak speed
	gTrakAsm.Parameter.Velocity := 2.0;
	gTrakAsm.Parameter.Acceleration := 20;
	gTrakAsm.Parameter.Deceleration := 20;
	//  Trak speed end
	
	(* Write this value into the Size of Userdata in the Shuttle Stereotype configuration *)
	SizeofUserdata := SIZEOF(gShuttleUserData);
	
	(* Assembly reference for FUB's *)
	MC_BR_AsmPowerOn_AcpTrak_0.Assembly     := ADR(gAssembly_1);
	MC_BR_AsmGetShuttle_AcpTrak_0.Assembly  := ADR(gAssembly_1);
	MC_BR_AsmPowerOff_AcpTrak_0.Assembly    := ADR(gAssembly_1);
	MC_BR_AsmReadStatus_AcpTrak_0.Assembly  := ADR(gAssembly_1);
	MC_BR_AsmReset_AcpTrak_0.Assembly       := ADR(gAssembly_1);
	(* Enable reading of current status of the assembly *)
	MC_BR_AsmReadStatus_AcpTrak_0.Enable := TRUE;
	MC_BR_SecGetShuttle_AcpTrak_B.Sector := ADR(SectorPouring_B);
	MC_BR_SecGetShuttle_AcpTrak_A.Sector := ADR(SectorPouring_A);
	MC_BR_SecGetShuttle_AcpTrak_Cap.Sector := ADR(SectorCapping);
	TON_Pouring_B.PT:=T#5s;
	TON_Pouring_B.IN:=FALSE;
	TON_Pouring_A.PT:=T#5s;
	TON_Pouring_A.IN:=FALSE;
	TON_Capping.PT:=T#2s;
	TON_Capping.IN:=FALSE;
END_PROGRAM

PROGRAM _CYCLIC
	
	MC_BR_ShReadInfo_AcpTrak_0.Enable:=FALSE;
	MC_BR_ShReadInfo_AcpTrak_0();
	MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := FALSE;
	MC_BR_RoutedMoveAbs_AcpTrak_0();
	
	CASE Step OF
    
		(*        Assemply power off and waiting for power on command        *)
		POWER_OFF:
			
			IF EDGEPOS(MC_BR_AsmPowerOff_AcpTrak_0.Done) THEN    (* When power off is done, delete the shuttle reference *)
				MC_BR_AsmPowerOff_AcpTrak_0.Execute := FALSE;
				brsmemset(ADR(ShuttleAxis), 0, SIZEOF(ShuttleAxis));
			ELSIF NOT(gTrakAsm.Status.Disabled) THEN             (* Assembly is not powered off yet *)
				MC_BR_AsmPowerOff_AcpTrak_0.Execute := TRUE;
			ELSIF (gTrakAsm.Command.Power) THEN
				Step := POWER_ON;
			END_IF

			(*        Assembly power ON        *)
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
            
			(*        Adding Shuttles for simulation (These steps are not needed on real Hardware)        *)
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
        
			(*        Get all available on the assembly (physically available on the real hardware or the added ones in the simulation)        *)
		GET_SHUTTLE:
			
			MC_BR_AsmGetShuttle_AcpTrak_0.Enable := TRUE;
            
			IF (MC_BR_AsmGetShuttle_AcpTrak_0.Valid) THEN
				IF (MC_BR_AsmGetShuttle_AcpTrak_0.RemainingCount <> (MC_BR_AsmGetShuttle_AcpTrak_0.TotalCount - CntShuttle)) THEN
					CntShuttle := CntShuttle + 1;
					MC_BR_AsmGetShuttle_AcpTrak_0.Next := FALSE;
				ELSE
					ShuttleAxis[CntShuttle] := MC_BR_AsmGetShuttle_AcpTrak_0.Axis;    (*Save all Axis References to an array for global movement commands*)
					MC_BR_AsmGetShuttle_AcpTrak_0.Next := TRUE;   (*Get next Shuttle reference with positive Edge on .next*)
                
					IF (MC_BR_AsmGetShuttle_AcpTrak_0.RemainingCount = 0) THEN
						MC_BR_AsmGetShuttle_AcpTrak_0.Enable := FALSE;
						MC_BR_AsmGetShuttle_AcpTrak_0.Next := FALSE;
						Shuttles_exist := TRUE;
						Step := READY;
					END_IF
				END_IF
			END_IF
        
			(*        Assembly Active and ready for movement        *)
		READY:
			
			IF (gTrakAsm.Command.Power = FALSE) THEN     (*Power Off Command*)
				Step := POWER_OFF;
			ELSIF (gTrakAsm.Command.ShuttleStart) THEN   (*Waiting for Movement command*)
				gTrakAsm.Command.ShuttleStart := FALSE;
				CntShuttle := 1;
				
				Step := PROCESS;
			END_IF
    
			(*             Accelerate all shuttles in assembly via the same target position to the same velocity            *)
			(* Used for startup, to accelerate all shuttles to an initial velocity in order to pass the first process-point *)
		PROCESS:	
			
			
			
			
			
			MC_BR_ShReadInfo_AcpTrak_0.Axis:= ADR(ShuttleAxis[ActiveShuttle]); //ActiveShuttle
			MC_BR_ShReadInfo_AcpTrak_0.Enable:=TRUE;
			MC_BR_ShReadInfo_AcpTrak_0();
			MC_BR_ShReadInfo_AcpTrak_1.Axis:= ADR(ShuttleAxis[2]);
			MC_BR_ShReadInfo_AcpTrak_1.Enable:=TRUE;
			MC_BR_ShReadInfo_AcpTrak_1();
			MC_BR_ShReadInfo_AcpTrak_2.Axis:= ADR(ShuttleAxis[3]);
			MC_BR_ShReadInfo_AcpTrak_2.Enable:=TRUE;
			MC_BR_ShReadInfo_AcpTrak_2();
			
			// States of running shuttles
			
			IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleInput' THEN
				Step_Sector:=Bottle_Input;
				IF Odebrane=TRUE THEN
				//	Odebrane:=FALSE;
					Step_Sector:=WaitPour;
				END_IF;
				
			ELSIF MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleInput' THEN
				Step_Sector:=Bottle_Input;
				
			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitPour'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitPour'
				THEN
				Step_Sector:=WaitPour;
				
				// Pouring arrive
				IF Pouring_A_Comming=FALSE AND Step_Sector=WaitPour THEN // AND  PouringShuttles < 2
					Step_Sector:=Pouring_A;
				END_IF;
				IF Pouring_A_Comming=TRUE AND Step_Sector=WaitPour AND Pouring_B_Comming=FALSE  THEN //AND  PouringShuttles < 2
					Step_Sector:=Pouring_B;
				END_IF;
			

			
			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_A'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorPouring_A'
				THEN
				Step_Sector:=Pouring_A;
				IF   TON_Pouring_A.Q=TRUE   THEN
					Pouring_A_Busy:=FALSE;
					Pouring_A_Comming:=FALSE;
					Step_Sector:=WaitCap;
					TON_Pouring_A.IN:=FALSE;
				END_IF

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_B'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorPouring_B'
				THEN
				Step_Sector:=Pouring_B;
				IF   TON_Pouring_B.Q=TRUE   THEN
					Pouring_B_Busy:=FALSE;
					Pouring_B_Comming:=FALSE;
					Step_Sector:=WaitCap;
					TON_Pouring_B.IN:=FALSE;
				END_IF

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorWaitCapping'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorWaitCapping'
				THEN
				Step_Sector:=WaitCap;
				IF Step_Sector=WaitCap AND Capping_Comming=FALSE THEN
					Step_Sector:=Capping;
				END_IF;

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping'
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorCapping'
				THEN
				Step_Sector:=Capping;
				IF   TON_Capping.Q=TRUE   THEN
					Capping_Busy:=FALSE;
					Step_Sector:=Bottle_Output;
					TON_Capping.IN:=FALSE;
					Capping_Comming:=FALSE;
				END_IF

			ELSIF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleOutput' 
				OR MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName = 'SectorBottleOutput'
				THEN
				Step_Sector:=Bottle_Output;
				IF Oddane=TRUE THEN
				//	Oddane:=FALSE;
					Step_Sector:=Bottle_Input;
				END_IF;
			END_IF;

			
			
			// TON activating
			IF Pouring_B_Busy=TRUE THEN
				TON_Pouring_B.IN:=TRUE;
			END_IF;
			IF Pouring_A_Busy=TRUE THEN
				TON_Pouring_A.IN:=TRUE;
			END_IF;
			IF Capping_Busy=TRUE THEN
				TON_Capping.IN:=TRUE;
			END_IF;
			// TON end
			

			// Pouring quit and capping arrive
			

			
			(*
			
			IF	EDGEPOS(MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorPouring_A')
				OR EDGEPOS(MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.RouteDestinationInfo.SectorName='SectorPouring_B') THEN
				PouringShuttles:=PouringShuttles+1;
				
			END_IF
			*)
			
			
			// TON handling
			



			// TON end
			
			
		//	IF EDGEPOS(ruch) THEN
			//	ruch:=FALSE;
				CASE Step_Sector OF
				Bottle_Input:
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorBottleInput' THEN
					END_IF;
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
					
				Pouring_A:
					Pouring_A_Comming:=TRUE;
				//	MC_BR_SecGetShuttle_AcpTrak_A.Enable:=TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_A' THEN
						Pouring_A_Busy:=TRUE;
					END_IF;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_A);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
					
					
				Pouring_B:
					Pouring_B_Comming:=TRUE;
				//	MC_BR_SecGetShuttle_AcpTrak_B.Enable:=TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorPouring_B' THEN
						Pouring_B_Busy:=TRUE;
					END_IF;
					MC_BR_RoutedMoveAbs_AcpTrak_0.Axis          := ADR(ShuttleAxis[ActiveShuttle]);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Execute       := TRUE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Sector        := ADR(SectorPouring_B);
						MC_BR_RoutedMoveAbs_AcpTrak_0.Position      := 0.305;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Velocity      := gTrakAsm.Parameter.Velocity;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Acceleration  := gTrakAsm.Parameter.Acceleration;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Deceleration  := gTrakAsm.Parameter.Deceleration;
						MC_BR_RoutedMoveAbs_AcpTrak_0.Jerk          := 0.0;
						MC_BR_RoutedMoveAbs_AcpTrak_0.BufferMode    := mcABORTING;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.StartDirection     := mcDIR_UNDEFINED;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.EndDirection       := mcDIR_POSITIVE;
						MC_BR_RoutedMoveAbs_AcpTrak_0.AdvancedParameters.ShuttleOrientation := mcDIR_UNDEFINED;
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
						
						PouringShuttles:=PouringShuttles-1;
						
						
				Capping:
					Capping_Comming:=TRUE;
				//	MC_BR_SecGetShuttle_AcpTrak_Cap.Enable:=TRUE;
					IF	MC_BR_ShReadInfo_AcpTrak_0.ShuttleInfo.CurrentValues.SectorName = 'SectorCapping' THEN
						Capping_Busy:=TRUE;
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
		//	END_IF;
			
			IF(gTrakAsm.Command.ShuttleStop) AND (ActiveShuttle > NUM_SIM_SHUTTLES) THEN   (*Waiting for Stop command*)
				CntShuttle := 1;
				Step := STOPPING;
			END_IF
            
			(* When there is invalid speed or acceleration setting, or shuttle caused ErrorStop *)
			IF (MC_BR_RoutedMoveVel_AcpTrak_0.Error) THEN
				MC_BR_AsmReset_AcpTrak_0.Execute := TRUE;
				Step := RESET;
			END_IF

			
			
			
			(*        Stop all Shuttles with specified Deceleration at their current location        *)
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
        
			(*        Reset Assembly due to an error        *)
		RESET:
			IF EDGEPOS(MC_BR_AsmReset_AcpTrak_0.Done) THEN
				gTrakAsm.Command.ShuttleStart    := FALSE;
				gTrakAsm.Command.ShuttleStop     := FALSE;
				MC_BR_AsmReset_AcpTrak_0.Execute := FALSE;
				MC_BR_RoutedMoveVel_AcpTrak_0.Execute := FALSE;
                
				Step := READY;
			END_IF
        
	END_CASE
    
	(* Read Assembly status cyclic to Assembly interface *)
	gTrakAsm.Status.Disabled  := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyDisabled;
	gTrakAsm.Status.Ready     := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyReady;
	gTrakAsm.Status.Homing    := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyHoming;
	gTrakAsm.Status.Stopping  := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyStopping;
	gTrakAsm.Status.ErrorStop := MC_BR_AsmReadStatus_AcpTrak_0.AssemblyErrorStop;
    
	(*        Cyclic FUB call        *)
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

	
	
	MC_BR_SecGetShuttle_AcpTrak_B();
(*	IF MC_BR_SecGetShuttle_AcpTrak_B.Busy=TRUE THEN
	  MC_BR_SecGetShuttle_AcpTrak_B.Enable:=FALSE;
	ELSE
		MC_BR_SecGetShuttle_AcpTrak_B.Enable:=TRUE;
	END_IF;*)
	MC_BR_SecGetShuttle_AcpTrak_Cap();
	(*IF MC_BR_SecGetShuttle_AcpTrak_Cap.Busy=TRUE THEN
		MC_BR_SecGetShuttle_AcpTrak_Cap.Enable:=FALSE;
	ELSE
		MC_BR_SecGetShuttle_AcpTrak_Cap.Enable:=TRUE;
	END_IF;*)
	
	MC_BR_SecGetShuttle_AcpTrak_A();
	(*IF MC_BR_SecGetShuttle_AcpTrak_A.Busy=TRUE THEN
		MC_BR_SecGetShuttle_AcpTrak_A.Enable:=FALSE;
	ELSE
		MC_BR_SecGetShuttle_AcpTrak_A.Enable:=TRUE;
	END_IF;*)
	
	TON_Pouring_B();
	TON_Pouring_A();
	TON_Capping();
	


	
	
	ActiveShuttle:=ActiveShuttle-1;	
	IF ActiveShuttle=0 THEN
		ActiveShuttle:=NUM_SIM_SHUTTLES;
	END_IF;
	
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

