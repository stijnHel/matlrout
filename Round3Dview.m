function vOut = Round3Dview(ax,fac)
%Round3Dview - Set the 3D-view to rounded values
%    Round3Dview(ax,fac)
%          ax  : axes (default: current axes)
%          fac : factor to be used for rounding (default 10)
%   

if nargin==0 || isempty(ax)
	ax = gca;
end
if nargin<2 || isempty(fac)
	fac = 10;
end
V = zeros(length(ax),2);
for i=1:length(ax)
	if strcmp(get(ax(i),'Type'),'figure')
		v = Round3Dview(GetNormalAxes(ax(i)),fac);
		v = mean(v,1);
	else
		v = get(ax(i),'View');
		v = round(v/fac)*fac;
		set(ax(i),'View',v)
	end
	V(i,:) = v;
end

if nargout
	vOut = V;
end
