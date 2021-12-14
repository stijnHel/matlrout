function fOut=toonfigs(ff)
%TOONFIGS - Zet alle aanwezige figuren op de voorgrond

if ~exist('ff','var')||isempty(ff)
	shh=get(0,'ShowHiddenHandles');
	set(0,'ShowHiddenHandles','on')
	ff=findobj(get(0,'Children'),'flat','type','figure','Visible','on');
	set(0,'ShowHiddenHandles',shh)
end
for i=1:length(ff)
  figure(ff(i))
end
if nargout
	fOut=ff;
end
