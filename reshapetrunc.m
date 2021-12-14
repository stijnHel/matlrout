function x=reshapetrunc(x,varargin)
%reshapetrunc - reshape with truncation of last part
%    same as reshape function, but if the full array can't be split in the
%       new sizes, it is truncated
%   Y = reshapetrunc(X,m,n,...)
% or
%   Y = reshapetrunc(X,[m,n,...])
%
% in the first format, one dimension can be empty.  in that case it is
% calculated from the original arraysize
%
% Normally the size can only be reduced.  There is one special case:
%    m=0.  Then, if necessary, the array is expanded with zeros.  In that
%    case, no default dimension size can be given.
%    Alternative method to force expansion rather than truncation:
%         reshapetrunc(X,...,'bExpand',true)
%    or shorter
%         reshapetrunc(X,...,'-bExpand')

bExpand=false;
if nargin==2||length(varargin{1})>1
	mn=double(varargin{1});	% double because prod(mn) doesn't work with integers
	if length(mn)==1
		x=x(:);
		return
	end
	if length(varargin)>1
		setoptions({'bExpand'},varargin{2:end})
	end
else
	mnC=varargin;
	nArgs=length(mnC);
	for i=1:nArgs
		if ischar(mnC{i})
			nArgs=i-1;
			mnC=mnC(1:nArgs);
			break
		end
	end
	if length(varargin)>nArgs
		setoptions({'bExpand'},varargin{nArgs+1:end})
	end
	is0=cellfun('isempty',mnC);
	if any(is0)
		if ~is0(1)&&mnC{1}==0
			bExpand=true;
			is0(1)=[];
			mnC(1)=[];
		end
		i=find(is0);
		if length(i)>1
			error('Only one unknown dimension can be given')
		end
		mn=double(cat(2,mnC{:}));
		if bExpand
			mnC{i}=ceil(numel(x)/prod(mn));
		else
			mnC{i}=floor(numel(x)/prod(mn));
		end
	end
	mn=double(cat(2,mnC{:}));
end
if mn(1)==0
	bExpand=true;
	mn(1)=[];
end
if prod(mn)<numel(x)
	%if length(mn)>2
	%	x=x(1:end-rem(end,mn(1)),:);
	%end
	x=x(1:prod(mn));
elseif prod(mn)>numel(x)
	if bExpand
		x=x(:);
		x(prod(mn))=0;
	else
		error('Can''t expand the array (see option "0")')
	end
end
x=reshape(x,mn);
