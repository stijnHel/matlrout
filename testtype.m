function [t,u2]=testtype(f,extra)
% TESTTYPE - Test type van tekstfile
%   [t,u2]=testtype(f,extra)
%              extra=1  ===> recursief voor directories
%   types :
%        1 : DOS
%        2 : Macintosh
%        3 : Unix
%     -100 : onbekend (er komt geen CR of LF in voor)
%       -2 : onbekend (evenveel CR's als LF's, maar niet correct op elkaar volgend)
%       -3 : onbekend (ongelijk aantal CR's als LF's)

switch exist(f)
	case 0
		e=0;
	case 2
		e=typetekstfile(f);
	case 7
		d=dir(f);
		d(1:2)=[];
		e=struct('naam',cell(length(d),1),'type',[]);
		for i=1:length(d)
			e(i).naam=[f filesep d(i).name];
			if d(i).isdir
				if exist('extra')&~isempty(extra)&extra
					e(i).type=testtype(e(i).naam,1);
				end
			else
				e(i).type=typetekstfile(e(i).naam);
			end
		end
	otherwise
		d=-1;
end

if nargout==0
	if isstruct(e)
		toontypes(e);
	else
		switch e
			case 1
				fprintf('DOS\n');
			case 2
				fprintf('Macintosh\n');
			case 3
				fprintf('Unix\n');
			otherwise
				fprintf('Onbekend (%d)\n',e)
		end
	end
elseif nargout==1
	t=e;
else
	
end

function t=typetekstfile(f)
fid=fopen(f,'r');
if fid<3
	error(['Kon file "',f,'" niet openen'])
end
x=fread(fid);
fclose(fid);
if isempty(x)
	t=-3;
	return
end
iCR=find(x==setstr(13));
iLF=find(x==setstr(10));
if isempty(iCR)
	if isempty(iLF)
		t=-100;
	else
		t=3;	% unix
	end
elseif isempty(iLF)
	t=2;
elseif length(iCR)==length(iLF)
	if all(iCR+1==iLF)
		t=1;
	else
		t=-2;
	end
else
	t=-3;
end

function toontypes(e)
for i=1:length(e)
	if isstruct(e(i).type)
		fprintf('----------Directory "%s" :\n',e(i).naam)
		toontypes(e(i).type)
		fprintf('----%s-----\n',e(i).naam)
	else
		fprintf('%-40s : %d\n',e(i).naam,e(i).type)
	end
end
