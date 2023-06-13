function fcn = MultiCallbackFcn(varargin)
%MultiCallbackFcn - Callback function combining multiple callback functions
%   This function makes it possible to use multiple callback functions of
%   graphical objects.  Create a function instance of this function, with
%   the set of callback functions, and use this as callback function for
%   the graphical object.
%
%   fcn = MultiCallbackFcn(fcn1,fcn2,...);
%       fcn<i> are supposed to be function_handle's, but it's also allowed
%          to have strings.
%
%   Extension:
%         MultiCallbackFcn('set',<handle>,<propertiy>,fcn1,fcn2,...);
%
%   Example:
%      fig = figure;
%      f1 = @(h,ev) disp('callback1');
%      f2 = @(h,ev) disp('callback2');
%      f = MultiCallbackFcn(f1,f2);
%      set(fig,'KeyPressFcn',f)
%   or with the extension of this function:
%      fig = figure;
%      f1 = @(h,ev) disp('callback1');
%      f2 = @(h,ev) disp('callback2');
%      MultiCallbackFcn('set',fig,'KeyPressFcn',f1,f2);

if ischar(varargin{1}) && strcmp(varargin{1},'set')
	h = varargin{2};
	prop = varargin{3};
	f = MultiCallbackFcn(varargin{4:end});
	for i=1:length(h)
		if ischar(prop)
			prop = {prop};
		end
		for j = 1:length(prop)
			set(h(i),prop{j},f)
		end
	end
	return
end
for i=1:length(varargin)
	if ~ischar(varargin{i}) && ~isa(varargin{i},'function_handle')
		error('Wrong callback-function?!')
	end
end
fcn = [{@CombinedCallback},varargin];

function CombinedCallback(h,ev,varargin)
for i = 1:length(varargin)
	if ischar(varargin{i})
		eval(varargin{i})
	else
		varargin{i}(h,ev)
	end
end
