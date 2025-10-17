function [B,l]=plotcarr(c,t,namen,f)
% PLOTCARR - plot aparte vlaggen van een carrier
%   [B,l]=plotcarr(c,t,namen,f)
%        c = vector met carrier
%        t = tijd-vector
%        namen = namen van vlaggen binnen carrier
%            als namen slechts één string is, wordt dit genomen als
%                   #<bit0>#<bit1>#...
%        f = selectie van de vlaggen
%
%        B = matrix van de aparte bits
%        l = handles naar de lijnen

n0=[];
if min(size(c))>1 % bits already separated
	bits=c;
	nC=size(bits,1);
else
	bits=[];
	nC=length(c);
end
if ~exist('t','var')||isempty(t)
	t=0:nC-1;
elseif length(t)==1
	t=(0:nC-1)*t;
end
if ~exist('namen','var')
	namen=[];
end
if ~exist('f','var');f=[];end
if ischar(namen)
	if size(namen,1)==1
		N=namen;
		ii=[find(namen=='#') length(namen)+1];
		namen=cell(1,length(ii)-1);
		for i=1:length(ii)-1
			namen{i}=N(ii(i)+1:ii(i+1)-1);
		end
	else
		namen=cellstr(namen);
	end
end
if isempty(f) && (length(namen)>1)
	b=strncmp('xxx',namen,3);
	if any(b)
		f=0:length(namen)-1;
		f(b)=[];
	end
end
if isempty(bits)
	% beter kijken of er achter de comma ook nog iets staat.
	i=find(isnan(c)|isinf(c));
	if ~isempty(i)
		c(i)=0;
	end
	c=round(c(:));
	if any(c<0)
		mx=max(abs(c));
		if mx>255
			c=c+65536*(c<0);
		else
			c=c+256*(c<0);
		end
		if any(c<0)
			error('!!! te negatief ???')
		end
	%	error('carrier moet positief zijn');
	end
	bits=zeros(length(c),nextpow2(max(c)));
	nBit=0;
	while any(c)
		nBit=nBit+1;
		bits(:,nBit)=bitand(c,1);
		c=bitshift(c,-1);
	end
	if size(bits,2)<nBit
		bits=bits(:,1:nBit);	% possible?
	end
end
if isempty(bits)
	ht=text(0.5,0.5,'Alles is nul','verticalalignment','middle','horizontalalignment','center');
	axis([0 1 0 1])
	set(ht,'units','pixels')
	if nargout>0
		B=c;
	end
	if ~isempty(n0)
		title(n0)
	end
	return
end
if length(namen)>size(bits,2)
	bits=[bits zeros(size(bits,1),length(namen)-size(bits,2))];
end
if ~isempty(f)
	if any(f-floor(f)>0)
		error('f moet gehele waarden bevatten')
	end
	if min(f)<0
		error('f moet minimaal 0 zijn')
	end
	f=f+1;
	if max(f)>size(bits,2)
		if max(f)>16
			error('f moet maximaal 15 zijn')
		end
		bits=[bits zeros(size(bits,1),max(f)-size(bits,2))];
	end
	if length(namen)>=max(f)
		namen=namen(f);
	else
		fprintf('namen heeft %d elementen en er zijn %d bits te tonen.\n'	...
			,length(namen),max(f));
		fprintf('Er worden daarom geen namen aan de vlaggen gegeven.\n');
		namen=[];
	end
	bits=bits(:,f);
end
newplot;
grid on
l=zeros(1,size(bits,2));
for i=1:size(bits,2)
	l(i)=line(t,double(bits(:,i)~=0)/2+(i-1.5));
end
set(gca,'YLim',[-0.6 size(bits,2)-0.3],'Box','on')
if length(namen)==size(bits,2)
	set(gca,'YTick',0:size(bits,2)-1,'YTickLabel',namen);
else
	set(gca,'YTick',0:size(bits,2)-1);
end
if ~isempty(n0)
	title(n0)
end
if nargout>0
	B=bits;
end
