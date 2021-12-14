function komb(f,ftot,recurs,fdir)
% KOMB     - Kombineer files
%     komb(<directory>[,fnaar[,recurs[,fdir]]])
%           fnaar : file (of fid) waar samengebrachte files naartoe gestuurd worden
%                 indien niet gegeven : fffffm.txt (in huidige directory)
%                 (files worden gesorteerd op naam)
%           recurs : als 1 (verschillend van nul) worden directories gelezen.
%           (voor fdir zie verder)
%     komb(<filelist>[,fnaar,[recurs[,fdir]]])
%             filelist is een struct-vector met files
%                                     naam van file in 'name'-field
%                                     isdir geeft aan of het een directory is
%                 (dit kan een output zijn van dir)
%             fdir : directory waar files gelezen worden
%
%  (!! komb('*.txt') bijvoorbeeld werkt niet omdat '*.txt' gebruikt wordt als directory !!)
%      komb('*.txt',[],'') werkt wel
%  (!! het is ook (nog) niet mogelijk om filetype-selectie te kombineren met recursieve bewerking!!)


if ~exist('recurs')|isempty(recurs)
	recurs=0;
end
if ~exist('fdir')
	if ischar(f)
		fdir=f;
		if fdir(end)~=filesep
			fdir(end+1)=filesep;
		end
	else
		fdir='';
	end
elseif ~isempty(fdir)
	if fdir(end)~=filesep
		fdir(end+1)=filesep;
	end
end

if isstruct(f)
	l=f;
else
	l=dir(f);
	while l(1).name(1)=='.'
		l(1)=[];
	end
	l=sort(l,'name');
end

if ~exist('ftot')|isempty(ftot)
	ftot='fffffm.txt';
end
if ischar(ftot)
	fid=fopen(ftot,'wt');
	if fid<3
		error('Kon file niet openen om gegevens naartoe te sturen')
	end
else
	fid=ftot;
end
for i=1:length(l)
	if l(i).isdir
		if recurs
			d=[fdir l(i).name];
			fprintf(fid,'----------directory %s--------------\n',d);
			komb(d,fid,1,d);
			fprintf(fid,'-------einde directory %s--------\n',d);
		end
	else
		ff=fopen([fdir l(i).name],'rt');
		if ff<3
			fprintf('file "%s" kon niet geopend worden\n',l(i).name);
		else
			x=fread(ff);
			fclose(ff);
			fprintf(fid,'----------------- start %15s-(%s)---------------\n',l(i).name,fdir);
			fwrite(fid,x);
			fprintf(fid,'------------------ eind %15s-(%s)---------------\n',l(i).name,fdir);
		end
	end
end
if ischar(ftot)
	fclose(fid);
end
