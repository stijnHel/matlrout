function c=times(a,b)
% UINT8/TIMES - a.*b for UINT8 class
%   eenvoudige implementatie langs double om
c=uint8(bitand(255,double(a).*double(b)));
