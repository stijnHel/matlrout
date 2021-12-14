function [rout,extern,fgevonden,fn]=beprout(fn)
% BEPROUT  - Bepaal de gepaste routine om de file te lezen.
%
%        rout=beprout(fn)
%  Mogelijke routines :
%          leescsv
%          leesdago
%          leeseven
%          (leeskont)
%          leeskopp
%          leeslphd
%          leesmdf
%          leesmusy
%          leessam
%  Uitgebreide routine :
%        [rout,extern,gevonden]=beprout(fn)
%        gevonden geeft aan of de file gevonden is :
%              0 : niet gevonden
%              1 : gevonden in "zetev-directory"
%              2 : gevonden in "working directory"
%  Als routine niet gevonden is, wordt gezocht naar andere lees-mogelijkheden :
%        rout is dan leeg
%        bij '.txt'-files                   : ['dos';'notepad']
%        bij '.m'-,'.mdl'-files : is extern : 'matlab'
%        bij '.mat'-files                   : ['matlab';'load']

bZetEvDir=true;	%!toch niet gebruikt!!
i=find(fn=='.');
if isempty(i)
	ext='';
	f=fn;
	if ~exist(fn,'file')&&~exist(zetev([],fn),'file')
		d=dir([zetev fn '.*']);
		if isempty(d)
			d=dir([fn '.*']);
			if ~isempty(d)
				bZetEvDir=false;
			end
		end
		if ~isempty(d)
			if length(d)>1
				warning('BEPROUT:NotFound','File niet gevonden, maar wel meerdere met extensie.')
			else
				fn=d.name;
				i=find(fn=='.');
				ext=upper(fn(i(1)+1:length(fn)));
			end
		end
	end	% file bestaat
else	% met extensie
	f=fn(1:i(end)-1);
	ext=upper(fn(i(end)+1:length(fn)));
end
f=[f char(zeros(1,4))];	% toevoegen sentinels

fgevonden=0;
ffn=[zetev fn];
eFile=exist(ffn,'file');
if eFile==0
	ffn=fn;
	eFile=exist(ffn,'file');
	if eFile
		fgevonden=2;
	end
else
	fgevonden=1;
end
if eFile==7
	fgevonden=-fgevonden;
end

x='';
if fgevonden>0
	fid=fopen(ffn,'r');
	if fid>2
		x=fread(fid,4,'char');
		fclose(fid);
	else
		fid=fopen(fn,'r');
		if fid>2
			x=fread(fid,4,'char');
			fclose(fid);
		end
	end
	x=x(:)';
	if length(x)<4
		x(4)=0;
	end
	x=char(x);
end

rout='';
if nargout>1
	extern='';
end
if fgevonden<0
	d=dir([ffn filesep 'TDS*']);
	if ~isempty(d)
		rout='leestekdir';
	end
elseif strcmp(x,'|CF,') || (~fgevonden&&(strcmp(ext,'DAT')) || strcmp(ext,'RAW'))
	rout='leesmusy';
elseif strcmp(x,'MDF ')
	rout='leesmdf';
elseif strcmp(x,'DTLG')
	rout='leesnlph';
elseif strcmp(x,'DIAE')
	rout='leesdago';
elseif strcmp(ext,'CSV')
	rout='leescsv';
elseif strcmp(ext,'TDM')
	rout='leesTDM';
elseif strcmp(ext,'TDMS')
	rout=@leesTDMS;
	%rout='leesTDMS';
elseif strcmp(ext,'XML')
	rout='leesFMTClvXMLmeas';
elseif strcmp(ext,'MES')||strcmp(ext,'MEC')||strcmp(ext,'MED')
	rout='leessam';
elseif strcmp(x,'LabV')
	rout='leeslvtxt';
elseif strcmp(ext,'TXT')&&strcmpi(x,'SAMP')
	rout='leeslvsvdp';
elseif nargout>1
	if strcmp(ext,'M')||strcmp(ext,'MDL')
		extern='matlab';
	elseif strcmp(ext,'MAT')
		extern=addstr('matlab','load');
	elseif strcmp(ext,'TXT')
		extern=addstr('dos','notepad');
	end
end
