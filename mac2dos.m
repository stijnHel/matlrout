function mac2dos(f,maakbak)
% MAC2UNIX - zet Mac-files om in unix-files
%   mac2dos(f,maakbak)
if ~exist('maakbak')|isempty(maakbak)
	maakbak=0;
end
if any(f=='?') | any(f=='*')
   dd=dir(f);
   ddd=f;
   f='';
   for i=1:length(dd)
      if ~dd(i).isdir
         f=strvcat(f,dd(i).name);
      end
   end
end

for i=1:size(f,1)
	fnaam=deblank(f(i,:));
	fprintf('converteren van "%s"\n',fnaam);
	fid=fopen(fnaam,'rb');
	if fid==-1
		fprintf('"%s" kon niet geopend worden.\n',fnaam);
	else
		tekst=setstr(fread(fid,'char')');
		fclose(fid);
		nLF=sum(tekst==10);
		nCR=sum(tekst==13);
		if nLF>nCR
			if nCR==0
				warning('Dit lijkt geen mac-tekst maar een unix tekst te zijn!  De conversie zal juist gebeuren.')
			else
				warning('Dit lijkt geen mac-tekst maar eerder een unix tekst te zijn, maar bevat toch CR''s!!??')
			end
			tekst=strrep(tekst,char([13 10]),char(13));
			tekst(tekst==10)=13;
		elseif nLF==nCR
			warning('!Dit lijkt eerder een DOS-tekst te zijn!')
		elseif nLF
			warning('!!!teksten met gemengde LF/CR worden niet noodzakelijk goed geconverteerd!!!')
		end
		tekst(find(tekst==setstr(10)))='';	% verwijder LF's
		test=find(tekst<9);
		if ~isempty(test)
			fprintf('Ik verwijder ook ongekende tekens ! (');
			fprintf('%d ',abs(unique(tekst(test))));
			fprintf(')\n');
			tekst(test)='';
		end
		tekst=strrep(tekst, setstr(13), setstr([13 10]));
		if maakbak&strcmp(computer,'PCWIN')
			fnaambak=[fnaam '.bak'];
			if exist(fnaambak)
				dos(['del ' fnaambak '|']);
			end
			dos(['ren ' fnaam ' ' fnaambak '|']);
		end
		fid=fopen(fnaam,'wb');
		if fid<3
			error('Kan file niet openen om te schrijven -- Is het een schrijf-beveiligde file?')
		end
		fwrite(fid, tekst, 'char');
		fclose(fid);
	end
end