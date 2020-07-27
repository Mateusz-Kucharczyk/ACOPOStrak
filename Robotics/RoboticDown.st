VAR CONSTANT      

   P1 : McPointType := (Pos:=(X:=0, Y:=0, Z:=-600));
   P2 : McPointType := (Pos:=(X:=0, Y:=0, Z:=-700));
  END_VAR



PROGRAM _MAIN          
 Feedrate(6000);   //move with reduced speed
 PathAcceleration(60000);
 MoveJ(P1);        //move system to point P1
 MoveJ(P2);
 WaitTime(2);        //wait for 1 second    
 MoveJ(P1);        //move system to point P1
END_PROGRAM