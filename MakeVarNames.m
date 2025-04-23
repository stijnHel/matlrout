function N=MakeVarNames(N,bAvoidDoubles,maxLen)
%MakeVarNames - Make names that can be used as variable name
%    N=MakeVarNames(N,bAvoidDoubles,maxLen)
%           N: char (one name) or cell-vector (multiple names)
%           bAvoidDoubles: default true, avoid doubles
%                doubles are extended with '_'
%           maxLen: maximum length
%
% only made for simple cases(!)

persistent repC bRepC

if nargin<2||isempty(bAvoidDoubles)
	bAvoidDoubles=true;
end
if nargin<3 || isempty(maxLen)
	maxLen = 250;
end

defName='x';
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

if ischar(N)
	N = strtrim(N);
	B=N==13|N==10;
	if any(B)
		N(B)='_';
	end
	if length(N)>maxLen
		N = N(1:maxLen);	% just truncate - nothing more usefull(!)
	end
	if isempty(N)
		N=defName;
	else
		if any(N==0)
			warning('LVDATA2STRUCT:ZeroInString','Zero-value in string?!')
			N(N==0)='a';
		end
		if any(abs(N)>255)
			N(abs(N)>255) = 'a';	%!!!!!
		end
		if any(bRepC(abs(N)))
			for ii=1:size(repC,1)
				N(N==repC(ii))=repC(ii,2);
			end
		end
	end
	if (N(1)>='0'&&N(1)<='9')||N(1)=='_'
		N=['a' N];
	end
else
	for i=1:length(N)
		N{i}=MakeVarNames(N{i},bAvoidDoubles,maxLen);
	end
	[~,i,j]=unique(N);
	if bAvoidDoubles&&length(i)<length(j)
		% there are "doubles"
		%    add '_' behind doubles
		%    this is not completely safe(!)
		%         (if 'a_' and twice 'a' exist, this will result in twice 'a_'!)
		for ii=1:length(i)
			b=j==ii;
			if sum(b)>1
				n=0;
				for jj=1:length(b)
					if b(jj)
						n=n+1;
						if n>1
							N{jj}(end+1:end+n-1)='_';
						end
					end
				end
			end
		end
	end
end
