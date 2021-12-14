function cur=cursread(file)
% CURSREAD - Read cursor-file
%   cur=cursread(file);
%     curs : struct
%        data : matrix met pixels (kleuren aangeduid door index in RGB-array
%        mask
%        RGB(?) : matrix van RGB-data

% Dit zit nog vol onbekenden

if ~ischar(file)
	if isstruct(file)
		% Hier zou iets moeten komen over het kombineren van de kleuren
		nfigure
		for i=1:length(file)
			subplot(length(file),2,i*2-1)
			image(file(i).data+1);
			axis equal
			title('Data')
			subplot(length(file),2,i*2)
			image(file(i).mask+1)
			axis equal
			title('Mask')
		end
		colormap(file(end).RGB)	% !!!!laatste kleurmap wordt gebruikt
		return
	else
		x=file;
	end
else
	if ~any(file=='.')
		file=[file '.cur'];
	end
	fid=fopen(file,'r');
	if fid<3
		error('File niet gevonden');
	end
	x=fread(fid);
	fclose(fid);
end

big_endian=[1 256 65536 16777216];

aantal=x(5);
j0=7;
kleuren=cell(aantal,1);
data=kleuren;
mask=kleuren;
nulpunt=zeros(aantal,2);
for i=1:aantal
	hor=x(j0);
	ver=x(j0+1);
	nulpunt=[1 256]*reshape(x(j0+4:j0+7),2,2);
	EindEnStart=big_endian*reshape(x(j0+8:j0+15),4,2);
	start=EindEnStart(2);
	eind=EindEnStart(1);
	j0=j0+16;

	nbits=x(start+15);
	nkleuren=2^nbits;
	
	%fprintf('%s, l=%d (0x%04x), (%d soorten) %dx%d, %d kleuren\n',file,length(x),length(x),aantal,hor,ver,nkleuren)
	%printhex(x(1:128));
	j=start+40+nkleuren*4;
	n=hor*ver/8*nbits;
	kleuren{i}=reshape(x(start+41:j),4,nkleuren)';
	kleuren{i}=kleuren{i}(:,1:3)/255;
	data{i}=bitmatr(x(j+1:j+n),nbits,hor,ver);
	j=j+n;
	mask{i}=bitmatr(x(j+1:j+n/nbits),1,hor,ver);
end

cur=struct('data',data,'mask',mask,'RGB',kleuren);
if ~nargout
	cursread(cur);
	if ischar(file)
		set(gcf,'Name',file)
	end
end

function M=bitmatr(data,nbits,m,n)
if length(data)~=m*n/8*nbits
	error('Verkeerd aantal bytes doorgegeven aan bitmatr')
end
data=data(:)';
M=zeros(8/nbits,length(data));
k=round(2^nbits);
m1=k-1;
j=1;
for i=8/nbits:-1:1
	M(i,:)=bitand(data,m1)/j;
	m1=m1*k;
	j=j*k;
end
M=reshape(M,m,n)';
