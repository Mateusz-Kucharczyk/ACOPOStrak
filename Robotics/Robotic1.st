VAR CONSTANT      
   P1 : McPointType := (Pos:=(X:=-100, Y:=0, Z:=-600));
   P2 : McPointType := (Pos:=(X:=-100, Y:=0, Z:=-900));
   P3 : McPointType := (Pos:=(X:=100, Y:=0, Z:=-600));
   P4 : McPointType := (Pos:=(X:=100, Y:=0, Z:=-900));
END_VAR

PROGRAM _MAIN          
 Feedrate(60000);   //move with reduced speed
 PathAcceleration(600000);
 MoveJ(P3);        //move system to point P1
MoveJ(P4);        //move system to point P2

 WaitTime(1);        //wait for 1 second
MoveJ(P3);
 MoveJ(P1);        //move back to origin position
 MoveJ(P2);
 WaitTime(1);
 MoveJ(P1);
END_PROGRAM