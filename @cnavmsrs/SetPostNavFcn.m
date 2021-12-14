function c=SetPostNavFcn(c,fcn)
%cnavmsrs/SetPostNavFcn - Set post-navigate-function
%    [c=]SetPostNavFcn(c,fcn)

c.opties.postNavFcn=fcn;
set(c.fig,'UserData',c)
if nargout==0
	clear c
end
