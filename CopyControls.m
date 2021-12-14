function CopyControls(fig,varargin)
%CopyControls - copy controls in a figure - to check how it looks
%    CopyControls(fig)
%    CopyControls('figTag')
%
%   ?hetzelfde als ShowUIs?

[bUseChildren]=true;	% if true: use children of figure
					% else hControls-appdata is used
figTag=[];
figNr=[];
figTgt=[];
if ~isempty(varargin)
	setoptions({'bUseChildren','figTgt','figTag','figNr'},varargin{:})
	if ischar(figTgt)
		figTag=figTgt;
	elseif ~isempty(figTgt)
		figNr=figTgt;
	end
end

if nargin<1||(isempty(fig)&&~ischar(fig))
	fig=gcf;
elseif ischar(fig)
	if isempty(fig)
		fig='CNHdataAnalyserGUI';
	end
	fig=getmakefig(fig,false,false);
	if isempty(fig)
		return
	end
end

if bUseChildren
	H=get(fig,'Children');
	nControls = length(H);
else
	H=getappdata(fig,'hControls');
	fn=fieldnames(H);
	nControls = length(fn);
end

if ~isempty(figNr)
	f=figNr;
	figure(f)
	clf(f)
elseif ischar(figTag)
	[f,bN]=getmakefig(figTag);
	if ~bN
		clf
	end
else
	f=nfigure;
end
set(f,'position',get(fig,'position'))
for i=1:nControls
	if bUseChildren
		h=H(i);
	else
		h=H.(fn{i});
	end
	for j=1:length(h)
		if ~contains(get(h(j),'Type'),'menu')
			uicontrol('Position',get(h(j),'position'))
		end
	end
end
set(get(f,'children'),'units','normalized')
