function m2d(t)
% M2D      - Mac to DOS-format
%   m2d(t) waar t output is van testtype
%   m2d(dir)
%      Zoekt alle files van type Mac op en zet dit om naar DOS-formaat

if ischar(t)
	t=testtype(t,1);
end

for i=1:length(t)
	if isstruct(t(i).type)
		m2d(t(i).type);
	elseif t(i).type==2
		mac2dos(t(i).naam);
	end
end
