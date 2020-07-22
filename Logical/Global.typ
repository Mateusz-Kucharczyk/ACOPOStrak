
TYPE
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
