function [D,sInfo]=intsrdata(X,varargin)
%intsrdata - Interpretes SR-motor control data from CAN log
%    D=intsrdata(<fnama>,options);
% or
%    D=intsrdata(X,options...)
%        with X result from readcantrace (or similar structure)
%   D is a structure array with data for each type of data
%        options are pairs of name and data
%
%   only one option possible:
%      'bExtra' : if true, the function gives some infmation in the command
%                 window, the same info is given in a second output
%                 argument ([D,sInfo]=intsrdata(....)
%
%    See also readcantrace

global msgGroupData msgData

if ischar(X)
	X=readcantrace(X);
end

bExtraInfo=false;

if ~isempty(varargin)
	setoptions({'bExtraInfo'},varargin{:})
end

ID=uint32(X.ID);
msgGroup=bitand(ID,126)/2;
tx=bitand(ID,1);
subnode=bitand(ID,256)/256;

msgGroupData={	...
	32,'WOM','send motion messages to the drive';
	33,'RWM','manipulate control parameters of the drive';
	34,'ROM','get actual info about the drive';
	35,'RWM','get drive status';
	36,'WOM','update drive info';
	37,'RWM','send read/write motion messages';
	38,'RWM','ask master to do something'};
msgData={	...
	32, 0,'bytes',0,'activate/deactivate';
	32, 1,'bytes',0,'control mode';
	32, 2,0.001,1,'speed request';
	32, 3,1,1,'torque request';
	32, 4,1/65536,1,'current request';
	32, 5,0.01,1,'position offset';
	32, 6,[4,0.01;2,0.01],1,'position offset with reference';
	32, 7,1/65536,1,'manual current';
	32, 8,1,0,'manual time';
	32, 9,1,0,'phases';
	32,10,[2 1;2 1],0,'tracking scale factor';
	32,11,1,0,'brake';
	32,12,1,0,'set absolute encoder position';
	32,13,1,0,'enable mask';
	33, 0,[2 1;2 1],0,'Kp';
	33, 1,[2 1;2 1],0,'Ki';
	33, 2,[2 1;2 1],0,'Ke';
	33, 3,[2 1],0,'Kp_dest';
	33, 4,[2 1],0,'Ki_dest';
	33, 5,[2 1],0,'Kv_dest';
	33, 6,[2 1],0,'smoothing time';
	33, 7,[2 1],0,'position tolerance';
	33, 8,[2 1],0,'position tolerance time';
	33, 9,[2 1],0,'speed max during running timeout';
	33,10,[2 1],0,'speed limit time';
	34, 0,0.001,1,'actual motor speed';
	34, 1,0.001,1,'actual encoder speed';
	34, 2,0.01,0,'actual motor position';
	34, 3,0.01,0,'actual encoder position';
	34, 4,0.01,1,'actual encoder position error';
	34, 5,0.01,1,'motor dissipation';
	34, 6,1,1,'actual motor torque';
	34, 7,1,0,'actual absolute encoder position';
	35, 0,1,0,'info status bits';
	35, 1,1,0,'error status bits';
	35, 2,[2 1],0,'update time base';
	35, 3,1,0,'status interest mask';
	36, 0,1,0,'info-status';
	36, 1,1,0,'error-status';
	37, 0,'bytes',0,'ADC input setup';
	37, 1,[1 1;2 1],0,'tracking data';
	37, 2,[4 0.001],0,'speed limit';
	37, 3,[4 0.01],0,'position error limit';
	37, 4,[4 0.01],0,'position error limit - pos control&holding';
	37, 5,[2 1],0,'maximum positive torque';
	37, 6,[2 1],0,'maximum negative torque'
	37, 7,1,0,'test mode';
	37, 8,1,0,'current profiling flag';
	37, 9,[2 1;2 1],0,'motor/encoder revolutions ratio';
	37,10,[4 1],0,'acceleraration in speed mode';
	37,11,[4,1],0,'deceleration in speed mode';
	37,12,[4 1],0,'acceleration';
	37,13,[4 1],0,'deceleration';
	37,14,[4 1],0,'encoder type';
	38, 0,[1 1],0,'open/close brake';
	};

mdID=cat(2,msgData{:,1});
mdM=cat(2,msgData{:,2});
nMD=size(msgData,1);
nD=zeros(1,nMD);
D=struct('type',num2cell(1:nMD),'t',[],'D',[],'i',[]);
be=[16777216;65536;256;1];
for i=1:nMD
	b=msgGroup==mdID(i)&X.D(:,1)==mdM(i)&X.n>1;
		% X.n>1 added to have only real data(!) not the requests
	j=find(b);
	D(i).t=X.t(b);
	D(i).i=j;
	md=msgData{i,3};
	bSigned=msgData{i,4};
	if ischar(md)
		D(i).D=X.D(b,:);
	else
		D(i).D=zeros(length(j),size(md,1));
		if length(md)==1	% simple scaled data, variable byte length
			for k=1:length(j)
				n=X.n(j(k))-1;
				d=X.D(j(k),2:n+1)*be(5-n:4);
				if bSigned&&d>=2^(n*8-1)
					d=d-256^n;
				end
				D(i).D(k)=d*md;
			end
		else	% more complex data or fixed byte size
			nmd=size(md,1);
			% [nBytes1 scale1;nBytes2 scale2;...]
			S=zeros(sum(md(:,1)),nmd);
			iS=0;
			for k=1:nmd
				S(iS+1:iS+md(k),k)=be(5-md(k):4);
				iS=iS+md(k);
			end
			D(i).D=X.D(j,2:iS+1)*S;
		end
	end
end
%voorlopig geen msg-aparte data
%for i=1:length(X.t)
%	j=find(mdID==msgGroup(i)&mdM==X.D(i));
%end

if bExtraInfo
	nD=cellfun('length',{D.t});
	d=find(nD);
	for i=1:length(d)
		fprintf('%2d : (%5d msgs) - %s\n',d(i),length(D(d(i)).t),msgData{d(i),5})
	end
end

if nargout>1
	sInfo='';
	nD=cellfun('length',{D.t});
	d=find(nD);
	for i=1:length(d)
		sInfo=[sInfo sprintf('%2d : (%5d msgs) - %s\n',d(i),length(D(d(i)).t),msgData{d(i),5})];
	end
end
