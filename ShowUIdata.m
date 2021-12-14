function varargout=ShowUIdata(in,varargin)
%ShowUIdata - Show data saved by "plotui"
%      ShowUIdata(fName)
%      ShowUIdata(nr)
%      ShowUIdata(PUIdata)
%      ShowUIdata(UIdata)
%      D=ShowUIdata('getRaw')
%      D=ShowUIdata('get')
%      D=ShowUIdata('getFiles')
%      ShowUIdata('setD',<type>,data)
%         ShowUIdata('setD','l<X/Y>','label','unit')
%      ShowUIdata('setL',<nr>,<type>,<data>)

persistent FILES

bRead=false;
bTranslateStruct=false;
if isnumeric(in)
	if isempty(FILES)
		FILES=dir('*.mat');
		FILES=sort(FILES,'datenum');
		B=false(size(FILES));
		for i=1:length(FILES)
			fd=who('-file',FILES(i).name);
			B(i)=ismember('PUIdata',fd);
		end
		FILES=FILES(B);
	end
	bRead=isscalar(in)&&in==floor(in)&&in>0&&in<=length(FILES);
	if bRead
		fName=FILES(in).name;
	else
		error('numbered file must be between 1 and %d',length(FILES))
	end
elseif ischar(in)
	switch lower(in)
		case 'getraw'
			f=GetUIfig();
			D=getappdata(f,'Xraw');
			varargout={D};
			return
		case 'get'
			f=GetUIfig();
			D=GetData(f);
			varargout={D};
			return
		case 'getfiles'
			varargout={FILES};
			return
		case 'setd'
			f=GetUIfig();
			D=GetData(f);
			fn=varargin{1};
			if isfield(D,fn)
				D.(fn)=varargin{2};
				if any(strcmp(fn,{'lX','lY'}))&&length(varargin)>2
					fn(1)='u';
					D.(fn)=varargin{3};
				end
			else
				error('non-existing field!')
			end
			SetData(f,D);
			PlotData(D)
			return
		case 'setl'
			f=GetUIfig();
			nr=varargin{1};
			tp=varargin{2};
			d=varargin{3};
			D=GetData(f);
			if isfield(D.L,tp)
				D.L(nr).(tp)=d;
			else
				error('non-existing field!')
			end
			SetData(f,D);
			PlotData(D)
			return
		case 'plotui'
			X=plotui('get');
			fName=plotui('figName');
			if isempty(fName)
				fName='unknown';
			else
				[~,fName]=fileparts(fName);
			end
			bTranslateStruct=true;
		case 'xlog'
			f=GetUIfig();
			D=GetData(f);
			l=getappdata(f,'lines');
			for i=1:length(D.L)
				D.L(i).X=10.^D.L(i).X;
				set(l(i),'Xdata',D.L(i).X)
			end
			set(get(l(i),'parent'),'Xscale','log')
			SetData(f,D)
			setappdata(f,'bXlog',true);
			return
		case 'ylog'
			f=GetUIfig();
			D=GetData(f);
			l=getappdata(f,'lines');
			for i=1:length(D.L)
				D.L(i).Y=10.^D.L(i).Y;
				set(l(i),'ydata',D.L(i).Y)
			end
			set(get(l(i),'parent'),'yscale','log')
			SetData(f,D)
			setappdata(f,'bYlog',true);
			return
		otherwise
			bRead=true;
			fName=in;
	end
elseif isstruct(in)
	if isfield(in,'file')
		D=in;
	elseif isfield(in,'L')&&isfield(in,'schaal')
		fName='unknown';
		bTranslateStruct=true;
		X=in;
	elseif isfield(in,'name')&&isfield(in,'datenum')
		fName=in;
		bRead=true;
	else
		error('Unknown input')
	end
else
	error('Wrong use')
end
f=getmakefig('UI_data');
if bRead
	X=load(fName);
	X=X.PUIdata;
	bTranslateStruct=true;
end
if bTranslateStruct
	D=struct('file',fName,'description',[],'info',[]	...
		,'lX',[],'lY',[],'uX',[],'uY',[]	...
		,'L',struct('info',cell(1,length(X.L)-1),'X',[],'Y',[]));
	for i=1:length(X.L)-1
		D.L(i).X=X.L(i+1).xs;
		D.L(i).Y=X.L(i+1).ys;
	end
	setappdata(f,'Xraw',X)
end
setappdata(f,'bXlog',false);
setappdata(f,'bYlog',false);
PlotData(D)
SetData(f,D)

function D=GetData(f)
D=getappdata(f,'Xlines');

function SetData(f,D)
setappdata(f,'Xlines',D)

function PlotData(D)
B=false(1,length(D.L));
l=zeros(1,length(B));
f=gcf;
for i=1:length(B)
	if i>1
		hold all
	end
	l(i)=plot(D.L(i).X,D.L(i).Y);
	B(i)=~isempty(D.L(i).info)&&ischar(D.L(i).info);
end
if i>1
	hold off
end
grid on
bXlog=getappdata(f,'bXlog');
if ~isempty(bXlog)&&bXlog
	set(gca,'XScale','log')
end
bYlog=getappdata(f,'bYlog');
if ~isempty(bYlog)&&bYlog
	set(gca,'YScale','log')
end
setappdata(f,'lines',l)
if isempty(D.description)||~ischar(D.description)
	title(D.file,'interpreter','none')
else
	title(D.description)
end
if isempty(D.lX)
	if ~isempty(D.uX)
		xlabel(sprintf('[%s]',D.uX))
	end
else
	if isempty(D.uX)
		xlabel(D.lX)
	else
		xlabel(sprintf('%s [%s]',D.lX,D.uX))
	end
end
if isempty(D.lY)
	if ~isempty(D.uY)
		ylabel(sprintf('[%s]',D.uY))
	end
else
	if isempty(D.uY)
		ylabel(D.lY)
	else
		ylabel(sprintf('%s [%s]',D.lY,D.uY))
	end
end
if all(B)
	legend({D.L.info})
end

function f=GetUIfig()
f=getmakefig('UI_data',true,false);
if isempty(f)
	error('No figure found!')
end
