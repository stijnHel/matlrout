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
	,'bodyStyle',[]	...
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
	,'figure',[]	... figure if matlab figure browser is requested
	,'useUIfigure',true	...
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
		f = CFlexFile(10000);
	elseif strcmpi(f,'figure')
		bFigureBrowser = true;
		f = CFlexFile(10000);
	else
		f = CFlexFile(f,'wt');
	end
	stroptions.printhead=1;
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
	f.printf('<html>\n<head>\n<title>%s</title>\n<meta name="GENERATOR" content="PRINT2HTML - Matlab function">\n',stroptions.title);
	if stroptions.useCSS
		printCSSdef(f,stroptions)
	end
	f.printf('</head>\n<body>\n');
end

printdata(f,s,nrecurs,stroptions);
REFidx = printdata();
TESTREF = REFidx;

if stroptions.printhead
	f.printf('</body>\n</html>\n');
end
f.close()
if f.bMemFile
	S = f.get();
	if nargout
		HTMLout = S;
		return
	end
	if bSystemBrowser
		web(['text://' S],'-browser',stroptions.webArguments{:})
	elseif bFigureBrowser
		AddToFigure(S,stroptions)
	else
		web(['text://' S],stroptions.webArguments{:})
	end
end

function R=printdata(f,d,nrecurs,options,Sref0)
%printdata - print field-data
%  called recursively

persistent REFidx

if nargin==0
	R = REFidx;
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
	f.printf('%s',s)
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
				f.printf('<a href="%s">',d.link);
				printstring(f,d.text);
				f.printf('</a><br>');
			elseif nrecurs>0&&n<=options.maxel
				if isempty(d)
					f.printf('empty %s (%d fields)<br>\n',typS,length(fields));
					if options.bStructFields&&~isempty(fields)
						f.printf('(%s',fields{1})
						if length(fields)>1
							f.printf(', %s',fields{2:end})
						end
						f.printf(')<br>\n');
					end
				elseif isscalar(d)
					f.printf('<table%s>\n',options.optstructtable);
					Sref = Sref0;
					Sref(end+1).type = '.';
					for i=1:length(fields)
						f.printf('<tr><td>%s :</td><td>',fields{i});
						Sref(end).subs = fields{i};
						printdata(f,d.(fields{i}),nrecurs-1,options,Sref);
						f.printf('</td></tr>\n');
					end
					f.printf('</table>\n');
				else
					f.printf('<table%s>\n<tr><td> </td>',options.optstructtable);
					for i=1:length(fields)
						f.printf('<td>%s</td>',fields{i});
					end
					f.printf('</tr>\n');
					a=cell(1,ndim0);
					Sref = Sref0;
					Sref(end+1).type = '()';
					iSrefArr = length(Sref);
					Sref(end+1).type = '.';
					iSrefField = length(Sref);
					for i=1:n
						Sref(iSrefArr).subs = {i};
						f.printf('<tr><td valign="top">%d',i);
						if ndim>1	% add full index
							[a{:}]=ind2sub(sz,i);
							f.printf(' (%d',a{1});
							f.printf(',%d',a{2:ndim0});
							f.printf(')');
						end
						f.printf('</td>\n');
						for j=1:length(fields)
							f.printf('<td>');
							Sref(iSrefField).subs = fields{j};
							printdata(f,getfield(d,{i},fields{j}),nrecurs-1,options,Sref);
							f.printf('</td>\n');
						end	% fields
						f.printf('</tr>\n');
					end	% rows
					f.printf('</table>\n');
				end	% struct array
			else
				s = sprintf('%s %s (%d fields)',typS,stringsize(sz),length(fields));
				REFidx(end+1) = struct('label',s,'sref',Sref0);
				f.printf('%s\n',s);
				if options.bStructFields&&~isempty(fields)
					f.printf('<br>\n(%s',fields{1})
					if length(fields)>1
						f.printf(', %s',fields{2:end})
					end
					f.printf(')');
				end
			end
		case 'table'
			if size(d,2)>10	%(!!!!!!! option !!!!!)
				bGenClassView = true;
			else
				f.printf('<table border="3">\n<tr>');
				f.printf('   <td><b>%s</b></td>\n',d.Properties.VariableNames{:});
				f.printf('</tr>\n');
				if sz(1)>20
					f.printf('<tr><td colspan="%d">%d elements</td></tr>\n',sz([2,1]));
				else
					Sref = Sref0;
					Sref(end+1).type = '.';
					iSrefArr = length(Sref);
					Sref(end+1).type = '()';
					for i=1:sz(1)
						f.printf('<tr>');
						Sref(iSrefArr+1).subs = {[i]};
						for j=1:sz(2)
							Sref(iSrefArr).subs = d.Properties.VariableNames{j};
							f.printf('<td>');
							printdata(f,d.(Sref(iSrefArr).subs)(i),nrecurs-1,options,Sref);
							f.printf('</td>');
						end
						f.printf('</tr>\n');
					end	% rows
				end
				f.printf('</table>\n');
			end
		case {'double','single','uint8','int8','uint16','int16'	...
				,'uint32','int32','uint64','int64','sparse','logical'}
			if n==1
				f.printf(FormNumber(d,options));
			elseif n==0
				f.printf(options.emptyArray);
			elseif ndim0==2&&sz(1)<=options.maxrowarray&&sz(2)<=options.maxcolarray
				f.printf('<table%s>\n',options.optnumtable);
				for i=1:sz(1)
					f.printf('<tr>');
					for j=1:sz(2)
						f.printf('<td>');
						if i*j==1
							f.printf('[');
						end
						f.printf(FormNumber(d(i,j),options));
						if i*j==sz(1)*sz(2)
							f.printf(']');
						end
						f.printf('</td>');
					end
					f.printf('</tr>\n');
				end	% rows
				f.printf('</table>\n');
			elseif n<=options.maxel
				f.printf('<table%s>\n',options.optnumtable);
				for i=1:n
					[a{:}]=ind2sub(sz,i);
					f.printf('<tr><td>%d (%d',i,a{1});
					f.printf(',%d',a{2:ndim0});
					f.printf(')</td><td>%s</td></tr>\n',FormNumber(d(i),options));
				end
				f.printf('</table>\n');
			else
				f.printf('%s ',stringsize(sz));
				if issparse(d)
					f.printf('sparse ');
				end
				f.printf('array\n');
			end
		case 'cell'
			if n==0
				f.printf(options.emptyCell);
			elseif nrecurs<=0
				f.printf('%s cell array\n',stringsize(sz));
			elseif ndim0==2&&sz(1)<=options.maxrowcell&&sz(2)<=options.maxcolcell
				f.printf('<table%s>\n',options.optcelltable);
				Sref = Sref0;
				Sref(end+1).type = '{}';
				iSrefArr = length(Sref);
				for i=1:sz(1)
					f.printf('<tr>');
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
								f.printf(sprintf('<td colspan="%d">',sz(2)-j+1));
							else
								f.printf('<td>');
							end
							if i*j==1 && options.bCellChar
								f.printf('{');
							end
							Sref(iSrefArr).subs = {[i,j]};
							printdata(f,d{i+(j-1)*sz(1)},nrecurs-1,options,Sref);
								% no d{i,j} to allow data types allowing only one index
							if i*j==sz(1)*sz(2) && options.bCellChar
								f.printf('}');
							end
							f.printf('</td>');
						end
					end
					f.printf('</tr>\n');
				end	% rows
				f.printf('</table>\n');
			elseif n<=options.maxel&&nrecurs>0
				f.printf('<table%s>\n',options.optcelltable);
				Sref = Sref0;
				Sref(end+1).type = '{}';
				iSrefArr = length(Sref);
				for i=1:n
					[a{:}]=ind2sub(sz,i);
					f.printf('<tr><td valign="top">%d (%d',i,a{1});
					f.printf(',%d',a{2:ndim0});
					f.printf(')</td><td>');
					Sref(iSrefArr).subs = {i};
					printdata(f,d{i},nrecurs-1,options,Sref);
					f.printf('</td></tr>\n');
				end
				f.printf('</table>\n');
			else
				s = sprintf('%s cell array',stringsize(sz));
				REFidx(end+1) = struct('label',s,'sref',Sref0);
				f.printf('%s\n',s);
			end
		case 'string'
			if isscalar(d)
				if strlength(d)>options.maxstrlen
					f.printf('long string %d',strlength(d));
				else
					f.printf('%s\n',d);
				end
			elseif min(sz)>1 || length(sz)>options.maxrowarray
				f.printf('%s string array',stringsize(sz));
			else
				for i=1:max(sz)-1
					if options.bDirectString
						f.printf(d(i))
					else
						printstring(f,d(i));
					end
					f.printf('<br>\n');
				end
				if options.bDirectString
					f.printf(d(end))
				else
					printstring(f,d(end));
				end
			end
		case 'char'
			if isempty(d)
				f.printf('&nbsp;');
			elseif ndim0>2||(min(sz)==1&&max(sz)>options.maxstrlen)	...
					||(min(sz)>1&&sz(1)>options.maxrowarray)
				f.printf('%s char array',stringsize(sz));
			elseif sz(1)>1&&sz(2)==1	% transposed string?!
				f.printf('"(')
				printstring(f,d');
				f.printf(')"')
			else
				for i=1:sz(1)-1
					if options.bDirectString
						f.printf(d(i,:))
					else
						printstring(f,d(i,:));
					end
					f.printf('<br>\n');
				end
				if options.bDirectString
					f.printf(d(end,:))
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
						f.printf('<br>\n')
					end
					f.printf('%s',char(d(i)))
				end
			end
		case 'datetime'
			if isscalar(d)
				f.printf('%s',d)
			else
				f.printf('%s datetime',stringsize(sz))
			end
		case 'function_handle'
			f.printf('%s',char(d))
		case 'timeseries'
			if n==0
				f.printf('%s timeseries',stringsize(sz));
			elseif n==1
				if ismatrix(d.Data)
					f.printf('timeseries %s, %dx%d %s',d.Name,size(d.Data),class(d.Data))
				else
					sz=size(d.Data);
					f.printf('timeseries %s, (%d',d.Name,sz(1))
					f.printf('x%d',sz(2:end))
					f.printf(') %s',class(d.Data))
				end
			elseif n<=options.maxel
				f.printf('<table%s>\n',options.optnumtable);
				for i=1:n
					f.printf('<tr><td>');
					if ismatrix(d(i).Data)
						f.printf('timeseries %s, %dx%d %s',d(i).Name,size(d(i).Data),class(d(i).Data))
					else
						sz=size(d(i).Data);
						f.printf('timeseries %s, (%d',d(i).Name,sz(1))
						f.printf('x%d',sz(2:end))
						f.printf(') %s',class(d(i).Data))
					end
					f.printf('</td></tr>\n');
				end
				f.printf('</table>\n');
			else
				bGenClassView=true;
			end
		otherwise
			if isenum(d)
				f.printf('%s',string(d))
			else
				bGenClassView=true;
				if nrecurs>0 && isscalar(d) && ismethod(d,'get')
					try
						S = d.get();
						if isstruct(S)
							f.printf('&lt;class %s&gt;:\n',class(d));
							printdata(f,d.get(),nrecurs-1,options,Sref0);
							bGenClassView=false;
						end
					catch
					end
				end
			end
	end
end
if bGenClassView
	f.printf('%s (%d',class(d),size(d,1));
	for i=2:ndims(d)
		f.printf('x%d',size(d,i));
	end
	f.printf(')');
end

function ssize=stringsize(sz)
ssize=num2str(sz(1));
ssize=[ssize sprintf('x%d',sz(2:end))];

function printCSSdef(f,options)
% PRINTCSSHEAD - Print the definition of the CSS
f.printf('<style type="text/css">\n');
if ~isempty(options.bodyStyle)
	f.printf(' body {%s}\n',options.bodyStyle);
end
f.printf('.cstruct {\n');
if isempty(options.structStyle)
	f.printf('    // no styles given\n');
else
	printCSSdef1(f,options.structStyle);
end	% struct styles
f.printf('}\n');
f.printf('.ccell {\n');
if isempty(options.cellStyle)
	f.printf('    // no styles given\n');
else
	printCSSdef1(f,options.cellStyle);
end	% cell styles
f.printf('}\n');
%fprintf(f,'.cnum {\n    %s}\n',options.CSSnum);
f.printf('</style>\n');

function printCSSdef1(f,options)
% PRINTCSSDEF1 - Print 1 definition (for CSS-usage)
fields=fieldnames(options);
for i=1:length(fields)
	value=options.(fields{i});
	switch fields{i}
		case 'border'
			% not in CSS (?!!)
		case 'color'
			f.printf('    color: %s;\n',getcolorspec(value));
		case 'bgColor'
			f.printf('    background: %s;\n',getcolorspec(value));
		case 'font'
			f.printf('    font-family: %s;\n',value);
			% also :
			%  font-weigth
			%  font-style
			%  font-face
			%  text-decoration
		case 'fontSize'
			if ischar(value)
				f.printf('    font-size: "%s";\n',value);
			else
				f.printf('    font-size: "%dpt";\n',value);
			end
		case 'extra'
			f.printf('    %s;\n',value);
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
if any(s=='&')
	i = 0;
	while i<length(s)
		i = i+1;
		if s(i)=='&'
			if i==1 || s(i-1)~='\'
				s = [s(1:i) 'amp;' s(i+1:end)];
				i = i+3;
			else	% replace '\&' by '&'
				s = [s(1:i-2) s(i:end)];
			end
		end
	end
end
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
f.printf('%s',s);

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
elseif iscell(options.figure)
	f = getmakefig(options.figure{:});
else
	f = options.figure;
end
browser = getappdata(f,'browser');

if options.useUIfigure
	if isempty(browser)
		browser = uihtml(f,'Position',[10 10 f.Position([3 4])-20],"HTMLSource",S);
		setappdata(f,'browser',browser)
	else
		browser.HTMLSource = S;
	end
else
	if isempty(browser)
		% Add the browser object on the right
		jObject = com.mathworks.mlwidgets.html.HTMLBrowserPanel;
		[browser,container] = javacomponent(jObject, [], f);
		set(container, 'Units','norm', 'Pos',[0.05,0.05,0.9,0.9]);
		setappdata(f,'browser',browser)
	end
	browser.setHtmlText(S)
end
