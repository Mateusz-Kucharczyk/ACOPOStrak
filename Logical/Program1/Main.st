
PROGRAM _INIT
	(* Insert code here *)
	CF := 'CF';
	MyFile := 'MyFile';
	s := 'Program1:Coffee';
	MpRecipeXML_0.MpLink := ADR(gRecipeXml);
	MpRecipeXML_0.Enable := TRUE;
	MpRecipeXML_0.DeviceName := ADR(CF);
	MpRecipeXML_0.FileName := ADR(MyFile);
	
	Coffee.Milk := 50;
	Coffee.Powder:= 10;
	Coffee.Sugar :=5;
	Coffee.Temperature := 80;
	Coffee.Water := 250;
	
	MpRecipeRegPar_0.MpLink := ADR(gRecipeXml);
	MpRecipeRegPar_0.Enable := TRUE;
	MpRecipeRegPar_0.PVName := ADR(s);
	
END_PROGRAM

PROGRAM _CYCLIC
	(* Insert code here *)
	MpRecipeXML_0();
	MpRecipeRegPar_0();
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
	 
END_PROGRAM

