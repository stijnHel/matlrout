function [uOut,D]=calcdoorg(p,el,d0,nd,methode)
%calcdoorg - Calculates time of meridian transits
%   uOut=calcdoorg(p,el,d0,nd,method)
%         p : position on earth (default 'ukkel')
%         el: element (default 'zon')
%         d0: starting date (default [1 1 2006])
%         nd: number of transits (default 1 without output, 366 with)
%         method: (default 4)
%             1: using fzero (accurate but very slow)
%             2: linear approximation using two points
%                  worst (and sometimes with extrapolation)
%             3: linear correction using position at one point
%             4: improvement of 2 (even more accurate than 1!)
%             5: similar to 3 but with varying correction factor
%                    !not stable!
%             6: similar to 1 (fzero) but with changed starting point
%   first time is always done using fzero.  The following are using the
%   given method.

if ~exist('el','var')||isempty(el)
	el='zon';
end
if ~exist('d0','var')||isempty(d0)
	if nargout
		d0=[1 1 2006];
	else
		d0=clock;
		d0=d0([3 2 1]);
	end
end
if ~exist('nd','var')||isempty(nd)
	if nargout
		nd=366;
	else
		nd=1;
	end
end
if ~exist('p','var')||isempty(p)
	p='ukkel';
end
if ischar(p)
	p=geogcoor(p);
end
d0=calcjd(d0);
u=zeros(nd,1);
u(1)=fzero(@(u) calcphra(u,p,d0,el),12-p(1)/2/pi*24);
pp=calcposhemel(p,d0+u(1)/24,el);
if abs(pp(1))>1
	if u(1)>12
		u(1)=u(1)-12;
	else
		u(1)=u(1)+12;
	end
	u(1)=fzero(@(u) calcphra(u,p,d0,el),u(1));
end
ddu=.01;
nUW=0;
if ~exist('methode','var')||isempty(methode)
	methode=4;
end
if nd>1&&(methode==3||methode==4||methode==5)
	u1=calcphra(u(1)+ddu,p,d0,el);
	du=u1/ddu;
	TEST=u;
	TEST(1)=du;
end
for d=1:nd-1
	switch methode
		case 1
			u(d+1)=fzero(@(u) calcphra(u,p,d0+d,el),u(d));
		case 2
			u1=calcphra(u(d)-ddu,p,d0+d,el);
			u2=calcphra(u(d)+ddu,p,d0+d,el);
			if u1*u2>0
				nUW=nUW+1;
				if nUW<4
					warning('!!!!')
				end
			end
			u(d+1)=u(d)-(u1+u2)/2*ddu/(u2-u1);
		case 3
			u1=calcphra(u(d),p,d0+d,el);
			u(d+1)=u(d)-u1/du;
		case 4
			u1=calcphra(u(d),p,d0+d,el);
			u2=u(d)-u1/du;
			u3=calcphra(u2,p,d0+d,el);
			du=-(u3-u1)/u1*du;
			TEST(d+1)=du;
			u(d+1)=u2-u3/du;
		case 5
			if d<2
				u1=calcphra(u(d),p,d0+d,el);
				u(d+1)=u(d)-u1/du;
			else
				u2=2*u(d)-u(d-1);
				u1=calcphra(u2,p,d0+d,el);
				u(d+1)=u2-u1/du;	% can be made stable by du/2 (or other starting date)
			end
		case 6
			if d<2
				u1=u(d);
			else
				u1=2*u(d)-u(d-1);
			end
			u(d+1)=fzero(@(u) calcphra(u,p,d0+d,el),u1);
	end
end
if nUW>3
	warning('%d keer extrapolatie!!',nUW)
end
if nargout==0&&nd==1
	mn=(u-floor(u))*60;
	fprintf('Berekende doorgang van %s om %d:%02d:%02.0f\n',el,floor(u),floor(mn),(mn-floor(mn))*60)
else
	uOut=u;
	if nargout>1
		D=var2struct(ddu,TEST);
	end
end
