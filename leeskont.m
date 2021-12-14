function [kanalen,dt,t] = leeskont(meting,kannr,schalen)
%LEESKONT - Leest kontrongegevens.
%  [kanalen,dt,t] = leeskont(meting,kannr,schalen)
%  met
%    meting is metingnummer (dit mag slechts een nummer zijn)
%    kannr is kanaalnummer (dit mogen meerdere kanaalnummers zijn)
%    schalen zijn de schalen van de verschillende kanalen (er moeten evenveel
%      schalen gegeven worden als kanalen)
%
%    kanalen is een matrix met per rij een meting.  Het eerste opgevraagde kanaal
%      (niet noodzakelijk kanaal 1) staat in de eerste kolom.
%    dt is de tijdschaal
%    t is een vector die de tijdas weergeeft.

global EVDIR LASTMET LASTKAN LASTSCHAL
if ~exist('kannr') & (LASTKAN~=[])
  kannr=LASTKAN;
end
if ~exist('schalen') & (LASTSCHAL~=[])
  schalen=LASTSCHAL;
end
LASTMET=meting;
LASTKAN=kannr;
LASTSCHAL=schalen;
if isstr(meting)
	smet=meting;
else
	smet=int2str(meting);
	while length(smet)<2
	   smet=['0' smet];
	end
end
kanalen=[];
for i=1:length(kannr)
   if isstr(meting)
     fnaam=[EVDIR smet];
   else
	 skan=int2str(kannr(i));
     fnaam=[EVDIR '0000', smet, '0', skan, '.001'];%!!!!!!!!!!!!!!!!!!!!
	 %fnaam=[EVDIR '0001', smet, '0', skan, '.001'];
   end
   fkanaal=fopen(fnaam);
   disp(fnaam)
   kanaal=fread(fkanaal,'uchar');
   fclose(fkanaal);
   if (nargout>1) & i==1
     if length(kanaal)<640
       error('meting is korter dan mogelijk !')
     end
     fact=[1e-6 1e-3 1];
     if kanaal(24)>3
       error('De gebruikte tijdschaal is hier onbekend')
     end
     dt=kanaal(22)*256+kanaal(23)*fact(kanaal(24)+1);
     fact=kanaal(25)*256+kanaal(26);
     if fact>0
       disp('Ik weet niet of de tijdschaal juist bepaald werd.')
       dt=dt*fact*10;
     end
     if nargout>2
       t=dt*(0:(length(kanaal)-128)/2-1);
     end
   end
   kanaal=reshape(kanaal,2,length(kanaal)/2)';
   kanalen=[kanalen (kanaal(65:length(kanaal),1)*256 ...
                    +kanaal(65:length(kanaal),2))/65536*schalen(i)];
end
