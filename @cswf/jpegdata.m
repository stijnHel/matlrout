function [A,nEnc]=jpegdata(c,i,j)
% CSWF/JPEGDATA - Geeft jpeg-data
%    A=jpegdata(c,i)	(i : i-de jpeg in swf)
%    A=jpegdata(c,i,j)

if nargin==2
	if length(i)==1
		k=zoekjpegs(c);
		j=k(i,2);
		i=k(i,1);
	else
		j=i(2);
		i=i(1);
	end
end

x=gettagdata(c,i,j);
if isfield(x,'JPEG')
	x=x.JPEG;
	if x(1)~=255|x(2)~=216
		if x(2)==217
			fprintf('???juiste JPEG-structuur???Begin en end omgedraaid van encoding data???\n');
			i1=find(x==216);
			x(2)=216;
			x(i1(1))=217;	%!!!!????
		else
			error('Verkeerde data')
		end
	end
	i1=find(x(1:end-1)==255&x(2:end)==216);
	i2=find(x(1:end-1)==255&x(2:end)==217);
	if length(i1)~=2|length(i2)~=2
		warning(sprintf('!!??verkeerde JPEG data?? - aantal begin (%d) en eindtags (%d) zijn niet gelijk aan 2',length(i1),length(i2)))
	elseif i2(2)~=length(x)-1
		warning('!!??verkeerde JPEG data?? - eindtag niet op einde van JPEG-data??')
	end
	A=x([i1(1):i2(1)-1 i1(2)+2:end]);
else
	error 'voor deze data heb ik nog niets'
end
