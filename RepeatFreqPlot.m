function RepeatFreqPlot(n,varargin)
%RepeatFreqPlot - Repeat frequency plot (related to periodic DFT result)
%     RepeatFreqPlot(n)
%         if an image exist in the current plot ==> vertical (Y) periodic
%         else horizontally
%     RepeatFreqPlot(h,n)
%         h can be the handle of a figure, axes, a line or an image
%            if h not given, current figure is used
%         if figure, then all axes in the current figure are used

h=[];
nUsed=1;
if nargin>1&&ishandle(n)
	h=n;
	n=varargin{1};
	nUsed=2;
end

if nargin>nUsed
	warning('Sorry, currently no options available!')
end

if isempty(h)
	h=gcf;
end
if ~isscalar(h)
	tp=get(h,'type');
	if ~all(strcmp(tp,tp(1)))
		error('Sorry, all handles should be of the same type!')
	end
end
switch get(h(1),'Type')
	case 'figure'
		f=h;
		ax=GetNormalAxes(f);
		h=get(ax,'Children');
	case 'axes'
		ax=h;
		h=get(ax,'Children');
	case {'line','image'}
	otherwise
		error('Wrong type!')
end
if iscell(h)
	h=cat(1,h{:});
end
for i=1:length(h)
	switch get(h(i),'type')
		case 'line'
			F=get(h(i),'XData');
			X=get(h(i),'YData');
			F=F(:);
			X=X(:);
			n2=floor(length(F)/2);
			tol=(max(X)-min(X))*1e-15;
			if tol==0	% not really usefull...
				tol=1;
			end
			bSymmetric=all(abs(X(2:n2)-X(end:-1:end-n2+2))<tol);
			if ~bSymmetric
				% flip first
				F=[F;F(2:end)+F(end)]; %#ok<AGROW>
				X=[X;X(end-1:-1:2)]; %#ok<AGROW>
			end
			F=bsxfun(@plus,F(:,ones(1,n)),(0:n-1)*(F(2)+F(end)));
			F=F(:);
			X=repmat(X,n,1);
			set(h(i),'XData',F,'YData',X)
		case 'image'
			F=get(h(i),'YData');
			X=get(h(i),'CData');
			F=F(:);
			n2=floor(length(F)/2);
			tol=(max(X(:,1))-min(X(:,1)))*1e-15;
			if tol==0	% not really usefull if everything is zero!
				tol=1;
			end
			bSymmetric=all(abs(X(2:n2)-X(end:-1:end-n2+2))<tol);
			if ~bSymmetric
				% flip first
				F=[F;F(2:end-1)+F(end)]; %#ok<AGROW>
				X=[X;X(end-1:-1:2,:)]; %#ok<AGROW>
			end
			F=bsxfun(@plus,F(:,ones(1,n)),(0:n-1)*(F(2)+F(end)));
			F=F(:);
			X=repmat(X,n,1);
			set(h(i),'YData',F,'CData',X)
			axis(ancestor(h(i),'axes'),'tight')
	end
end
