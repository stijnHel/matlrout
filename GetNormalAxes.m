function ax=GetNormalAxes(in,varargin)
%GetNormalAxes - Find "normal axes" (no legend, ...)
%     ax=GetNormalAxes(in)
% additionally
%    GetNormalAxes('AddDiscard',<tag-to-discard>)
%    GetNormalAxes('RemDiscard',<tag-to-discard>)
%    <tag-to-discard>=GetNormalAxes('GetDiscard');
%    GetNormalAxes('default')
%
% Warning!
%    Changes to the behaviour (by Add/Rem Discard) are "global changes",
%    which might give unexpected results for other functions!


persistent TagsToDiscard

if isempty(TagsToDiscard)
	TagsToDiscard={'legend','Colorbar','title'};
end
if ischar(in)
	if strncmpi(in,'AddDiscard',length(in))
		if length(varargin)>1||ischar(varargin{1})
			tg=varargin;
		elseif iscell(varargin{1})
			tg=varargin{1};
		end
		TagsToDiscard=union(TagsToDiscard,tg);
	elseif strncmpi(in,'RemDiscard',length(in))
		if length(varargin)>1||ischar(varargin{1})
			tg=varargin;
		elseif iscell(varargin{1})
			tg=varargin{1};
		end
		TagsToDiscard=setdiff(TagsToDiscard,tg);
	elseif strncmpi(in,'GetDiscard',length(in))
		ax=TagsToDiscard;
	elseif strncmpi(in,'default',length(in))
		TagsToDiscard=[];	% will be setup in next call
	else
		warning('Wrong use of this function (unknown cmd "%s")',in)
	end
	return
end

ax=findobj(in,'Type','axes','Visible','on');
for tp=TagsToDiscard
	ll=findobj(ax,'Tag',tp{1});
	if ~isempty(ll)
		ax=setdiff(ax,ll);
	end
end
