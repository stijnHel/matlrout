function D=ReadHotIntStruct(fName,varargin)
%ReadHotIntStruct - Read HID files (HotInt simulation model)
%       D=ReadHotIntStruct(fName)

% variables:
%    two ways are used to hold variables: struct-vector with fields name
%       and value, and a structure with all variables as fields.
%    the two are OK, but the combination is not (no distincation can be
%       made between one variable and two variables ('name' and 'value')!
%    See MergeVars for an illustration of the difficulty.

% - if for-constructs are used, nL is the number of read lines, including the
%    repeated lines!
% - for only works for not very long files (direct use of L, iL)
% - is everything OK with case insentivity (lower is removed)
%           it's not!!!!!!!
%         lower is added again, except for the <var>{...} cases!
%         ------------- problem is coming via (case sensitive) fields
%        is it OK now? ------ with "SetCIfield", ...
%               !!!!!nee - kristof-model!!!!!!!!

varExternal=[];
bOnlyKeepVars=false;	% doesn't really work!
	% the goal was to get a "cleaner output".
bMainFile=true;
bCombineTypes=true;
Elements=struct('elements',[],'connectors',[]	...
	,'loads',[],'sensors',[],'geomElement',[]);
if nargin>1
	if isstruct(varargin{1})
		varExternal=varargin{1};
		options=varargin(2:end);
	else
		options=varargin;
	end
	if ~isempty(options)
		setoptions({'bOnlyKeepVars','bMainFile','Elements','CombineTypes'},options{:})
	end
end

bBlank=false(1,255);
bLetter=bBlank;
bDigit=bBlank;
bBlank(abs(' '))=true;
bBlank([9 10 13])=true;
bLetter(abs('a'):abs('z'))=true;
bLetter(abs('A'):abs('Z'))=true;
bLetter(abs('_'))=true;
bDigit(abs('0'):abs('9'))=true;
bVar=bLetter|bDigit;
bNumber=bDigit;
bNumber(abs('.'))=true;
cRevBracket=char(zeros(1,255));
cRevBracket(abs('{'))='}';
cRevBracket(abs('}'))='{';
cRevBracket(abs('['))=']';
cRevBracket(abs(']'))='[';
cRevBracket(abs('('))=')';
cRevBracket(abs(')'))='(';

[fPath,fname,fext]=fileparts(fName);
fExist=exist(fName,'file');
if ~fExist
	if isempty(fext)
		fName=[fName,'.hid'];
	end
elseif fExist==7	% directory
	fName1=fullfile(fName,[fname '.hid']);
	if exist(fName1,'file')==2
		fPath=fName;
		fName=fName1;
	else
		d=dir(fullfile(fName,'*.hid'));
		if length(d)==1
			fName=fullfile(fName,d.name);
		else
			error('No file could be chosen from the directory')
		end
	end
end
if exist(fName,'file')~=2
	fName=zetev([],fName);
	if ~exist(fName,'file')
		error('File not found!')
	end
end
cFile=cBufTextFile(fName);
L=fgetlN(cFile,1000);
iL=1;
nL=0;

Stack=cell(3,20);% 1: type, 2: contents, 3: vars
% ?better make it a structure?
nStack=1;	% top level
Stack{1,1}='root';
Stack{2,1}=cell(1,0);
Stack{3,1}=cell(1,0);
BB=char(zeros(1,30));
Constructs=struct('typ',cell(1,10),'level',-1,'cond',true	...
	,'fullCond',true,'data',[]);
	% by not interpreting when ~bOperate, fullCond is not really needed!
nConts=1;	% first element as sentinel
bOperate=true;

while iL<=length(L)
	nL=nL+1;
	l=GetLine();
	if isempty(l)
		continue
	end
	i=1;
	while i<=length(l)
		c=abs(l(i));
		if bBlank(c)
			% do nothing
		elseif l(i)=='%'
			l(i:end)=[];
		elseif bLetter(c)||bNumber(c)
			i_s=i;
			i_e=i;
			%i=i+1;
			%c=abs(l(i));
			nBB=0;
			lastChar=l(i);
			while bBlank(c)||bVar(c)||any(l(i)=='+-*/^.=<>~!([])%"')	...
					||(nBB&&any(l(i)==',;'))
				if l(i)=='%'
					l(i:end)=[];
				else
					if ~bBlank(c)
						i_e=i;
					end
					if l(i)=='"'
						i=i+1;
						while l(i)~='"'	% (!)implicit error when line ends during string
							%if l(i)=='\'	% escape character possible?
							%	i=i+1;
							%end
							i=i+1;
						end
						i_e=i;
					end
					if ~bBlank(c)
						lastChar=l(i);
					end
					i=i+1;
				end
				if i>length(l)
					if nBB==0
						break
					end
					nL=nL+1;
					cSep=' ';
					if nBB&&BB(nBB)=='['&&lastChar~=';'
						cSep=';';	% force next row in an array
					end
					l=[l cSep GetLine()]; %#ok<AGROW>
					i=i+1;
					if cSep~=' '
						i_e=i;
					end
				end
				if any(l(i)=='([')
					nBB=nBB+1;
					BB(nBB)=l(i);
				elseif any(l(i)==')]')
					if nBB==0||cRevBracket(abs(l(i)))~=BB(nBB)
						error('Wrong structure!? (%s#%d)',fname,nL)
					end
					nBB=nBB-1;
				end
				c=abs(l(i));
			end		% go to end of formula
			if bOperate
				sForm=l(i_s:i_e);
				[Df,vars,Oform]=InterpreteFormula(sForm,'--bForceFloat'	...
					,'-bMatlabForm','charEscape',0);
				vars=lower(vars);
				if size(Df,2)==1
					if Df(2,1)~=1	% variable
						error('"name" expected! (%s)',l)
					end
					%val=struct('type','varName','name',sForm);
					val=struct('type','varName','name',lower(sForm));
					Stack{2,nStack}{1,end+1}=val;
					Simplify();
				else
					nVars=length(vars);
					bAssignment=Df(2,Oform(end,1))==7;
					vars(3,:)=num2cell(false(1,nVars));
					vars(4,:)=num2cell(zeros(1,nVars));
					if bAssignment
						if sum(Df(2,:)==7)>1
							error('Multiple assignments are not foreseen here!')
						end
						iA=Oform(end,1);
					else
						iA=0;
					end
					% set variables (dependent on its type)
					%for j=iA+1:size(Df,2)
					for j=1:size(Df,2)
						switch Df(2,j)
							case 1	% variable
								jVar=Df(5,j);
								Vi=vars{1,jVar};
								if vars{4,jVar}
									if vars{4,jVar}~=1
										warning('Double use of name for different types (%s)!'	...
											,Vi)
									end
								elseif strcmpi(Vi,'pi')
									vars{2,jVar}=pi;
									vars{3,jVar}=true;
									vars{4,jVar}=1;
								else
									[vars{2,jVar},vars{3,jVar}]=GetVarVal(Vi);
									vars{4,jVar}=1;
								end
							case 5	% function
								jVar=Df(5,j);
								Vi=vars{1,jVar};
								if vars{4,jVar}
									if vars{4,jVar}~=5
										warning('Double use of name for different types (%s)!'	...
											,Vi)
									end
								else
									% different if assignent or not???
									%	(!)arrays <-- in assignment!
									switch lower(Vi)
										case 'sqr'
											vars{2,jVar}=@HI_sqr;
											vars{3,jVar}=true;
										case 'sqrt'
											vars{2,jVar}=@HI_sqrt;
											vars{3,jVar}=true;
										case 'product'
											vars{2,jVar}=@HI_product;
											vars{3,jVar}=true;
										case 'cols'
											vars{2,jVar}=@HI_cols;
											vars{3,jVar}=true;
										case 'rows'
											vars{2,jVar}=@HI_rows;
											vars{3,jVar}=true;
										case {'if','include','for'}
											% handled later
										case 'addconnector'
											vars{2,jVar}=@HI_AddConnector;
											vars{3,jVar}=true;
										case 'addelement'
											vars{2,jVar}=@HI_AddElement;
											vars{3,jVar}=true;
										case 'addgeomelement'
											vars{2,jVar}=@HI_AddGeomElement;
											vars{3,jVar}=true;
										case 'addload'
											vars{2,jVar}=@HI_AddLoad;
											vars{3,jVar}=true;
										case 'addsensor'
											vars{2,jVar}=@HI_AddSensor;
											vars{3,jVar}=true;
										otherwise
											if exist(Vi,'builtin')
												vars{2,jVar}=str2func(Vi);
												vars{3,jVar}=true;
											elseif exist(Vi,'file')
												vars{2,jVar}=str2func(Vi);
												vars{3,jVar}=true;
											else
												AddUnknownFcn(Vi)
											end
									end		% switch Vi
									vars{4,jVar}=5;
								end		% else (if vars(4,jVar))
						end		% switch Df(2,j)
					end		% for j
					[Vform,bOKform,Vinterm]=InterpreteFormula(Df,vars	...
						,Oform,'idxStart',1);
					if bAssignment
						if iA>2
							sVar=GetElem(l(1:Df(1,iA)-1),Df,iA-1,Oform,Vinterm);
							sVar=lower(sVar);
						else
							sVar=vars{1};
						end
						iO1=-Oform(end,6);
						if iO1<=0
							error('Unknown option of assignment')
						end
						b=Vinterm{1,iO1};
						val=Vinterm{2,iO1};
						if ~b
							val=struct('type','formula','formula',sForm	...
								,'D',Df,'vars',{vars},'order',Oform		...
								,'Vinterm',{Vinterm});
						end
						if iscell(val)&&size(val,1)==3
							halloxxx=1;
						end
						SetVar(sVar,val)
						if ~bOnlyKeepVars
							S1=struct('type','assign','name',{sVar},'value',{val});
							Stack{2,nStack}{1,end+1}=S1;
						end
						Simplify();
					else
						bAddFunction=true;
						if Df(2)==5	% function
							switch lower(vars{1})
								case 'if'
									nConts=nConts+1;
									Constructs(nConts).typ='if';
									Constructs(nConts).level=nStack;
									if Vinterm{1,end-1}
										cond=Vinterm{2,end-1};
									else
										cond=[];
									end
									Constructs(nConts).cond=cond;
									if nConts>1
										if isempty(Constructs(nConts-1).fullCond)||isempty(cond)
											cond=[];
										else
											cond=Constructs(nConts-1).fullCond&&cond;
										end
									end
									Constructs(nConts).fullCond=cond;
									bOperate=cond;
								case 'for'
									nConts=nConts+1;
									Constructs(nConts).typ='for';
									Constructs(nConts).level=nStack;
									if Df(2,2)~=50||Df(2,end)~=51
										error('Unexpected for definition! (%s)',sForm)
									end
									iOinit=-Oform(end-3,5);
									iOcond=-Oform(end-3,6);
									iDinit=Oform(iOinit);
									if Df(2,iDinit)~=7
										error('No simple init of for-construct? (%s)',sForm);
									end
									if ~Vinterm{1,Oform(-Oform(iOinit,6))}
										error('No init value in for-construct?! (%s)',sForm);
									end
									iV=Df(5,Oform(-Oform(iOinit,5)));
									val=Vinterm{2,-Oform(iOinit,6)};
									SetVar(vars{1,iV},val);
									vars{2,iV}=val;
									vars{3,iV}=true;
									Oform(iOinit)=0;	% disable - also dependent operationa!
									% recalculate, with init value (!?also init!)
									[Vform,bOKform,Vinterm,vars]=InterpreteFormula(Df,vars	...
										,Oform,'idxStart',1);
									if ~Vinterm{1,iOcond}
										error('Can''t evaluate condition!!')
									end
									Constructs(nConts).data=var2struct(Df,vars,Oform,nL		...
										,iOcond,iL);
									cond=Vinterm{2,iOcond}~=0;
									Constructs(nConts).cond=cond;
									if nConts>1
										if isempty(Constructs(nConts-1).fullCond)||isempty(cond)
											cond=[];
										else
											cond=Constructs(nConts-1).fullCond&&cond;
										end
									end
									Constructs(nConts).fullCond=cond;
									bOperate=cond;
								case 'include'
									iD=Oform(1);
									fNameImport=fullfile(fPath		...
										,l(Df(1,iD)+1:Df(1,iD)-2+Df(3,iD)));
									varExternal=CombineVars(varExternal,Stack{3});
									Dimport=ReadHotIntStruct(fNameImport,varExternal	...
										,'bOnlyKeepVars',bOnlyKeepVars	...
										,'Elements',Elements,'--bMainFile');
									varExternal=Dimport.vars;
										%(!)Supposing "level 1"(!)
									Stack{2,nStack}{1,end+1}=Dimport.contents;
									Elements=Dimport.Elements;
									Simplify();
									bAddFunction=false;
							end		% switch vars{1}
						end		% elseif function
						if bAddFunction
							if bOKform
								S1=struct('type','instruction','text',sForm	...
									,'value',Vform);
							else
								S1=struct('type','instruction','text',sForm	...
									,'D',Df,'vars',{vars},'order',Oform		...
									,'Vinterm',{Vinterm});
							end
							Stack{2,nStack}{1,end+1}=S1;
							Simplify();
						end
					end		% else (#>1 && ~bAssignment)
				end		% else (not just a name)
			end		% if bOperate
			l=l(i:end);
			i=0;
		elseif l(i)=='['||l(i)=='('
			% shouldn't be possible
			warning('Toch mogelijk dat een vrije ''(''/''['' voorkomt?! (%s#%d)',fname,nL)
		elseif l(i)=='{'
			S1=Stack{2,nStack};
			S1vars=cell(1,0);
			if ~isempty(S1)&&IsFieldType(S1{end},'varName')
				Stack{2,nStack}{end}=struct('type','assignOpen'	...
					,'name',S1{end}.name);
				[S1v,bF]=GetVarVal(S1{end}.name);
				if bF
					S1n=fieldnames(S1v);
					S1vars=struct('name',S1n,'value',cell(length(S1n),1));
					for iS1=1:length(S1n)
						S1vars(iS1).value=GetCIfield(S1v,S1n{iS1});
					end
				end
			end
			nStack=nStack+1;
			Stack{1,nStack}=l(i);
			Stack{2,nStack}=cell(1,0);
			Stack{3,nStack}=S1vars;
			l=l(i+1:end);
			i=0;
		elseif l(i)=='}'||l(i)==']'||l(i)==')'
			if nStack==0||cRevBracket(abs(l(i)))~=Stack{1,nStack}
				error('Wrong structure!?')
			end
			bDecLevel=true;
			if Constructs(nConts).level==nStack-1&&strcmp(Constructs(nConts).typ,'for')
				[~,~,Vinterm,Constructs(nConts).data.vars]=InterpreteFormula(	...
					Constructs(nConts).data.Df		...
					,Constructs(nConts).data.vars	...
					,Constructs(nConts).data.Oform,'idxStart',1);
				cond=Vinterm{2,Constructs(nConts).data.iOcond}~=0;
				if cond
					iL=Constructs(nConts).data.iL+1;
					bDecLevel=false;
				end
			end
			if bDecLevel
				S1=Stack{2,nStack};
				if iscell(S1)&&isscalar(S1)
					S1=S1{1};
					Stack{2,nStack}=S1;
				end
				if l(i)==')'
					S1=Stack(:,nStack);	% do something? - is this possible?
				elseif l(i)==']'
					S1=Stack(:,nStack);	% do something? - is this possible?
				else
					if bOnlyKeepVars
						S1=Stack{3,nStack};
					else
						S1=Stack(:,nStack);
					end
				end
				nStack=nStack-1;
				if Constructs(nConts).level==nStack
					if ~bOnlyKeepVars&&~isequal(size(S1),[3 1])	...
							||~IsFieldType(Stack{2,nStack}{end},'instruction')
						error('Unexpected (but foreseen...) error!')
					end
					if Constructs(nConts).cond
						if bOnlyKeepVars
							Stack{3,nStack}=MergeVars(Stack{3,nStack},S1);
						else
							if iscell(S1{2})&&isscalar(S1{2})
								S1{2}=S1{2}{1};	% not possible?
							end
							if isscalar(Stack{2,nStack}{end})
								Stack{2,nStack}{end}=S1{2};
							else
								Stack{2,nStack}{end}(end)=[];
								Stack{2,nStack}{1,end+1}=S1{2};
							end
							Stack{3,nStack}=MergeVars(Stack{3,nStack},S1{3});
						end
					elseif bOnlyKeepVars
						% do nothing
					elseif isscalar(Stack{2,nStack}{end})
						Stack{2,nStack}(end)=[];
					else
						Stack{2,nStack}{end}(end)=[];
					end
					nConts=nConts-1;
					bOperate=Constructs(nConts).fullCond;
				else
					Stack{2,nStack}{1,end+1}=S1;
				end
			end
			Simplify();
			l=l(i+1:end);
			i=0;
		elseif l(i)==';'
			% allowed but not needed ==> discarded
		else
			warning('Unexpected character? (%s#%d - "%s" in "%s")'	...
				,fname,nL,l(i),l)
		end
		i=i+1;
	end		% read line
end
if nStack>1
	error('End of file inside a structure?')
end
if nConts>1
	warning('Something goes wrong with the "Constructs"! (#%d)',nConts-1)
end
vars=Stack{3};
if isempty(vars)
	vars=varExternal;
else
	vars=MakeVarStruct(vars,varExternal);
end
if iscell(Stack{2})&&isscalar(Stack{2})
	Stack{2}=Stack{2}{1};
end
fnE=fieldnames(Elements);
for iE=1:length(fnE)
	if bCombineTypes
		if bMainFile
			Elements.(fnE{iE})=CombineTypes(Elements.(fnE{iE}));
		end
	else
		Elements.(fnE{iE})=GroupElements(Elements.(fnE{iE}),bMainFile);
	end
end
D=struct('nL',nL,'contents',Stack(2),'Elements',Elements	...
	,'vars',vars);

	function l=GetLine()
		l=strtrim(L{iL});
		iL=iL+1;
		if iL>length(L)&&~feof(cFile)
			L=fgetlN(cFile,5000);
			iL=1;
		end
	end		% function GetLine

	function [bFound,vRef,bExt,nFound]=FindVar(sVar)
		if iscell(sVar)
			sVar1=sVar{1};
		else
			sVar1=sVar;
		end
		bExt=false;
		bFound=false;
		iS=nStack;
		nFound=0;	% should replace bFound
		while iS
			if ~isempty(Stack{3,iS})
				Vlist={Stack{3,iS}.name};
				bV=strcmpi(sVar1,Vlist);
				if any(bV)
					bFound=true;
					vRef=struct('type',{'{}','()','.'}	...
						,'subs',{{3,iS},{find(bV)},'value'});
					nFound=1;
					break
				end
			end
			iS=iS-1;
		end
		if ~bFound
			if ~isempty(varExternal)&&isCIfield(varExternal,sVar1)
				bFound=true;
				vRef=struct('type','.','subs',sVar1);
				bExt=true;
				nFound=1;
			else
				vRef=[];
			end
		end
		if bFound&&iscell(sVar)
			if bExt
				V1=subsref(varExternal,vRef);
			else
				V1=subsref(Stack,vRef);
			end
			[~,bFound,Sref1,nFoundF]=FindField(V1,sVar(2:end));
			nFound=nFound+nFoundF;
			if ~bFound		% try to correct?
				if length(vRef)==length(sVar1)*2-4

				else
					%...
				end
			end
			if bFound
				vRef=[vRef Sref1];
			end
		end		% found
	end		% function FindVar

	function CreateVar(sVar,val)
		if isempty(Stack{3,nStack})
			% first variable (on this level)
			V1=struct('name',sVar,'value',val);
			Stack{3,nStack}=V1;
		else
			Stack{3,nStack}(end+1).name=sVar;
			Stack{3,nStack}(end).value=val;
		end
	end		% function CreateVar

	function SetVar(sVar,val)
		% set variable
		%    if value is not given, the variable is created
		[bOK,Sref,bExt,nFound]=FindVar(sVar);
		if bOK
			if isstruct(val)&&ischar(sVar)	% keep not newly assigned fields
				if bExt
					valOld=subsref(varExternal,Sref);
				else
					valOld=subsref(Stack,Sref);
				end
				if ~isstruct(valOld)
					warning('Unexpected: variable (%s) number-->struct!'	...
						,sVar);
				else
					fnOld=fieldnames(valOld);
					fnNew=fieldnames(val);
					fnDif=setdiff(fnOld,fnNew)';
					if ~isempty(fnDif)
						for fni=fnDif
							val=SetCIfield(val,fni{1},GetCIfield(valOld,fni{1}));
						end
					end
					%?? order fieldnames?
				end
			end
			if bExt
				varExternal=subsasgn(varExternal,Sref,val);
			else
				Stack=subsasgn(Stack,Sref,val);
			end
		else	% not found
			if iscell(sVar)
				if nFound
					iS=length(sVar);
					while iS>nFound+1
						val=struct(sVar{iS},{val});
						iS=iS-1;
					end
					Sref(end+1).type='.';
					Sref(end).subs=sVar(nFound+1);
					if bExt
						varExternal=subsasgn(varExternal,Sref,val);
					else
						Stack=subsasgn(Stack,Sref,val);
					end
				else
					iS=length(sVar);
					while iS>1
						val=struct(sVar{iS},{val});
						iS=iS-1;
					end
					CreateVar(sVar{1},val)
				end
			else
				CreateVar(sVar,val);
			end
		end
	end		% function SetVar

	function [v,bFound]=GetVarVal(sVar)
		[bFound,Sref,bExt]=FindVar(sVar);
		if bFound
			if bExt
				v=subsref(varExternal,Sref);
			else
				v=subsref(Stack,Sref);
			end
		else
			v=[];
			bFound=false;
		end
	end		% function GetVarVal

	function Simplify()
		bCont=true;
		while bCont
			P1=Stack{2,nStack};
			if isempty(P1)
				return
			end
			bCont=false;
			P1_1=P1{end};
			if length(P1)>1
				P1_1type=GetFieldType(P1_1);
				P1_2=P1{end-1};
				if isstruct(P1_2)
					P1_2type=GetFieldType(P1_2);
					if strcmp(P1_2type,'assignOpen')
						if length(P1_2)>1	% unfinished assignement!
							Stack{2,nStack}{end-1}=P1_2(1:end-1);
							Stack{2,nStack}{end}=P1_2(end);
							Stack{2,nStack}{1,end+1}=P1_1;
						end
						Stack{2,nStack}{end-1}.type='assign';
						if isnumeric(P1_1)
							%Do nothing
						elseif iscell(P1_1)&&isequal(size(P1_1),[3 1])	...
								&&strcmp(P1_1{1},'[')	...
								&&iscell(P1_1{2})&&isscalar(P1_1{2})	...
								&&isnumeric(P1_1{2}{1})
							P1_1=P1_1{2}{1};
						elseif strcmp(P1_1type,'var')
							P1_1=P1_1.value;
						else
							s=1;	% breakpoint possibility setting
						end
						if iscell(P1_1)
							if size(P1_1,2)~=1
								aaaaaaaaaaa=1;
							end
							vP1_1=MakeVarStruct(P1_1{3},[]);
						else
							vP1_1=P1_1;
						end
						SetVar(Stack{2,nStack}{end-1}.name,vP1_1)
						if bOnlyKeepVars
							Stack{2,nStack}(end-1)=[];
						else
							%Stack{2,nStack}{end-1}.value=P1_1;
							Stack{2,nStack}{end-1}.value=vP1_1;
						end
						Stack{2,nStack}(end)=[];
						bCont=true;
					elseif strcmp(P1_2type,'instruction')
						aaaaaaaaaa=1;
					else
						aaaaaaaaaa=1;
					end		% if assignOpen
				end
				if length(Stack{2,nStack})>1	...
						&&all(cellfun('isclass',Stack{2,nStack}(end-1:end),'struct'))
					if isequal(fieldnames(Stack{2,nStack}{end-1}),fieldnames(Stack{2,nStack}{end}))
						%strcmp(Stack{2,nStack}{end-1}(1).type,Stack{2,nStack}{end}(1).type)
						% combine similar structures
						Stack{2,nStack}{end-1}=cat(2,Stack{2,nStack}{end-1:end});
						Stack{2,nStack}(end)=[];
					end
				end
			end
		end		% while bCont
	end		% function Simplify

	function p=HI_AddHI(typ,el)
		if isempty(Elements.(typ))
			Elements.(typ)={el};
		else
			Elements.(typ){1,end+1}=el;
		end
		if isfield(el,'name')
			name=el.name;
		else
			fn=fieldnames(el)';
			name=[];
			for fni=fn
				vi=GetCIfield(el,fni{1});
				if ~isempty(vi)&&ischar(vi)&&size(vi,1)==1
					name=[fni{1} '_' vi];
					break;
				end
			end
			if isempty(name)
				name=sprintf('#%d',length(Elements.(typ)));
			end
		end
		p={name,length(Elements.(typ))};
	end		% function HI_AddHI

	function p=HI_AddElement(el)
		p=[{'body'} HI_AddHI('elements',el)];
		p=struct('type',p(1),'name',p(2),'nr',p(3));	% test
	end		% function HI_AddElement

	function p=HI_AddConnector(el)
		p=[{'connector'} HI_AddHI('connectors',el)];
		p=struct('type',p(1),'name',p(2),'nr',p(3));	% test
	end		% function HI_AddConnector

	function p=HI_AddLoad(el)
		p=[{'load'} HI_AddHI('loads',el)];
		p=struct('type',p(1),'name',p(2),'nr',p(3));	% test
	end		% function HI_AddLoad

	function p=HI_AddSensor(el)
		p=[{'sensor'} HI_AddHI('sensors',el)];
		p=struct('type',p(1),'name',p(2),'nr',p(3));	% test
	end		% function HI_AddSensor

	function p=HI_AddGeomElement(el)
		p=[{'geomEl'} HI_AddHI('geomElement',el)];
		p=struct('type',p(1),'name',p(2),'nr',p(3));	% test
	end		% function HI_AddGeomElement

	function AddUnknownFcn(fcn)
		global UNKNOWNfcns
		if isempty(UNKNOWNfcns)
			UNKNOWNfcns={fcn;fname};
		elseif ~any(strcmp(fcn,UNKNOWNfcns(1,:)))
			UNKNOWNfcns{1,end+1}=fcn;
			UNKNOWNfcns{2,end}=fname;
		end
	end		% function AddUnknownFcn

end		% function ReadHotIntStruct

function s=GetElem(l,B,nB,Oform,Vinterm)
if nB==1
	s=l;
%elseif B(2,1)~=1||any(B(2,2:2:nB)~=40)||any(B(2,3:2:nB)~=91)
%	error('wrong structure?!')
else
	nField1=floor((nB+1)/2);
	s=cell(1,nField1);
	s{1}=l(B(1,1):B(1,1)+B(3,1)-1);
	j=1;
	for i=2:nField1
		j=j+1;
		if B(2,j)==40	% field reference
			j=j+1;
			if B(2,j)~=91
				error('wrong structure?!')
			end
			s{i}=l(B(1,j):B(1,j)+B(3,j)-1);
		elseif B(2,j)==52		% array index
			% ?test if last element?
			k=-Oform(Oform(:,1)==j,6);
			if ~Vinterm{1,k}
				error('Unknown index number')
			end
			s{i}=['[' num2str(Vinterm{2,k})];
			if i<nField1
				s=s(1:i);
			end
			break
		else
			error('wrong structure?!')
		end
	end
end
end		% function GetElem

function [V,flds]=MakeVarStruct(vars,Svar)
if isempty(vars)
	V=Svar;
	if isempty(Svar)
		flds=[];
	else
		flds=fieldnames(Svar);
	end
else
	if isempty(Svar)
		V=struct();
	else
		V=Svar;
	end
	for i=1:length(vars)
		v=vars(i).value;
		if isstruct(v)
			if isfield(v,'name')&&isfield(v,'value')&&length(fieldnames(v))==2
				v=MakeVarStruct(v,[]);
			end
		end
		V.(vars(i).name)=v;
	end
	flds=fieldnames(V);
end

end		% function MakeVarStruct

function [v,bFound,Sref,nFound]=FindField(v,sVar)
Sref=struct('type',cell(1,length(sVar)*2),'subs',[]);
nS=0;
bFound=true;
nFound=0;
while  nFound<length(sVar)
	sVar1=sVar{nFound+1};
	if sVar1(1)=='[';
		nS=nS+1;
		Sref(nS).type='()';
		idx=str2double(sVar1(2:end));
		Sref(nS).subs={idx};
		v=v(idx);
	elseif isstruct(v)&&isscalar(v)&&isCIfield(v,sVar1)
		nS=nS+1;
		Sref(nS).type='.';
		Sref(nS).subs=sVar1;
		v=GetCIfield(v,sVar1);
	elseif ~isstruct(v)||~isfield(v,'name')||~isfield(v,'value')
		bFound=false;
		break
	else
		b=strcmpi(sVar1,{v.name});
		if any(b)
			i=find(b);
			nS=nS+1;
			Sref(nS).type='()';
			Sref(nS).subs={i};
			nS=nS+1;
			Sref(nS).type='.';
			Sref(nS).subs='value';
			v=v(b).value;
		else
			bFound=false;
			break;
		end
	end
	nFound=nFound+1;
end		% while nFound
Sref=Sref(1:nS);
end		% function FindField

function varExternal=CombineVars(varExternal,newVars)
[S,fNames]=MakeVarStruct(newVars,varExternal);
if isempty(varExternal)
	varExternal=S;
else
	for i=1:length(fNames)
		varExternal=SetCIfield(varExternal,fNames{i},GetCIfield(S,fNames{i}));
	end
end
end		% function CombineVars

function V=MergeVars(V,Vnew)
% currently it's supposed that Vnew contain only new vars!
if isempty(V)
	V=Vnew;
elseif isempty(Vnew)
	% Do nothing
elseif isstruct(V)
	if ~isscalar(V)||isequal(fieldnames(V),{'name';'value'})
		if ~isscalar(Vnew)||isequal(fieldnames(Vnew),{'name';'value'})
			V=[V Vnew];
		else
			fn=fieldnames(Vnew)';
			Vfn=cell(1,length(fn));
			for i=1:length(fn)
				Vfn{i}=GetCIfield(Vnew,fn{i});
			end
			V=[V struct('name',fn,'value',Vfn)];
		end
	else
		if ~isscalar(Vnew)||isequal(fieldnames(Vnew),{'name';'value'})
			for i=1:length(Vnew)
				V=SetCIfield(V,Vnew(i).name,Vnew(i).value);
			end
		else
			fn=fieldnames(Vnew)';
			for i=1:length(fn)
				V=SetCIfield(V,fn{i},GetCIfield(Vnew,fn{i}));
			end
		end
	end
else
	error('Is this possible?')
end
end		% function MergeVars

function tp=GetFieldType(S)
if iscell(S)
	if size(S,1)==1
		tp='CLASScell1';
	elseif size(S,1)==2
		tp='CLASScell2';
	elseif size(S,1)==3
		tp='CLASScell3';
	else
		tp='CLASScellx';
	end
elseif isstruct(S)
	if isempty(S)
		tp='CLASSstructEmpty';
	elseif isfield(S(end),'type')
		tp=S(end).type;
	else
		tp='CLASSstruct';
	end
else
	tp=['CLASS' class(S)];
end
end		% function GetFieldType

function b=IsFieldType(S,tp)
b=strcmp(GetFieldType(S),tp);
end		% function IsFieldType

%% HotInt-functions
function p=HI_product(a,b)
if isnumeric(a)&&isnumeric(b)
	p=sum(a(:).*b(:));
else
	p=NaN;
end
end

function p=HI_sqr(a)
if isnumeric(a)
	p=a^2;
else
	p=NaN;
end
end

function p=HI_sqrt(a)
if isnumeric(a)
	p=sqrt(a);
else
	p=NaN;
end
end

function p=HI_cols(a)
p=size(a,2);
end

function p=HI_rows(a)
p=size(a,1);
end

function E=GroupElements(E,bUncellSingles)
FN=cell(1,length(E));
NE=zeros(1,length(FN));
for iE=1:length(FN)
	FN{iE}=sort(fieldnames(E{iE}));
	NE(iE)=length(FN{iE});
end
iE=1;
while iE<length(E)
	B=NE(iE+1:end)==NE(iE);
	if any(B)
		for i=1:length(B)
			if B(i)
				B(i)=isequal(FN{iE},FN{iE+i});
			end
		end
		if any(B)
			B=[false(1,iE-1) true B]; %#ok<AGROW>
			E{iE}=[E{B}];	% combine
			B(iE)=false;	% keep element [iE]
			E(B)=[];	% remove combined elements
			FN(B)=[];	%    and its relatives
			NE(B)=[];
		end
	end
	iE=iE+1;
end
if bUncellSingles&&isscalar(E)
	E=E{1};
end
end		% function GroupElements

function E=CombineTypes(E)
% care for different cases of fields?!
if ~iscell(E)
	return
end
if length(E)==1
	E=E{1};
	return
end
FN=cell(1,length(E));
FNall={};
for i=1:length(E)
	FN{i}=fieldnames(E{i});
	FNall=union(FNall,FN{i});
end
for i=1:length(E)
	fnNew=setdiff(FNall,FN{i});
	for j=1:length(fnNew)
		E{i}(1).(fnNew{j})=[];
	end
end
E=[E{:}];
end		% function CombineTypes

function [b,field]=isCIfield(S,field)
%isCIfield - Is field - Case Insensitive
b=isfield(S,field);
if ~b
	fn=fieldnames(S);
	B=strcmpi(field,fn);
	b=any(B);
	if b
		field=fn{B};
	end
end
end

function S=SetCIfield(S,field,val)
%SetCIfield - Set field - using case insensitivity (while still using case)
if ~isfield(S,field)
	fn=fieldnames(S);
	B=strcmpi(field,fn);
	if any(B)
		field=fn{B};
	end
end
S.(field)=val;
end

function val=GetCIfield(S,field)
%GetCIfield - Get field - using case insensitivity (while still using case)
if ~isfield(S,field)
	fn=fieldnames(S);
	B=strcmpi(field,fn);
	if any(B)
		field=fn{B};
	else
		error('Not existing field!')
	end
end
val=S.(field);
end
