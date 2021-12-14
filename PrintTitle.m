function PrintTitle(tit,cUnderline,fid)
%PrintTitle - Print title with text-underline
%    PrintTitle(<title>[,cUnderline[,fid]])
%
% Print <title> (using fprintf), followed by a line of underline
% characters.
% If cUnderline is not given (or empty), '-' is used.
% cUnderline can be numeric (for fixed order of underlining):
%      (1:)'-' '=' '+' '*'

if nargin<3||isempty(fid)
	fid=1;
end
if nargin<2||isempty(cUnderline)
	cUnderline='-';
elseif isnumeric(cUnderline)
	fixedOrder='-=+*';
	cUnderline=fixedOrder(max(1,min(end,round(cUnderline))));
end

fprintf(fid,'%s\n%s\n',tit,cUnderline(1,ones(1,length(tit))));
