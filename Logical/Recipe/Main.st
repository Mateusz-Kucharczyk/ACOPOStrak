

PROGRAM _INIT
	Filename := 'OutFile';
	PVName := 'Recipe:ClientOrder';
	
	gOrder.bottleSize := 0;
	gOrder.bottlesPerPackage := 0;
	gOrder.drinkColor := 0;
	gOrder.numberOfPackages := 0;
	
	NewRecipe.bottlesPerPackage := 0;
	NewRecipe.numberOfPackages := 0;
	NewRecipe.drinkColor := 0;
	NewRecipe.bottleSize := 0;
	
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
	
	IF gProcessFinished AND diLoad THEN
		diLoad := FALSE;
		gOrder := ClientOrder;
		gCurrentRecipeName := UIConnect.Recipe.List.Names[UIConnect.Recipe.List.SelectedIndex];
	END_IF;
	
	IF UIConnect.New.FileName = 'Death' THEN
		coffinFlag := TRUE;
	ELSE
		coffinFlag := FALSE;
	END_IF;
	
	IF UIConnect.New.FileName = 'Party' THEN
		gPartyOn := TRUE;
	ELSE
		gPartyOn := FALSE;
	END_IF;
	
	IF diAdd AND NOT(diLoad) THEN
		ClientOrder := NewRecipe;
		UIConnect.New.Create := TRUE;
		diAdd := FALSE;
		MpRecipeUI_0();
	END_IF;
	
	IF EDGENEG(UIConnect.New.Create) THEN
		UIConnect.New.FileName := '';
		NewRecipe.bottlesPerPackage := 0;
		NewRecipe.numberOfPackages := 0;
		NewRecipe.drinkColor := 0;
		NewRecipe.bottleSize := 0;
		
	END_IF;
	UIConnect.Recipe;
	
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
	
	// Error reset handling
	MpRecipeXML_0.ErrorReset := diErrorReset;
	MpRecipeRegPar_0.ErrorReset:= diErrorReset;
	MpRecipeUI_0.ErrorReset := diErrorReset;
	
	IF MpRecipeXML_0.Error OR MpRecipeRegPar_0.Error OR MpRecipeUI_0.Error THEN
		IF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_WITH_ERRORS
			OR MpRecipeUI_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_WITH_ERRORS THEN
			// Damaged XML structure
			ErrorStatus := ERROR_XML_DAMAGED;
		ELSIF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_DATA
			OR MpRecipeUI_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_DATA THEN
			// File is missing
			ErrorStatus := ERROR_FILE_MISSING;
		ELSIF (UIConnect.Recipe.NewFileName = '' OR UIConnect.New.FileName = '') AND MpRecipeUI_0.Error THEN
			// Somebody tried to add recipe without new name
			ErrorStatus := ERROR_WRONG_FILE_NAME;
		END_IF;
	ELSE
		ErrorStatus := NO_ERROR;
		diErrorReset := FALSE;
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

