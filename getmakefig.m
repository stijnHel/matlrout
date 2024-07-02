function [fout,bNew,Stitles]=getmakefig(t,activate,create,titl,varargin)
%getmakefig - Searches and makes if necessary a figure with a specified tag
%     [f,bNew]=getmakefig(tag[,activate[,create[,titl[,options]]]])
%     [f,tags,titles]=getmakefig

persistent bForceNormalFigure

if isempty(bForceNormalFigure)
	bForceNormalFigure = false;
end

if nargin>1 && ischar(activate)
	if nargin==2
		options = [{activate},varargin];
	elseif nargin==3
		options = [{activate,create},varargin];
	else
		options = [{activate,create,titl},varargin];
	end
else
	options = varargin;
end
if strcmpi(t,'bForceNormalFigure')
	if nargin==1
		if nargout
			fout = bForceNormalFigure;
		else
			fprintf('normal figure options: %d\n',bForceNormalFigure)
		end
	else
		bForceNormalFigure = activate;
	end
	return
end
if ~exist('activate','var')||isempty(activate)
	activate=true;
end
if ~exist('create','var')||isempty(create)
	create=true;
end
if ~exist('titl','var')
	titl=[];
end

% make sure all figures are found, even the hidden handles (non-integer
% handles)
shH = get(0,'ShowHiddenHandles'); % store state to restore to original
set(0,'ShowHiddenHandles','on')	% make sure hidden handles are found
bHandled=false;
if nargin<1||isempty(t)
	f=findobj('Type','figure');
	Tags=get(f,'Tag');
	Titles=get(f,'Name');
	if isscalar(f)
		Tags={Tags};
		Titles={Titles};
	end
	B=cellfun(@isempty,Tags);
	f(B)=[];
	Tags(B)=[];
	if nargout
		bNew=Tags;
		Stitles=Titles;
	else
		for i=1:length(f)
			fprintf('%10g:\t%-30s\t%s\n',double(f(i)),Tags{i},Titles{i})
		end
	end
	bHandled=true;
else
	f=findobj('Type','figure','Tag',t);
end
set(0,'ShowHiddenHandles',shH);	% reset original state
if bHandled
	% do nothing anymore
elseif isempty(f)
	if ~create
		if nargout
			fout=[];
			bNew=false;
		end
		return
	end
	if ~bForceNormalFigure && exist('nfigure.m','file')
		f=nfigure('Tag',t,options{:});
	else
		f=figure('Tag',t,options{:});
	end
	bNew=true;
else
	if ~strcmp(get(f,'Visible'),'on')
		set(f,'Visible','on')
	end
	if length(f)>1
		warning('More than one figure found!')
		if activate
			for i=1:length(f)
				figure(f(i))
			end
		end
	else
		if activate
			figure(f);
		end
	end
	bNew=false;
	if ~isempty(options)
		try
			[~,~,options] = setoptions({},options{:});	% convert to "standard Matlab options"
			% to allow "creation-options" (like bUIfig), this is done in a
			% loop and not at once
			%set(f,options{1:2,:})
			for i=1:size(options,2)
				if isprop(f,options{1,i})
					set(f,options{1,i},options{2,i})
				else
					fprintf('Assuming an "init-property" (%s) not to be re-set.\n',options{1,i})
				end
			end
		catch err
			DispErr(err)
			warning('Problem with settings - maybe a special (n)figure-setting?')
		end
	end
end
if ~isempty(titl)
	set(f,'Name',titl)
end
if nargout
	fout=f;
end
