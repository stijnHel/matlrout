function fOut=toonfigs(ff,varargin)
%TOONFIGS - Zet alle aanwezige figuren op de voorgrond

[bOnlyReturn] = false;	% don't "show" them
if nargin==0 || isempty(ff)
	[bShowHidden] = true;
	[bGetInvisible] = false;
	if nargin>1
		setoptions({'bShowHidden','bGetInvisible','bOnlyReturn'},varargin{:})
	end
	props = {};
	if ~bGetInvisible
		props = {'Visible','on'};
	end
	if bShowHidden
		shh=get(0,'ShowHiddenHandles');
		set(0,'ShowHiddenHandles','on')
	end
	ff=findobj(get(0,'Children'),'flat','type','figure',props{:});
	if bShowHidden
		set(0,'ShowHiddenHandles',shh)
	end
end
if ~bOnlyReturn
	for i=1:length(ff)
		if strcmp(ff(i).Visible,'on')
			figure(ff(i))
		end
	end
end
if nargout
	fOut=ff;
end
