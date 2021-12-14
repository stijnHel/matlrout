function [l,I]=sort(lijst,veld,fun,varargin)
%struct/sort - Sorteer struct-arrays (!enkel voor struct-vectoren!)
% [l,i]=sort(lijst,veld)
% [l,i]=sort(lijst,veld,fun)
%          fun is een functie die op elk element uitgevoerd
%              wordt voor het sorteren
%          speciale waarden voor fun:
%             'sval' : sort(lijst,veld,'sval',<sscanf format>)
%                 gebruikt sscanf om data uit een string te halen

if ~isfield(lijst,veld)
	error('Sorteren op niet bestaand veld gaat niet')
end

l1=cell(length(lijst),1);
if exist('fun','var')&&~isempty(fun)
	if isa(fun,'function_handle')
		typefun=1;
	elseif ischar(fun)
		switch fun
			case 'sval'
				typefun=10;
			otherwise
				typefun=2;
		end
	else
		error('Onbekend soort functie')
	end
	for i=1:length(lijst)
		switch typefun
			case {1,2}
				l1{i}=feval(fun,getfield(lijst(i),veld),varargin{:});
			case 10
				l1{i}=sscanf(getfield(lijst(i),veld),varargin{1});
		end
	end
else
	for i=1:length(lijst)
		l1{i}=getfield(lijst(i),veld);
	end
end
isch=cellfun('isclass',l1,'char');
isemp=cellfun('isempty',l1);
if ~all(isch)
	if any(isch)
		if all((isch&isemp)|~isch)
			for i=find(isch(:)')
				l1{i}=0;
				isch(i)=false;
			end
			isemp=cellfun('isempty',l1);
		else
			error('niet geimplementeerde combinatie van data')
		end
	end
	if ~any(isch)
		nd=cellfun('prodofsize',l1);
		if any(nd~=1)
			error('Kan dit niet sorteren')
		end
	end
	%!!!!nog andere testen uitvoeren
	l=zeros(size(l1));
	for i=1:length(l1)	% Dit zou beter moeten kunnen
		l(i)=l1{i};
	end
	l1=l;
end
[~,i]=sort(l1);
l=lijst(i);
if nargout>1
	I=i;
end
