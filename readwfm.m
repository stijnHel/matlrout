function [D,WFMdata]=readwfm(fn)
%readwfm  - Leest WFM-file (labView waveform)
%    quickquick-version
%   D=readwfm(fn)
% Reads wfm-files (in dtlg-format), and expects a limited number of
% waveforms.  All data is put to a structure array with a number of rows
% equal to the number of waveforms, and the columns give the number of
% channels.

fid=fopen(zetev([],fn),'r','ieee-be');
if fid<3
	error('Kan de file niet openen');
end
x=fread(fid,[1 4],'*char');
if ~strcmp(x,'DTLG')
	fclose(fid);
	error('File heeft verkeerd formaat');
end
versie=fread(fid,4,'uint8');	% ?versie
%fprintf('versie ? : %d %d %d %d\n',versie)
nBlok=fread(fid,1,'uint32');
start1=fread(fid,1,'uint32');
lDesc=fread(fid,1,'uint32');
x=fread(fid,[1 38],'uint8');
%y=fread(fid,[1 min(nBlok,128)],'uint32');
y=fread(fid,[1 128],'uint32');
D=struct('t0',cell(nBlok,1),'tnum',[],'dt',0,'e',[]);
jY=0;
kY=0;
z=[];
zz=[];
WFMdata=struct('attr',[],'l',[],'x',[]);
for i=1:nBlok
	jY=jY+1;
	if jY>length(y)
		kY=kY+1;
		if isempty(z)
			z=fread(fid,[1 128],'uint32');
		elseif kY>=length(z)
			if isempty(zz)
				zz=fread(fid,[1 128],'uint32');
			end
			z=fread(fid,[1 128],'uint32');
			kY=0;
		end
		y=fread(fid,[1 128],'uint32');
		jY=1;
	end
	fseek(fid,y(jY),'bof');
	n1=fread(fid,1,'uint32');
	for j=1:n1
		D(i,j).t0=lvtime([],fid);
		D(i,j).tnum=double(D(i,j).t0);
		D(i,j).dt=fread(fid,1,'double');
		n2=fread(fid,1,'int32');
		D(i,j).e=fread(fid,n2,'double');
		if i==1
			% waveform-data (see leesdtlg for better reading)
			iF1=ftell(fid);
			WFMdata(j).x=fread(fid,[1 25],'uint8');
			nAttr=fread(fid,1,'uint32');
			attr=struct('name',cell(1,nAttr),'value',[],'bytes1',[],'bytes2',[]);
			for iAttr=1:nAttr
				%!!!only string-attributes!!!!
				attr(iAttr).name=readstr(fid);
				attr(iAttr).bytes1=fread(fid,[1,20],'uint8');
				attr(iAttr).value=readstr(fid);
				attr(iAttr).bytes2=fread(fid,[1,4],'uint8');
			end
			iF2=ftell(fid);
			WFMdata(j).attr=attr;
			WFMdata(j).l=iF2-iF1;
		else
			%!all successive waveforms must have the same data!!!
			fseek(fid,WFMdata(j).l,'cof');
		end
	end
end
fclose(fid);

function s=readstr(fid)
l=fread(fid,1,'uint32');
if isempty(l)
	s='';
	return
end
s=fread(fid,[1 l],'*char');
