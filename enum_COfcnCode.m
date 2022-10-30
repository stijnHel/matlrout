classdef enum_COfcnCode < uint8
	%enum_COfcnCode - enumeration of possible CANOPEN-fcnCodes
	
	enumeration
		NMT				( 0)
		SYNC			( 1)
		TIME_STAMP		( 2)
		PDO1tx			( 3)
		PDO1rx			( 4)
		PDO2tx			( 5)
		PDO2rx			( 6)
		PDO3tx			( 7)
		PDO3rx			( 8)
		PDO4tx			( 9)
		PDO4rx			(10)
		SDOtx			(11)
		SDOrx			(12)
		NMTerrCtl		(14)
		BAD_13			(13)
		BAD_15			(15)
	end		% enumeration
end		% enum_COfcnCode
