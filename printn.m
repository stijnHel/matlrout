function printn(n)
% PRINTN print verschillende figuren naar printer.
%
%     n = getal   ------> alle figuren van 1 tot n worden geprint
%     n = matrix  ------> alle figuren aangegeven in de matrix worden geprint.
if ~exist('n');n=[];end
if isempty(n)
	n=gcf;
elseif length(n)==1
	n=1:n;
else
	n=sort(n(:));
	delN=find([0;~diff(n)]);
	n(delN)=[];
end
if strcmp(computer,'PCWIN')
	toFile='tttt.ps';
	dos(['del ' toFile '|']);
	fAppend=1;
else
	toFile=[];
	fAppend=[];
end
for I=1:length(n)
	print1(n(I),toFile,fAppend);
end
if strcmp(computer,'PCWIN')
	if isempty(find(toFile=='.'))
		ext='.ps';
	else
		ext='';
	end
	dos(['copy ' toFile ext ' lpt1&']);
end
