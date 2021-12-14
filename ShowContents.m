function Xout=ShowContents(s,nrecurs,varargin)
%ShowContents - Show contents in a clickable in a uitable
%   (based on print2html - and not (yet) working!!!!!!)
%    ShowContents(d[,nrecurs[,options]])
%        d - data
%        nrecurs - maximum level of recursive writing
%            if not given or empty : 1
%
%    arrays are printed if they are small, otherwise they are summarized in one line.
%    The definition of "small" can be changed by giving options.
%
%    OPTIONS
%    -------
%
%    options can be given as a 2d-cell-array, a 1d-cell-array or a struct :
%       1d :
%           {'option1'[,<value for option1 if necessary>],...}
%       struct :
%           struct('option1',<value for option1>,....);
%       2d :
%           {'option1',<value for option1>;
%            'option2.....}
%           (!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!)
%              this possibility can only be used if more then one option is used
%              otherwise confusion with 1d-list is possible
%     Additionally a string value may be used if one option without value is given.
%
%    The following options are possible (in any combination and order).
%
%        'maxcolarr' (def. 4) : maximum columns to display full array (numeric arrays)
%        'maxrowarr' (def.10) : maximum rows to display full array
%               (this limitation is also used in char-arrays)
%        'maxel'     (def.20) : maximum total number of values to display 1D-list of values
%        'forcehead'          : print head and end of HTML-page
%                In 1d-option-lists no value had to be given, otherwise
%                       values 0 or 1(~=0) can be given or 'on' or 'off'
%                for 1d-option-lists values 0 or 1 are allowed (no char-value
%                       because then this value is interpreted as a new option)
%
%        'numForm'  : the way numbers are displayed (input to fprintf)
%                 default %g : "normal display" (see fprintf-documentation for more details)
%                 (!)Every value displayed is using this format.
%        'emptyArray' : this gives what has to be displayed for an empty array (default '[]')
%        'emptyCell'  : this gives what has to be displayed for an empty cell (default '{}')
%        'maxcolcell' (def. 0) : maximum columns to display full cell
%        'maxrowcell' (def. 0) : maximum rows to display full cell
%        'title' : title of html-page (default Matlab-data display)
%        'bStructFields' : give field list of structures to large to be displayed
%        'customPrint'   : custom print function for specific types
%                          (function with struct output)
%      .................................
%      Other options (related to the display of data) are possible but these are too
%         long to list here.  Look to the comments further in the code to find a more
%         complete list.


% Originally this function was made for structures.  By some simple
%    changes it was made to work on other data too.

stroptions=struct('maxcolarr',6,'maxrowarr',10,'maxel',20	...
	,'maxcolcell',6,'maxrowcell',10	...
	,'maxstrlen',256	...
	,'numForm','%g'	...
	,'emptyArray','[]'	...
	,'emptyCell','{}'	...
	,'optnumtable',''	...
	,'optcelltable',''	...
	,'printhead',0	...
	,'title',''	...
	,'bStructFields',false	...
	,'bExpandComplexS',true		... expand complex structures (like Simulink.Signal)
	,'fig',[]	...
	);

if ~exist('nrecurs','var')||isempty(nrecurs)
	nrecurs=1;
end
options=varargin;

if ~isempty(options)
	if isstruct(options)
		fn=fieldnames(options)';
		for i=1:length(fn)
			fn{2,i}=options.(fn{i});
		end
		options=fn(:);
	end
	[stroptions,~,options]=setoptions(stroptions,options);
	%!!!in older version:
	%   struct       ---> forcevalue --> 1
	%   cell-vector  ---> forcevalue --> 0
	%   cell-array   ---> forcevalue --> 1
	%           ??????????
	if ~isempty(options)
		for i=1:size(options,2)
			stroptions=setlocoptions(stroptions,options{1,i},options{2,i},1);
		end
	end
end

% first create a hierarchical cell vector
Xh=printdata(s,nrecurs,stroptions);

% now make a flat cell-array (elements in rows, hierarchy level in columns)
X=cell(1000,100);
hX=0;
wX=0;
[X,hX,wX,iX,jX]=AddToFlatX(X,hX,wX,iX,jX,

if nargout
	Xout=Xh;
	return
end

% set data in a uitable
if isempty(stroptions.fig)
	fig=nfigure;
elseif ischar(stroptions.title)
	fig=getmakefig(stroptions.title);
elseif ishandle(stroptions.title)
	if strcmp(get(stroptions.title,'type'),'figure')
		fig=stroptions.title;
	else
		error('Wrong type?!')
	end
else
	error('Wrong figure-specification!')
end
if isempty(stroptions.title)
	set(fig,'Name',stroptions.title)
end
p=get(fig,'Position');
hTable=uitable('Position',[1 1 p(3)-2,p(4)-2]	...
	,'CellSelectionCallback',@CellClicked	...
	);
set(hTable,'Units','normalized')
set(hTable,'Data',X)

function X=printdata(d,nrecurs,options)
% printdata - print field-data

sz=size(d);
n=numel(d);
ndim=sum(sz>1);
ndim0=length(sz);
a=cell(1,ndim0);
bGenClassView=false;

class_d=class(d);
if isstruct(d)
	typS='structure';
elseif options.bExpandComplexS&&any(class_d=='.')
	iDot=find(class_d=='.');
	switch lower(class_d(1:iDot(1)-1))
		case 'simulink'
			switch lower(class_d(iDot(1)+1:end))
				case 'signal'
					typS=class_d;
					class_d='struct';	% handle it like a struct
				case 'parameter'
					typS=class_d;
					class_d='struct';
				case 'bus'
					typS=class_d;
					class_d='struct';
				case 'configset'
					typS=class_d;
					class_d='struct';
			end
	end
end		% not a struct
switch class_d
	case 'struct'
		fields=fieldnames(d);
		if nrecurs>0&&n<=options.maxel
			if isempty(d)
				X=sprintf('empty %s (%d fields) ',typS,length(fields));
				if options.bStructFields&&~isempty(fields)
					X=[X,'(',fields{1}];
					if length(fields)>1
						X=[X,sprintf(', %s',fields{2:end})];
					end
					X=[X,')'];
				end
			elseif isscalar(d)
				X=cell(length(fields),1);
				for i=1:length(fields)
					X{i}={fields{i},printdata(d.(fields{i}),nrecurs-1,options)};
				end
			else
				X={fields,cell(n,length(fields))};
				a=cell(1,ndim0);
				for i=1:n
%					sF='';
% 					if ndim>1	% add full index
% 						[a{:}]=ind2sub(sz,i);
% 						sF=[sprintf(' (%d',a{1}),sprintf(',%d',a{2:ndim0}),')'];
% 					end
					for j=1:length(fields)
						X{2}{j,i}=printdata(getfield(d,{i},fields{j}),nrecurs-1,options);
					end	% fields
				end	% rows
			end	% struct array
		else
			X=sprintf('%s %s (%d fields)',typS,stringsize(sz),length(fields));
			if options.bStructFields&&~isempty(fields)
				X=[X,',',sprintf('(%s',fields{1})];
				if length(fields)>1
					X=[X,sprintf(', %s',fields{2:end})];
				end
				X=[X,')'];
			end
		end
	case {'double','single','uint8','int8','uint16','int16'	...
			,'uint32','int32','uint64','int64','sparse','logical'}
		if n==1
			X=sprintf(options.numForm,d);
		elseif n==0
			X=options.emptyArray;
		elseif ndim0==2&&sz(1)<=options.maxrowarr&&sz(2)<=options.maxcolarr
			%options.numForm
			X=d;
		elseif n<=options.maxel
			X=d;
		else
			X=[stringsize(sz) ' '];
			if issparse(d)
				X=[X 'sparse '];
			end
			X=[X,'array'];
		end
	case 'cell'
		if n==0
			X=options.emptyCell;
		elseif nrecurs<=0
			X=[stringsize(sz),' cell array'];
		elseif ndim0==2&&sz(1)<=options.maxrowcell&&sz(2)<=options.maxcolcell
			X={};
			for i=1:sz(1)
				for j=1:sz(2)
					if i*j==1
						X=[X,{'{'}]; %#ok<AGROW>
					end
					X=[X,{printdata(d{i,j},nrecurs-1,options)}]; %#ok<AGROW>
					if i*j==sz(1)*sz(2)
						X=[X,{'}'}]; %#ok<AGROW>
					end
				end
			end	% rows
		elseif n<=options.maxel&&nrecurs>0
			X=[];
			for i=1:n
				[a{:}]=ind2sub(sz,i);
				X=[X,{[sprintf(' %d (%d',i,a{1}),sprintf(',%d',a{2:ndim0}),')']}]; %#ok<AGROW>
				X=[X,{printdata(f,d{i},nrecurs-1,options)}]; %#ok<AGROW>
			end
		else
			X=sprintf('%s cell array\n',stringsize(sz));
		end
	case 'char'
		if ndim0>2||sz(1)>options.maxrowarr||sz(2)>options.maxstrlen
			X=sprintf('%s char array',stringsize(sz));
		elseif isempty(d)
			X='''''';
		else
			X='';
			for i=1:sz(1)-1
				X=[X,deblank(d(i,:)),',']; %#ok<AGROW>
			end
			X=[X,deblank(d(end,:))];
		end
	case 'lvtime'
		if isempty(d)||numel(d)>4||min(size(d))>1
			bGenClassView=true;
		else
			X='';
			for i=1:numel(d)
				if i>1
					X=[X,',']; %#ok<AGROW>
				end
				X=[X,char(d(i))]; %#ok<AGROW>
			end
		end
	case 'function_handle'
		X=char(d);
	case 'timeseries'
		if isscalar(d)
			if ismatrix(d.Data)
				X=sprintf('timeseries %s, %dx%d %s',d.Name,size(d.Data),class(d.Data));
			else
				sz=size(d.Data);
				X=[sprintf('timeseries %s, (%d',d.Name,sz(1))	...
					,sprintf('x%d',sz(2:end))	...
					,sprintf(') %s',class(d.Data))];
			end
		else
			bGenClassView=true;
		end
	otherwise
		bGenClassView=true;
end
if bGenClassView
	sd=size(d);
	X=[sprintf('%s (%d',class(d),size(d,1))	...
		,sprintf('x%d',sd(2:end))	...
		,')'];
end

function ssize=stringsize(sz)
ssize=num2str(sz(1));
ssize=[ssize sprintf('x%d',sz(2:end))];

function [options,n]=setlocoptions(options,opt,value,forcevalue)
% SETLOCOPTIONS - set option according to user supplied option
%   forcevalue means that a value is always given
%   n is 2 if value is used, 1 if value is not used (for determining
%       next value in 1d-lists

n=2;
switch lower(opt)
	case 'forcehead'
		if isnumeric(value)
			options.printhead=value~=0;	% (value could be used but ...)
		elseif forcevalue
			if strcmp(value,'on')	% if value is not numeric or char a matlab-error will occur
				options.printhead=1;
			elseif strcmp(value,'off')
				options.printhead=0;
			else
				error('Invalid value for "forcehead"-option');
			end
		else
			options.printhead=1;
			n=1;
		end
	case 'usecss'	%!!!!!!!!!!!!!! (in basic setoptions!)
		if isnumeric(value)
			options.useCSS=value~=0;	% (value could be used but ...)
		elseif forcevalue
			if strcmp(value,'on')	% if value is not numeric or char a matlab-error will occur
				options.useCSS=1;
			elseif strcmp(value,'off')
				options.useCSS=0;
			else
				error('Invalid value for "forcehead"-option');
			end
		else
			options.useCSS=1;
			n=1;
		end
	case 'structborder'
		options.structStyle.border=value;
	case 'structbolor'
		options.structStyle.color=value;
	case 'structbgcolor'
		options.structStyle.bgColor=value;
	case 'structfont'
		options.structStyle.font=value;
	case 'structfontsize'
		options.structStyle.fontSize=value;
	case 'structextra'
		options.structStyle.extra=value;
	case 'structcss'
		options.structStyle.CSS=value;
	case 'cellborder'
		options.cellStyle.border=value;
	case 'cellcolor'
		options.cellStyle.color=value;
	case 'cellbgcolor'
		options.cellStyle.bgColor=value;
	case 'cellfont'
		options.cellStyle.font=value;
	case 'cellfontsize'
		options.cellStyle.fontSize=value;
	case 'cellextra'
		options.cellStyle.extra=value;
	case 'cellcss'
		options.cellStyle.CSS=value;
	otherwise
		error('Unknown option "%s"',opt)
end

function CellClicked(h,ev)
disp(ev)
