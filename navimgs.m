function varargout=navimgs(varargin)
%navimgs - navigator between images
%   navimgs(<directory-list (structure)>[,<directory>])
%   navimgs({<filenamelist>})
%   navimgs(<filenamelist (stringlist)>)
%   navimgs(X)
%      with X a 3D array : X(:,:,1) - first image
%   navimgs(IMGstream)	with IMGstream an object like RIFFstream
%   navimgs(VIDstream)  with VIDstream a VideoReader object
%
%  current figure (if exist) is used.
%  Navigating can be done using the following key-presses:
%      ' ' - next figure
%      'p' - previous figure
%      's' - go to first (start) figure
%      'f' - if the image is a movie ("film"), navimgs is shown in a new figure
%      'e' - go to the last (end) figure
%      'g' - Puts the image (as shown in the figure) in a variable (NVIimg)
%      'c' - copies an image to a "copy-window"
%      'C' - stops copying to the "copy-window" (next copy will go to a new window)
%
%   It's also possible to give a source directory as input.
%      navimgs(<filesnames - any type>,'<directory path>')
%   A third argument can be used to set change the way the files are read.
%     Default, the imread function is used.
%
%   Extra :
%      X=navimgs('get'[,index]); - current data (or data of image #<index>)
%      n=navimgs('n');	 - gives the number of images
%      navimgs('n',n);	 - sets (changes) the number of images
%      X=navimgs('getall'); - all images in one array
%      navimgs first - command line possibility for get next image
%         navimgs next	- optional output : is last
%         navimgs previous - optional output : is first
%         navimgs last
%         navimgs('frame',idx) - go to frame number
%      navimgs('addkeyimg',key,fcn) - adds functionality
%              fcn will be called as : fcn(X), with X image data
%      navimgs{'limit',{<limits>,...}
%         images are limited
%            <limits> length is 2 : dimension of image is calculated as :
%                i=limits[1]:limits[2]:end
%            length is 3
%                i=limits[1]:limits[2]:limits[3]
%            other length
%                i=limits (for example to use one color channel)
%                   to be able to use this option, even with 2 or 3
%                   values, this is also used if first limit<0
%                   the absolute values are taken
%      navimgs axlim [0/1 or false/true] - fixed (X/Y-)axes limits or
%                            rescaling
%      navimgs clim - settings of color - different possibilities
%              navimgs clim auto - automatic adaptation of colors (in fact
%                                  every string will give this)
%              navimgs('clim',[cmin cmax]) - sets fixed color limits
%      navimgs setsave - "installs" a save option (keypress 'S')
%      navimgs setfname <filename-start> - sets the start of the name
%                            of the file (default 'NVimg')
%      navimgs setfext <extension> - sets extension (and with it filetype)
%                     see imwrite for possible extensions
%      navimgs setfdir <directory> - sets directory for saved images
%      navimgs transpose - transposes the figure (also for real-colour images)
%        or navimgs('transpose',0/1) to set it on or off
%      navimgs raw2color - converts raw images (Bayer pattern) to colour
%                        images (uses convRaw2Color)
%      navimgs zoom ['x'/'y'/'xy'(default) - set zooming on (standard off)
%      navimgs('axscale',[xmin xmax],[ymin ymax])
%                     or navimgs('axscale',[xmin xmax ymin ymax])
%      navimgs('fcnUpdate',fcn) - sets a function called after updating
%                    extra input: 'NAVIMGSbUpdateX': true ==> image (X) adapted
%              without NAVIMGSbUpdateX:
%                     function called: fcn(idx)
%              with NAVIMGSbUpdateX
%                     function called: X=fcn(idx,X)
%      navimgs('otherKeyFcn',fcn) - add function for handling not handled keys
%              fcn must be a function with normal key-callback signature
%               !!!!!!!! see addkeyimg !!!!!!!!!!
%               reason for new functionality: use of Key and Character...
%               to be reviewed
%
%   Requirement IMGstream: (methods used)
%         length() --> number of images
%         getImage(idx) --> returns the image at index idx

%  FMTC - Stijn Helsen - 2007

%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
% *  Maybe extend AddKeyImg with "default action" as a replacement for
%          otherKeyFcn?
%!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

D=varargin{1};
if isstruct(D)||isobject(D)||iscell(D)||ischar(D)||(isnumeric(D)&&~ismatrix(D))
	f=gcf;
	if ischar(D)&&size(D,1)==1
		switch lower(D)
			case 'get'
				h=getappdata(f,'NAVIMGShImg');
				if isempty(h)
					% this is not a navimg figure
					fs=findobj('type','figure');
					fNI=false(1,length(fs));
					for i=1:length(fs)
						h=getappdata(fs(i),'NAVIMGShImg');
						fNI(i)=~isempty(h);
					end
					if ~any(fNI)
						error('At least one navimgs window must exist!')
					elseif sum(fNI)>1
						error('Current figure is no navimgs window, and more than one exists! Make the right one current, and do the same...')
					end
					f=ancestor(fs(fNI~=0),'figure');
					figure(f)
					h=getappdata(f,'NAVIMGShImg');
				end
				if nargin>1
					i=varargin{2};
					n=getappdata(f,'NAVIMGSn');
					if ischar(i)
						if strcmpi(i,'last')
							i=n;
						else
							error('Wrong input for navimgs get')
						end
					elseif ~isnumeric(i)||~isscalar(i)||i<1||i~=round(i)||i>n
						error('Wrong index value')
					end
					setappdata(f,'NAVIMGSidx',i)
					Update(f,0);
				end	% nargin>1
				X=get(h,'CData');
				varargout{1}=X;
				if nargout>1
					varargout{2}=h;
				end
			case 'n'
				if nargin>1
					setappdata(f,'NAVIMGSn',varargin{2});
				else
					n=getappdata(f,'NAVIMGSn');
					varargout={n};
				end
			case 'getall'
				h=getappdata(f,'NAVIMGShImg');
				X=get(h,'CData');
				n=getappdata(f,'NAVIMGSn');
				sX=size(X);
				nD=length(sX);
				ciX={1:sX(1),1:sX(2)};
				if nD==3
					ciX{3}=1:sX(3);
				elseif nD~=2
					error('Unknown type')
				end
				X=X(ciX{:},ones(1,n));
				bSizeFault=false;
				for idx=1:n
					setappdata(f,'NAVIMGSidx',idx)
					Update(f,0)
					drawnow
					X1=get(h,'CData');
					sX1=size(X1);
					if length(sX1)~=nD||(nD==3&&sX(3)~=sX1(3))
						warning('NAVIMGS:imgssize','!!Type of images have to be the same!! - only %d images read',idx-1)
						break
					end
					if any(sX1~=sX)
						if ~bSizeFault
							bSizeFault=true;
							warning('NAVIMGS:imgformat','!!Not all images have the same format!!')
						end
						if any(sX1>sX)
							csX1=num2cell(sX1);
							X(csX1{:},n)=0;
						end
						if any(sX>sX1)
							csX=num2cell(sX);
							X1(csX{:})=0;
						end
					end	% different size
					X(ciX{:},idx)=X1;
				end	% for idx
				setappdata(f,'NAVIMGSidx',idx)
				Update(f,0)
				varargout{1}=X;
			case 'addkeyimg'
				bReplace=true;
				if nargin>3
					i=varargin{4};
					if isnumeric(i)
						bReplace=i~=0;
					elseif islogical(i)
						bReplace=i;
					else
						switch lower(i)
							case {'0','no','off'}
								bReplace=false;
							case {'1','yes','on'}
								bReplace=true;
							otherwise
								error('Wrong input')
						end
					end
				end
				key=varargin{2};
				if isnumeric(key)
					if ~isscalar(key)
						error('Numeric key-data must be scalar!')
					elseif key~=round(key)||key<0||key>65535
						error('Impossible key code!')
					end
					key=char(key);
				end
				sKeysData='NIimgKeys';
				sKeyFcns='NIimgFcns';
				if ischar(key)
					if ~isscalar(key)
						error('Sorry, only single character keys are allowed!')
					elseif any(key==' sepg')
						error('Basic key-commands are not allowed to be overwritten')
					end
				elseif iscell(key)	% key (not character)
					sKeysData='NIimgKeyCodes';
					sKeyFcns='NIimgKeyFcns';
				else
					error('Unknown type of key-data!')
				end
				keys=getappdata(f,sKeysData);
				if isempty(keys)
					keys=key(1);
					fcns=varargin(3);
				else
					if iscell(keys)
						B=strcmpi(keys,key{1});	% (!)only first element used - extend to modifiers?
						if any(B)
							if ~bReplace
								return
							end
							i=find(B);
							warning('NAVIMGS:overwrittenkey','key is overwritten')
						else
							i=length(keys)+1;
							keys(1,i)=key(1);
						end
					elseif any(keys==key)
						if ~bReplace
							return
						end
						i=find(keys==key);
						warning('NAVIMGS:overwrittenkey','key is overwritten')
					else
						i=length(keys)+1;
						keys(1,i)=key;
					end
					fcns=getappdata(f,sKeyFcns);
					fcns{i}=varargin{3};
				end
				setappdata(f,sKeysData,keys);
				setappdata(f,sKeyFcns,fcns);
			case 'first'
				ev=struct('Character','s','Modifier',{cell(1,0)}	...
					,'Key','space');
				NAVkey(f,ev)
			case 'next'
				ev=struct('Character',' ','Modifier',{cell(1,0)}	...
					,'Key','space');
				NAVkey(f,ev)
				if nargout
					n=getappdata(f,'NAVIMGSn');
					idx=getappdata(f,'NAVIMGSidx');
					varargout={idx==n};
					if nargout>1
						varargout{2}=idx;
					end
				end
			case 'frame'
				h=getappdata(f,'NAVIMGShImg');
				if isempty(h)
					error('Something wrong!')
				end
				i=varargin{2};
				n=getappdata(f,'NAVIMGSn');
				if ischar(i)
					if strcmpi(i,'last')
						i=n;
					else
						error('Wrong input for navimgs get')
					end
				elseif ~isnumeric(i)||~isscalar(i)||i<1||i~=round(i)||i>n
					error('Wrong index value')
				end
				setappdata(f,'NAVIMGSidx',i)
				Update(f,0);
			case 'previous'
				ev=struct('Character','p','Modifier',{cell(1,0)}	...
					,'Key','p');
				NAVkey(f,ev)
				if nargout
					idx=getappdata(f,'NAVIMGSidx');
					varargout={idx==1};
					if nargout>1
						varargout{2}=idx;
					end
				end
			case 'last'
				ev=struct('Character','e','Modifier',{cell(1,0)}	...
					,'Key','space');
				NAVkey(f,ev)
				if nargout>0
					varargout={getappdata(f,'NAVIMGSn')};
				end
			case 'limit'
				setappdata(f,'NAVIMGSlimit',varargin{2});
				Update(f,0)
			case 'axlim'
				if nargin>1
					lim=varargin{2};
					if ischar(lim)
						switch lower(lim)
							case {'0','false','off','no'}
								lim=false;
							case {'1','true','on','yes'}
								lim=true;
							case 'keep'
								lim='keep';
							otherwise
								error('Wrong use of navimgs axlim setting')
						end
					end
				else
					lim=getappdata(f,'NAVIMGSaxlim');
					if isempty(lim)
						lim=true;
					else
						lim=~lim;
					end
					fprintf('axes limits - ')
					if lim
						fprintf('automatic\n')
					else
						fprintf('fixed\n')
					end
				end
				setappdata(f,'NAVIMGSaxlim',lim)
			case 'clim'
				h=getappdata(f,'NAVIMGShImg');
				clim=varargin{2};
				if isnumeric(clim)
					set(h,'CDataMapping','scaled')
					set(get(h,'parent'),'CLim',clim)
				else
					set(h,'CDataMapping','scaled')
					set(get(h,'parent'),'CLimmode','auto')
				end
			case 'setsave'
				navimgs('addkeyimg','S',@SaveImage)	% "half integrated"
			case 'setfext'
				setappdata(f,'NVimgFExt',varargin{2});
			case 'setfdir'
				setappdata(f,'NVimgDest',varargin{2})
			case 'transpose'
				if nargin>1
					b=varargin{2};
				else
					b=getappdata(f,'NVtranspose');
					if isempty(b)
						b=true;
					else
						b=~b;
						sOnOff={'ff','n'};
						fprintf('image transpose is switched o%s\n',sOnOff{b+1})
					end
				end
				setappdata(f,'NVtranspose',b)
				Update(f,0)
            case 'raw2color'
				if nargin>1
					b=varargin{2};
				else
					b=getappdata(f,'NVrawcolor');
					if isempty(b)
						b=true;
					else
						b=~b;
						sOnOff={'ff','n'};
						fprintf('color conversion is switched o%s\n',sOnOff{b+1})
					end
				end
				setappdata(f,'NVrawcolor',b)
				if nargin>2
					setappdata(f,'NVrcOptions',varargin{3});
				else
					rcOpts=getappdata(f,'NVrcOptions');
					if isempty(rcOpts)
						setappdata(f,'NVrcOptions',{'bRevCol',true,'bTranspose',false});
					end
				end
				Update(f,0)
			case 'film'
				CopyToFilmFigure(f);
			case 'zoom'
				bZoom=[true true];
				if nargin>1
					typ=varargin{2};
					switch lower(typ)
						case 'x'
							bZoom=[true false];
						case 'y'
							bZoom=[false true];
						case 'xy'
							bZoom=[true true];
						otherwise
							error('Wrong use of zoom-option of navimgs')
					end
				end
				navimgs('addkeyimg','i',@ZoomIn,false)
				navimgs('addkeyimg','u',@ZoomOut,false)
				navimgs('addkeyimg','o',@ZoomOut,false)
				navimgs('addkeyimg',28,@MoveLeft1,false)
				navimgs('addkeyimg',29,@MoveRight1,false)
				navimgs('addkeyimg','l',@MoveLeft,false)
				navimgs('addkeyimg','r',@MoveRight,false)
				navimgs('addkeyimg',30,@MoveUp,false)
				navimgs('addkeyimg',31,@MoveDown,false)
				navimgs('addkeyimg','X',@FullZoom,false)
				setappdata(f,'NIzoom',bZoom)
			case 'axscale'
				xscale=varargin{2};
				if length(xscale)==4
					yscale=xscale(3:4);
					xscale=xscale(1:2);
				else
					yscale=varargin{3};
				end
				h=getappdata(f,'NAVIMGShImg');
				set(h,'XData',xscale,'YData',yscale)
				set(ancestor(h,'axes'),'xlim',xscale([1 end]),'ylim',yscale([1 end]))
			case 'titles'
				setappdata(f,'NAVIMGStitles',varargin{2})
			case 'fcnupdate'
				setappdata(f,'NAVIMGSfcnUpdate',varargin{2})
				if length(varargin)>2
					setappdata(f,'NAVIMGSbUpdateX',varargin{3})
				end
			case 'otherkeyfcn'
				if isempty(varargin{2})
					if isappdata(f,'otherKeyAction')
						rmappdata(f,'otherKeyAction')
					end
				else
					setappdata(f,'otherKeyAction',varargin{2})
				end
			case 'fcnclick'
				set(getappdata(f,'NAVIMGShImg'),'ButtonDownFcn',varargin{2})
			case 'link'
				LinkFigures(varargin{2});
			case 'reset'
				Update(f,true);
			otherwise
				warning('NAVIMGS:unknowninput','Unknown use of navimgs - nothing happened')
		end	% switch
		return
	end
	if isstruct(D)&&isfield(D,'cdata')&&isfield(D,'colormap')
		% output of a avifile
		if ~isempty(D(1).colormap)
			colormap(D(1).colormap);
		end
		D={D.cdata};
	end
	if isstruct(D)||iscell(D)
		n=length(D);
	elseif isobject(D)
		if isa(D,'VideoReader')
			try
				n=D.NumberOfFrames();
			catch
				warning('I couldn''t get the right number of frames!')
				n=round(D.Duration*D.FrameRate);
			end
		else
			n=D.length();
		end
	elseif ischar(D)
		n=size(D,1);
	elseif ndims(D)==3
		n=size(D,3);
	elseif ndims(D)==4
		n=size(D,4);
	else
		error('Something is wrong!')
	end
	imRfcn=@imread;
	if nargin>1
		sDir=varargin{2};
		if ~isempty(sDir)&&sDir(end)~=filesep
			sDir(end+1)=filesep;
		end
		if nargin>2
			imRfcn=varargin{3};
		end
	else
		sDir='';
	end
	set(f,'Name',sprintf('%d images',n))
	setappdata(f,'NAVIMGSdata',D)
	setappdata(f,'NAVIMGSn',n);
	setappdata(f,'NAVIMGSidx',1)
	setappdata(f,'NAVIMGSdir',sDir)
	setappdata(f,'NAVIMGSfcn',imRfcn)
	setappdata(f,'NAVIMGSsavename','NVimg')
	setappdata(f,'NAVIMGSbFilmMsg',false)
	set(f,'KeyPressFcn',@NAVkey)
	Update(f,1)
end

function Update(f,bInit)
imgLimit=getappdata(f,'NAVIMGSlimit');
axlim=getappdata(f,'NAVIMGSaxlim');
bConvColor=getappdata(f,'NVrawcolor');
imgPixScale=getappdata(f,'imgPixScale');
bUsePCOLOR=getappdata(f,'bUsePCOLOR');
ImgTranformData = getappdata(f,'ImgTranformData');
if isempty(bConvColor)
    bConvColor=false;
end
if isempty(bUsePCOLOR)
	bUsePCOLOR=false;
end
[X,tit]=GetImage(f,bInit);
bFilm=size(X,3)>3;	%(!)img-array was niet voorzien van kleurdata, en dit wel?
if bConvColor&&~bFilm
	rcOpts=getappdata(f,'NVrcOptions');
    X=convRaw2Color(X,rcOpts);
end
if bFilm
	setappdata(f,'NAVIMGSfilm',X);
	bFilmMsg=getappdata(f,'NAVIMGSbFilmMsg');
	if ~bFilmMsg
		setappdata(f,'NAVIMGSbFilmMsg',true)
		warning('NAVIMGS:imgismovie','!This is a movie - the first frame is shown, use ''f'' to view this movie')
	end
	X=X(:,:,1)';
end
setappdata(f,'NVfilm',bFilm)
if ~isempty(imgLimit)
	for i=1:length(imgLimit)
		if imgLimit{i}(1)<0
			imgLimit{i}=abs(imgLimit{i});
		elseif length(imgLimit{i})==2
			imgLimit{i}=imgLimit{i}(1):imgLimit{i}(2):size(X,i);
		elseif length(imgLimit{i})==3
			imgLimit{i}=imgLimit{i}(1):imgLimit{i}(2):imgLimit{i}(3);
		end
	end
	X=X(imgLimit{:});
end
bTranspose=getappdata(f,'NVtranspose');
if isempty(bTranspose)
	bTranspose=false;
end
if bTranspose
	if ismatrix(X)
		X=X';
	else
		X=permute(X,[2 1 3]);
	end
end
if ~isempty(imgPixScale)
    X=X*imgPixScale;
end
if ~isempty(ImgTranformData)
	X = ImgTranformData.Transform(X);
end

if bInit
	if bUsePCOLOR
		h=pcolor((1:size(X,2))-0.5,(1:size(X,1))-0.5,X);
	else
		h=imagesc(X);
	end
	ax=ancestor(h,'axes');
	setappdata(f,'NAVIMGShImg',h)
	if ischar(axlim)
		axlim=[];
	end
else
	h=getappdata(f,'NAVIMGShImg');
	ax=ancestor(h,'axes');
	if ischar(axlim)
		axlim=[xlim(ax) ylim(ax)];
	end
	set(h,'CData',X)
end
set(get(ax,'Title'),'String',tit,'Interpreter','none')
if isempty(axlim)||~isscalar(axlim)||axlim
	if length(axlim)==4
		xl=axlim(1:2);
		yl=axlim(3:4);
	else
		sx=size(X,2);
		sy=size(X,1);
		xl=get(h,'XData');
		yl=get(h,'YData');
		xl=xl([1 end]);
		yl=yl([1 end]);
		xl=xl(1)+diff(xl)/max(2,sx-1)*[-0.5 sx-0.5];
		yl=yl(1)+diff(yl)/max(2,sy-1)*[-0.5 sy-0.5];
	end
	set(get(h,'Parent'),'XLim',xl,'YLim',yl)
end

function [X,tit]=GetImage(f, bReset)
persistent IsUpdating
if nargin>1&&bReset
	IsUpdating =  false;
end
D=getappdata(f,'NAVIMGSdata');
idx=getappdata(f,'NAVIMGSidx');
imRfcn=getappdata(f,'NAVIMGSfcn');
sDir=getappdata(f,'NAVIMGSdir');
bLoad=false;
if ischar(D)
	fName=deblank(D(idx,:));
	bLoad=true;
elseif isobject(D)
	if isa(D,'VideoReader')
		X=D.read(idx);
	else
		X=D.getImage(idx);
	end
	if isstruct(X)
		switch X.err
			case 'max'
				nNew=X.n;
				X=X.X;
				setappdata(f,'NAVIMGSn',nNew);
			otherwise
				error('Not implemented!')
		end
	end
	tit=sprintf('%4d/%d',idx,getappdata(f,'NAVIMGSn'));
elseif iscell(D)
	if ischar(D{idx})
		fName=D{idx};
		bLoad=true;
	elseif isnumeric(D{idx})
		X=D{idx};
		tit=sprintf('%2d',idx);
	else
		error('Unknown use')
	end
elseif isstruct(D)
	fName=fullfile(D(idx).folder,D(idx).name);
	bLoad=true;
else
	if ismatrix(D)
		if idx>1
			error('Only 1 image available!')
		else
			X=D;
			nX=1;
		end
	elseif ndims(D)<4
		X=D(:,:,idx);
		nX=size(D,3);
	else
		X=D(:,:,:,idx);
		nX=size(D,4);
	end
	tits=getappdata(f,'NAVIMGStitles');
	if idx<=length(tits)
		tit=sprintf('%d/%d: %s',idx,nX,tits{idx});
	else
		tit=sprintf('%d/%d',idx,nX);
	end
end
if bLoad
	if isempty(sDir)&&~exist(fName,'file')
		if exist(zetev([],fName),'file')
			sDir=zetev();
			setappdata(f,'NAVIMGSdir',sDir);
		else
			error('Can''t find file (#%d) %s!',idx,fName)
		end
	end
	X=imRfcn([sDir fName]);
	[~,fNm,fExt] = fileparts(fName);
	tit=sprintf('%2d - %s',idx,[fNm,fExt]);
end
fcnUpdate=getappdata(f,'NAVIMGSfcnUpdate');
bUpdateX=getappdata(f,'NAVIMGSbUpdateX');
if ~isempty(fcnUpdate)&&(isempty(IsUpdating)||~IsUpdating)
	IsUpdating=true;	% to avoid reentrant execuation
		% another method could be the use of dbstack(?)
	try
		if iscell(fcnUpdate)
			fcnList=fcnUpdate;
		else
			fcnList={fcnUpdate};
		end
		for i=1:length(fcnList)
			fcnUpdate=fcnList{i};
			if isa(fcnUpdate,'function_handle')
				if bUpdateX
					X=fcnUpdate(X,idx);
				else
					fcnUpdate(idx)
				end
			else
				error('Wrong updateFcn!')
			end
		end
	catch err
		IsUpdating=false;
		rethrow(err)
	end
	IsUpdating=false;
end

function NAVkey(f,ev)
n=getappdata(f,'NAVIMGSn');
idx=getappdata(f,'NAVIMGSidx');
bUpdate=false;
c=ev.Character;
if isempty(c)
	c=ev.Key;
end
bDone = false;
if isempty(ev.Character)	% two kinds should be combined!!!
	keys=getappdata(f,'NIimgKeyCodes');
	if ~isempty(keys)
		B=strcmpi(ev.Key,keys);
		if any(B)
			fcns=getappdata(f,'NIimgKeyFcns');
			fcn=fcns{B};
			h=getappdata(f,'NAVIMGShImg');
			X=get(h,'CData');
			fcn(X,get(get(ancestor(h,'axes'),'Title'),'String'));
			bDone = true;
		end	% known key
	end	% ~isempty(keys)
else
	keys=getappdata(f,'NIimgKeys');
	if ~isempty(keys)
		if any(ev.Character==keys)
			fcns=getappdata(f,'NIimgFcns');
			fcn=fcns{ev.Character==keys};
			h=getappdata(f,'NAVIMGShImg');
			X=get(h,'CData');
			fcn(X,get(get(ancestor(h,'axes'),'Title'),'String'));
			bDone = true;
		end	% known key
	end	% ~isempty(keys)
end
if ~bDone
	switch c
		case ' '
			idx=idx+1;
			if idx>n
				idx=1;
			end
			bUpdate=true;
		case {'s','0'}
			idx=1;
			bUpdate=true;
		case {'1',29}	% right
			idx=min(n,idx+1);
			bUpdate=true;
		case {'2',30}	% up
			idx=min(n,idx+10);
			bUpdate=true;
		case {'3','pagedown'}
			idx=min(n,idx+100);
			bUpdate=true;
		case '4'
			idx=min(n,idx+1000);
			bUpdate=true;
		case {'9',28}	% left
			idx=max(1,idx-1);
			bUpdate=true;
		case {'8',31}	% down
			idx=max(1,idx-10);
			bUpdate=true;
		case {'7','pageup'}
			idx=max(1,idx-100);
			bUpdate=true;
		case '6'
			idx=max(1,idx-1000);
			bUpdate=true;
		case 'f'
			bFilm=getappdata(f,'NVfilm');
			if ~isempty(bFilm)&&bFilm
				CopyToFilmFigure(f);
			end
		case 'e'
			idx=n;
			bUpdate=true;
		case 'p'
			idx=idx-1;
			if idx<1
				idx=n;
			end
			bUpdate=true;
		case 'g'
			h=getappdata(f,'NAVIMGShImg');
			X=get(h,'CData');
			assignin('base','NVIimg',X);
		case 'c'
			h=getappdata(f,'NAVIMGShImg');
			X=get(h,'CData');
			CC=get(f,'colormap');
			[f1,nfig]=getmakefig('NVIcopy',0);
			sTit=sprintf('Copy of image (%s)',get(get(get(h,'parent'),'title'),'string'));
			if nfig
				set(f1,'Name','NAVIMGS copy figure')
				h1=image(X);
				title(sTit,'interpreter','none')
				ax1=get(h1,'parent');
				ax0=get(h,'parent');
				set(f1,'colormap',CC)
				setappdata(f1,'hImage',h1);
				imSets={'CDataMapping','XData','YData'};
				axSets={'YDir','XLim','YLim','XLimMode','YlimMode'	...
					,'XTick','YTick','XTickLabel','YTickLabel'	...
					,'XTickLabelMode','XTickLabelMode'	...
					,'YTickLabelMode','YTickLabelMode'};
				for i=1:length(imSets)
					set(h1,imSets{i},get(h,imSets{i}))
				end
				for i=1:length(axSets)
					set(ax1,axSets{i},get(ax0,axSets{i}))
				end
				xlabel(get(get(ax0,'XLabel'),'String'))
				ylabel(get(get(ax0,'YLabel'),'String'))
			else
				h1=getappdata(f1,'hImage');
				set(h1,'CData',X)
				set(get(get(h1,'parent'),'title'),'string',sTit,'interpreter','none')
			end
		case 'C'
			f1=findobj('Type','figure','Tag','NVIcopy');
			if ~isempty(f1)
				set(f1,'Tag','')
			end
		case char(3)
			close(f)
		case 't'	% show all figures
			fLinked=getappdata(f,'NAVIMGSlinked');
			B=false(size(fLinked));
			for i=1:numel(fLinked)
				if isgraphics(fLinked(i))
					figure(fLinked(i))
				else
					B(i)=true;
				end
			end
			if any(B(:))
				LinkFigures(fLinked(~B));
				warning('Figures relinked!')
			end
		otherwise
			fcn = getappdata(f,'otherKeyAction');
			if ~isempty(fcn)
				fcn(f,ev)
			end
	end
end
if bUpdate
	setappdata(f,'NAVIMGSidx',idx)
	Update(f,0);
end

function SaveImage(X,tit)
f=gcf;
i=find(tit=='-');
if isempty(i)
	fn=getappdata(f,'NAVIMGSsavename');
	fn=sprintf('%s%03d',fn,str2double(tit));
else
	s=tit(i+2:end);
	[~,fn]=fileparts(s);
end
fext=getappdata(f,'NVimgFExt');
if isempty(fext)
	fext='.png';
end
fDest=getappdata(f,'NVimgDest');
if isempty(fDest)
	fDest='';
elseif fDest(end)~=filesep
	fDest(end+1)=filesep;
end
fName=[fDest fn fext];
imwrite(X,fName)
fprintf('Image written to %s.\n',fName)

function Zoom(ax,fac)
f=get(ax,'parent');
bZoom=getappdata(f,'NIzoom');
if bZoom(1)	% x
	xl=get(ax,'XLim');
	xl=mean(xl)+(xl-(mean(xl)))*fac;
	set(ax,'XLim',xl)
end
if bZoom(2)	% y
	yl=get(ax,'YLim');
	yl=mean(yl)+(yl-(mean(yl)))*fac;
	set(ax,'YLim',yl)
end

function ZoomIn(~,~)
Zoom(gca,.5)

function ZoomOut(~,~)
Zoom(gca,2)

function Move(ax,step)
xl=get(ax,'xlim');
yl=get(ax,'ylim');
xl=xl+step(1)*diff(xl);
yl=yl+step(2)*diff(yl);
set(ax,'xlim',xl,'ylim',yl)

function MoveLeft1(~,~)
Move(gca,[-0.1 0])

function MoveRight1(~,~)
Move(gca,[0.1 0])

function MoveLeft(~,~)
Move(gca,[-0.5 0])

function MoveRight(~,~)
Move(gca,[0.5 0])

function MoveUp(~,~)
ax=gca;
dy=0.5;
if strcmp(get(ax,'YDir'),'reverse')
	dy=-dy;
end
Move(ax,[0 dy])

function MoveDown(~,~)
ax=gca;
dy=-0.5;
if strcmp(get(ax,'YDir'),'reverse')
	dy=-dy;
end
Move(ax,[0 dy])

function FullZoom(~,~)
ax=gca;
h=findobj(gca,'Type','image');
xl=get(h,'XData');
yl=get(h,'YData');
set(ax,'XLim',xl([1 end]),'YLim',yl([1 end]))

function CopyToFilmFigure(f)
CC=get(f,'colormap');
X=getappdata(f,'NAVIMGSfilm');
f1=nfigure;
navimgs(X);
navimgs('transpose',true)
set(f1,'colormap',CC)

function LinkFigures(fLinked)
for i=1:length(fLinked)
	setappdata(fLinked(i),'NAVIMGSlinked',fLinked)
	setappdata(fLinked(i),'NAVIMGSfcnUpdate',@UpdateLinked)
end

function UpdateLinked(idx)
f=gcbf;
fLinked=getappdata(f,'NAVIMGSlinked');
B=false(size(fLinked));
for i=1:numel(fLinked)
	fi=fLinked(i);
	if fi~=f
		if isgraphics(fi)
			setappdata(fi,'NAVIMGSidx',idx)
			Update(fi,0);
		else
			B(i)=true;
		end
	end
end
if any(B)
	warning('Figures relinked!')
	LinkFigures(fLinked)
end
