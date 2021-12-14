function [soorten,indices,infonamen,infos]=leesini(f)
% LEESINI  - Leest standaard ini-file
%    [soorten,indices,infonamen,infos]=leesini(f)

indices=[];
infonamen='';
infos='';
fid=fopen(f,'r');
if fid<=0
	soorten=0;
	return
end
soorten='';

while 1
	lijn=fgetl(fid);
	if ~isstr(lijn)
		break;
	end
	lijn=deblank(lijn);
	if ~isempty(lijn)
		if lijn(1)==';'
			% commentaarlijn, deze wordt niet bekeken
		elseif lijn(1)=='['
			lijn=lijn(2:length(lijn)-1);
			if isempty(lijn)
				fprintf('!!!!!Er komt een "lege soort" voor !!!!!\n')
				lijn=char(0);
			end
			i=fstrmat(soorten,lijn);
			if ~isempty(i)
				fprintf('!"%s\n" komt meerdere keren voor',lijn)
			end
			soorten=addstr(soorten,lijn);
			indices(length(indices)+1)=size(infonamen,1)+1;
		else	% niet beginnend met '[' of ';'
			i=find(lijn=='=');
			if isempty(i)
				fprintf('Bij %s een lijn zonder "=" : %s\n',soorten(size(soorten,1),:),lijn)
				infonaam=lijn;
				info=char(0);
			else
				if length(i)>1
					fprintf('Meerdere "="''s : %s\n',lijn)
				end
				infonaam=lijn(1:i(1)-1);
				info=lijn(i(1)+1:length(lijn));
				if isempty(info)
					info=char(0);
				end
			end
			infonamen=addstr(infonamen,infonaam);
			infos=addstr(infos,info);
		end
	end
end
fclose(fid);
indices(length(indices)+1)=size(infonamen,1)+1;
