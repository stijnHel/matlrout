function out=whosclass(sClass,varargin)
%whosclass - WHOS but only variables of specific type
%
%     out=whosclass(sClass);

w=evalin('caller','whos');
b=strcmp({w.class},sClass);
if nargout
	out=w(b);
else
	fprintf('  Name                Size             Bytes  Class    Attributes\n\n');
	for i=1:length(w)
		if b(i)
			ss=[num2str(w(i).size(1)) sprintf('x%d',w(i).size(2:end))];
			fprintf('  %-19s %13s %9d %-10s\n',w(i).name,ss,w(i).bytes,w(i).class)
		end
	end
end
