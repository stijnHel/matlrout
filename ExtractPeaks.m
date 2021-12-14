function [Xout,Yout]=ExtractPeaks(fig)
%ExtractPeaks - Extract peaks based on polynomial fit
%    S=ExtractPeaks(fig) - gcf if fig is not given
%         (fig can also be a handle to an axes - or even to a line)
%         S: struct with peak data
%    [X,Y]=ExtractPeakFreq(...)

if nargin==0||isempty(fig)
	fig=gcf;
end

l=findobj(fig,'Type','line');

S=struct('line',num2cell(l),'type',[],'X',[],'Y',[]);
for i=1:length(l)
	x=get(l(i),'XData');
	if length(x)<3
		continue
	end
	y=get(l(i),'YData');
	xl=get(ancestor(l(i),'axes'),'XLim');
	B=x>=xl(1)&x<=xl(2);
	
	if sum(B)<4
		B=conv(B(:),ones(3,1),'same');
		if sum(B)<4
			continue
		end
	end
	x = x(B);
	y = y(B);
	bMax = max(y([1 end]))<max(y);
	if bMax
		[Ym,iM] = max(y);
		S(i).type = 'max';
	else
		[Ym,iM] = min(y);
		S(i).type = 'min';
	end
	if iM==1||iM==length(x)
		Xm = x(iM);
	else
		if y(iM+1)==Ym&&iM+1<length(x)
			ii = iM-1:iM+2;
		else
			ii = iM-1:iM+1;
		end
		x0 = mean(x(ii));
		y0 = mean(y(ii));
		p = polyfit(x(ii)-x0,y(ii)-y0,2);	% scale to be numerically safe?
		if p(1)==0	% is this possible? (starting with lower value ==> p(1)~=0 or all max (and then Xm=x(iM)))
			% this is not possible
			Xm = x(iM);	% p(2) will be zero too?
			if p(2)~=0
				warning('Not as expected?! (not flat but and not quadratic?!')
			end
		else
			Xm = -p(2)/(2*p(1)) + x0;
			Ym = p(3)-p(2)^2/4/p(1) + y0;	% p in Xm
		end
		
	end
	S(i).X=Xm;
	S(i).Y=Ym;
	if nargout==0
		fprintf('#%2d (%s): x=%10g, y=%10g\n',i,S(i).type,Xm,Ym)
	end
end

if nargout
	if nargout==1
		Xout=S;
	else
		Xout=[S.X];
		Yout=[S.Y];
	end
end