(*shuttle-UserData structure*)
TYPE
	ShuttleUserData_typ :     STRUCT 
		Color : ShuttleColor_enum; (*example: product colour*)
		Weight : REAL; (*example: product weight*)
		Partnumber : UDINT; (*example: product part number*)
	END_STRUCT;
	ShuttleColor_enum : 
		(
		ORANGE,
		GREEN,
		RED,
		BLUE,
		WHITE
	);
END_TYPE

(*Assembly Interface Type*)
TYPE
	TrakAsmCommand_type : STRUCT 
		Power : BOOL;
		ShuttleStart : BOOL;
		ShuttleStop : BOOL;
	END_STRUCT;
	TrakAsmParameter_type : STRUCT 
		Velocity : REAL;
		Acceleration : REAL;
		Deceleration : REAL;
	END_STRUCT;
	TrakAsmStatus_type : STRUCT 
		Disabled : BOOL;
		Ready : BOOL;
		Homing : BOOL;
		Stopping : BOOL;
		ErrorStop : BOOL;
	END_STRUCT;
	TrakAsm_type : STRUCT 
		Command : TrakAsmCommand_type;
		Parameter : TrakAsmParameter_type;
		Status : TrakAsmStatus_type;
	END_STRUCT;
	Order_type : 	STRUCT 
		numberOfPackages : USINT;
		bottlesPerPackage : USINT;
		bottleSize : BottleSize_enum;
		drinkColor : DrinkColor_enum;
	END_STRUCT;
	DrinkColor_enum : 
		(
		DRINK_COLOR_RED,
		DRINK_COLOR_GREEN,
		DRINK_COLOR_BLUE
		);
	BottleSize_enum : 
		(
		BOTTLE_SIZE_SMALL,
		BOTTLE_SIZE_LARGE
		);
END_TYPE
