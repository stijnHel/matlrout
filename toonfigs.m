function fOut=toonfigs(ff,varargin)
%TOONFIGS - Zet alle aanwezige figuren op de voorgrond
%    toonfigs(<figs>) ---> opens(/activates) all figures
%         by default (no input or empty array) all figures are found
%    f = toonfigs(figs) - opens figures and returns a list
%    [f = ]toonfigs(figs,...) options:
%         bShowHidden    - include hidden handles
%         bGetInvisible  - include invisible figures
%         bOnlyReturn    - don't activate figures, only searches for them

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
