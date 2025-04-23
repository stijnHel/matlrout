function D = ReadSatTLE(fName)
%ReadSatTLE - Read TLE of satelite (only "proposed function")
%     D = ReadSatTLE(fName)

% see https://celestrak.org/NORAD/documentation/tle-fmt.php

% Data for each satellite consists of three lines in the following format:
% 
% AAAAAAAAAAAAAAAAAAAAAAAA
% 1 NNNNNU NNNNNAAA NNNNN.NNNNNNNN +.NNNNNNNN +NNNNN-N +NNNNN-N N NNNNN
% 2 NNNNN NNN.NNNN NNN.NNNN NNNNNNN NNN.NNNN NNN.NNNN NN.NNNNNNNNNNNNNN
% Line 0 is a twenty-four character name (to be consistent with the name length in the NORAD SATCAT).
% 
% Lines 1 and 2 are the standard Two-Line Orbital Element Set Format identical to that used by NORAD and NASA. The format description is:
