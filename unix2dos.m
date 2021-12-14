function unix2dos(f)
% UNIX2DOS - zet Unix-files om in DOS-files
if any(f=='?') | any(f=='*')
	d=dir(f);
	d(cat(1,d.isdir))=[];
	i=find(f==filesep);
	fl=strvcat(d.name);
	if isempty(i)
		f=fl;
	else
		f=[f(ones(length(d),1),1:i(end)) fl];
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
		j=find(tekst==13);
		isCRLF=tekst(min(end,j+1))==10;
		tekst(j(~isCRLF))=10;	% vervang enkele CRs naar LF
		tekst(j(isCRLF))='';	% verwijder CR's van CRLFs
		test=find(tekst<9);
		if ~isempty(test)
			tti=zeros(8,1);
			tti(tekst(test))=ones(1,length(test));
			fprintf('Ik verwijder ook ongekende tekens ! (');
			fprintf('%d ',find(tti));
			fprintf(')\n');
			tekst(test)='';
		end
		tekst=strrep(tekst, char(10), char([13 10]));
		if strcmp(computer,'PCWIN')
			d=find(fnaam=='.');
			if isempty(d)
				fnaambak=[fnaam '.bak'];
			else
				fnaambak=[fnaam(1:d) 'bak'];
			end
			dos(['del ' fnaambak '|']);
			dos(['ren ' fnaam ' ' fnaambak '|']);
		end
		fid=fopen(fnaam,'wb');
		if fid<3
			error('Kan file niet openen om te openen')
		end
		fwrite(fid, tekst, 'char');
		fclose(fid);
	end
end