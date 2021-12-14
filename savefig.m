function savefig(fig,varargin)
% SAVEFIG - Bewaart figuur naar file op (mijn) standaard manier
%   savefig([fig[,fname[,siz[,pos[,opt[,options]]]]]])
%   savefig([fig[,fname[,siz[,options]]])
%   savefig([fig[,fname[,options]])
%   savefig(fname[,...]) uses current figure
%
%   default filename : 'lastfig'
%   options: bOverwrite
%
%  bewaart figuur, standaard naar epsc of volgens extensie

inp=varargin;
if ~exist('fig','var')||isempty(fig)
	fig=gcf;
elseif iscell(fig)
	if isscalar(fig)
		fig=fig{1};
		if ischar(fig)
			fig=getmakefig(fig);
		end
	else
		for i=1:size(fig,1)
			savefig(fig(i),fig{i,2},varargin{:})
		end
		return
	end
elseif ischar(fig)
	inp=[{fig},inp];
	fig=gcf;
end
fname=[];
siz=[];
pos=[];
opt=[];
bOverwrite=false;
if ~isempty(inp)
	fname=inp{1};
	inp(1)=[];
	if ~isempty(inp)&&isnumeric(inp{1})
		siz=inp{1};
		if isequal(siz,0)	% default
			siz=[];
		end
		inp(1)=[];
		if ~isempty(inp)&&isnumeric(inp{1})
			pos=inp{1};
			if isequal(pos,0)	% default
				pos=[];
			end
			inp(1)=[];
			if ~isempty(inp)
				opt=inp{1};
				inp(1)=[];
			end
		end
	end
end
if ~isempty(inp)
	setoptions({'bOverwrite'},inp{:})
	if ischar(bOverwrite)
		bOverwrite=str2num(bOverwrite); %#ok<ST2NM>
	end
end
if isempty(fname)
	fname='lastfig';
	warning('SAVEFIG:defFilename','!!default filename : lastfig')
end
if isempty(siz)
	siz=[17 10];
end
if isempty(pos)
	pos=[0.5 0.5 siz-1];
end
[~,~,fext]=fileparts(fname);
if isempty(fext)
	fname=[fname '.eps'];
	fext='.eps';
end
if isempty(opt)
	opt={};
elseif ischar(opt)
	opt={opt};
end
switch lower(fext)
	case '.eps'
		opt{end+1}='-depsc';
	case '.png'
		opt{end+1}='-dpng';
	case {'.jpg','jpeg'}
		opt{end+1}='-djpeg';
	case {'.tif','.tiff'}
		opt{end+1}='-dtiff';
	case '.emf'
		% no option (not saved via print command)
	otherwise
		opt{end+1}='-depsc';
		warning('SAVEFIG:unknownOption','!!onbekende optie!!')
end
figure(fig)
if ~bOverwrite&&exist(fname,'file')
	error('File already exists - use option "bOverwrite" if you want to overwrite')
end
orient tall
set(fig,'paperunits','centimeter')
set(fig,'papersize',siz)
set(fig,'paperposition',pos)
if strcmpi(fext,'.emf')
	if ~isempty(opt)
		warning('Saving to emf is not done via print but via saveas, some options are not used!')
	end
	saveas(fig,fname,'emf')
else
	print(fname,['-f' num2str(double(fig))],opt{:});
end
