function D = ReadPPickle(in)
%ReadPPickle - Read Python-Pickle data (or tries to)
%    D = ReadPPickle(in)
%
%  real functionality is in Unpickle
% see also Unpickle, ReadPickle(!!)

if ischar(in) || isstruct(in)
	fid = fopen(fFullPath(in));
	x = fread(fid,[1 Inf],'*uint8');
	fclose(fid);
else
	x = in;
end

warning('This function is hardly started - not giving any (useful) output!!!')
D = Unpickle(x);
