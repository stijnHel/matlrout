function n=nsecond(dag,maand,jaar,uur,min,sec)
% NSECOND - Bepaal aantal seconden vanaf 1 maart 1700, 0:00:00

if nargin==0;help nsecond;return;end
if nargin==1
	sec=dag(6);
	min=dag(5);
	uur=dag(4);
	jaar=dag(3);
	maand=dag(2);
	dag=dag(1);
elseif nargin==3
	uur=0;
	min=0;
	sec=0;
end
if maand<3;maand=maand+13;jaar=jaar-1;else maand=maand+1;end
n=((((floor(jaar*365.25)+floor(maand*30.6)+dag-621049)*24+uur)*60)+min)*60+sec;
