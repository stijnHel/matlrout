function [C,Y]=hierstruct(Xin,delim)
% HIERSTRUCT - Structureer hierarchie
%   [C,Y]=hierstruct(X[,delim]);
%      (gemaakt voor X uit leesdcm voor het lezen van kalibratie-files)
%   als Y niet gegeven, wordt er een uitvoer in het command-window weergegeven

if ~exist('delim','var')|isempty(delim)
	delim='.';
end

% (?beter standaard met structs werken ipv char-array?)
if isstruct(Xin)
	if isfield(Xin,'naam')
		X=strvcat(Xin.naam);
	elseif isfield(Xin,'name')
		X=strvcat(Xin.name);
	else
		error('Onbekende struct')
	end
elseif iscell(Xin)
	X=strvcat(Xin);
else
	X=Xin;
end

C=cell(1,3);
C{1,1}='basis';
for i=1:size(X,1)
	n1=deblank(X(i,:));
	j=find(n1==delim);
	cstr=cell(length(j)+1,1);
	if isempty(j)
		cstr{1}=n1;
	else
		cstr{end}=n1(1:j(1)-1);
		for k=1:length(j)-1
			cstr{end-k}=n1(j(k)+1:j(k+1)-1);
		end
		cstr{1}=n1(j(end)+1:end);
	end
	istr=zeros(1,length(cstr));
	iC=1;
	nCs=C{iC,2};
	nC=C(nCs,1);
	for k=1:length(cstr)
		j=strmatch(cstr{k},nC,'exact');
		if isempty(j)
			%sss
			for j=k:length(cstr)
				C{end+1,1}=cstr{j};
				C{iC,2}(end+1)=size(C,1);
				iC=size(C,1);
				C{iC,3}=i;
			end
			break;
		end
		iC=nCs(j);
		C{iC,3}(end+1)=i;
		nCs=C{iC,2};
		nC=C(nCs,1);
	end
end

for i=1:size(C,1)
	iC=C{i,2};
	if ~isempty(iC)
		[sC,si]=sort(upper(C(iC,1)));
		C{i,2}=iC(si);
	end
end

if nargout>1|~isstruct(Xin)
	Y=makestruct(C,C{1,2});
elseif isfield(Xin,'value')&isfield(Xin,'type')
	printstructCal(C,C{1,2},'',Xin);
else
	printstruct(C,C{1,2},'');
end

function Y1=makestruct(C,i)
Y1=struct('name',C(i,1),'children',[],'items',C(i,3));
for j=1:length(i)
	if ~isempty(C{i(j),2})
		Y1(j).children=makestruct(C,C{i(j),2});
	end
end

function printstruct(C,i,s0)
sHierSpace='  ';
Y1=struct('name',C(i,1),'children',[],'items',C(i,3));
for j=1:length(i)
	fprintf('%s%-20s\t%3d\t%3d\n',s0,C{i(j),1},length(C{i(j),2}),length(C{i(j),3}))
	if ~isempty(C{i(j),2})
		printstruct(C,C{i(j),2},[s0 sHierSpace]);
	end
end

function printstructCal(C,i,s0,X)
sHierSpace='  ';
metVolgnummer=1;
metKalData=1;
metStringAlign=1;
Y1=struct('name',C(i,1),'children',[],'items',C(i,3));
for j=1:length(i)
	if isempty(C{i(j),2})
		if length(C{i(j),3})>1
			error('!!??Meerdere definities??')
		end
		if metVolgnummer
			fprintf('%3d: ',C{i(j),3});
		end
		if metKalData
			if metStringAlign
				fprintf('%-24s\t',[s0,C{i(j),1}])
			else
				fprintf('%s\t',[s0,C{i(j),1}])
			end
			X1=X(C{i(j),3});
			switch X1.type
			case '1D'
				fprintf('1D (%d)\n',length(X1.value))
			case '2D'
				fprintf('2D (%dx%d)\n',size(X1.value))
			case 'lijst'
				fprintf('lijst (%d)\n',length(X1.value))
			case 'param'
				if isnumeric(X1.value)
					fprintf('%g\n',X1.value);
				elseif ischar(X1.value)
					fprintf('%s\n',X1.value);
				else
					fprintf('??????\n');
				end
			otherwise
				error('Onbekend parameter-type')
			end
		else
			fprintf('%s%s\n',s0,C{i(j),1})
		end
	else
		if metVolgnummer
			fprintf('---  ');
		end
		fprintf('%s%s',s0,C{i(j),1})
		fprintf('\n',length(C{i(j),2}),length(C{i(j),3}))
		printstructCal(C,C{i(j),2},[s0 sHierSpace],X);
	end
end
