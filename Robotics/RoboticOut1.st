VAR CONSTANT      
   P1 : McPointType := (Pos:=(X:=0, Y:=200, Z:=-600));
   P2 : McPointType := (Pos:=(X:=0, Y:=200, Z:=-700));
   P3 : McPointType := (Pos:=(X:=-150, Y:=-350, Z:=-600));
   P4 : McPointType := (Pos:=(X:=-150, Y:=-350, Z:=-700));
END_VAR

PROGRAM _MAIN          
 Feedrate(60000);   //move with reduced speed
 PathAcceleration(600000);
 MoveJ(P1);        //move system to point P1
 MoveJ(P2);        //move system to point P2
 WaitTime(1);        //wait for 1 second
 MoveJ(P1);
 MoveJ(P3);        //move back to origin position
 MoveJ(P4);
 WaitTime(1);
 MoveJ(P3); 
 MoveJ(P1);        //move system to point P1
END_PROGRAM