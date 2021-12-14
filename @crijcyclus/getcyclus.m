function cyc=getcyclus(c)
% CRIJCYCLUS/GETCYCLUS - Geeft rijcyclus
%    snelheid wordt gegeven in km/h(!!!)

cyc=c.Vlijst;
cyc(:,2)=cyc(:,2)*3.6;