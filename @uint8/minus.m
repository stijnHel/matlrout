function c=minus(a,b)
% UINT8/MINUS - a-b for UINT8 class
%   eenvoudige implementatie langs double om
c=double(a)-double(b);
c=uint8(c+256*(c<0));
