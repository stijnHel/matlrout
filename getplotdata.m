function [D,h]=getplotdata(f,varargin)
%getplotdata - Get numerical data from a plot
%  D=getplotdata[(f)]
%  D=getplotdata(f,<options>)
%        options
%          xlim
%          ylim
%
%  see also getsigs

if nargin==0||isempty(f)
	f=gcf;
end
xlim=true;
ylim=false;
if nargin>1
	setoptions({'xlim','ylim'},varargin{:})
end


ax=findobj(f,'type','axes','-depth',1);
D=cell(1,length(ax));
for iAx=1:length(ax)
	h=get(ax(iAx),'children');
	xL=get(ax(iAx),'xlim');
	yL=get(ax(iAx),'ylim');
	ih=1;
	D1=cell(1,length(h));
	while ih<=length(h)
		switch get(h(ih),'Type')
			case 'line'
				x=get(h(ih),'XData');
				y=get(h(ih),'YData');
				if xlim
					b=x>=xL(1)&x<=xL(2);
					y=y(b);
					x=x(b);
				end
				if ylim
					b=y>=yL(1)&y<=yL(2);
					x=x(b);
					y=y(b);
				end
				if ih>1&&isequal(x(:),D1{ih-1}(:,1))
					D1{ih-1}(:,end+1)=y(:);
					D1(ih)=[];
					h(ih)=[];
				else
					D1{ih}=[x(:) y(:)];
					ih=ih+1;
				end
			% patch,image,...
			otherwise
				D1(ih)=[];
				h(ih)=[];
		end		% switch type
	end		% while ih
	if length(D1)==1
		D1=D1{1};
	end
	D{iAx}=D1;
end
if nargout==0
	for iD=1:length(D)
		fprintf('axes %d\n',iD)
		D1=D{iD};
		if ~iscell(D1)
			D1={D1};
		end
		for iD1=1:length(D1)
			D2=D1{iD1};
			fprintf('   %10g-%10g (#%5d): %10g (%10g)',D2([1 end],1),size(D2,1),mean(D2(:,2)),std(D2(:,2)))
			if size(D2,2)>2
				for i=3:size(D2,2)
					fprintf(', %10g (%10g)',mean(D2(:,i)),std(D2(:,i)))
				end
			end
			fprintf('\n')
		end
	end
	clear D
	return
end
if length(D)==1
	D=D{1};
end
