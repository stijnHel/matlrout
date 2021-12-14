function X=leesImg(fn)
% LEESIMG - Leest labview-(tempmeet)-image

fid=fopen(fn,'r');
if fid<3
	error('Kan file niet openen!')
end
x=reshape(fread(fid,'*uint8'),4,768,576);
fclose(fid);
%X=shiftdim(x(2:4,:,:),1);
X=uint8(zeros(576,768,3));
for i=1:3
	X(:,:,i)=squeeze(x(i+1,:,:))';
end
