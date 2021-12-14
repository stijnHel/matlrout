function mac2unix(f,alle)
% MAC2UNIX - zet Mac-files om in unix-files
if ~exist('alle');alle=[];end
if isempty(alle)
	alle=0;
end
if alle

end

for i=1:size(f,1)
	fnaam=deblank(f(i,:));
	fid=fopen(fnaam,'rb');
	if fid==-1
		fprintf('"%s" kon niet geopend worden.\n',fnaam);
	else
		tekst=char(fread(fid,'char')');
		fclose(fid);
		i=find(tekst(1:end-1)==13&tekst(2:end)==10);
		if ~isempty(i)
			tekst(i+1)='';
		end
		tekst(tekst==13)=char(10);
		%tekst=strrep(tekst, 13, 10);
		d=find(fnaam=='.');
		if isempty(d)
			fnaambak=[fnaam '.bak'];
		else
			fnaambak=[fnaam(1:d) 'bak'];
		end
		if strcmp(computer,'PCWIN')
			dos(['del ' fnaambak '|']);
			dos(['ren ' fnaam ' ' fnaambak '|']);
		elseif isunix
			dos(['rm ' fnaambak]);
			dos(['mv ' fnaam ' ' fnaambak]);
		else
			warning('onbekend besturingsysteem - geen backup gemaakt')
		end
		fid=fopen(fnaam,'w');
		fwrite(fid, tekst, 'char');
		fclose(fid);
		end
	end
end