function fNew=copycombineplots(fList,fTarget,form)
%copycombineplots - Copy and combine plots to a "plotmat"
%    copycombineplots(fList,fTarget,form)
%              fList : list of target axes's or figures
%              fTarget: target figure (can be empty, new figure is created)
%              form : number of rows and columns - used with subplot
%                 if number of axes's is higher than prod(form):
%                   if fTarget is not given (empty), multiple figure are created
%                   else only the first axes are copied (multiple target
%                        figures can be given)
%
% !!this function currently handles colorbars, legends (, ...) well!
%      they are handled as separate axes if supplied as axes!!
%         they are not copied if figure handles are given. (tried OK?)

if ~exist('fTarget','var')
	fTarget=[];
end
i=1;
fList=fList(:);
while i<=length(fList)
	switch get(fList(i),'Type')
		case 'axes'
			i=i+1;	% OK
		case 'figure'
			ax=GetNormalAxes(fList(i));	% exclude legend, colorbar
			fList=[fList(1:i-1);ax(:);fList(i+1:end)];
			i=i+length(ax);
		otherwise
			error('fList should only contain figures and/or axes')
	end
end
nAx=length(fList);
if ~exist('form','var')||isempty(form)
	if nAx<4
		form=[nAx 1];
	else
		form=[ceil(nAx/2),2];
	end
end
fNew=fTarget;

iAxFig=0;
nFig=0;
for iAx=1:nAx
	if rem(iAxFig,prod(form))==0
		nFig=nFig+1;
		if isempty(fTarget)
			fNew(1,end+1)=nfigure;
			set(fNew(end),'Name',sprintf('copied plots #%d',length(fNew)))
		elseif nFig<=length(fTarget)
			fNew(nFig)=figure(fTarget);
		else
			break
		end
		iAxFig=1;
	else
		iAxFig=iAxFig+1;
	end
	ax=subplot(form(1),form(2),iAxFig);	% (!only for getting default position!)
	pos=get(ax,'Position');
	delete(ax);
	ax=copyobj(fList(iAx),fNew(nFig));
	set(ax,'Position',pos)
	if ~isempty(getappdata(ax,'LegendPeerHandle'))
		legend(ax,'show')
	end
	if ~isempty(getappdata(ax,'LegendColorbarOriginalInset'))
		colorbar
	end
end
if nargout==0
	clear fNew
end
