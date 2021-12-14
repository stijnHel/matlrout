function [puit,tuit]=plotvar(var,v,g,gaslijnen,plaatsTekst)
% PLOTVAR - plot variogram
global speed_const iOD iLOW

if ~exist('v');v=[];end
if ~exist('g');g=[];end
if ~exist('gaslijnen');gaslijnen=[];end
if ~exist('plaatsTekst');plaatsTekst=[];end

if isempty(v)
	[v,g,var]=getmatr(var);
	var=var';
end

if isempty(speed_const)
	speed_const=190/10240;
end
if isempty(iOD)
	iOD=0.445;
end
if isempty(iLOW)
	iLOW=2.46;
end

vmax=200;
nmax=vmax/speed_const*iOD;

bZetTekst=(nargout>1) | ~isempty(plaatsTekst);
if bZetTekst
       if isempty(plaatsTekst)
              vtmax=vmax;
       elseif length(plaatsTekst)==1
              vtmax=plaatsTekst;
              plaatsTekst=[];
       end
end
pl=[];
tl=[];

if min(size(var))==1
       % plot tip-variogram
       if isempty(v)
              v=1500;
       end
       if isempty(g)
              g=5300;
       end
       minn=v;
       maxn=g;
       vmn=minn/var(1)*speed_const;
       vmx=maxn/var(1)*speed_const;
       pl=plot([vmn vmx vmx],[minn maxn vmx/speed_const*var(2)]);
       hold on
       for i=2:length(var)
              vmn=minn/var(i)*speed_const;
              vmx=maxn/var(i)*speed_const;
              nvorig=vmn/speed_const*var(i-1);
              if i<length(var)
                     nvolgend=vmx/speed_const*var(i+1);
              else
                     nvolgend=nmax;
              end
              pl=[pl ...
                     plot([vmn vmn vmx vmx],[nvorig minn maxn nvolgend])     ...
                     ];
       end
else
       if isempty(v)
              v=0:12.8:204.8;
       end
       if isempty(g)
              g=(0:16:256)/2.55;
       end
       
       if isempty(gaslijnen)
              gaslijnen=0:20:100;
       end
       v=v(:);
       g=g(:);
       
       if max(gaslijnen)>max(g)
              gaslijnen(length(gaslijnen))=max(g);
       end
       
       for i=1:length(gaslijnen)
              gas=gaslijnen(i);
              ig1=find(gas<g);
              if isempty(ig1)
                     ig1=length(g);
              end
              ig1=ig1(1);
              delta=(gas-g(ig1-1))/(g(ig1)-g(ig1-1));
              n1=((1-delta)*var(:,ig1-1)+delta*var(:,ig1));
              nstall=n1(1);
              vstall=nstall/iLOW*speed_const;
              dnLOW=n1-v/speed_const*iLOW;
              dnOD=n1-v/speed_const*iOD;
              j1=find(dnLOW<0);
              j1=j1(1);
              j2=find(dnOD>0);
              j2=j2(length(j2));
              nLow=table1([dnLOW(j1-1:j1) n1(j1-1:j1)],0);
              vLow=nLow/iLOW*speed_const;
              if vstall>=vLow
              	if vLow>=v(j1)
						vlijn=[0;vLow;v(j1+1:j2)];
						nlijn=[nstall;nLow;n1(j1+1:j2)];
              	else
						vlijn=[0;vLow;v(j1:j2)];
						nlijn=[nstall;nLow;n1(j1:j2)];
					end
              else
					vlijn=[0;vstall;vLow;v(j1:j2)];
					nlijn=[nstall;nstall;nLow;n1(j1:j2)];
              end
              if j2==length(n1)
                     nOD=n1(j2);
                     vOD=v(j2);
              else
                     nOD=table1([dnOD(j2:j2+1) n1(j2:j2+1)],0);
                     vOD=nOD/iOD*speed_const;
                     vlijn=[vlijn;vOD;vmax];
                     nlijn=[nlijn;nOD;nmax];
              end
              pl=[pl plot(vlijn,nlijn)];
              if length(pl)==1
                     hold on
              end
              if bZetTekst
                     if isempty(plaatsTekst)
                            vt=vtmax/length(gaslijnen)*(i-0.5);
                     else
                            vt=plaatsTekst(i);
                     end
                     nt=table1([vlijn nlijn],vt)+30;
                     t1=text(vt,nt,sprintf('%3.0f %%',gas)     ...
                            ,'HorizontalAlignment','center','VerticalAlignment','bottom');
                     tl=[tl t1];
              end
       end
end
hold off
grid
title('Variogram');
xlabel('speed [kph]')
ylabel('engine rpm [rpm]')
axis([0 vmax 0 6000])
if nargout>0
       puit=pl;
       if nargout>1
              tuit=tl;
       end
end