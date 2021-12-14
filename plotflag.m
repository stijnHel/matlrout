function B=plotcarr(c,t,namen,f)
% PLOTCARR - plot aparte vlaggen van een carrier
%   B=plotcarr(c,t,namen,f)
%        c = vector met carrier
%        t = tijd-vector
%        namen = namen van vlaggen binnen carrier
%            als namen slechts één string is, wordt dit genomen als
%            de naam van de carrier.
%        f = selectie van de vlaggen
%
%        B = matrix van de aparte bits

n0=[];
if ~exist('t')
	t=0:length(c)-1;
end
if ~exist('namen')
	namen=[];
end
if ~exist('f');f=[];end
if size(namen,1)==1
	namen=lower(namen);
	n0=namen;
	if strcmp(namen,'csys')
		namen=[
			'vlvrev ';
			'vlveng ';
			'vlvch  ';
			'vlvpark';
			'vlvlran';
			'xxxxxxx';
			'srphigh';
			'dsterr ';
			'cluclos';
			'brake  ';
			'cts    ';
			'tipsw  ';
			'tipswup';
			'tipswdn';
			'tipswul';
			'tipswdl';
			];
	elseif strcmp(namen,'cste')
		namen=[
			'tipup  ';
			'tipdown';
			'tipuold';
			'tipdold';
			'tipcont';
			'tiplow ';
			'tipfor2';
			'xxxxxxx';
			'pidinit';
			'stelow ';
			'stefrod';
			'rpmosc ';
			'steinit';
			'rpmdhin'];
	elseif strcmp(namen,'cled')
		namen=[
			'ledon   ';
			'ledflash';
			'ledinit '];
	elseif strcmp(namen,'cerr')
		namen=[
			'errnmot';
			'errthp ';
			'errthp2';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'errtemp';
			'cenhigh'];
	elseif strcmp(namen,'ccal')
		namen=[
			'callh ';
			'xxxxx ';
			'xxxxx ';
			'xxxxx ';
			'xxxxx ';
			'xxxxx ';
			'xxxxx ';
			'calthp'];
	elseif strcmp(namen,'cclustat')
		namen=[
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'xxxxxxx';
			'cluset ';
			'clueng ';
			'clucts ';
			'cluhigh'];
	else
		if nargout>0
			B=[];
			return
		else
			error('onbekende carrier')
		end
	end
end
if isempty(f) & (size(namen,1)>1)
	i=fstrmat(namen(:,1:min(3,end)),'xxx');
	if ~isempty(i)
		f=0:size(namen,1)-1;
		f(i)=[];
	end
end
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
bits=zeros(length(c),0);
while any(c)
	bits=[bits rem(c,2)];
	c=floor(c/2+0.1);
end
if isempty(bits)
	t=text(0.5,0.5,'Alles is nul','verticalalignment','middle','horizontalalignment','center');
	axis([0 1 0 1])
	set(t,'units','pixels')
	if nargout>0
		B=c;
	end
	if ~isempty(n0)
		title(n0)
	end
	return
end
if size(namen,1)>size(bits,2)
	bits=[bits zeros(size(bits,1),size(namen,1)-size(bits,2))];
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
	if size(namen,1)>=max(f)
		namen=namen(f,:);
	else
		fprintf('namen heeft %d elementen en er zijn %d bits te tonen.\n'	...
			,size(namen,1),max(f));
		fprintf('Er worden daarom geen namen aan de vlaggen gegeven.\n');
		namen=[];
	end
	bits=bits(:,f);
end
%if size(namen,1)<size(bits,2)
%	plotmat(bits,(1:size(bits,2))',t)
%else
%	plotmat(bits,(1:size(bits,2))',t,namen)
%end
newplot;
grid on
for i=1:size(bits,2)
	line(t,bits(:,i)/2+(i-1));
end
set(gca,'YLim',[-0.1 size(bits,2)-0.4],'Box','on')
if size(namen,1)==size(bits,2)
	set(gca,'YTick',(1:size(bits,2))-0.5,'YTickLabel',namen);
end
if ~isempty(n0)
	title(n0)
end
if nargout>0
	B=bits;
end
