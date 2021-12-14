function [varargout]=sscanfMulti(s,spec,varargin)
%sscanfMulti - sscanf - multiple outputs

bRepeat=false;
bEndMulti=false;

if ~isempty(varargin)
	setoptions({'bRepeat','bEndMulti'},varargin{:})
	if bRepeat&&bEndMulti
		error('repeating and multiple end options are not compatible| (select only one)')
	end
end

varargout=cell(1,nargout);

ii=find(spec=='%');
if ~isempty(ii)
	i=1;
	while i<length(ii)
		if ii(i)+1==ii(i+1)
			ii(i:i+1)=[];	% "%%" is no data-field
		else
			i=i+1;
		end
	end
	if ii(end)==length(spec)
		if ii(end)==1
			error('Bare "%" at the end?!')
		end
	end
end
if isempty(ii)
	warning('Nothing to extract?!')
	return
end
if nargout<length(ii)
	warning('less outputs than specified?!')
	varargout=cell(1,length(ii));
elseif nargout>length(ii)
	warning('More outputs requested than specified! Blank outputs supplied')
end
% find end
jj=ii;
for i=1:length(ii)
	j=ii(i)+1;
	while lower(spec(j))<'a'||lower(spec(j))>'z'
		j=j+1;
		if j>length(spec)||spec(j)=='%'	% add only allowable characters?
			error('Error in spec (#%d)',i)
		end
	end
	jj(i)=j;
	if spec(j)=='s'&&bRepeat
		varargout{i}={};
	end
end
bLoop=true;
nLoop=0;
iSpec=1;
while bLoop
	nLoop=nLoop+1;
	for i=1:length(ii)
		if i==length(ii)&&bEndMulti
			if spec(jj(i))=='s'
				while ~isempty(s)
					[x,n,~,iN]=sscanf(s,spec(iSpec:jj(i)),1);
					if n
						varargout{i}{1,end+1}=x;
						s=s(iN:end);
					end
				end
				break
			else
				[x,n,err,iN]=sscanf(s,spec(iSpec:jj(i)),[1 Inf]);
			end
		else
			[x,n,err,iN]=sscanf(s,spec(iSpec:jj(i)),1);
		end
		if n==0
			if nLoop==1
				warning('Extracting data stopped after %d elements ("%s")',i-1,err)
			elseif i>1
				warning('Extracting stopped within a set?!')
			end
			break
		end
		iSpec=jj(i)+1;
		if iscell(varargout{i})
			varargout{i}{1,end+1}=x;
		elseif isscalar(x)&&isnumeric(x)
			varargout{i}(1,end+1)=x;
		else
			varargout{i}=x;
		end
		s=s(iN:end);
	end		% for i
	if bRepeat&&~isempty(s)
		bLoop=true;
		iSpec=1;
	else
		bLoop=false;
	end
end		% while bLoop
