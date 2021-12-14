function f=an2f(x,dt,rfilt,npuls)
% AN2F     - Omzetting van "ruw frequentie-signaal" naar frequentie
%    f=and2f(x,dt,rfilt,npuls)
%         x : analoog frequentie signaal
%         dt : sample tijd
%         rfilt (als gegeven) : relatieve filterfrequentie
%              (als 0 geen filtering)
%         npuls (als gegeven) : meten over npuls pulsen

if ~exist('rfilt')|isempty(rfilt)
	rfilt=0.15;
end
if ~exist('npuls')|isempty(npuls)
	npuls=1;
end

x=x-mean(x);
A=max(x)-min(x);
minA=A/100;

%x=((x>minA)|(x<-minA)).*x;

xCS=cumsum(abs(x));
xnulstijg=(x(1:end-1)<0)&(x(2:end)>=0);
xnulstijg(1:5)=0;	% vereenvoudiging van het volgende (met marge) : eerste nuldoorgangen
	% worden niet meegeteld
xnulstijg(end-3:end)=0;	% hetzelfde als in het begin
dgx=zeros(size(x));
inulstijg=find(xnulstijg);
if npuls>1
	inulstijg=inulstijg(1:npuls:end);
end
dgx(inulstijg(1))=xCS(inulstijg(1));
dgx(inulstijg(2:end))=xCS(inulstijg(2:end))-xCS(inulstijg(1:end-1));
xCS=xCS-cumsum(dgx);

inulstijg(find(xCS(inulstijg-1)<minA*5))=[];

tnulstijg=(inulstijg-1-x(inulstijg)./(x(inulstijg+1)-x(inulstijg)))*dt;
dtnulstijg=min(0.2,diff(tnulstijg));
df=zeros(size(x));
if rfilt>0
	try
		[B,A]=butter(2,rfilt);
		fnulstijg=filtfilt(B,A,1./dtnulstijg);
	catch
		warning('!!signal toolbox niet beschikbaar!! Vereenvoudigde manier gebruikt.!!')
		A=[1 -1.866892279712 0.875214548254];
		B=[0.002080567135 0.004161134271 0.002080567135];
		fnulstijg=filter(B,A,1./dtnulstijg);
	end
else
	fnulstijg=1./dtnulstijg;
end
df(inulstijg(2:end-1))=diff(fnulstijg);
df(inulstijg(1))=fnulstijg(1);
f=cumsum(df)*npuls;
