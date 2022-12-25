function [varargout] = UIoptionsSetter(pos_options,default_vals)
%UIoptionsSetter - UI for options settings
%      UIoptionsSetter(pos_options,default_vals)
%      UIoptionsSetter(pos_options)

bBaseWSdata = nargin<2 || isempty(default_vals);

if isstruct(pos_options)
	fn = fieldnames(pos_options)';
	default_vals = cell(1,length(fn));
	for i=1:length(fn)
		default_vals{i} = pos_options.(fn{i});
	end
	pos_options = fn;
elseif bBaseWSdata
	default_vals = cell(1,length(pos_options));
	for i=1:length(pos_options)
		default_vals{i} = evalin('base',pos_options{i});
	end
elseif isstruct(default_vals) || isobject(default_vals)
	c = default_vals;
	default_vals = cell(1,length(pos_options));
	for i=1:length(pos_options)
		try
			default_vals{i} = c.(pos_options{i});
		catch err
			fprintf('Error when requesting default value for "%s"!\n',pos_options{i})
			DispErr(err)
			rethrow(err)
		end
	end
end

[fig,bN] = getmakefig('figUIoptionsSetter');
if ~bN
	clf(fig)
end

x0 = 5;
wLabel = 120;
dx = 5;
wValue = 200;
hElem = 15;
dy = 4;

y0 = 30+(hElem+dy)*length(pos_options);

pos = fig.Position;
pos(3) = x0+wLabel+dx+wValue+10;
pos(4) = y0+30;
fig.Position = pos;

xVal = x0+wLabel+dx;
y = y0-hElem;
Helem = gobjects(1,length(pos_options));

for i=1:length(pos_options)
	v = default_vals{i};
	bTitle = true;
	if islogical(v)
		Helem(i) = uicontrol('Position',[xVal,y,wValue,hElem],'String',pos_options{i}		...
			,'Style','checkbox','Value',v);
		bTitle = false;
	elseif ischar(v) && (isrow(v) || isempty(v))
		Helem(i) = uicontrol('Position',[xVal,y,wValue,hElem],'String',v		...
			,'Style','edit');
	elseif isnumeric(v) && isscalar(v)
		Helem(i) = uicontrol('Position',[xVal,y,wValue,hElem],'String',num2str(v)		...
			,'Style','edit');
	else
		if isnumeric(v)
			if isempty(v)
				typ = 'empty array';
			elseif isrow(v)
				typ = 'row';
			elseif iscolumn(v)
				typ = 'column';
			elseif ismatrix(v)
				typ = sprintf('%dx%d array',size(v));
			else
				typ = sprintf('%dD-array',ndims(v));
			end
			uicontrol('Position',[xVal,y,wValue,hElem],'String',['[',typ,'] - not implemented']		...
				,'Style','text','HorizontalAlignment','left');
		else
			typ = class(v);
		end
		warning('Not implemented value type for "%s" (%s)!!',pos_options{i},typ)
	end
	if bTitle
		uicontrol('Position',[x0,y,wLabel,hElem],'String',pos_options{i}	...
			,'Style','text','HorizontalAlignment','left');
	end
	y = y-hElem-dy;
end

hName = uicontrol('Position',[5 10 70 hElem],'String','SET','Style','edit');
uicontrol('Position',[90 10 70 hElem],'String','STRUCT','Callback',@SetStruct);
uicontrol('Position',[170 10 70 hElem],'String','CELL','Callback',@SetCell);
uicontrol('Position',[250 10 70 hElem],'String','OPT','Callback',@SetOpt);

D = var2struct(pos_options,default_vals,Helem,hName);
fig.UserData = D;

function [V,D,var_name] = GetVals(h)
fig = ancestor(h,'figure');
D = fig.UserData;
var_name = strtrim(D.hName.String);
if ~isvarname(var_name)
	error('Sorry, but the given name is not a valid variable name! (%s)',var_name)
end
V = D.pos_options(:)';
for i=1:length(V)
	if isgraphics(D.Helem(i))
		switch D.Helem(i).Style
			case 'checkbox'
				V{i} = D.Helem(i).Value;
			case 'edit'
				s = D.Helem(i).String;
				if isnumeric(D.default_vals{i})
					V{i} = str2double(s);
				else
					V{i} = s;
				end
			otherwise
				warning('Unexpected input style (%s)',D.Helem(i).Style)
		end
	end
end

function SetStruct(h,~)
[V,D,var_name] = GetVals(h);
C = [D.pos_options(:)';V];
assignin('base',var_name,struct(C{:}))
fprintf('Values set in "%s".\n',var_name)

function SetCell(h,~)
[V,~,var_name] = GetVals(h);
assignin('base',var_name,V)
fprintf('Values set in "%s".\n',var_name)

function SetOpt(h,~)
[V,D,var_name] = GetVals(h);
C = [D.pos_options(:)';V];
assignin('base',var_name,C(:))
fprintf('Values set in "%s".\n',var_name)
