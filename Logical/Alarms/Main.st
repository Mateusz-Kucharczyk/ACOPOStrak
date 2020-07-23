
PROGRAM _INIT
	MpAlarmXCore_0.MpLink := ADR(gAlarmXCore);
	MpAlarmXCore_0.Enable := TRUE;
	
	MpAlarmXHistory_0.MpLink :=ADR(gAlarmXHistory);
	MpAlarmXHistory_0.Enable := TRUE;
END_PROGRAM

PROGRAM _CYCLIC
	IF EDGEPOS(UserAlarm) THEN
		MpAlarmXSet(gAlarmXCore, 'UserAlarm');
	END_IF;
	IF EDGENEG(UserAlarm) THEN
	  MpAlarmXReset(gAlarmXCore, 'UserAlarm');
	END_IF;
	
	MpAlarmXCore_0();
	MpAlarmXHistory_0();
END_PROGRAM

PROGRAM _EXIT
	MpAlarmXCore_0.Enable := FALSE;
	MpAlarmXHistory_0.Enable := FALSE;
	
	MpAlarmXCore_0();
	MpAlarmXHistory_0();
END_PROGRAM

