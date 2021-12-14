function [e,ne,de,e2,gegs]=leestekdir(fn)
%leestekdir - Reads directory with tektronics/labview data (TXT,CSV,ISF)
%     [e,ne,de,e2,gegs]=leestekdir(fn)

if isnumeric(fn)
    fn=sprintf('ALL%04d',fn);
end
if exist(zetev([],fn),'dir')
	fn=zetev([],fn);
end
fn(end+1)=filesep;
d=dir([fn '*.txt']);
if ~isempty(d)
	typ=1;
else
	d=dir([fn '*.CSV']);
	if ~isempty(d)
		typ=2;
	else
		d=dir([fn '*.ISF']);
		typ=3;
	end
end
if isempty(d)
	error('No datafiles found')
end
for i=1:length(d)
	switch typ
		case 1
			e1=leeslvtxt([fn d(i).name]);
		case 2
			e1=leesoscmeas([fn d(i).name]);
		case 3
			e1=leesISF([fn d(i).name]);
	end
	if i==1
		e=e1(:,[1 2 ones(1,length(d)-1)]);
	else
		e(:,i+1)=e1(:,2);
	end
end
ne=('t-')';
ne(3:size(e,2))='-';
de=ne;
de(1)='s';
e2=[];
gegs=zeros(1,18);
