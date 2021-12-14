function [Dfound,nFound]=FindHierField(D,fldChildren,testFcn,nMax,varargin)
%FindHierField - Find elements in an hierarchical struct-structure
%   Dfound=FindHierField(D,fldChildren,testFcn[,nMax])
%       D           : a struct-vector, with children with similar fields
%       fldChildren : field to look to children
%       testFcn     : function handle working on a struct-element
%                     if returning true (or nonzero), the element is selected
%                     simplified use:
%                        * fieldname: if fieldname exist, struct is returned
%                        * {fieldname,value}:
%                             with value: string or numeric (isequal is used)
%                        * {@function,fieldname[,value]}
%       nMax        : if >0 ==> maximum number of selected elements
%                     else all elements are searched
%
%   elements are combined to a struct-vector if possible, otherwise
%     they are combined in cell-vectors
%  In Dfound, an extra field is added as a link to the field in the
%  original structure.
%
%  Options:
%      testValFcn: function used to test if a field is "what you want".
%
%  Example:
%      Xselect=FindHierField(X,[],{@regexp,'Name','Length'});
%           searched for all structures with existing field "Name" and its
%              value contains the word "Length".
%           remark: it is supposed that the fieldrecords "Name" always are
%                  strings!  If not you need additional test, for example:
%              Xselect=FindHierField(X,[],{@(s,a) ischar(s)&&~isempty(regexp(s,a)),'Name','Length'});
%      Xselect=FindHierField(X,[],[],'testval',@(x) isa(x,'timeseries'))
%           returns all timeseries somewhere "hidden" in X

% Deze functie is niet meer helemaal OK, lijkt het!  Aanpassingen zijn
% gebeurd, maar er lijkt functionaliteit ontdubbeld te zijn?!
%         verwarring over testen op veldnaam en veldwaarde

Dfound=[];
bOnlyChildIfSelected=false;
options=varargin;
testValFcn=[];
Sref=[];
if nargin>3
	if ischar(nMax)
		options=[{nMax} options];
		nMax=0;
	else
		if isstruct(varargin{1})
			Sref=varargin{1};
			options=varargin(2:end);
		end
	end
else
	nMax=0;
end
if ~isempty(options)
	setoptions({'bOnlyChildIfSelected','testValFcn'},options{:})
end

nFound=0;
bStruct=true;
fldChildren0=fldChildren;
if isempty(fldChildren)
	fldChildren=fieldnames(D);
elseif ischar(fldChildren)
	fldChildren={fldChildren};
end
for i=1:length(D)
	if isa(testFcn,'function_handle')
		b=testFcn(D(i));
	elseif ischar(testFcn)
		if any(testFcn=='*')
			iW=find(testFcn=='*');
			if length(iW)>1||iW<length(testFcn)
				error('Sorry, only simple wildcards are implemented ("<string>*")')
			end
			fn=fieldnames(D);
			b=any(strncmpi(testFcn,fn,iW-1));
		else
			b=isfield(D,testFcn);
		end
	elseif iscell(testFcn)
		if isscalar(testFcn)
			b=isfield(D,testFcn{1});
		elseif ischar(testFcn{1})
			b=isfield(D,testFcn{1});
			if b
				v=D(i).(testFcn{1});
				vr=testFcn{2};
				if ischar(vr)
					if ~ischar(v)
						b=false;
					elseif vr(end)=='*'
						b=strncmp(v,vr,length(vr)-1);
					else
						b=isequal(v,vr);
					end
				elseif isnumeric(vr)
					b=isequal(v,vr);
				else
					error('Wrong use of this function (cell(2) must be for strings or numerics!')
				end
			end
		elseif length(testFcn)<=3
			b=isfield(D,testFcn{2});
			if b
				v=testFcn{1}(D(i).(testFcn{2}),testFcn{3:end});
				if ischar(v)||iscell(v)
					b=~isempty(v);
				else
					b=any(v);
				end
			end
		else
			error('Wrong use of testFcn (cell: length 2 or three)!')
		end
	elseif isempty(testFcn)	%(!!)
		b=false;
	else
		error('Wrong use of testFcn (must be function_handle or cell)!')
	end
	if b
		Di=D(i);
		Srefi=struct('type','()','subs',{{i}});	% also when isscalar(D)
		if ~isempty(Sref)
			Srefi=[Sref Srefi]; %#ok<AGROW>
		end
		Di.refToOrig=Srefi;
		AddFoundData(Di);
		nFound=nFound+1;
		if nMax>0&&nFound>=nMax
			break
		end
		bCheckChild=true;
	else
		bCheckChild=~bOnlyChildIfSelected;
	end
	if bCheckChild
		for iField=1:length(fldChildren)
			fldChil_i=fldChildren{iField};
			if isfield(D,fldChil_i)
				b=false;
				fldChild=D(i).(fldChil_i);
				if ~isempty(testValFcn)&&testValFcn(fldChild)
					b=true;
					Df1=fldChild;
					nF1=1;
				elseif isstruct(fldChild)
					Srefi=struct('type',{'()','.'},'subs',{{i},fldChil_i});
					if ~isempty(Sref)
						Srefi=[Sref,Srefi]; %#ok<AGROW>
					end
					[Df1,nF1]=FindHierField(fldChild,fldChildren0	...
						,testFcn,nMax-nFound,Srefi	...
						,'bOnlyChildIfSelected',bOnlyChildIfSelected	...
						,'testValFcn',testValFcn	...
						);
					b=nF1>0;
				end
				if b
					AddFoundData(Df1);
					nFound=nFound+nF1;
				end
			end		% isfield
		end		% for iField
	end		% if bCheckChild
end		% for i

	function AddFoundData(Df)
		if isempty(Dfound)
			Dfound=Df;
		elseif bStruct
			try
				Dfound=[Dfound Df];
			catch
				Dfound={Dfound,Df};
				bStruct=false;
			end
		else
			Dfound{1,end+1}=Df;
		end
	end

end
