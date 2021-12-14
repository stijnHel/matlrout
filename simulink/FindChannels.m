function IC=FindChannels(D,t,V,varargin)
%FindChannels - Find channels with approximate values (relative)
%       IC=FindChannels(D,t,V,varargin)
%
% made for simscape logs (see GetAllSLLogs)

rLim=0.001;
if nargin>3
	setoptions({'rLim'},varargin{:})
end

VD=zeros(1,length(D));
for iC=1:length(D)
	VD(iC)=interp1(D(iC).Data(:,1),D(iC).Data(:,2),t);
end
IC=cell(1,length(V));
B=false(1,length(D));
for iV=1:length(V)
	for iC=1:length(D)
		B(iC)=~isnan(VD(iC))&&abs(VD(iC)-V(iV))<=V(iV)*rLim;
	end
	IC{iV}=find(B);
end

if length(IC)==1
	IC=IC{1};
end