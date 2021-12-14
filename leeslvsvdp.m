function [e,ne,de,e2,gegs,str,err]=leeslvsvdp(fnaam,start,lengte,ongeschaald,kanalen)
%LEESLVSVDP - Leest meetfiles van SVDP-LabView-files.
%   [e,ne,de,e2,gegs,str,err]=leeslvsvdp(fnaam)
%       De metingen bestaan uit twee files, een zonder extensie (de
%          werkelijke meetfile) en een met '.txt' extensie (info)
%       De twee files kunnen doorgegeven worden.
%       De files in het aangegeven path worden geopend als een path opgegeven
%          anders wordt gezocht in de "event-directory".  Als zetev niet bestaat,
%          wordt deze functie niet gebruikt.

%     (!!!enkel de laatste input wordt gebruikt!! de anderen staan er voor
%      compatibiliteitsredenen!!!)

if ~exist('start','var')||isempty(start)
	start=0;
end
if ~exist('lengte','var')||isempty(lengte)
	lengte=0;
end

[pth,fn,ext]=fileparts(fnaam);
if ~isempty(pth)
	fdata=[pth filesep fn];
elseif exist('zetev','file')
	fdata=zetev([],fn);
else
	fdata=fn;
end

fid=fopen([fdata '.txt']);
if fid<3
	error('kan tekst file niet openen')
end
fs=[];
Ntot=[];
N=[];
modes=[];
ne=[];
de=[];
e2=[];
gegs=[];
str='';
while ~feof(fid)
	l=deblank(fgetl(fid));
	if ~isempty(l)
		i=find(l==':');
		if ~isempty(i)
			i1=i(1);
			w1=l(1:i1-1);
			w2=l(i1+1:end);
			while ~isempty(w2)&&w2(1)==' '
				w2(1)='';
			end
			if strcmp(w1,'Sample Rate')
				fs=str2num(w2);
			elseif strcmp(w1,'Numple of points')||strcmp(w1,'Number of points')
				Ntot=str2num(w2);
			elseif strcmp(w1,'Sample Length')
				N=str2num(w2);
			elseif strcmp(w1(1:min(end,5)),'Modes')
				modes=sscanf(w2,'%d/');
			elseif strcmp(w1,'Channel Names')
				j=[0 find(w2=='/') length(w2)+1];
				ne=cell(1,length(j)-1);
				for i=1:length(j)-1
					ne{i}=w2(j(i)+1:j(i+1)-1);
				end
			elseif strcmp(w1,'Channel Name')
				ne={w2};
				if isempty(modes)
					modes=1;
				end
			elseif strcmp(w1,'Comments')||strcmp(w1,'Commments')
				str={w2};
				while ~feof(fid)
					w2=fgetl(fid);
					if ~isempty(w2)
						str{end+1}=w2;
					end
				end
				if length(w2)==1
					w2=w2{1};
				end
			end
		end	% ':' found
	end	% line not empty
end	% while feof
fclose(fid);

if isempty(fs)||isempty(modes)
	error('Niet voldoende gegevens gevonden!')
end
if ~isempty(ne)
	if length(ne)~=length(modes)
		error('Verschillend aantal modes en kanalen???')
	end
	ne=ne(modes>0);
end
nKan=sum(modes>0);

fid=fopen(fdata,'r','ieee-be');
if fid<3
	error('Kan datafile niet openen')
end
fseek(fid,0,'eof');
Ndata=floor(ftell(fid)/8);
fseek(fid,0,'bof');
if isempty(Ntot)
	Ntot=Ndata;
elseif Ndata~=Ntot*nKan
	warning('!!??Datafile andere lengte dan tekstfile aangeeft! (%d - %d)',Ndata,Ntot*nKan)
	Ntot=min(Ntot*nKan,Ndata);
end
if isempty(N)
	if nKan==1
		N=1;	% blocksize is not important
		% no block structuring simplifies reading (for example for reading
		%     only a part)
	else
		N=Ntot;
	end
end
if rem(Ntot,N)
	fclose(fid);
	error('Onvolledig veelvoud van datablokken??')
end
nBlok=Ntot/N;
startB=floor(start/N);
if startB>0
	fseek(fid,startB*N*nKan,'bof');
	nBlok=nBlok-startB;
	% (nog) niets gedaan met afronding door blokken
end
if lengte>0
	endPt=start+lengte-1;
	endBlok=floor(endPt/N);
	nBlok=endBlok-startB+1;
end
e=fread(fid,N*nKan*nBlok,'double');
fclose(fid);
if N>1
	e=reshape(e,N,nKan,nBlok);
	i=(0:nBlok-1)'*nKan;
	j=1:nKan;
	i=i(:,ones(1,nKan))+j(ones(1,nBlok),:);
	e=reshape(e(:,i),N*nBlok,nKan);
elseif nKan>1
	e=reshape(e,nKan,nBlok)';
end
e=[(0:nBlok*N-1)'/fs e];
if ~isempty(ne)
	ne={'t' ne{:}};
end
