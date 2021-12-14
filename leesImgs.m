function X=leesImgs(fn,ncol,nrow)
% LEESIMGS - Leest labview-(tempmeet)-images
%    X=leesImgs(fn[,ncol,nrow]);

fid=fopen(fn,'r','ieee-be');
if fid<3
	fid=fopen(zetev([],fn),'r','ieee-be');
	if fid<3
		error('Kan file niet openen!')
	end
end
fseek(fid,0,'eof');
lFile=ftell(fid);
fseek(fid,0,'bof');
n=fread(fid,1,'uint32');
siz=fread(fid,4,'uint32');
lHead=ftell(fid);
b=siz(3)-max(1,siz(1));	%!!!
h=siz(4)-max(1,siz(2));	%!!!
b=ceil(b/2)*2;	%!!!!!!!
h=ceil(h/2)*2;	%!!!!!!!
if exist('ncol','var')&&~isempty(ncol)
	b=ncol;
end
if exist('nrow','var')&&~isempty(nrow)
	h=nrow;
end
bSizeOK=(lFile-lHead==4*b*h*n);
bBOK=true;
bHOK=true;
if b<1
	bSizeOK=false;
	bBOK=false;
	warning('!!Onmogelijke breedte opgegeven (%d)!!',b)
	b=1;
end
if h<1
	bSizeOK=false;
	bHOK=false;
	warning('!!Onmogelijke hoogte opgegeven (%d)',h)
	h=1;
end
if ~bSizeOK
	if bHOK
		b0=b;
		b=floor((lFile-lHead)/4/n/h);
		if lFile-lHead==4*b*h*n
			warning('Breedte herberekend (%d --> %d)',b0,b)
		else
			h1=(lFile-lHead)/4/n/b0;
			if h1==floor(h1)&&bBOK
				warning('Hoogte herberekend (%d --> %d)',h,h1)
				h=h1;
				b=b0;
			else
				warning('Breedte herberekend, maar zal toch niet juist zijn (%d --> %d)',b0,b)
			end
		end
	elseif bBOK
		h0=h;
		h=floor((lFile-lHead)/4/n/b);
		if lFile-lHead==4*b*h*n
			warning('Hoogte herberekend (%d --> %d)',h0,h)
		else
			warning('Hoogte herberekend, maar zal toch niet juist zijn (%d --> %d)',h0,h)
		end
	else
		% Wat hier?
	end
end
X=uint8(zeros(h,b,3,n));
nRead=4*b*h;
for ib=1:n
	x=fread(fid,nRead,'*uint8');
	if length(x)~=nRead
		if feof(fid)
			warning('!!!vroegtijdig afgebroken!!! (n(/N) bxh imgs=%d/%d %dx%d, datagedeelte %d B gelezen, %d B verwacht)',ib-1,n,b,h,ftell(fid)-20,4*h*b*n)
		else
			warning('Minder data gelezen dan nodig, en toch einde file niet bereikt??!!!')
		end
		break;
	end
	x=reshape(x,4,b,h);
	for i=1:3
		X(:,:,i,ib)=squeeze(x(i+1,:,:))';
	end
end
n=ftell(fid);
x=fread(fid,1,'char');
if ~isempty(x)
	warning('Slechts %d van %d bytes gelezen (%d bytes over)!!?',n,lFile,lFile-n)
end
fclose(fid);
