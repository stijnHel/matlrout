function MatchYlims(f1,f2,varargin)
%MatchYlims - Match Y-limits of plots
%   MatchYlims(f1,f2,varargin)
% undo:
%   MatchYlims(f1,f2,'auto')

ax1=findobj(f1,'type','axes');

if nargin>2
	if ~ischar(varargin{1})	...
			||~strncmpi(varargin{1},'auto',min(1,length(varargin{1})))
		error('Bad input')
	end
	set(ax1,'ylimmode','auto')
	ax2=findobj(f2,'type','axes');
	set(ax2,'ylimmode','auto')
	return
end

P1=get(ax1,'Position');
P1=cat(1,P1{:});
%P2=get(ax2,'Position');
%P2=cat(1,P2{:});

for i=1:length(ax1)
	ax2=findobj(f2,'Position',P1(i,:));
	if ~isempty(ax2)
		Yl1=ylim(ax1(i));
		Yl2=ylim(ax2);
		Yl=[Yl1;Yl2];
		set([ax1(i) ax2],'Ylim',[min(Yl(:,1)) max(Yl(:,2))])
	end
end
