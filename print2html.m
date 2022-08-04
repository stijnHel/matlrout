function HTMLout=print2html(s,nrecurs,f,varargin)
% PRINT2HTML - Write data in a structured way using html-code
%    print2html(d[,nrecurs[,f[,options]]])
%        d - data
%        nrecurs - maximum level of recursive writing
%            if not given or empty : 1
%        f - filename, file-handle for result
%            1 : screen
%            if a filename is given a general html begin and end is added.
%            'web' or not given : data is sent to Matlab-webviewer
%            'browser': system webbrowser
%            'figure': make a "browser" in a normal MATLAB figure window
%    HTMLout=print2html(d[,nrecurs[,options]])
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
%        'maxcolarray' (def. 4) : maximum columns to display full array (numeric arrays)
%        'maxrowarray' (def.10) : maximum rows to display full array
%               (this limitation is also used in char-arrays)
%        'maxel'     (def.20) : maximum total number of values to display 1D-list of values
%        'forcehead'          : print head and end of HTML-page
%                In 1d-option-lists no value had to be given, otherwise
%                       values 0 or 1(~=0) can be given or 'on' or 'off'
%                for 1d-option-lists values 0 or 1 are allowed (no char-value
%                       because then this value is interpreted as a new option)
%
%        'numFormat'  : the way numbers are displayed (input to fprintf)
%                 default %g : "normal display" (see fprintf-documentation for more details)
%                 (!)Every value displayed is using this format.
%        'emptyArray' : this gives what has to be displayed for an empty array (default '[]')
%        'emptyCell'  : this gives what has to be displayed for an empty cell (default '{}')
%        'maxcolcell' (def. 0) : maximum columns to display full cell
%        'maxrowcell' (def. 0) : maximum rows to display full cell
%        'title' : title of html-page (default Matlab-data display)
%        'bStructFields' : give field list of structures too large to be displayed
%        'customPrint'   : custom print function for specific types
%                          (function with struct output)
%        'webArguments'  : arguments "forwarded" to web
%                useful example:
%                print2html(...,...,[],'webArg',{'-new'})
%                         ---> display in MATLAB web browser in new tab
%        'bLinks'        : create links ==> struct's with fields 'link' and
%                          'text' are replaced by links
%        'bCellChar'     : add starting/closing bracket ('{'/'}') for cells
%                          (default true)
%      .................................
%      Other options (related to the display of data) are possible but these are too
%         long to list here.  Look to the comments further in the code to find a more
%         complete list.
%
% "Hidden possibility" for cell arrays
%     if a cell is a single char, with value char(3), then the rest of the
%         row is "spanned"


% Originally this function was made for structures.  By some simple
%    changes it was made to work on other data too.

% Copyright (c)2003, Stijn Helsen <SHelsen@compuserve.com> Januari 2003

% History
%    2003-01-10 - first version
%    2003-01-22 - print structures also done in printdata
%                 no tables for single values
%                 options added
%                 CSS-possibilities added
%                 some special characters are translated to HTML-code ('&','<','>')
%    2003-2005  - "running changes"
%                 tests for adding CSS-usage
%    2006-02-27 - Because of a proposal from Ralph Smith (Thanks!)
%                 possibility for sending to "web", for direct view

% In development:
%    expanding/collapsing capability
%        status: adapt printdata to know its "path" (sref) to the current level
%           stores refs into a global variable - further unused!!!

% Comments :
%   Non-ASCII-codes are not translated to HTML-code
%   Now that options are added can be said that the input nrecurs better could be defined
%        as an option.  For keeping the same function call, this is not done.
%   If output is written to a file is not closed if an error occurs, also if the file is
%        opened inside this program.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%% Other options %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% The display of data-elements can be changed.
%
%    This can be done in two different ways :
%        use of CSS.
%        use of separate options for structures, cells and numerical data
%              (type-data is included for every element separately)
%    The same options can be used for both methods.
%
%    Advantages of CSS are :
%        one definition for elements in the beginning of the file.
%            to change later (not in Matlab) the style of all structures you
%                have to change only the beginning of the file
%        because the styles don't have to be copied everytime, the file is smaller
%    Disadvantages are :
%        not all programs that can read HTML-files use the info of the stylesheet.
%           some programs even use the CSS-definition as text
%    Therefore the two ways are combined if the use of CSS is activated.
%        borders of tables (used in structures, (cell-)arrays) are not done in CSS.
%
%        options :
%           'useCSS' : values : 0 or 1, 'off' or 'on' of no value (for 1d-list))
%
%           'structBorder' : value : size of border (default 1) (if empty no border is defined)
%                    this defines the border of the struct
%           'structColor : RGB-values, HTML-name of color or HTML-colorspec (example #ff0000)
%                    foreground color
%           'structBgColor'
%           'structFont' :
%           'structFontSize' :
%           'structExtra' :
%           'structCSS' : method for complete CSS-definition at once (overwrites other options)
%
%           'cellBorder' : value : size of border (default 1) (if empty no border is defined)
%                    this defines the border of the struct
%           'cellColor : RGB-values, HTML-name of color or HTML-colorspec (example #ff0000)
%                    foreground color
%           'cellBgColor'
%           'cellFont' :
%           'cellFontSize' :
%           'cellExtra' :
%           'cellCSS' : method for complete CSS-definition at once (overwrites other options)
%
% !!!array styles
%

global TESTREF

stroptions=struct('maxcolarray',6,'maxrowarray',10,'maxel',20	...
	,'maxcolcell',6,'maxrowcell',10	...
	,'maxstrlen',256	...
	,'numFormat','%g'	...
	,'intFormat','%d'	...
	,'intLimit',1e12	...
	,'emptyArray','[]'	...
	,'emptyCell','{}'	...
	,'optstructtable',' border="1"'	...
	,'optnumtable',''	...
	,'optcelltable',''	...
	,'printhead',0	...
	,'useCSS',0	...
	,'structStyle',[]	...
	,'cellStyle',[]	...
	,'title','Matlab-data display'	...
	,'bStructFields',false	...
	,'customPrint',[]	...
	,'bExpandComplexS',true		... expand complex structures (like Simulink.Signal)
	,'bDirectString',false	... no "safe text"
	,'bLinks',false	... replace "links" by HTML-anchors
	,'bCellChar',true	... add starting/closing bracket ('{'/'}') for cells
	,'bExpandLink',false	... create a link for "collapsed data"
	,'webArguments',{{}}	... arguments "forwarded" to web-call
	,'figure',[]	... figure if matlab figure brwowser is requested
	);

if ~exist('nrecurs','var')||isempty(nrecurs)
	nrecurs=1;
end
if length(varargin)==1&&iscell(varargin{1})
	options=varargin{1};
else
	options=varargin;
end
if ~exist('f','var')
	f=[];
end
ownf=0;
if nargout&&~isempty(f)
	if isempty(options)
		options=f;
	else
		options=[{f},options];
	end
	f=[];
end
if nargout||isempty(f)
	f='web';
end
bSystemBrowser = false;
bFigureBrowser = false;
if ischar(f)
	if strcmpi(f,'web')||strcmpi(f,'browser')
		bSystemBrowser=strcmpi(f,'browser');
		f=struct('buffer',char(zeros(1,10000)),'n',0);
	elseif strcmpi(f,'figure')
		bFigureBrowser = true;
		f=struct('buffer',char(zeros(1,10000)),'n',0);
	else
		f=fopen(f,'wt');
		if f<3
			error('Can''t open file');
		end
	end
	stroptions.printhead=1;
	ownf=1;
end

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
	
	if ~isempty(stroptions.structStyle)
		if ~isfield(stroptions.structStyle,'border')
			stroptions.structStyle.border=1;	% default
		end
		if stroptions.useCSS
			stroptions.optstructtable=sprintf(' class="cstruct" border ="%d"',stroptions.structStyle.border);
		else
			stroptions.optstructtable=printDef1(stroptions.structStyle);
		end
	end
	if ~isempty(stroptions.cellStyle)
		if ~isfield(stroptions.cellStyle,'border')
			stroptions.cellStyle.border=1;	% default
		end
		if stroptions.useCSS
			stroptions.optcelltable=sprintf(' class="ccell" border ="%d"',stroptions.cellStyle.border);
		else
			stroptions.optcelltable=printDef1(stroptions.cellStyle);
		end
	end
end

if stroptions.printhead
	% print html-header
	localprint(f,'<html>\n<head>\n<title>%s</title>\n<meta name="GENERATOR" content="PRINT2HTML - Matlab function">\n',stroptions.title);
	if stroptions.useCSS
		printCSSdef(f,stroptions)
	end
	localprint(f,'</head>\n<body>\n');
end

f=printdata(f,s,nrecurs,stroptions);
REFidx = printdata();
TESTREF = REFidx;

if stroptions.printhead
	localprint(f,'</body>\n</html>\n');
end
if ownf
	if nargout
		if ~isstruct(f)
			error('Something went wrong in this program!!!!')
		end
		HTMLout=f.buffer(1:f.n);
		return
	end
	if isstruct(f)
		S = f.buffer(1:f.n);
		if bSystemBrowser
			web(['text://' S],'-browser',stroptions.webArguments{:})
		elseif bFigureBrowser
			AddToFigure(S,stroptions)
		else
			web(['text://' S],stroptions.webArguments{:})
		end
	else
		fclose(f);
	end
end

function f=printdata(f,d,nrecurs,options,Sref0)
%printdata - print field-data
%  called recursively

persistent REFidx

if nargin==0
	f = REFidx;
	return
end

sz=size(d);
n=prod(sz);
ndim=sum(sz>1);
ndim0=length(sz);
a=cell(1,ndim0);
bGenClassView=false;
if nargin<5
	REFidx = struct('label',cell(1,0),'sref',[]);	% reset (at highest level call)
	Sref0 = struct('type',cell(1,0),'subs',[]);
end

fcn=[];
if ~isempty(options.customPrint)
	if iscell(options.customPrint)
		b=strcmp(class(d),options.customPrint(:,1));
		if any(b)
			fcn=options.customPrint{b,2};
		end
	elseif isstruct(options.customPrint)
		b=strcmp(class(d),{options.customPrint.type});
		if any(b)
			fcn=options.customPrint(b).function;
		end
	else
		error('Wrong input for "customPrint"-option!')
	end
end
if ~isempty(fcn)
	if ~isa(fcn,'function_handle')
		error('Function must be given as a function handle!')
	end
	s=fcn(d);
	if ~ischar(s)
		error('custum output function must return a char!')
	end
	localprint(f,'%s',s)
else
	class_d=class(d);
	if isstruct(d)
		typS='structure';
	elseif istable(d)
		typS = 'table';
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
					case {'bus','coderinfo','logginginfo','buselement'}
						typS=class_d;
						class_d='struct';
					case 'configset'
						typS=class_d;
						class_d='struct';
					case 'simulationdata.dataset'
						typS=class_d;
						class_d='cell';
						sz = [numElements(d),1];
					case 'simulationdata.state'
						typS = class_d;
						class_d = 'struct';
					case 'simulationdata.signal'
						typS = class_d;
						class_d = 'struct';
					case 'simulationdata.blockpath'
						typS=class_d;
						if isscalar(d)
							class_d='char';
							d = d.getBlock(1);
						else
							class_d='cell';
							d = convertToCell(d);
						end
				end
		end
	end		% not a struct
	switch class_d
		case 'struct'
			fields=fieldnames(d);
			if options.bLinks && isscalar(d) && length(fieldnames(d))==2 && isfield(d,'link') && isfield(d,'text')
				localprint(f,'<a href="%s">',d.link);
				printstring(f,d.text);
				localprint(f,'</a><br>');
			elseif nrecurs>0&&n<=options.maxel
				if isempty(d)
					localprint(f,'empty %s (%d fields)<br>\n',typS,length(fields));
					if options.bStructFields&&~isempty(fields)
						localprint(f,'(%s',fields{1})
						if length(fields)>1
							localprint(f,', %s',fields{2:end})
						end
						localprint(f,')<br>\n');
					end
				elseif isscalar(d)
					localprint(f,'<table%s>\n',options.optstructtable);
					Sref = Sref0;
					Sref(end+1).type = '.';
					for i=1:length(fields)
						localprint(f,'<tr><td>%s :</td><td>',fields{i});
						Sref(end).subs = fields{i};
						f=printdata(f,d.(fields{i}),nrecurs-1,options,Sref);
						localprint(f,'</td></tr>\n');
					end
					localprint(f,'</table>\n');
				else
					localprint(f,'<table%s>\n<tr><td> </td>',options.optstructtable);
					for i=1:length(fields)
						localprint(f,'<td>%s</td>',fields{i});
					end
					localprint(f,'</tr>\n');
					a=cell(1,ndim0);
					Sref = Sref0;
					Sref(end+1).type = '()';
					iSrefArr = length(Sref);
					Sref(end+1).type = '.';
					iSrefField = length(Sref);
					for i=1:n
						Sref(iSrefArr).subs = {i};
						localprint(f,'<tr><td valign="top">%d',i);
						if ndim>1	% add full index
							[a{:}]=ind2sub(sz,i);
							localprint(f,' (%d',a{1});
							localprint(f,',%d',a{2:ndim0});
							localprint(f,')');
						end
						localprint(f,'</td>\n');
						for j=1:length(fields)
							localprint(f,'<td>');
							Sref(iSrefField).subs = fields{j};
							f=printdata(f,getfield(d,{i},fields{j}),nrecurs-1,options,Sref);
							localprint(f,'</td>\n');
						end	% fields
						localprint(f,'</tr>\n');
					end	% rows
					localprint(f,'</table>\n');
				end	% struct array
			else
				s = sprintf('%s %s (%d fields)',typS,stringsize(sz),length(fields));
				REFidx(end+1) = struct('label',s,'sref',Sref0);
				localprint(f,'%s\n',s);
				if options.bStructFields&&~isempty(fields)
					localprint(f,'<br>\n(%s',fields{1})
					if length(fields)>1
						localprint(f,', %s',fields{2:end})
					end
					localprint(f,')');
				end
			end
		case 'table'
			if size(d,2)>10	%(!!!!!!! option !!!!!)
				bGenClassView = true;
			else
				localprint(f,'<table border="3">\n<tr>');
				localprint(f,'   <td><b>%s</b></td>\n',d.Properties.VariableNames{:});
				localprint(f,'</tr>\n');
				if sz(1)>20
					localprint(f,'<tr><td colspan="%d">%d elements</td></tr>\n',sz([2,1]));
				else
					Sref = Sref0;
					Sref(end+1).type = '.';
					iSrefArr = length(Sref);
					Sref(end+1).type = '()';
					for i=1:sz(1)
						localprint(f,'<tr>');
						Sref(iSrefArr+1).subs = {[i]};
						for j=1:sz(2)
							Sref(iSrefArr).subs = d.Properties.VariableNames{j};
							localprint(f,'<td>');
							f=printdata(f,d.(Sref(iSrefArr).subs)(i),nrecurs-1,options,Sref);
							localprint(f,'</td>');
						end
						localprint(f,'</tr>\n');
					end	% rows
				end
				localprint(f,'</table>\n');
			end
		case {'double','single','uint8','int8','uint16','int16'	...
				,'uint32','int32','uint64','int64','sparse','logical'}
			if n==1
				localprint(f,FormNumber(d,options));
			elseif n==0
				localprint(f,options.emptyArray);
			elseif ndim0==2&&sz(1)<=options.maxrowarray&&sz(2)<=options.maxcolarray
				localprint(f,'<table%s>\n',options.optnumtable);
				for i=1:sz(1)
					localprint(f,'<tr>');
					for j=1:sz(2)
						localprint(f,'<td>');
						if i*j==1
							localprint(f,'[');
						end
						localprint(f,FormNumber(d(i,j),options));
						if i*j==sz(1)*sz(2)
							localprint(f,']');
						end
						localprint(f,'</td>');
					end
					localprint(f,'</tr>\n');
				end	% rows
				localprint(f,'</table>\n');
			elseif n<=options.maxel
				localprint(f,'<table%s>\n',options.optnumtable);
				for i=1:n
					[a{:}]=ind2sub(sz,i);
					localprint(f,'<tr><td>%d (%d',i,a{1});
					localprint(f,',%d',a{2:ndim0});
					localprint(f,')</td><td>%s</td></tr>\n',FormNumber(d(i),options));
				end
				localprint(f,'</table>\n');
			else
				localprint(f,'%s ',stringsize(sz));
				if issparse(d)
					localprint(f,'sparse ');
				end
				localprint(f,'array\n');
			end
		case 'cell'
			if n==0
				localprint(f,options.emptyCell);
			elseif nrecurs<=0
				localprint(f,'%s cell array\n',stringsize(sz));
			elseif ndim0==2&&sz(1)<=options.maxrowcell&&sz(2)<=options.maxcolcell
				localprint(f,'<table%s>\n',options.optcelltable);
				Sref = Sref0;
				Sref(end+1).type = '{}';
				iSrefArr = length(Sref);
				for i=1:sz(1)
					localprint(f,'<tr>');
					bSpan = false;
					for j = 2:sz(2)
						if ischar(d{i,j}) && isscalar(d{i,j}) && d{i,j}==3
							% (special format!!) - the rest is "spanned"
							bSpan = true;
							jSpan = j;
							break
						end
					end
					for j=1:sz(2)
						if ~bSpan || j<jSpan		% else discard
							if bSpan && j==jSpan-1
								localprint(f,sprintf('<td colspan="%d">',sz(2)-j+1));
							else
								localprint(f,'<td>');
							end
							if i*j==1 && options.bCellChar
								localprint(f,'{');
							end
							Sref(iSrefArr).subs = {[i,j]};
							f=printdata(f,d{i+(j-1)*sz(1)},nrecurs-1,options,Sref);
								% no d{i,j} to allow data types allowing only one index
							if i*j==sz(1)*sz(2) && options.bCellChar
								localprint(f,'}');
							end
							localprint(f,'</td>');
						end
					end
					localprint(f,'</tr>\n');
				end	% rows
				localprint(f,'</table>\n');
			elseif n<=options.maxel&&nrecurs>0
				localprint(f,'<table%s>\n',options.optcelltable);
				Sref = Sref0;
				Sref(end+1).type = '{}';
				iSrefArr = length(Sref);
				for i=1:n
					[a{:}]=ind2sub(sz,i);
					localprint(f,'<tr><td valign="top">%d (%d',i,a{1});
					localprint(f,',%d',a{2:ndim0});
					localprint(f,')</td><td>');
					Sref(iSrefArr).subs = {i};
					f=printdata(f,d{i},nrecurs-1,options,Sref);
					localprint(f,'</td></tr>\n');
				end
				localprint(f,'</table>\n');
			else
				s = sprintf('%s cell array',stringsize(sz));
				REFidx(end+1) = struct('label',s,'sref',Sref0);
				localprint(f,'%s\n',s);
			end
		case 'string'
			if isscalar(d)
				if strlength(d)>options.maxstrlen
					localprint(f,'long string %d',strlength(d));
				else
					localprint(f,'%s\n',d);
				end
			elseif min(sz)>1 || length(sz)>options.maxrowarray
				localprint(f,'%s string array',stringsize(sz));
			else
				for i=1:max(sz)-1
					if options.bDirectString
						localprint(f,d(i))
					else
						printstring(f,d(i));
					end
					localprint(f,'<br>\n');
				end
				if options.bDirectString
					localprint(f,d(end))
				else
					printstring(f,d(end));
				end
			end
		case 'char'
			if isempty(d)
				localprint(f,'&nbsp;');
			elseif ndim0>2||(min(sz)==1&&max(sz)>options.maxstrlen)	...
					||(min(sz)>1&&sz(1)>options.maxrowarray)
				localprint(f,'%s char array',stringsize(sz));
			elseif sz(1)>1&&sz(2)==1	% transposed string?!
				localprint(f,'"(')
				printstring(f,d');
				localprint(f,')''"')
			else
				for i=1:sz(1)-1
					if options.bDirectString
						localprint(f,d(i,:))
					else
						printstring(f,d(i,:));
					end
					localprint(f,'<br>\n');
				end
				if options.bDirectString
					localprint(f,d(end,:))
				else
					printstring(f,d(end,:));
				end
			end
		case 'lvtime'
			if isempty(d)||numel(d)>4||min(size(d))>1
				bGenClassView=true;
			else
				for i=1:numel(d)
					if i>1
						localprint(f,'<br>\n')
					end
					localprint(f,'%s',char(d(i)))
				end
			end
		case 'function_handle'
			localprint(f,'%s',char(d))
		case 'timeseries'
			if n==0
				localprint(f,'%s timeseries',stringsize(sz));
			elseif n==1
				if ismatrix(d.Data)
					localprint(f,'timeseries %s, %dx%d %s',d.Name,size(d.Data),class(d.Data))
				else
					sz=size(d.Data);
					localprint(f,'timeseries %s, (%d',d.Name,sz(1))
					localprint(f,'x%d',sz(2:end))
					localprint(f,') %s',class(d.Data))
				end
			elseif n<=options.maxel
				localprint(f,'<table%s>\n',options.optnumtable);
				for i=1:n
					localprint(f,'<tr><td>');
					if ismatrix(d(i).Data)
						localprint(f,'timeseries %s, %dx%d %s',d(i).Name,size(d(i).Data),class(d(i).Data))
					else
						sz=size(d(i).Data);
						localprint(f,'timeseries %s, (%d',d(i).Name,sz(1))
						localprint(f,'x%d',sz(2:end))
						localprint(f,') %s',class(d(i).Data))
					end
					localprint(f,'</td></tr>\n');
				end
				localprint(f,'</table>\n');
			else
				bGenClassView=true;
			end
		otherwise
			if isenum(d)
				localprint(f,'%s',string(d))
			else
				bGenClassView=true;
			end
	end
end
if bGenClassView
	localprint(f,'%s (%d',class(d),size(d,1));
	for i=2:ndims(d)
		localprint(f,'x%d',size(d,i));
	end
	localprint(f,')');
end

function ssize=stringsize(sz)
ssize=num2str(sz(1));
ssize=[ssize sprintf('x%d',sz(2:end))];

function printCSSdef(f,options)
% PRINTCSSHEAD - Print the definition of the CSS
localprint(f,'<style type="text/css">\n');
localprint(f,'.cstruct {\n');
if isempty(options.structStyle)
	localprint(f,'    // no styles given\n');
else
	printCSSdef1(f,options.structStyle);
end	% struct styles
localprint(f,'}\n');
localprint(f,'.ccell {\n');
if isempty(options.cellStyle)
	localprint(f,'    // no styles given\n');
else
	printCSSdef1(f,options.cellStyle);
end	% cell styles
localprint(f,'}\n');
%fprintf(f,'.cnum {\n    %s}\n',options.CSSnum);
localprint(f,'</style>\n');

function printCSSdef1(f,options)
% PRINTCSSDEF1 - Print 1 definition (for CSS-usage)
fields=fieldnames(options);
for i=1:length(fields)
	value=options.(fields{i});
	switch fields{i}
		case 'border'
			% not in CSS (?!!)
		case 'color'
			localprint(f,'    color: %s;\n',getcolorspec(value));
		case 'bgColor'
			localprint(f,'    background: %s;\n',getcolorspec(value));
		case 'font'
			localprint(f,'    font-family: %s;\n',value);
			% also :
			%  font-weigth
			%  font-style
			%  font-face
			%  text-decoration
		case 'fontSize'
			if ischar(value)
				localprint(f,'    font-size: "%s";\n',value);
			else
				localprint(f,'    font-size: "%dpt";\n',value);
			end
		case 'extra'
			localprint(f,'    %s;\n',value);
		otherwise
			error('!!!!unknown spec!!!')
	end
end

function s=printDef1(options)
% PRINTCSSDEF1 - Print 1 definition (for inline styles)
s='';
if isempty(options)
	return;
end
fields=fieldnames(options);
for i=1:length(fields)
	value=options.(fields{i});
	switch fields{i}
		case 'border'
			s=[s sprintf(' border="%d"',value)]; %#ok<AGROW>
		case 'color'
			s=[s ' color="' getcolorspec(value) '"']; %#ok<AGROW>
		case 'bgColor'
			
		case 'font'
			
		case 'fontSize'
		case 'extra'
		otherwise
			error('!!!!unknown spec!!!')
	end
end

function printstring(f,s)
% PRINTSTRING - Print a string to the file
%    Only some conversions are done of special characters.
s=strrep(s,'&','&amp;');
s=strrep(s,'<','&lt;');
s=strrep(s,'>','&gt;');
s=strrep(s,'�','&eacute;');
s=strrep(s,[char(13) newline],'<br>');
s=strrep(s,newline,'<br>');
s=strrep(s,char(13),'<br>');
if isstring(s)
	s = char(s);
end
B=s<32|(s>=127&s<160);
while any(B)
	i=find(B,1);
	s=sprintf('%s#%03o%s',s(1:i-1),abs(s(i)),s(i+1:end));
	B=s<32|(s>=127&s<160);
end
localprint(f,'%s',s);
assignin('caller','f',f)
% This is not so nice Matlab-code, but prevents adding
%     f=localp.... everywhere.

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

function s=getcolorspec(value)
if isnumeric(value)
	if length(value)~=3
		error('If value is given for color, three elements has to be given.');
	end
	if any(value>1)	% values between 0 and 255 are expected (8-bit-format)
		s=sprintf('#%02x%02x%02x',min(255,max(0,value)));
	else	% values between 0 and 1 are expected (matlab-format)
		s=sprintf('#%02x%02x%02x',min(255,max(0,value*255)));
	end
else
	s=value;
end

function localprint(f,varargin)
% localprint - for flexible ouput writing (to buffer or file)

if isstruct(f)
	s=sprintf(varargin{:});
	if length(f.buffer)<f.n+length(s)
		f.buffer(end+length(s)+1000)=char(0);
	end
	n=f.n+length(s);
	f.buffer(f.n+1:n)=s;
	f.n=n;
	assignin('caller','f',f)
	% This is not so nice Matlab-code, but prevents adding
	%     f=localp.... everywhere.
else
	fprintf(f,varargin{:});
end

function s=FormNumber(x,options)
if x~=round(x)||abs(x)>=options.intLimit
	t=options.numFormat;
else
	t=options.intFormat;
end
s=sprintf(t,x);

function AddToFigure(S,options)
% based on:
%          https://undocumentedmatlab.com/articles/gui-integrated-browser-control

%!!!!!!!!!!use stroptions
%     figure number
%     browser object
%     size
%     ...
if isempty(options.figure)
	f = nfigure;
elseif ischar(options.figure)
	f = getmakefig(options.figure);
else
	f = options.figure;
end
browser = getappdata(f,'browser');

if isempty(browser)
	% Add the browser object on the right
	jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
	[browser,container] = javacomponent(jObject, [], f);
	set(container, 'Units','norm', 'Pos',[0.05,0.05,0.9,0.9]);
	setappdata(f,'browser',browser)
end
browser.setHtmlText(S)
