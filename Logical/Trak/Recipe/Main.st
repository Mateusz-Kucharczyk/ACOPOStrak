

PROGRAM _INIT
	Filename := 'OutFile';
	ErrorMessage := '';
	PVName := 'Recipe:ClientOrder';
	
	gOrder.bottleSize := 0;
	gOrder.bottlesPerPackage := 0;
	gOrder.drinkColor := 0;
	gOrder.numberOfPackages := 0;
	
	MpRecipeXML_0.MpLink := ADR(gRecipeXml);
	MpRecipeXML_0.DeviceName := ADR('CF');
	MpRecipeXML_0.FileName := ADR(Filename);
	MpRecipeXML_0.Enable := TRUE;
	
	MpRecipeRegPar_0.MpLink := ADR(gRecipeXml);
	MpRecipeRegPar_0.PVName := ADR(PVName);
	MpRecipeRegPar_0.Enable := TRUE;
	
	MpRecipeUI_0.MpLink := ADR(gRecipeXml);
	MpRecipeUI_0.Enable := TRUE;
	UISetup.RecipeListSize:= 20;
	UIConnect.Recipe.Refresh := TRUE;
	
	MpRecipeUI_0.UISetup := UISetup;
	MpRecipeUI_0.UIConnect := ADR(UIConnect);
	  
END_PROGRAM

PROGRAM _CYCLIC
	MpRecipeXML_0();
	MpRecipeRegPar_0();
	MpRecipeUI_0();
	
	IF gProcessFinished THEN
		gOrder := ClientOrder;
		gCurrentRecipeName := UIConnect.Recipe.List.Names[UIConnect.Recipe.List.SelectedIndex];
	END_IF;
	
	SelectedProgramName := UIConnect.Recipe.List.Names[UIConnect.Recipe.List.SelectedIndex];
	
	FOR i := 0 TO 19 BY 1 DO
		// delete contents of WidgetString[i]
		WidgetString[i] := DELETE(WidgetString[i], 255, 0);
		IF UIConnect.Recipe.List.Names[i] <> '' THEN
				
			// convert value of i and store it in Temp
			brsitoa(i, ADR(Temp));
				
			// Construction of string '{"value":"<i>","text":"<UIConnect.Recipe.List.Names[i]>"}'
			WidgetString[i] := CONCAT(WidgetString[i], '{"value":"');
			WidgetString[i] := CONCAT(WidgetString[i], Temp);
			WidgetString[i] := CONCAT(WidgetString[i], '","text":"');
			WidgetString[i] := CONCAT(WidgetString[i], UIConnect.Recipe.List.Names[i]);
			WidgetString[i] := CONCAT(WidgetString[i], '"}');
		END_IF;	
	END_FOR;
	
	MpRecipeXML_0.ErrorReset := diErrorReset;
	MpRecipeRegPar_0.ErrorReset:= diErrorReset;
	MpRecipeUI_0.ErrorReset := diErrorReset;
	
	IF MpRecipeXML_0.Error OR MpRecipeRegPar_0.Error OR MpRecipeUI_0.Error THEN
		isError := TRUE;
		IF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_WITH_ERRORS
			OR MpRecipeUI_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_WITH_ERRORS THEN
			// Damaged XML structure
			ErrorMessage := 'XML structure may be damaged. Check if all tags are correct!';
		ELSIF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_DATA
			OR MpRecipeUI_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_DATA THEN
			// File is missing
			ErrorMessage := 'The file or XML structure may be missing!';
		ELSIF UIConnect.Recipe.NewFileName = '' AND MpRecipeUI_0.Error THEN
			// Somebody tried to add recipe without new name
			ErrorMessage := 'You must enter new file name!';
		END_IF;
	ELSE
		ErrorMessage := '';
		diErrorReset := FALSE;
		isError := FALSE;
	END_IF;

END_PROGRAM

PROGRAM _EXIT
	MpRecipeXML_0.Enable := FALSE;
	MpRecipeXML_0();

	MpRecipeRegPar_0.Enable := FALSE;
	MpRecipeRegPar_0();
	
	MpRecipeUI_0.Enable := FALSE;
	MpRecipeUI_0();
END_PROGRAM

