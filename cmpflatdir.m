function [g1,g2,dubbels1,dubbels2,X1,X2]=cmpflatdir(X10,X20)
% CMPFLATDIR - vergelijkt "vlak gemaakte directory"
%     [g1,g2,dubbels1,dubbels2,X1,X2]=cmpflatdir(X10,X20)
% zie ook hierdir

X1=sort(flattenDir(X10),'name');
X2=sort(flattenDir(X20),'name');
i1=1;
i2=1;
dubbels1=zeros(1,length(X1));
dubbels2=zeros(1,length(X2));
g1=dubbels1;
g2=dubbels2;
while i1<=length(X1)&&i2<=length(X2)
    i10=i1;
    i20=i2;
    while i1<length(X1)&&strcmp(X1(i1).name,X1(i1+1).name)
        i1=i1+1;
        dubbels1(i1)=dubbels1(i1-1)+1;
    end
    while i2<length(X2)&&strcmp(X2(i2).name,X2(i2+1).name)
        i2=i2+1;
        dubbels2(i2)=dubbels2(i2-1)+1;
    end
    v=strcmpc(X1(i1).name,X2(i2).name);
    if v<0
        i1=i1+1;
    elseif v>0
        i2=i2+1;
    else
        g1(i10:i1)=i2;
        g2(i20:i2)=i1;
        i1=i1+1;
        i2=i2+1;
    end
end
if nargout==1
    g1=struct('g1',g1,'g2',g2,'dubbels1',dubbels1,'dubbels2',dubbels2	...
		,'X1',X1,'X2',X2	...
		);
end
