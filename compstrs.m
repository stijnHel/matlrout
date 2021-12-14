function [igelijk,i_1,i_2]=compstrs(S1,S2,nocase)
% COMPSTRS - Compares two unsorted string-arrays
%    [igelijk,i1,i2]=compstr(S1,S2,nocase)
% see also compstr

%	S. Helsen 2003-09-22
%	Copyright (c) 2003 by ZFST-STE

if nargin>2&~isempty(nocase)&nocase
	S1=upper(S1);
	S2=upper(S2);
end
%[S1s,i1s]=sortstr(S1);	% was used in matlab 4
%[S2s,i2s]=sortstr(S2);
[S1s,i1s]=sortrows(S1);
[S2s,i2s]=sortrows(S2);
[igelijk,i_1,i_2]=compstr(S1s,S2s);
igelijk=[i1s(igelijk(:,1)) i2s(igelijk(:,2))];
i_1=i1s(i_1);
i_2=i2s(i_2);
