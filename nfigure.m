function fOut=nfigure(f,varargin)
% NFIGURE - Maakt figuur aan met enkele extra standaard opties.

persistent SETTINGS

if isempty(SETTINGS)
	SETTINGS=struct('defColOrder',[0.00    0.00    1.00;
			0.00    0.50    0.00;
			1.00    0.00    0.00;
			0.00    0.75    0.75;
			0.75    0.00    0.75;
			0.75    0.75    0.00;
			0.25    0.25    0.25]	... the old standard colors!
		,'defColMap',jet(64)	...	the old standard colororder
		,'defMenubar','none'	...
		,'defPapertype','A4'	...
		);
end

if ~exist('f','var')
	f=[];
end
if ischar(f)
	V=[{f},varargin];
	f=[];
else
	V=varargin;
end
if ~isempty(f)&&f~=0
	if any(findobj('Type','figure')==f)
		figure(f)
		if nargout
			fOut=f;
		end
		return
	end
end
if ~isempty(V)
	[SETTINGS,~,V,~]=setoptions(SETTINGS,V{:});
	if ~isempty(V)
		V=reshape(V(1:2,:),1,[]);
	end
end
if ~isempty(f)&&f==0	% only change of defaults
	if ~isempty(V)
		fprintf('      %s\n',V{1,:})
		warning('Not all default settings set!')
	end
	return
end
S=struct('colOrder',SETTINGS.defColOrder	...
	,'colMap',SETTINGS.defColMap	...
	,'menubar',SETTINGS.defMenubar	...
	,'papertype',SETTINGS.defPapertype	...
	,'bUIfigure',false	...
	,'bNavfig',false	...
	);
if ~isempty(V)
	[S,~,V]=setoptions(S,V{:});
	V=reshape(V(1:2,:),1,[]);
end
fN={'colOrder','defaultAxesColorOrder';
	'colMap','colormap';
	'menubar','Menubar';
	'papertype','Papertype'};
for i=1:size(fN,1)
	if ~isempty(S.(fN{i}))
		V=[fN(i,2),S.(fN{i}),V]; %#ok<AGROW>
	end
end

if S.bUIfigure
	f = uifigure(V{:});
else
	f=figure(V{:});
	orient(f,'landscape')
	if S.bNavfig
		navfig
	end
end
if nargout
	fOut=f;
end
