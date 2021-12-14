function r=horzcat(varargin)
if nargin==1
    r=varargin{1};
else
    rD=0;
    rP=0;
    for i=1:nargin
        a=long(varargin{i});
        rD=[rD,a.decimales];
        rP=[rP,a.potencia];
    end
    rD(1)=[];
    rP(1)=[];
    r=long(rD,rP);
end
