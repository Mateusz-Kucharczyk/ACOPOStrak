
PROGRAM _INIT
	MpAlarmXCore_0.MpLink := ADR(gAlarmXCore);
	MpAlarmXCore_0.Enable := TRUE;
	
	MpAlarmXHistory_0.MpLink :=ADR(gAlarmXHistory);
	MpAlarmXHistory_0.Enable := TRUE;
END_PROGRAM

PROGRAM _CYCLIC
	IF EDGEPOS(gdiInterrupt) THEN
		MpAlarmXSet(gAlarmXCore, 'InterruptAlarm');
	END_IF;
	IF EDGENEG(gdiInterrupt) THEN
	  MpAlarmXReset(gAlarmXCore, 'InterruptAlarm');
	END_IF;
	
	IF EDGEPOS(gdiInstantStop) THEN
		MpAlarmXSet(gAlarmXCore, 'SuddenlyStopAlarm');
	END_IF;
	IF EDGENEG(gdiInstantStop) THEN
		MpAlarmXReset(gAlarmXCore, 'SuddenlyStopAlarm');
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

