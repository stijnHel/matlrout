function del(c,nr)
%CNAVMSRS/DEL - delete line
%    del(c,nr)

f=getmakefig('navmsrcopy',0,0);
if isempty(f)
	error('Can''t find a "navmsrs-copy figure".')
end
D=getappdata(f,'navcopydata');
if nr<1||nr>length(D.hL)
	error('Index of line doesn''t exist (%d lines)',length(D.hL))
end
hLc=D.hL{nr};
for i=1:numel(hLc)
	for j=1:size(c.kols,2)
		if hLc{i}(j)
			delete(hLc{i}(j))
		end
	end	% for j
end % for i
D.L(nr)=[];
D.hL(nr)=[];
setappdata(f,'navcopydata',D)
