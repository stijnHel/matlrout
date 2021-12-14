function f=CalcBunF_graph(ax,flag)
%CalcBunF_graph - Calculate Buneman frequency from graph - frequency plot
%         f=CalcBunF_graph(ax,flag)
%               ax: the axes (current axes if not given)
%               flag: 0 (default) - maximum in shown graph
%                     1           - maximum close to current point
%
% see also buneman

if nargin<1||isempty(ax)
	ax=gca;
end
if nargin<2||isempty(flag)
	flag=0;
end

if flag==1
	pt=get(ax,'currentpoint');
	pt=pt(1);
else
	pt=xlim(ax);
end

l=findobj(ax,'Type','line','Visible','on');
l=l(end:-1:1);	% plotting order
f=zeros(1,length(l));
for i=1:length(l)
	X=get(l(i),'XData');
	Y=get(l(i),'YData');
	N=length(X);
	switch flag
		case 0
			ii=find(X>=pt(1)&X<=pt(2));
			if length(ii)<3
				f(i)=NaN;
			else
				[~,iMx]=max(Y(ii));
				iMx=ii(iMx);
			end
		case 1
			iMx=findclose(X,pt);
			if iMx>1&&Y(iMx-1)>Y(iMx)&&(iMx==N||Y(iMx+1)<Y(iMx-1))
				while iMx>1&&Y(iMx-1)>Y(iMx)
					iMx=iMx-1;
				end
			else
				while iMx<N&&Y(iMx+1)>Y(iMx)
					iMx=iMx+1;
				end
			end
		otherwise
			error('Unknown flag!')
	end		% switch flag
	B=iMx-1+N/pi*atan(sin(pi/N)/(cos(pi/N)+Y(iMx)/Y(iMx+1)));
	f(i)=B*(X(2)-X(1));
end		% for i
