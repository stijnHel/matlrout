function installOpti(v,varargin)
%installOpti - Install optitoolbox
%        installOpti(v)
%            version (default [1 77] --> 1.77)

if nargin>1
	v=[v varargin{:}];
end

if nargin==0||isempty(v)
	v=[1 77];
elseif isscalar(v)
	v=[floor(v) (v-floor(v))*100];
	i=1;
	while abs(v(2)-round(v(2)))>1e-8
		v(2)=v(2)*10;
	end
end
d=pwd;
cd(sprintf('C:\\Users\\shel\\Documents\\MATLAB\\OptiToolbox_v%d.%02d\\',v))
opti_Install
cd(d)
