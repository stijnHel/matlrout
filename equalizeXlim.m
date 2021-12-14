function equalizeXlim(as1,assen,varargin)
% EQUALIZEXLIM - Zet assen op gelijke Xschaal - met uitbreiding naar Y
%        equalizeXlim(as1,assen)
%        equalizeXlim(<'X'/'Y'/'Z','C'>,as1,assen)
%    assen mogen ook verwijzen naar figuren

axType='X';
if ~exist('as1','var')||isempty(as1)
	as1=gca;
elseif ischar(as1)
	axType=upper(as1);
	if ~any(axType=='XYZC')
		error('Wrong type!')
	end
	if nargin>1
		as1=assen;
		if nargin>2
			assen=varargin{1};
		else
			assen=[];
		end
	else
		as1=gca;
	end
elseif strcmp(get(as1,'type'),'figure')
	as1=findobj(as1,'type','axes');
	as1=as1(1);
end
if ~exist('assen','var')||isempty(assen)
	assen=findobj('type','axes');
else
	assen=findobj(assen,'type','axes');	% zet eventuele figuren om in zijn assen
end
slim=[axType 'Lim'];
Xl1=get(as1,slim);
dX=diff(Xl1);
for i=1:length(assen)
	Xl=get(assen(i),slim);
	set(assen(i),slim,[Xl(1) Xl(1)+dX])
end
