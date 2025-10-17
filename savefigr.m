function savefigr(fig,varargin)
% SAVEFIGR - Bewaart figuur naar file op (mijn) standaard manier
%   savefigr([fig[,fname[,siz[,pos[,opt[,options]]]]]])
%   savefigr([fig[,fname[,siz[,options]]])
%   savefigr([fig[,fname[,options]])
%   savefigr(fname[,...]) uses current figure
%
%   default filename : 'lastfig'
%   options: bOverwrite, bCropImage, bTranspEdge
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
			savefigr(fig(i),fig{i,2},varargin{:})
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
[bOverwrite,bCropImage,bTranspEdge]=deal(false,true,false);	% defaults (don't "show" to Matlab
	% the starting values - because of "confusing Mlint")
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
if isempty(opt)
	opt={};
elseif ischar(opt)
	opt={opt};
end
if ~isempty(inp)
	i=1;
	while i<=length(inp)
		if strncmp(inp{i},'-r',2)
			opt{end+1}=inp{i}; %#ok<AGROW>
			inp(i)=[];
		else
			i=i+1;
		end
	end
	setoptions({'bOverwrite','bCropImage','bTranspEdge'},inp{:})
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
	fname=[fname '.png'];
	fext='.png';
end
bNoCrop = false;
switch lower(fext)
	case '.eps'
		opt{end+1}='-depsc';
		bNoCrop = true;
	case '.png'
		opt{end+1}='-dpng';
	case {'.jpg','jpeg'}
		opt{end+1}='-djpeg';
	case {'.tif','.tiff'}
		opt{end+1}='-dtiff';
	case '.emf'
		opt{end+1}='-dmeta';
		bNoCrop = true;
		% no option (not saved via print command)
	case '.hdf'
		opt{end+1}='-dhdf';
		bNoCrop = true;
	case '.svg'
		opt{end+1}='-dsvg';
		bNoCrop = true;
	otherwise
		opt{end+1}='-depsc';
		bNoCrop = true;
		warning('SAVEFIG:unknownOption','!!onbekende optie!!')
end
if bNoCrop && bCropImage
	warning('This type of image (%s) can''t be cropped here!',fext)
	bCropImage = false;
end
figure(fig)
if ~bOverwrite&&exist(fname,'file')
	error('File already exists - use option "bOverwrite" if you want to overwrite')
end
orient(fig,'tall')
set(fig,'paperunits','centimeter','papersize',siz,'paperposition',pos)
%set(fig,'paperunits','centimeter','papersize',siz)
if strcmpi(fext,'.emf')
	if ~isempty(opt)
		warning('Saving to emf is not done via print but via saveas, some options are not used!')
	end
	saveas(fig,fname,'emf')
else
	print(fname,['-f' num2str(double(fig))],opt{:});
	if bTranspEdge||bCropImage
		Ximg=imread(fname);
		Alpha=[];
		if bTranspEdge
			% this is done before cropping because otherwise parts of the edge
			%   might be blocked
			Bsel=BlobSelect2D(Ximg);
			Alpha=zeros(size(Ximg,1),size(Ximg,2),'uint8');
			Alpha(~Bsel)=uint8(255);
		end
		if bCropImage
			[L,Ximg]=CheckMarginImg(Ximg);
			if ~isempty(Alpha)
				Alpha=Alpha(L(2,1):L(2,2),L(1,1):L(1,2));
			end
		end
		%Overwrite file
		if isempty(Alpha)
			imwrite(Ximg,fname)
		else
			imwrite(Ximg,fname,'Alpha',Alpha)
		end
	end
end
