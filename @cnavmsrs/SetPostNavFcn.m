function c=SetPostNavFcn(c,fcn)
%cnavmsrs/SetPostNavFcn - Set post-navigate-function
%    [c=]SetPostNavFcn(c,fcn)
%        fcn: function handle of a function: fcn(hFig,nr)

c.opties.postNavFcn=fcn;
%set(c.fig,'UserData',c) - not required anymore
if nargout==0
	clear c
end
