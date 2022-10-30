function X=InterpretCANOPEN(in,varargin)
%InterpretCANOPEN - Interpret canopen-messages
%    X=InterpretCANOPEN(IXXAT-logfile)
%    X=InterpretCANOPEN(<leesIXXATtrace-struct>)

[bExtendedLabel]=false;
[bData] = false;
[bFillGaps] = false;
if nargin>1
	setoptions({'bExtendedLabel','bData','bFillGaps'},varargin{:})
end

if ischar(in)
	[~,~,fExt] = fileparts(in);
	if strcmpi(fExt,'.bin')
		X = ReadCANLOG(in);
	elseif strcmpi(fExt,'.csv')||strcmpi(fExt,'.txt')
		X=readIXXATtrace(in);
	else
		error('Unknown file format!')
	end
elseif isfield(in,'ssm')	% cancon-data (IXXATcom)
	D = zeros(length(in),9);
	D(:,1) = [in.dlc];
	for i=1:length(in)
		D(i,2:length(in(i).data)+1) = in(i).data;
	end
	X = struct('T',[in.time]	...
		,'ID',[in.ID]	...
		,'D',D);
elseif length(in)>1&&isstruct(in)&&isfield(in,'ID')
	if isfield(in,'t')
		T = [in.t];
	elseif isfield(in,'time')
		T = [in.time];
	else
		T = 0:length(in)-1;
	end
	X = struct('T',T,'ID',[in.ID],'D',zeros(length(in),9),'bSent',[in.bOut]);
	for i=1:length(in)
		X.D(i) = length(in(i).D);
		X.D(i,2:1+length(in(i).D)) = in(i).D;
	end
else
	X=in;
end
if size(X.D,1)==8&&isfield(X,'DLC')
	X.D=[X.DLC(:),X.D'];
elseif size(X.D,2)==8&&isfield(X,'DLC')
	X.D=[X.DLC(:),X.D];
end

SNMTservices={1,'Start_RemoteNode';
	  2,'Stop_RemoteNode';
	128,'Enter_Pre_Operational_State';
	129,'Reset_Node';
	130,'Reset_Communication'};
Sstates={0,'Initializing';
	  1,'Disconnected';
	  2,'Connecting';
	  3,'Preparing';
	  4,'Stopped';
	  5,'Operational';
	127,'Pre-Operational'};

fcnCode = min(15,floor(X.ID/128));
X.fcnCode=enum_COfcnCode(fcnCode);
X.nodeID=rem(X.ID,128);
X.coInterp=cell(size(X.ID));
B_SDO = fcnCode==11 | fcnCode==12;
X.SDOobIdx=nan(length(X.ID),1);
X.SDOobSidx=X.SDOobIdx;
X.SDOobIdx(~B_SDO) = 0;
X.SDOobSidx(~B_SDO) = 0;
X.SDOval=X.SDOobIdx;
xI16=[1;256];
xI32=[1;256;65536;16777216];

for i=1:length(X.ID)
	if X.ID(i)<0	% error indication?
		% do nothing
	elseif X.ID(i)>0&&X.ID(i)<256	% no CANOPEN
	elseif X.ID(i)>=0
		switch X.fcnCode(i)
			case 0	% NMT
				if X.D(i)<2
					warning('NMT with too low number of data bytes! (#%d - %d)'	...
						,i,X.D(i))
				else
					iNMT=find([SNMTservices{:,1}]==X.D(i,2));
					if isempty(iNMT)
						warning('Unknown NMT command specifier! (#%d - %d)'	...
							,i,X.D(i,2));
					else
						X.coInterp{i}=sprintf('NMT - %s - node %d'	...
							,SNMTservices{iNMT,2},X.D(i,3));
					end
				end
			case 1	% SYNC / emergency
				switch X.nodeID(i)
					case 0	% SYNC
						X.coInterp{i}=sprintf('SYNC');
					otherwise
						if X.D(i)<8
							warning('EMCY with too low number of databytes! (#%d - %d)'	...
								,i,X.D(i))
						else
							errCode=double(X.D(i,2:3))*xI16;
							errReg=X.D(i,4);
							elmoErrCode=X.D(i,5);
							errData1=double(X.D(i,6:7))*xI16;
							errData2=double(X.D(i,8:9))*xI16;
							X.coInterp{i}=sprintf('EMCY - ID 0x%02x - 0x%04x 0x%02x 0x%02x - data 0x%04x 0x%04x'	...
								,X.ID(i),errCode,errReg,elmoErrCode,errData1,errData2);
						end
				end
			case 2	% TIME STAMP
				tttt=0;
			case {3,5,7,9}	% PDO<i> tx
				%!!!not implemented!!!
				X.coInterp{i}=sprintf('PDO<%d> tx: %d %02x %02x %02x %02x   %02x %02x %02x %02x'	...
					,(X.fcnCode(i)-3)/2,X.D(i,1:X.D(i)+1));
				PDOtx=0;
			case {4,6,8,10}	% PDO<i> rx
				X.coInterp{i}=sprintf('PDO<%d> rx: %d %02x %02x %02x %02x   %02x %02x %02x %02x'	...
					,(X.fcnCode(i)-4)/2,X.D(i,1:X.D(i)+1));
				PDOrx=0;
			case 11	% SDO tx
				if X.D(i)~=8
					warning('SDO with <8 data bytes?! - #%d',i)
				else
					cs=X.D(i,2);
					Oidx=double(X.D(i,3:4))*xI16;
					OsIdx=X.D(i,5);
					X.SDOobIdx(i)=Oidx;
					X.SDOobSidx(i)=OsIdx;
					switch floor(cs/32)
						case 3	% initiate domain download <--server
							X.coInterp{i}=sprintf('SDO initiated domain download - 0x%X.0x%X',Oidx,OsIdx);
						case 1	% download domain segment <--server
							t=bitand(cs,32)/32;
							X.coInterp{i}=sprintf('SDO download domain segment (%d) - 0x%X.0x%X',t,Oidx,OsIdx);
						case 2	% initiate domain upload
							e=bitand(cs,2);
							s=bitand(cs,1);
							if e&&s
								n=bitand(cs,12)/4;
							else
								n=0;
							end
							if e
								v=double(X.D(i,6:9-n))*xI32(1:4-n);
								sData=sprintf('0x%X',v);
								X.SDOval(i)=v;
							else
								sData=sprintf('#%d',double(X.D(i,6:9))*xI32);
							end
							X.coInterp{i}=sprintf('SDO initiated domain upload - 0x%X.0x%X - %s',Oidx,OsIdx,sData);
						case 0	% upload domain segment <--server
							t=bitand(cs,32)/32;
							n=bitand(cs,14)/2;
							c=bitand(cs,1);
							sData=sprintf('%02x',X.D(i,9-n:-1:6));
							if c
								sData=[sData 'endDownload']; %#ok<AGROW>
							end
							X.coInterp{i}=sprintf('SDO upload domain segment (%d) - 0x%X.0x%X - %s',t,Oidx,OsIdx,sData);
						case 4	% abort domain transfer
							X.coInterp{i}=sprintf('SDO abort domain transfer - 0x%X.0x%X - %02X%02X %02X%02X'	...
								,Oidx,OsIdx,X.D(i,9:-1:6));
						case 5	% initiate block download <--server
							sc=bitand(cs,4)>0;
							X.coInterp{i}=sprintf('SDO initiate block download - 0x%X.0x%X - CRC? %d, blocksize %d'	...
								,Oidx,OsIdx,sc,X.D(i,6));
					end
				end
			case 12	% SDO rx
				if X.D(i)~=8
					warning('SDO with <8 data bytes?! - #%d',i)
				end
				cs=X.D(i,2);
				Oidx=double(X.D(i,3:4))*xI16;
				OsIdx=X.D(i,5);
				X.SDOobIdx(i)=Oidx;
				X.SDOobSidx(i)=OsIdx;
				switch floor(cs/32)
					case 1	% initiate domain download client-->
						e=bitand(cs,2);
						s=bitand(cs,1);
						if e&&s
							n=bitand(cs,12)/4;
						else
							n=0;
						end
						if e
							v=double(X.D(i,6:9-n))*xI32(1:4-n);
							sData=sprintf(['0x%0' num2str((4-n)*2) 'X'],v);
							X.SDOval(i)=v;
						else
							sData=sprintf('#%d',double(X.D(i,6:9))*xI32);
						end
						X.coInterp{i}=sprintf('SDO initiate domain download - 0x%X.0x%X - %s',Oidx,OsIdx,sData);
					case 0	% download domain segment client-->
						t=bitand(cs,32)/32;
						n=bitand(cs,14)/2;
						c=bitand(cs,1);
						sData=sprintf('%02x',X.D(i,9-n:-1:6));
						if c
							sData=[sData 'endDownload']; %#ok<AGROW>
						end
						X.coInterp{i}=sprintf('SDO download domain segment (%d) - 0x%X.0x%X - %s',t,Oidx,OsIdx,sData);
					case 2	% initiate domain upload
						X.coInterp{i}=sprintf('SDO initiate domain upload - 0x%X.0x%X',Oidx,OsIdx);
					case 3	% upload domain segment client-->
						t=bitand(cs,32)/32;
						X.coInterp{i}=sprintf('SDO upload domain segment (%d) - 0x%X.0x%X - %s',t,Oidx,OsIdx);
					case 4	% abort domain transfer
						X.coInterp{i}=sprintf('SDO abort domain transfer - 0x%X.0x%X - %02X%02X %02X%02X'	...
							,Oidx,OsIdx,X.D(i,9:-1:6));
					case 6	% initiate block download client-->
						sc=bitand(cs,4)>0;
						s=bitand(cs,2)>0;
						if s
							sData=sprintf('#%d',double(X.D(i,6:9))*xI32);
						else
							sData='#???';
						end
						X.coInterp{i}=sprintf('SDO initiate block download - 0x%X.0x%X - CRC? %d - %s'	...
							,Oidx,OsIdx,sc,sData);
				end
			case 14	% NMT err ctrl
				if X.D(i)==0	% NMT-Master --> NMT-Slave
					X.coInterp{i}=sprintf('NMT - state request - node %d',X.nodeID(i));
				elseif X.D(i,2)==0
					X.coInterp{i}=sprintf('NMT - node %d - Initializing'	...
						,X.nodeID(i));
				else	% NMT-Slave reply
					state=rem(X.D(i,2),128);
					iS=find([Sstates{:,1}]==state);
					if isempty(iS)
						sState='????';
					else
						sState=Sstates{iS,2};
					end
					X.coInterp{i}=sprintf('NMT - node %d - state reply (%d) %s'	...
						,X.nodeID(i),X.D(i,2)>127,sState);
				end
			otherwise
				warning('bad code? (#%d - %03x)',i,X.ID(i))
		end		% switch X.fcnCode
	end		% ID>=0
end

if bExtendedLabel
	cB=' ';
	for i=1:length(X.ID)
		DLC = X.D(i);
		X.coInterp{i} = [sprintf('%10.5f - %03x ',X.T(i)-X.T(1),X.ID(i))	...
			,sprintf(' %02x',X.D(i,2:1+DLC))	...
			,cB(1,ones(1,3*(8-X.D(i))))	...
			,' - ',X.coInterp{i}];
	end
end
if bData
	IDXext = X.SDOobIdx*256+X.SDOobSidx;
	[uIDXext,~,iIDX] = unique(IDXext);
	DataOut = nan(length(X.ID),length(uIDXext));
	DataIn = DataOut;
	for i=1:length(IDXext)
		if bFillGaps&&i>1
			DataOut(i,:)=DataOut(i-1,:);
			DataIn(i,:)=DataIn(i-1,:);
		end
		if ~isnan(X.SDOval(i))
			if X.fcnCode(i)==11	% SDOtx ==> DataOut
				DataOut(i,iIDX(i))=X.SDOval(i);
			else
				DataIn(i,iIDX(i))=X.SDOval(i);
			end
		end
	end
	X.IDXext = IDXext;
	X.uIDXext = uIDXext;
	X.DataOut = DataOut;
	X.DataIn = DataIn;
end
