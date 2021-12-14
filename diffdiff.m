function df=diffdiff(f,h,n)
% DIFFDIFF - numerieke differentiatie adhv voorwaartse differenties

if ~exist('h');h=[];end
if ~exist('n');n=2;end

if isempty(h)
 h=1;
end
if size(f,1)==1
 f=f';
 lf=1;
else
 lf=0;
end

nullen=zeros(1,size(f,2));
Df=[diff(f);nullen];
df=Df;
s=1;
for i=2:n
 s=-s;
 Df=diff([Df;nullen]);
 df=df+s/i*Df;
end

if lf
 df=df';
end
df=df/h;