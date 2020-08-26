VAR {AT PLC}
 Bottle : INT ;
 BottleInStage : USINT ;
END_VAR

VAR CONSTANT      
   P1 : McPointType := (Pos:=(X:=0, Y:=200, Z:=-600));
   P2 : McPointType := (Pos:=(X:=0, Y:=200, Z:=-700));
   P3 : McPointType := (Pos:=(X:=-150, Y:=-350, Z:=-600)); // 1 bottle
   P4 : McPointType := (Pos:=(X:=-150, Y:=-350, Z:=-700)); // 1 bottle
   P5 : McPointType := (Pos:=(X:=0, Y:=-350, Z:=-600));    // 2 bottle
   P6 : McPointType := (Pos:=(X:=0, Y:=-350, Z:=-700));    // 2 bottle
   P7 : McPointType := (Pos:=(X:=150, Y:=-350, Z:=-600));  // 3 bottle
   P8 : McPointType := (Pos:=(X:=150, Y:=-350, Z:=-700));  // 3 bottle
   P9 : McPointType := (Pos:=(X:=-150, Y:=-150, Z:=-600)); // 4 bottle
   P10 : McPointType := (Pos:=(X:=-150, Y:=-150, Z:=-700));// 4 bottle
   P11 : McPointType := (Pos:=(X:=0, Y:=-150, Z:=-600));   // 5 bottle
   P12 : McPointType := (Pos:=(X:=0, Y:=-150, Z:=-700));   // 5 bottle
   P13 : McPointType := (Pos:=(X:=150, Y:=-150, Z:=-600)); // 6 bottle
   P14 : McPointType := (Pos:=(X:=150, Y:=-150, Z:=-700)); // 6 bottle
END_VAR

PROGRAM _MAIN          
 Feedrate(60000);   //move with reduced speed
 PathAcceleration(600000);
 MoveJ(P1);        //move system to point P1
 MoveJ(P2);        //move system to point P2
 BottleInStage:=1;
 WaitTime(1);        //wait for 1 second
 MoveJ(P1);
 CASE Bottle OF
	1:
 		MoveJ(P3);        //move back to origin position
 		MoveJ(P4);
	2:
 		MoveJ(P5);        //move back to origin position
 		MoveJ(P6);
	3:
 		MoveJ(P7);        //move back to origin position
 		MoveJ(P8);
	4:
 		MoveJ(P9);        //move back to origin position
 		MoveJ(P10);
	5:
 		MoveJ(P11);        //move back to origin position
 		MoveJ(P12);
	6:
 		MoveJ(P13);        //move back to origin position
 		MoveJ(P14);
 END_CASE 
 WaitTime(1);
 BottleInStage:=0;
 CASE Bottle OF
	1:
 		MoveJ(P3);        //move back to origin position
	2:
 		MoveJ(P5);        //move back to origin position
	3:
 		MoveJ(P7);        //move back to origin position
	4:
 		MoveJ(P9);        //move back to origin position
	5:
 		MoveJ(P11);        //move back to origin position
	6:
 		MoveJ(P13);        //move back to origin position
 END_CASE 
 MoveJ(P1);        //move system to point P1
END_PROGRAM