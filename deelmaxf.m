function y=deelmaxf(x,n)
% DEELMAXF - Zoekt de bovenste "envelope" van een kurve
y=zeros(size(x));
y(1)=x(1);
im=1;
doeInter=0;
i=2;
status('Zoek van bovenste "envelope" van kurve',0);
k=0;
test=[];
while i<length(x)
	status(im/length(x))
	if x(i)>=x(im)
		if k
			doeInter=1;
		else
			y(i)=x(i);
			im=i;
		end
	elseif i-n>=im
		while x(im+1)<x(im)
			im=im+1;
			y(im)=x(im);
			if im==i
				break;
			end
		end
		while x(im+1)>=x(im)
			im=im+1;
			y(im)=x(im);
			if im==i
				break;
			end
		end
		i=im;
		k=0;
	else
		k=1;
	end
	if doeInter
		k=0;
		if im==1
			a=(x(i)-x(im))/(i-im);
			y0=x(i)-a*i;
			while (i+1)*a+y0<x(i+1)
				i=i+1;
				if i==length(x)
					break;
				end
				a=(x(i)-x(im))/(i-im);
				y0=x(i)-a*i;
			end
		else	% im>1
			while 1
				a=(x(i)-x(im))/(i-im);
				y0=x(i)-a*i;
				if (im-1)*a+y0<x(im-1)
					im=im-1;
				elseif (i+1)*a+y0<x(i+1)
					i=i+1;
					if i==length(x)
						while (im-1)*a+y0<x(im-1)
							im=im-1;
							a=(x(i)-x(im))/(i-im);
							y0=x(i)-a*i;
							if im==1
								break
							end
						end
						break
					end
				else
					break;
				end
			end	% while
		end	% else (im>1)
		a=(x(i)-x(im))/(i-im);
		y0=x(i)-a*i;
		y(im+1:i-1)=(im+1:i-1)'*a+y0;
		y(i)=x(i);
		im=i;
		doeInter=0;
	end   % if doeInter
	i=i+1;
end
if im==length(x)-1
	y(length(x))=x(length(x));
elseif im<length(x)
	y(im+1:length(x))=interp1([im length(x)],[y(im) x(length(x))],im+1:length(x));
end
status;
