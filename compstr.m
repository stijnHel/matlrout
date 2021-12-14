function [igelijk,i_1,i_2]=compstr(S1,S2,nocase)
% COMPSTR  - Compares two sorted string-arrays
%    [igelijk,i1,i2]=compstr(S1,S2)
%        igelijk : indices (two columns) of equal strings
%        i1 : indices of strings only in S1
%        i2 : indices of strings only in S2
%    ...=compstr(S1,S2,nocase)
%        if nocase : no case-sensitivity
%
% !!works only for string-arrays without equal strings in the same array!!
%
% see also compstrs

%	S. Helsen 2003-09-22
%	Copyright (c) 2003 by ZFST-STE

% ? better using setdiff, intersect

if nargin>2&~isempty(nocase)&nocase
	S1=upper(S1);
	S2=upper(S2);
end

n1=size(S1,1);
n2=size(S2,1);
I1=zeros(n1,1);
I2=zeros(n2,1);
i1=1;
for i2=1:n2
	if i1<=n1
		x=strcmpc(deblank(S1(i1,:)),deblank(S2(i2,:)));
		while x<0
			i1=i1+1;
			if i1>n1
				break;
			end
			x=strcmpc(S1(i1,:),S2(i2,:));
		end
		if x==0&i1<=n1
			I1(i1)=i2;
			I2(i2)=i1;
			i1=i1+1;
		end
	end
end
igelijk=[find(I1) find(I2)];
i_1=find(I1==0);
i_2=find(I2==0);
