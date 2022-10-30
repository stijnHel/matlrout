function out=navmsrs(c,varargin)
%CNAVMSRS/NAVMSRS - Navigatie-functie van cnavmsrs
%        following key-presses can be used:
%    	' ','space','n': next
%       'p'            : previous
%       '0'            : first
%       '1'            : idx+=10
%       '2'            : idx+=100
%       '3'            : idx-=1000
%       '6'            : idx+=1000
%       '7'            : idx-=100
%       '8'            : idx-=10
%       '9'            : last
%       'c'            : copy
%       'C'            : stop copying to current copy-figure
%       'g'            : gets data and stores in 'NAVdata'
%       'N'            : normal view
%       ctrl-'C'       : close window
%       ctrl-'Q'       : close window
%       ctrl-'F'       : show copy window
%   if no implementation for the key, the command is forwarded to navfig.

if nargout
	out=0;
end
fnr=c.nr;
fnr0=fnr;
hFig=c.fig;
bHandleLinked = true;
if isempty(varargin)
	k=get(hFig,'CurrentCharacter');
	%fprintf('key : "%s", character : %s\n',get(gcf,'currentkey'),get(gcf,'currentcharacter'))
	if isempty(k)
		k = get(hFig,'CurrentKey');
	end
	switch k
		case {' ','space','n',30}  % next
			fnr=fnr+1;
		case {'p',31}    % previous
			fnr=fnr-1;
		case '0'	% first
			fnr=1;
		case '1'	% skip 10
			fnr=fnr+10;
		case '2'	% skip 100
			fnr=fnr+100;
		case '3'	% skip 1000
			fnr=fnr+1000;
		case '6'	% previous 1000th
			fnr=fnr-1000;
		case '7'	% previous 100th
			fnr=fnr-100;
		case '8'	% previous 10th
			fnr=fnr-10;
		case '9'	% last
			fnr=c.nFiles;
		case 'c'	% copy
			fn=get(hFig,'Name');
			f = getappdata(hFig,'copyFig');
			if isempty(f) || ~ishandle(f) || ~strcmp(get(f,'Tag'),'navmsrcopy')
				[f,bN]=getmakefig('navmsrcopy',0);
				if bN
					setappdata(f,'copyOrigin',hFig)
					setappdata(hFig,'copyFig',f);
					navfig
				else
					bFound = false;
					for i=1:length(f)
						if isequal(getappdata(f(i),'copyOrigin'),hFig)
							bFound = true;
							f = f(i);
							break
						end
					end
					if ~bFound
						f = nfigure('Tag','navmsrcopy');
						setappdata(f,'copyOrigin',hFig)
						setappdata(hFig,'copyFig',f);
						navfig
					end
				end
			end
			hL=c.hL;
			bFirstCopy=isempty(get(f,'children'));
			if bFirstCopy
				set(f,'Name','copy')
				hLc=hL;	% init (will become the handles to the copied lines)
				axc=c.ax;	% init (will become the handles to the copied axes)
			else
				D=getappdata(f,'navcopydata');
				hLc=D.hL{1};
				axc=D.ax;
			end
			for i=1:numel(c.ax)
				if c.ax(i)
					ht=get(c.ax(i),'Title');
					st=get(ht,'Tag');
					if bFirstCopy
						axc(i)=axes('Parent',f,'Position',get(c.ax(i),'Position')	...
							,'XGrid',get(c.ax(i),'XGrid')	...
							,'YGrid',get(c.ax(i),'YGrid')	...
							,'Box',get(c.ax(i),'Box')	...
							);
						title(axc(i),get(ht,'String'),'Interpreter',get(ht,'Interpreter'));
					else
						ccc=get(axc(i),'ColorOrder');
						nccc=size(ccc,1);
						ll=length(findobj(axc(i),'Type','line'));
					end
					for j=1:size(c.kols,2)
						if c.kols(i,j)
							hcm=uicontextmenu('parent',ancestor(axc(i),'figure'));
							if strcmp(st,'channel')
								sMenu=get(ht,'String');
							else
								sMenu=num2str(fnr);
							end
							uimenu(hcm,'label',sMenu);
							if bFirstCopy
								lCol=get(hLc{i}(j),'Color');
							else
								lCol=ccc(rem(ll,nccc)+1,:);
								ll=ll+1;
							end
							hLc{i}(j)=line(	...
								get(hL{i}(j),'XData')	...
								,get(hL{i}(j),'YData')	...
								,'Parent',axc(i)	...
								,'Color',lCol	...
								,'Linestyle',get(hLc{i}(j),'Linestyle')	...
								,'Marker',get(hLc{i}(j),'Marker')	...
								,'UIcontextMenu',hcm		...
								);
						end	% if line
					end	% for j
				end
			end	% for i
			if bFirstCopy
				D=struct('hL',{{hLc}},'ax',axc,'L',{{}});
			else
				D.hL{end+1}=hLc;
			end
			if isempty(c.ne)
				cName=fn;	% be sure it's a string
			else
				ne=c.ne;
				if ischar(ne)
					cName=deblank(ne(fnr,:));
				elseif length(ne)==2&&fnr>length(ne)	%!!!!!
					cName=ne{2};
				else
					cName=ne{fnr};
				end
			end
			D.L{end+1}=cName;
			setappdata(f,'navcopydata',D)
		case 'C'	% stop copying to current copy-figure
			f = getappdata(hFig,'copyFig');
			if ~isempty(f)
				set(f,'Tag','');
				rmappdata(hFig,'copyFig')
			end
		case 'L'    % legend on copy window
			f=getmakefig('navmsrcopy',0,0);
			if ~isempty(f)
				D=getappdata(f,'navcopydata');
				figure(f)
				legend(D.L)
			end
		case 'D'    % delete last lines on copy window
			f=getmakefig('navmsrcopy',0,0);
			if isempty(f)
				return;
			end
			D=getappdata(f,'navcopydata');
			if ~isempty(D.hL)
				hLc=D.hL{end};
				for i=1:numel(hLc)
					for j=1:size(c.kols,2)
						if hLc{i}(j)
							delete(hLc{i}(j))
						end
					end	% for j
				end % for i
				D.L(end)=[];
				D.hL(end)=[];
				setappdata(f,'navcopydata',D)
			end
		case 'g'    % gets data and stores in 'NAVdata'
			D=c.hL;
			for i=1:numel(c.ax)
				if c.ax(i)
					D{i}=cell(1,size(c.kols,2));
					for j=1:size(c.kols,2)
						if c.kols(i,j)
							X=get(c.hL{i}(j),'XData');
							Y=get(c.hL{i}(j),'YData');
							D{i}{j,1}=[X(:) Y(:)];
						end
					end
				end
			end
			if length(D)==1
				D=D{1};
				if length(D)==1
					D=D{1};
				end
			end
			assignin('base','NAVdata',D);
		case 'N'	% normal view
			axis auto
		case {3,17}	% ctrl-C and ctrl-Q - close
			close(c.fig)
		case 6		% ctrl-F - go to copy figure
			f=getmakefig('navmsrcopy',0,0);
			if ~isempty(f)
				figure(f);
			end
        otherwise   % send key to navfig
			if length(k)>1
				navfig(char(0),k)
			else
				navfig(k)
			end
			return
	end
else
	bHandleLinked = false;
	if isnumeric(varargin{1})
		fnr=varargin{1};
		if length(varargin)>1
			fnr0 = 0;	% force update
		end
	else
		error('Verkeerd gebruik van deze functie')
	end
end
if nargout
	out=1;
end
if fnr0==fnr
	return
end
if fnr>c.nFiles
	if c.opties.bWrap
		fnr=c.opties.minNrFiles;
	else
		fnr=c.nFiles;
	end
elseif fnr<c.opties.minNrFiles
	if c.opties.bWrap
		fnr=c.nFiles;
	else
		fnr=c.opties.minNrFiles;
	end
end
e=[];
if isfield(c.opties,'msrs')
	fn=c.opties.msrs{fnr};
else
	fn=[];
end
f1=num2str(fnr);
if isstruct(c.fnaam)
	if isfield(c.fnaam,'fname')	% was it a fault or is this used?
		f1=c.fnaam(fnr).fname;
	elseif isfield(c.fnaam,'name')
		f1=c.fnaam(fnr).name;
	elseif isfield(c.fnaam,'data')&&isfield(c.fnaam,'idx')
		f1=num2str(fnr);
		if c.fnaam.idx(fnr)==0
			e=[0 0];
		else
			if min(size(c.fnaam.idx))==1
				e=c.fnaam.data(c.fnaam.idx(fnr):c.fnaam.idx(fnr+1)-1,:);
			else
				e=c.fnaam.data(c.fnaam.idx(fnr,1):c.fnaam.idx(fnr,2)-1,:);
			end
			if isempty(e)
				e=[0 0];
			end
		end
		ne=c.ne;
	else
		error('Unknown structure type')
	end
elseif ischar(c.fnaam)
	if size(c.fnaam,1)==1&&any(c.fnaam=='%')
		if isfield(c.opties,'msrs')
			fn1=c.opties.msrs(fnr);
		else
			fn1=fnr;
		end
		f1=sprintf(c.fnaam,fn1);
	else
		f1=deblank(c.fnaam(fnr,:));
	end
elseif iscell(c.fnaam)
	f1=c.fnaam{fnr};
	if iscell(c.ne) && length(c.ne)>=fnr
		fn = c.ne{fnr};
	end
end
fTitle=sprintf('NAVMSRS %d/%d',fnr,c.nFiles);
if ischar(fn)
	fTitle=[fTitle ' - ' fn];
elseif ischar(f1)
	fTitle=[fTitle ' - ' f1];
end

hasError=false;
try
	if ischar(f1)&&~isempty(c.opties.evdir)
		f1cor=fullfile(c.opties.evdir,f1);
	else
		f1cor=f1;
	end
	if ischar(c.funcnaam)
		eval(['[e,ne]=' c.funcnaam '(''' f1cor ''');']);
	elseif isa(c.funcnaam,'function_handle')
		[e,ne]=c.funcnaam(f1cor,c.opties.readOptions{:});
	elseif isnumeric(c.fnaam)
		if size(c.fnaam,3)>1
			%X=c.fnaam(:,fnr,2);
			%e=[X c.fnaam(:,fnr)];
			e=squeeze(c.fnaam(:,fnr,:));
		else
			e=c.fnaam(:,fnr);
		end
		if isempty(c.ne)
			ne='';	% be sure it's a string
		else
			ne=c.ne;
			if ischar(ne)
				ne1=deblank(ne(fnr,:));
			else
				ne1=ne{fnr};
			end
			title(c.ax(1),sprintf('%d: %s',fnr,ne1),'Tag','channel')
		end
	elseif istable(c.fnaam)
		ne=c.opties.ne;
		ne1=ne{fnr};
		e = c.fnaam.(ne1);
		title(c.ax(1),sprintf('%d: %s',fnr,ne1),'Tag','channel')
	elseif isempty(e)
		e=f1;
		ne=c.opties.ne;
		if size(e,2)~=length(ne)&&length(ne)==c.nFiles
			ne=c.ne;
			if ischar(ne)
				ne1=deblank(ne(fnr,:));
			else
				ne1=ne{fnr};
			end
			title(c.ax(1),sprintf('%d: %s',fnr,ne1),'Tag','channel')
		end
	end
catch err
	errordlg(['Er liep iets fout tijdens inlezen van de file (' f1 ') "' err.message '"'],'NAVMSRS-error')
	hasError=true;
	e=[];
end
if isempty(e)&&~hasError
	hasError=true;
	errordlg('geen data ingelezen!','NAVMSRS-error')
end
if hasError
	fTitle=['ERR ' fTitle];
	for i=1:size(c.kols,1)
		for j=1:size(c.kols,2)
			if c.kols(i,j)
				set(c.hL{i}(j),'XData',0,'YData',0)
			end
		end
	end
else
	if c.opties.bVarSignames
		title(c.ax(1),ne{2},'Tag','channel')	%!!!!very specific!!!!!
	elseif ~isequal(ne,c.ne)
		if length(c.ne)<5&&length(ne)<5
			disp('Oorspronkelijk :')
			disp(c.ne)
			disp('nu :')
			disp(ne)
		else
			fprintf('!andere kanalen (%d --> %d)\n',length(c.ne),length(ne))
		end
		if length(ne)==length(c.ne)
			uiwait(warndlg('Andere namen van kanalen!','NAVMSRS-warning','modal'))
		elseif (iscell(c.opties.kols)&&max(cat(2,c.opties.kols{:}))<=length(ne))||(~iscell(c.opties.kols)&&max(c.opties.kols)<=length(ne))
			uiwait(warndlg('Andere kanalen!','NAVMSRS-warning','modal'))
		else
			errordlg('Andere kanalen!','NAVMSRS-error')
			return
		end
	end
	c.ne = ne;
	lnr=0;
	hL=c.hL';
	for i=1:size(c.kols,1)
		kols=c.kols(i,:);
		bMultiX=false;
		if isempty(c.kanx)
			X=[];
		elseif length(c.kanx)==1
			if c.kanx<0
				X=(0:size(e,1)-1)'*abs(c.kanx);
			else
				X=e(:,c.kanx);
			end
		elseif length(c.kanx)==size(c.kols,1)
			X=e(:,c.kanx(i));
		elseif isequal(size(c.kanx),size(c.kols))
			X=e(:,nonzeros(c.kanx(i,:)));
			bMultiX=size(X,2)>1;
		else
			X=(0:size(e,1)-1)*(c.kanx(2)-c.kanx(1));
		end
		iX=0;
		for j=1:size(kols,2)
			if kols(j)>0
				lnr=lnr+1;
				Y=e(:,kols(j));
				if isfield(c.opties,'cfunc')	% character based function (transforming Y-values)
					if ischar(c.opties.cfunc)
						Y=eval([c.opties.cfunc '(Y);']);
					else
						Y=eval([c.opties.cfunc{lnr} '(Y);']);
					end
				elseif isfield(c.opties,'hfunc') % function handle based function (transforming Y-values)
					if isa(c.opties.hfunc,'function_handle')
						Y=c.opties.hfunc(Y);
					else
						Y=c.opties.hfunc{lnr}(Y);
					end
				end
				if ~isempty(X)
					if bMultiX
						iX=iX+1;
						set(hL{i}(j),'XData',X(:,iX))
					else
						set(hL{i}(j),'XData',X)
					end
				end
				if islogical(Y)
					Y = double(Y);	% plots don't like logicals...
				end
				set(hL{i}(j),'YData',Y)
			end
		end
	end
end
c.nr=fnr;
set(hFig,'Name',fTitle)
if bHandleLinked && ~isempty(c.opties.postNavFcn)
	if ischar(c.opties.postNavFcn)
		eval([c.opties.postNavFcn '(' num2str(c.fig) ',' num2str(fnr) ');']);
	elseif isa(c.opties.postNavFcn,'function_handle')
		c.opties.postNavFcn(c.fig,fnr);
	else
		error('Error using postNavFcn!')
	end
end
ax = GetNormalAxes(hFig);
if isequal(getappdata(ax(1),'updateAxes'),@axtick2date)
	axtick2date(hFig)
end
