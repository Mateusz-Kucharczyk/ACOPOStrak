PROGRAM _INIT 

    // size of Vis structure - this value has to be entered in B&R scene viewer (PVI -> Options -> Size)
	SizeofVis := SIZEOF(Vizu);
	// max number of displayed shuttles  
	NumVisShuttle := SIZEOF(Vizu.Vis.Shuttle) / SIZEOF(Vizu.Vis.Shuttle[0]);  
	FOR i:=0 TO (NumVisShuttle-1) DO
		Vizu.Vis.Shuttle[i].ColorRed     := 1.000;
		Vizu.Vis.Shuttle[i].ColorGreen   := 1.000;
		Vizu.Vis.Shuttle[i].ColorBlue    := 1.000;
	END_FOR;
	Vizu.BckgColor[0] := 0.5;
	Vizu.BckgColor[1] := 0.5;
	Vizu.BckgColor[2] := 0.5;
	RedChangeRate := 0.01;
	GreenChangeRate := 0.05;
	BlueChangeRate := 0.1;
	New_Variable := 1;
END_PROGRAM

PROGRAM _CYCLIC 

	IF EasterEgg THEN
		Vizu.BckgColor[0] := Vizu.BckgColor[0] + RedChangeRate;
		IF  Vizu.BckgColor[0] > 1 THEN
			RedChangeRate := -0.01;
		ELSIF Vizu.BckgColor[0] < 0 THEN
			RedChangeRate := 0.01;
		END_IF;
	
		Vizu.BckgColor[1] := Vizu.BckgColor[1] + GreenChangeRate;
	
		IF  Vizu.BckgColor[1] > 1 THEN
			GreenChangeRate := -0.05;
		ELSIF Vizu.BckgColor[1] < 0 THEN
			GreenChangeRate := 0.05;
		END_IF;
	
		Vizu.BckgColor[2] := Vizu.BckgColor[2] + BlueChangeRate;
	
		IF  Vizu.BckgColor[2] > 1 THEN
			BlueChangeRate := -0.1;
		ELSIF Vizu.BckgColor[2] < 0 THEN
			BlueChangeRate := 0.1;
		END_IF;
	END_IF;
	
	New_Variable := New_Variable + 1;
	
	IF New_Variable = 18 THEN
	  New_Variable := 1;
	END_IF;
	
	

	FOR i:=0 TO (NumVisShuttle-1) DO 
		IF gShuttleMon.Shuttle[i].Available THEN
			Vizu.Vis.Shuttle[i].Available     := 1;
			Vizu.Vis.Shuttle[i].PositionX     := LREAL_TO_REAL(gShuttleMon.Shuttle[i].Position.X);
			Vizu.Vis.Shuttle[i].PositionY     := LREAL_TO_REAL(gShuttleMon.Shuttle[i].Position.Y);
			Vizu.Vis.Shuttle[i].RotationZ     := LREAL_TO_REAL(gShuttleMon.Shuttle[i].Orientation.Angle1);
			Vizu.Vis.Shuttle[i].ExtentToFront := LREAL_TO_REAL(gShuttleMon.Shuttle[i].ExtentToFront);
			Vizu.Vis.Shuttle[i].ExtentToBack  := LREAL_TO_REAL(gShuttleMon.Shuttle[i].ExtentToBack);
			Vizu.Vis.Shuttle[i].Width         := LREAL_TO_REAL(gShuttleMon.Shuttle[i].Width);  
			brsitoa(gShuttleMon.Shuttle[i].Index, ADR(Vizu.Vis.Shuttle[i].Text));
			//
            
			
			IF gShuttleMon.Shuttle[i].UserData <> 0 THEN  
				pUserData ACCESS gShuttleMon.Shuttle[i].UserData;    // access to user data of this shuttle
				IF gShuttleColor[i] = 1 THEN                     // Color is defined with RGB values between 0 and 1
					Vizu.Vis.Shuttle[i].ColorRed     := 0.000;
					Vizu.Vis.Shuttle[i].ColorGreen   := 1.000;
					Vizu.Vis.Shuttle[i].ColorBlue    := 0.000;
				ELSIF gShuttleColor[i] = 2 THEN
					Vizu.Vis.Shuttle[i].ColorRed     := 1.000;
					Vizu.Vis.Shuttle[i].ColorGreen   := 0.000;
					Vizu.Vis.Shuttle[i].ColorBlue    := 0.000;
				ELSIF gShuttleColor[i] = 3 THEN
					Vizu.Vis.Shuttle[i].ColorRed     := 0.000;
					Vizu.Vis.Shuttle[i].ColorGreen   := 0.000;
					Vizu.Vis.Shuttle[i].ColorBlue    := 1.000;
				ELSIF pUserData.Color = 0 THEN
					Vizu.Vis.Shuttle[i].ColorRed     := 1.000;
					Vizu.Vis.Shuttle[i].ColorGreen   := 1.000;
					Vizu.Vis.Shuttle[i].ColorBlue    := 1.000;
				END_IF  
			END_IF
            
		ELSE
			brsmemset(ADR(Vizu.Vis.Shuttle[i]), 0, SIZEOF(Vizu.Vis.Shuttle[0]));  //If the selected shuttle is not available, it will be invisible in the Scene Viewer
		END_IF
	END_FOR
    
END_PROGRAM
