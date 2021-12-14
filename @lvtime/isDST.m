function bST=isDST(t)
%lvtime/isDST - Is Daylight Saving Time?
%  bST=isDST(t)

bST=isDST(datenum(t,true,false));
