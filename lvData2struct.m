function [D,bDefault]=lvData2struct(d,varargin)
%lvData2struct - labView-data to structure
%    D=lvData2struct(d)
%
% made to convert the result of readLVtypeString to a structure
% only made for simple cases(!)
%
% This function is being extended to handle arrays/vectors of data,
% combining multiple items - this is not ready
%    current "issue": some vectors don't contain all elements between 0 and
%        <n-1> - what to do with this (like in DAQmx scaling data)

%!!!!see also MakeVarNames

persistent repC bRepC

bCreateArr=true;
if nargin>1
	setoptions({'bCreateArr'},varargin{:})
end

defName='x';
nDefs=0;
if isempty(repC)
	repC=[' _';
		'._';
		'(_';
		')_';
		'{_';
		'}_';
		'[_';
		']_';
		'/_';
		'*_';
		'-_';
		'+_';
		',_';
		'"_';
		'''_';
		'\_';
		'|_';
		'&_';
		'#_';
		'%_';
		'~_';
		'^_';
		'`_';
		'@_';
		';_';
		':_';
		'?_';
		'<_';
		'>_'];
	bRepC=false(1,255);
	bRepC(abs(repC(:,1)))=true;
end

if isstruct(d)&&isfield(d,'Name')&&isfield(d,'data')
	d={d.data;d.Name}';	
end

bDefault=false(1,size(d,1));
i=0;
nd=size(d,1);
while i<nd
	i=i+1;
	n=d{i,2};
	if isempty(n)
		nDefs=nDefs+1;
		n=[defName num2str(nDefs)];
		bDefault(i)=true;
	elseif any(n==0)
		warning('LVDATA2STRUCT:ZeroInString','Zero-value in string?!')
		n(n==0)='a';
	elseif any(bRepC(abs(n)))
		if bCreateArr
			B=n(1:end-1)=='['&n(2:end)~=']';
			if any(B)
				% find all elements (assuming that al elements belonging to
				% this vector are put together(!))
				jB=find(B,1);
				i1=i;
				while i<nd&&strncmp(n,d{i+1,2},jB)
					i=i+1;
				end
				idx=zeros(1,i-i1+1);
				bArray=false;
				bSimple=false;
				bCancel = false;	% no array of true
				bCell=false;
				n=n(1:jB-1);
				if isempty(n)
					n='ARR';
				end
				for j=i1:i
					kB=jB+1;
					n1=d{j,2};
					while n1(kB)~=']'
						kB=kB+1;	% assume there will be a ']'(!)
					end
					if j==i1	% first element
						bCell=~isnumeric(d{i1})||~isscalar(d{i1});
							% assuming all elements having the same type!
							% this is only valid in "simple" case
						if kB==length(n1)	% simple vector
							bSimple=true;
						elseif n1(kB+1)=='['	% array
							bArray=true;
							lB=kB+2;
							while n1(lB)~=']'
								lB=lB+1;
							end
							if lB==length(n1)	% simple array
								bSimple=true;
							elseif n1(lB+1)~='_'
								error('Unexpected property! (%s)',n1)
							else
								d{j,2}=d{j,2}(lB+2:end);
							end
							idx(2,1)=sscanf(n1(kB+2:lB-1),'%d',1);
						elseif n1(kB+1)~='_'	% something else than a struct-vector
							error('Unexpected property! (%s)',n1)
						else
							d{j,2}=d{j,2}(kB+2:end);
						end
					elseif bArray
						lB=kB+2;
						while n1(lB)~=']'
							lB=lB+1;
						end
						idx(2,j-i1+1)=sscanf(n1(kB+2:lB-1),'%d',1);
						if ~bSimple
							d{j,2}=d{j,2}(lB+2:end);
						end
					elseif ~bSimple
						d{j,2}=d{j,2}(kB+2:end);
					end
					sSize = n1(jB+1:kB-1);
					if all((sSize>='0'&sSize<='9') | sSize==' ')
						idx(1,j-i1+1)=sscanf(sSize,'%d',1);
					else
						bCancel = true;
						break
					end
				end		% for j
				if bCancel
					% do nothing
				elseif bSimple
					if bCell
						if bArray
							P=cell(max(idx(1,:)+1),max(idx(2,:))+1);
							for j=i1:i
								P{idx(1,j-i1+1),idx(2,j-i1+1)}=d{j};
							end
						else
							P=cell(1,max(idx)+1);
							P(idx+1)=d(i1:i);
						end
					elseif bArray
						P=zeros(max(idx(1,:)+1),max(idx(2,:))+1);
						for j=i1:i
							P(idx(1,j-i1+1),idx(2,j-i1+1))=d{j};
						end
					else
						P=zeros(1,max(idx)+1);
						P(idx+1)=[d{i1:i}];
					end
				elseif bArray
					error('Not implemented (yet)!!!!')
					P=lvData2struct(d(i1:i,:));
				else
					P=cell(1,max(idx)+1);
					for j=1:length(P)
						ii=find(idx==j-1);
						if ~isempty(ii)
							P{j}=lvData2struct(d(i1-1+ii,:));
						end
					end		% for j
				end		% not simple
				if ~bCancel
					d{i1}=P;
					if i>i1
						d(i1+1:i,:)=[];
						i=i1;
						nd=size(d,1);
					end
				end
			end		% if any '['
		end		% if bCreateArr
		for ii=1:size(repC,1)
			n(n==repC(ii))=repC(ii,2);
		end
	end
	if (n(1)>='0'&&n(1)<='9')||n(1)=='_'
		n=['a' n];
	end
	if i>1
		while any(strcmp(n,d(1:i-1,2)))	% avoid doubles
			n(1,end+1)='_'; %#ok<AGROW>
		end
	end
	d{i,2}=n;
	if iscell(d{i})	% maybe not possible anymore
		d{i,1}=d(i);	% to prevent making of a structure array
	end
end

d=d(:,[2 1])';
D=struct(d{:});
