function updmetlijst(ffor,fn,doopen,d0)
% UPDMETLIJST - Update lijst van metingen
%   updmetlijst[(ffor[,fn[,doopen[,d0]]])]
%      ffor : formaat van files (default '*.dat')
%      fn : lijst met events (default 'metingen.txt')
%      d0 : vanaf welke datum

if nargin<1|isempty(ffor)
	ffor='*.dat';
end
if nargin<2|isempty(fn)
	fn='metingen.txt';
end

if ~any(fn==filesep)
	fn=zetev([],fn);
end
if ~exist('d0','var')|isempty(d0)
	d=dir(fn);
	if isempty(d)
		d0='1-jan-1990';
	else
		d0=d(1).date;
	end
end
dd0=datenum(d0);
d=dir(zetev([],ffor));
dd=datenum({d.date});
[dd,i]=sort(dd);
d=d(i);
II=find(dd>dd0);
if ~isempty(II)
	diary(fn)
	for j=1:length(II)
		i=II(j);
		fprintf('%-20s (%s) : ',d(i).name,d(i).date);
		e=leesalg(d(i).name,0,0);
	end
	diary off
end
if nargin>2&doopen
	edit(fn)
end
