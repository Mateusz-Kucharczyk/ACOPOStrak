VAR CONSTANT      
   P1 : McPointType := (Pos:=(X:=200, Y:=200, Z:=-500));
   P2 : McPointType := (Pos:=(X:=200, Y:=200, Z:=-800));
   P3 : McPointType := (Pos:=(X:=200, Y:=-200, Z:=-500));
   P4 : McPointType := (Pos:=(X:=200, Y:=-200, Z:=-800));
   P5 : McPointType := (Pos:=(X:=-200, Y:=200, Z:=-500));
   P6 : McPointType := (Pos:=(X:=-200, Y:=200, Z:=-800));
   P7 : McPointType := (Pos:=(X:=-200, Y:=-200, Z:=-500));
   P8 : McPointType := (Pos:=(X:=-200, Y:=-200, Z:=-800));
END_VAR

PROGRAM _MAIN          
 Feedrate(600000);   //move with reduced speed
 PathAcceleration(6000000);
 MoveJ(P1);        //move system to point P1
 MoveJ(P2);        //move system to point P2
 
 MoveJ(P1);
 MoveJ(P3);        //move back to origin position
 MoveJ(P4);
 
 MoveJ(P3); 
  MoveJ(P5);        //move system to point P1
 MoveJ(P6);        //move system to point P2
 
 MoveJ(P5);
 MoveJ(P7);        //move back to origin position
 MoveJ(P8);
 
 MoveJ(P7); 
 MoveJ(P1);        //move system to point P1
END_PROGRAM