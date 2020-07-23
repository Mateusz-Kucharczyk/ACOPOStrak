
PROGRAM _INIT
	(* Insert code here *)
	loopTmp := 1;
END_PROGRAM

PROGRAM _CYCLIC
	// 0 -> w³¹czony
	// 1 -> error
	// 2 -> wy³¹czony
	
	CASE loopTmp OF
		1:
			//WEJŒCIE
			IF svgBlocksToColor[0] = 0 THEN
				tranformation := '[{"select":"#wejscie","duration":1000,"fill":1}]';
			ELSIF svgBlocksToColor[0] = 1 THEN
				tranformation := '[{"select":"#wejscie","duration":1000,"fill":2}]';
			ELSIF svgBlocksToColor[0] = 2 THEN
				tranformation := '[{"select":"#wejscie","duration":1000,"fill":3}]';
			END_IF;
		2:
			//WYJŒCIE
			IF svgBlocksToColor[1] = 0 THEN
				tranformation := '[{"select":"#wyjscie","duration":1000,"fill":1}]';
			ELSIF svgBlocksToColor[1] = 1 THEN
				tranformation := '[{"select":"#wyjscie","duration":1000,"fill":2}]';
			ELSIF svgBlocksToColor[1] = 2 THEN
				tranformation := '[{"select":"#wyjscie","duration":1000,"fill":3}]';
			END_IF;
		3:
			//ZAKRÊCANIE
			IF svgBlocksToColor[2] = 0 THEN
				tranformation := '[{"select":"#zakrecanie","duration":1000,"fill":1}]';
			ELSIF svgBlocksToColor[2] = 1 THEN
				tranformation := '[{"select":"#zakrecanie","duration":1000,"fill":2}]';
			ELSIF svgBlocksToColor[2] = 2 THEN
				tranformation := '[{"select":"#zakrecanie","duration":1000,"fill":3}]';
			END_IF;
		4:
			//NALEWANIE A(dó³)
			IF svgBlocksToColor[3] = 0 THEN
				tranformation := '[{"select":"#nalewanieA","duration":1000,"fill":1}]';
			ELSIF svgBlocksToColor[3] = 1 THEN
				tranformation := '[{"select":"#nalewanieA","duration":1000,"fill":2}]';
			ELSIF svgBlocksToColor[3] = 2 THEN
				tranformation := '[{"select":"#nalewanieA","duration":1000,"fill":3}]';
			END_IF;
		5:
			//NALEWANIE B(góra)
			IF svgBlocksToColor[4] = 0 THEN
				tranformation := '[{"select":"#nalewanieB","duration":1000,"fill":1}]';
			ELSIF svgBlocksToColor[4] = 1 THEN
				tranformation := '[{"select":"#nalewanieB","duration":1000,"fill":2}]';
			ELSIF svgBlocksToColor[4] = 2 THEN
				tranformation := '[{"select":"#nalewanieB","duration":1000,"fill":3}]';
			END_IF;
	END_CASE;
	
	IF loopTmp = 5 THEN
		loopTmp := 1;
	ELSE
		loopTmp := loopTmp + 1;
	END_IF;
END_PROGRAM

PROGRAM _EXIT
	(* Insert code here *)
END_PROGRAM

