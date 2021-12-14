function s=convCmd2Fcn(s)
%convCmd2Fcn - Convert command line statement to function call
%     s=convCmd2Fcn(s)

s=strtrim(s);
if isempty(s)
	error('Wrong use of this function')
end
s(s==9)=' ';
iS=find(s==' ');
if isempty(iS)
	return
end
iS(iS(2:end)==iS(1:end-1)+1)=0;
iS=nonzeros(iS);
W=cell(1,length(iS));
n=length(iS);
iS(end+1)=length(s)+1;
W{1}=s(1:iS(1)-1);
for i=1:n
	W{i+1}=deblank(s(iS(i)+1:iS(i+1)-1));
end
s=[W{1} '(''' W{2} ''''];
if n>1
	s=[s sprintf(',''%s''',W{3:end})];
end
s=[s ');'];
