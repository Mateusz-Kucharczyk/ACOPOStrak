
PROGRAM _INIT
	Filename := 'MyFile';
	ErrorMessage := '';
	
	MpRecipeXML_0.MpLink := ADR(gRecipeXml);
	MpRecipeXML_0.DeviceName := ADR('CF');
	MpRecipeXML_0.FileName := ADR(Filename);
	MpRecipeXML_0.Enable := TRUE;
	
	MpRecipeRegPar_0.MpLink := ADR(gRecipeXml);
	MpRecipeRegPar_0.PVName := ADR('Recipe:ClientOrder');
	MpRecipeRegPar_0.Enable := TRUE;
END_PROGRAM

PROGRAM _CYCLIC
	MpRecipeXML_0();
	MpRecipeRegPar_0();
	
	MpRecipeXML_0.ErrorReset := diErrorReset;
	
	IF EDGEPOS(MpRecipeXML_0.Error) THEN
		Step := STEP_ERROR;
	END_IF;
	
	CASE Step OF
		STEP_AWAIT:
			MpRecipeXML_0.Load := FALSE;
			MpRecipeXML_0.Save := FALSE;
			
			IF EDGEPOS(diSave) THEN
				Step := STEP_SAVE;
			ELSIF EDGEPOS(diLoad) THEN
				Step := STEP_LOAD;
			END_IF;
		STEP_SAVE:
			
			MpRecipeXML_0.Save := TRUE;
			
			IF MpRecipeXML_0.CommandDone THEN
				Step := STEP_AWAIT;
			END_IF;
		STEP_LOAD:
			
			MpRecipeXML_0.Load := TRUE;
			
			IF MpRecipeXML_0.CommandDone THEN
				Step := STEP_AWAIT;
			END_IF;
		STEP_ERROR:

			IF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_WITH_ERRORS THEN
				// Damaged XML structure
				ErrorMessage := 'XML structure may be damaged. Check if all tags are correct!';
			ELSIF MpRecipeXML_0.Info.Diag.StatusID.ID = mpRECIPE_ERR_LOAD_DATA THEN
				// File is missing
				ErrorMessage := 'The file may be missing!';
			END_IF;
			
			IF NOT(MpRecipeXML_0.Error) THEN
				ErrorMessage := '';
				Step := STEP_AWAIT;
			END_IF;
	END_CASE;
END_PROGRAM

PROGRAM _EXIT
	MpRecipeXML_0.Enable := FALSE;
	MpRecipeXML_0();

	MpRecipeRegPar_0.Enable := FALSE;
	MpRecipeRegPar_0();
END_PROGRAM
