function [d,i]=sortdirdate(d,field)
%SORTDIRDATE - Sorteert directory (of andere struct) op basis van datum

if ~exist('field','var')||isempty(field)
	field='date';
end

numdates=datenum({d.(field)});
[numdates,i]=sort(numdates);
d=d(i);
