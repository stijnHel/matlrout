function chlijn(f,lt)
% CHLIJN - Vervangt kleuren naar verschillende lijntypes

if ~exist('f');f=[];end
if ~exist('lt');lt=[];end

if isempty(f)
	f=gcf;
end
if length(f)==1
	figure(f)
end
if isempty(lt)
	lt=['- ';': ';'-.';'--'];
end
collijst=get(f(1),'DefaultAxesColorOrder');
l=findobj(f,'Type','line');
for i=1:length(l)
	pt=[];
	c=get(l(i),'Color');
	if ~isempty(collijst)
		pt=find((c(1)==collijst(:,1))&(c(2)==collijst(:,2))&(c(3)==collijst(:,3)));
	end
	if isempty(pt)
		pt=size(collijst,1)+1;
		collijst=[collijst;c];
	end
	pt=rem(pt-1,size(lt,1))+1;
	axes(get(l(i),'Parent'))
	set(l(i),'LineStyle',deblank(lt(pt,:)));
end
