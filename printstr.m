function printstr(x1,x2,varargin)
% print strings van string-matrix samen met een nummering
%    printstr({string list})
%    printstr([string array])
%    printstr(<string format>,<list>)
%    printstr(<string format>,<list>,<format2>,<data2>,...)
%       can be extended with options
%           printstr(...,'options','opt-name1','opt-val',...)
%           printstr(...,{options})
%           printstr(...,'-opt1') or printstr(...,'--opt1')
%  <string format> is the format "given" to fprintf to print the string.
%     default is '%s'
%       possible use is right alignment, e.g. '%30s'
%     second data is meant to be numerical data
%
%  example:
%     printstr('%-5s',{'abc','d'},' : %4d',[123 321])
%          gives
%                 1 : abc   :  123
%                 2 : d     :  321
%
% extra:
%     printstr(<struct-array>) - select fields with strings
%             printstr(<struct>,{<fields>}[,options])
%                             options: bScalars, fn, discard
%     generic options: bPrintNumbers

% option to limit number of characters?

nArgIn = nargin;	% to be able to change it...
vargs = varargin;
if isenum(x1) && isscalar(x1) && nArgIn==1
	[e,en] = enumeration(x1);
	x1 = '%s';
	x2 = en;
	vMax = max(abs(double(e)));
	nDig = ceil(log10(max(2,vMax)))+1;
	vargs = {sprintf('%%%dd',nDig),e};
	nArgIn = 4;
end

[bPrintNumbers] = true;
[nrOffset] = 0;
if nArgIn==0
	error('Minstens 1 input !')
elseif isstruct(x1)
	if isempty(x1)
		return
	end
	fn=fieldnames(x1);
	bScalars=false;
	discard=[];	% fieldnames to be printed
	if nArgIn>1
		opts={};
		if iscell(x2)
			fn=x2;
			if nArgIn>3
				opts=vargs;
			elseif nArgIn>2
				opts=vargs;
				if isscalar(opts)&&iscell(opts{1})
					opts=opts{1};
				end
			end
		elseif nArgIn>2
			opts=[{x2},vargs];
		else
			opts={x2};
		end
		if ~isempty(opts)
			setoptions({'bScalars','fn','discard','bPrintNumbers','nrOffset'},opts{:})
		end
	end
	if ~isempty(discard)
		if ischar(discard)
			discard={discard};
		end
		%fn=setdiff(fn,discard);	% not used to keep order
		[~,idx]=intersect(fn,discard);
		if ~isempty(idx)
			fn(idx)=[];
		end
	end
	iFields=zeros(1,length(fn));
	for i=1:length(fn)
		fi=x1(1).(fn{i});
		if ischar(fi)
			Bchar=cellfun(@ischar,{x1.(fn{i})});
			if ~all(Bchar)
				Bempty=cellfun('length',{x1.(fn{i})})==0;
				if all(Bchar|Bempty)
					for k=1:length(Bchar)
						if ~Bchar(k)
							x1(k).(fn{i})='';
						end
					end
					Bchar=true;
				end
			end
			if all(Bchar)
				iFields(i)=max(cellfun('length',{x1.(fn{i})}));
			end
		elseif bScalars&&(isnumeric(fi)||islogical(fi))&&isscalar(fi)
			if all(cellfun('length',{x1.(fn{i})})==1)
				iFields(i)=-10;
			end
		end
	end
	if ~any(iFields)
		fprintf('No fields to show.\n')
		return
	end
	X=cell(2,sum(iFields>0));
	j=0;
	fprintf('      ');
	for i=1:length(fn)
		if iFields(i)
			j=j+1;
			if iFields(i)>0
				X{1,j}=sprintf('%%-%ds',iFields(i)+1);
				fprintf(X{1,j},CleanUpString(fn{i})) %#ok<PRTCAL>
			else
				X{1,j}=sprintf('%%%dg',1-iFields(i));
				fprintf(sprintf('%%-%ds',1-iFields(i)),CleanUpString(fn{i})) %#ok<PRTCAL>
			end
			X{2,j}={x1.(fn{i})};
			fprintf(' ')
		end
	end
	fprintf('\n')
	F=X(1,:);
	D=X(2,:);
elseif isa(x1,'Simulink.SimulationData.Dataset')
	fprintf('Simulink dataset: (blockPath & name)\n')
	C = cell(x1.numElements,2);
	for i = 1:x1.numElements
		C{i} = x1{i}.BlockPath.getBlock(1);
		C{i,2} = x1{i}.Name;
	end
	if nArgIn==1
		options = {};
	else
		options = [{x2},vargs];
	end
	printstr(C,options{:})
	return
elseif nArgIn==1
	F={'%s'};
	if min(size(x1))>1
		F=F(1,ones(1,size(x1,2)));
		D=mat2cell(x1,size(x1,1),ones(1,size(x1,2)));
	else
		D={x1};
	end
else
	nArg = length(vargs);
	n = 0;
	opts = {};
	while n+2<=nArg
		if ischar(vargs{n+1})
			if strcmpi(vargs{n+1},'options')
				opts = vargs(n+2:end);
				break
			end
		else
			error('Wrong inputs')
		end
		n = n+2;
	end
	if isempty(opts) && nArg==n+1
		if iscell(vargs{nArg}) || ischar(vargs{nArg})
			opts = vargs(nArg);
		else
			error('Wrong inputs')
		end
	end
	if ~isempty(opts)
		setoptions({'bPrintNumbers','nrOffset'},opts{:})
	end
	F={x1,vargs{1:2:n}};
	D={x2,vargs{2:2:n}};
	for i=1:length(F)
		if (size(D{i},1)==1)&&(size(D{i},2)>1)
			D{i}=D{i}';
		end
		if i==1
			n=size(D{i},1);
		elseif size(D{i},1)~=n
			error('Different lists must have equal number of elements!')
		end
	end
end

for i=1:length(F)
	if strcmp(F{i},'%s')	% find length
		if isdatetime(D{i})
			D{i} = string(D{i});
		end
		if iscell(D{i}) || isa(D{i},'string')
			Ns=cellfun('length',D{i});
			n=max(Ns);
		else
			n=find(any(D{i}>0),1,'last');
			if isempty(n)	% all empty!
				n=1;
			end
		end
		F{i}=sprintf('%%-%ds',n);
	end		% simple string
end		% for i (all string-lists)
if iscell(D{1})
	nD=length(D{1});
else
	nD=size(D{1},1);
end
for i=1:nD
	if bPrintNumbers
		fprintf('%3d :',i+nrOffset);
	end
	for j=1:length(F)
		if iscell(D{j})
			fprintf([' ' F{j}],CleanUpString(D{j}{i}));
		else
			fprintf([' ' F{j}],CleanUpString(D{j}(i,:)));
		end
	end
	fprintf('\n')
end

function s = CleanUpString(s)
if ischar(s)
	if any(s==10)
		s(s==10) = ' ';
	end
	% other changes? (codes 0..31, ...)
	%		(see printhex?)
end
