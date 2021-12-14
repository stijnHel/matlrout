function r=vertcat(varargin)
varargin
if nargin==1
    r=varargin{1};
else   
    rD=zeros(size(varargin{1}));
    rP=rD;    
    for i=1:nargin
        a=long(varargin{i});
        rD=[rD;a.decimales];
        rP=[rP;a.potencia];
    end
    rD(1,:)=[];
    rP(1,:)=[];
    r=long(rD,rP);
end
