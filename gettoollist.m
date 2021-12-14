function [T,NT]=gettoollist
%gettoollist - Give list of installed and licensed toolboxes
%     gettoollist - shows the list
%     [T,NT]=gettoollist
%            T : installed tools (structure with name and version info)
%            NT: installed but not licened

v=ver;
B=false(size(v));
for i=1:length(v)
	s=v(i).Name;
	s(s==' ')='_';
	B(i)=license('test',s(1:min(27,end)));
	if ~B(i)
		k=find(s=='_');
		if length(k)>1&&length(s)>7&&strcmpi(s(end-6:end),'Toolbox')
			s(k(1)+1:k(end))=[];
			B(i)=license('test',s);
		end
	end
end

if nargout
	T=v(B);
	NT=v(~B);
else
	v=v(B);
	fprintf('      %-30s %-6s %-9s %-14s\n','name','ver','release','date')
	printstr('%-30s',{v.Name},'%-6s',{v.Version},'%-9s',{v.Release}	...
		,'%-14s',{v.Date})
end