function C=GetVars(list,n)
%GetVars  - Get variables in calling workspace and put in cell vector
%     C=GetVars(list[,n])

if nargin==1
	n=length(list);
end
C=cell(1,n);
for i=1:n
	C{i}=evalin('caller',list{i});
end
