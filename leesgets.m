function A=leesgets(f,n)
% LEESGETS - Leest getallen
fid=fopen(f,'r');
if fid<0
	error('File niet gevonden')
end
A=fscanf(fid,'%g');
fclose(fid);
if nargin
	r=floor((length(A)+n-1)/n);
	A=reshape([A(:);zeros(r*n-length(A),1)],n,r)';
end
