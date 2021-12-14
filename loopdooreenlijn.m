function loopdooreenlijn(X,Y,opties)
% LOOPDOOREENLIJN - laat een bolletje lopen over een lijn
%     loopdooreenlijn(X,Y[,opties])
%  of
%     loopdooreenlijn([X,Y][,opties])
%
%  Laat een bolletje lopen door alle punten van een lijn

if nargin==2
	if ~isnumeric(Y)
		opties=Y;
		Y=[];
	end
end
if ~exist('opties','var')
	opties=[];
end

S=struct('color',[1 0 0]	...
	,'marker','o','markersize',20	...
	,'markerfacecolor','none','markeredgecolor','auto'	...
	,'erasemode','xor'	...
	,'delay',0	...
	);
Sf=fieldnames(S);
if iscell(opties)
	i=1;
	while i<=length(opties)
		if ~ischar(opties{i});
			error('Verkeerd gebruik van opties')
		end
		if strmatch(lower(opties{i}),Sf)
			S.(lower(opties{i}))=opties{i+1};
			i=i+1;
		else
			error('Verkeerd gebruik van opties')
		end
		i=i+1;
	end
elseif ~isempty(opties)
	error('Verkeerd gebruik van opties')
end

if ~exist('Y','var')||isempty(Y)
	Y=X(:,2);
	X=X(:,1);
end
l=line(X(1),Y(1),'Color',S.color	...
	,'Marker',S.marker,'MarkerSize',S.markersize	...
	,'MarkerFaceColor',S.markerfacecolor,'MarkerEdgeColor',S.markeredgecolor	...
	,'EraseMode',S.erasemode	...
	);
figure(gcf);
for i=1:length(X);
	set(l,'XData',X(i),'YData',Y(i));
	if S.delay>0
		pause(S.delay);
	else
		drawnow;
	end
end
delete(l)
