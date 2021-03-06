function [IDS,INFO,sINFO]=canmsgs(x,x2,x3)
% CANMSGS  - bekijkt ID's en kijkt na welke boodschappen
%    [ids]=canmsgs(x,x2,x3)
%       initialisatie : canmsgs('init',<proj>)
%                     proj : 'oxford','athena','ecu'(oude),'tucson'
%             canmsgs('limit',<limits>)
%                   {ID1,[item1,item2,...];...}
%                of {'data1','data2',...}
%                of 'min'
%             canmsgs('limitIDs',<messages>))
%                      [ID1, ID2, ...] of {'HCU1', 'TCU1' ...}
%       ids=canmsgs(x) met x=[IDs databytes tijd]
%            geeft lijst van aanwezige boodschappen met informatie van inhoud
%       [e,info,sINFO]=canmsgs({lijst van gewenste boodschappen},x)
%            met x de array met CAN-data ([IDs databytes tijd] (van monitor-prog
%                           of [tijd IDs nBytes databytes])
%            interpreteert CAN-data
%     als x3 gegeven is en niet nul : ruwe data wordt gegeven

persistent msgs msgsinit B_OLDCANSPEC
if nargin==0
	IDS=msgs;
	return
end
if isempty(msgs)&&(isempty(x)||~ischar(x)||~strcmp(x,'init')||~exist('x2','var')||isempty(x2))
	defmsgs='tucson';
	fprintf('Default can messages (%s)!\n',defmsgs);
	canmsgs('init',defmsgs)
	if exist('x2','var')&&strcmp(x2,'init')
		return
	end
end
if ischar(x)&&strcmp(x,'struct')
	IDS=struct('ID',msgs(:,1),'naam',msgs(:,2),'n',[],'structure',msgs(:,3));
	return
elseif ischar(x)&&strcmp(x,'limitIDs')
	if ischar(x2)
		x2={x2};
	end
	if isnumeric(x2)
		IDs=cat(2,msgs{:,1});
		k=true(1,length(IDs));
		for i=1:length(IDs)
			k(i)=any(IDs(i)==x2);
		end
	else
		k=[];
		for i=1:length(x2)
			k1=strmatch(x2{i},msgs(:,2));
			if ~isempty(k1)
				k=[k;k1];
			end
		end
	end
	msgs=msgs(k,:);
	return
elseif ischar(x)&&strcmp(x,'limit')
	if ischar(x2)
		switch x2
		case 'min'
			if isempty(msgsinit)
				error('canmsgs(''limit'',''min'') kan alleen gebruikt worden na initialisatie')
			end
			switch msgsinit
			case 'tucson'
			case 'oxford'
				x2={'R_SVehTcuC','R_TeCvtC','F_CltEnInhC'};
			otherwise
				error('Geen ''min''-definitie voor dit project bepaald')
			end
			canmsgs('limit',x2)
		end
	elseif iscell(x2)&&all(cellfun('isclass',x2,'char'))
		IDsOK=cell(1,size(msgs,1));
		sigs=cat(2,msgs{:,3});
		signames={sigs.signal};
		nsigs=cellfun('length',msgs(:,3));
		snsigs=[0;cumsum(nsigs)];
		for i=1:length(x2)
			j=strmatch(x2{i},signames,'exact');
			if isempty(j)
				warning('CANMSGS:SigNotFound','!!kon %s niet vinden!!',x2{i})
			else
				if length(j)>1
					warning('CANMSGS:MultipleMsg','!!%s werd meerdere keren (%d) gevonden!!',x2{i},length(j))
				end
				for k=1:length(j)	% voor als er meerdere variabele gevonden zijn
					m=find(j(k)<=snsigs);
					m=m(1)-1;
					IDsOK{m}(end+1)=j(k)-snsigs(m);
				end
			end
		end
		for i=1:size(msgs,1)
			msgs{i,3}=msgs{i,3}(sort(IDsOK{i}));
		end
		msgs(cellfun('isempty',msgs(:,3)),:)=[];
		if isempty(msgs)
			warning('CANMSGS:NoMessages','!!!!geen boodschappen zijn gedefinieerd!!!')
		end
	elseif iscell(x2)
		IDsOK=false(1,size(msgs,1));
		for i=1:size(x2,1)
			if ischar(x2{i,1})
				j=strmatch(x2{i,1},msgs(:,2));
			else
				j=find(x2{i,1}==cat(1,msgs{:,1}));
			end
			if isempty(j)
				warning('CANMSGS:IDnotFound','!!kon ID-%d niet vinden!!',i)
			else
				msgs{j,3}=msgs{j,3}(intersect(1:length(msgs{j,3}),x2{i,2}));
				IDsOK(j)=true;
			end
		end
		msgs=msgs(IDsOK,:);
	else
		error('limitatie niet OK')
	end
	return
elseif isnumeric(x)&&size(x,2)==11
	x=x(:,[2 4:11 1]);
end
if isempty(msgs)||(~isempty(x)&&ischar(x)&&strcmp(x,'init'))
	if iscell(x2)
		msgs=x2;
		B_OLDCANSPEC=false;
	else
		B_OLDCANSPEC=true;
		msgsinit=x2;
		switch x2
		case 'athena'
			MDI=180;
			msgs={'280','Motor1',struct(    ...
                    'signal',{'leergasinfo','Fahrpedal ungenau','kickdown'  ...
                        ,'Tinner','Nmotor','TinnerOhneExt','Fahrpedal'   ...
                        ,'Tloss','Tfahrwunch'   ...
                        }    ...
                    ,'byte',{1,1,1,2,[3 4],5,6,7,8} ...
                    ,'bit',{0,1,2,[0:7],[0:15],[0:7],[0:7],[0:7],[0:7]}  ...
                    ,'scale',{1,1,1,0.0039*MDI,0.25,0.0039*MDI,0.4,0.0039*MDI,0.0039*MDI}    ...
                    );
                '288','Motor2',struct(  ...
                    'signal',{'multiplexinfo','multiplexcode','kuhltemp'    ...
                        ,'bremslicht','bremstest'   ...
                        }   ...
                    ,'byte',{1,1,2,3,3} ...
                    ,'bit',{[0:5],[6 7],[0:7],0,1}  ...
                    ,'scale',{1,1,.75,1,1}  ...
                    );
                '380','Motor3',[];
                '480','Motor5',[];
                '488','Motor6',[];
                '588','Motor7',[];
                '580','MotorFlexia',[];
                '388','GRA',[];
                '38A','GRA_Neu',[];
                '52C','ADR1',[];
                '260','ADR2',[];
                '440','Getriebe1',[];
                '540','Getriebe2',[];
                'FFF','Getriebe3',[];
                '1A0','Bremse1',[];
                '5A0','Bremse2',[];
                '4A0','Bremse3',[];
                '2A0','Bremse4',[];
                '4A8','Bremse5',[];
                '1A8','Bremse6',[];
                '5A8','Bremse7',[];
                '2A8','Bremsbooster1',[];
                '2C0','Allrad1',[];
                '590','Niveau1',[];
                '598','Dampfer',[];
                '53C','Fahrwerk1',[];
                '320','Kombi1',[];
                '420','Kombi2',[];
                '520','Kombi3',[];
                '0C2','Lenkwinkel1',[];
                '5E0','Clima1',[];
                '050','Airbag1',[];
                '550','Airbag2',[];
                '5D0','Systeminfo1',[];
                '5D8','Verbauliste',[];
                '570','BSG_Last',[];
                '470','BSG_Kombi',[];
                '3D0','Lenkhilfe1',[];
                '578','BatMan1',[];
                '572','ZAS1',[];
                '530','Navigation1',[];
                '538','Wischer1',[];
                '534','Sitz_info',[];
                '4D0','RDK1',[];
                '3D8','RDK2',[];
                '7D8','RDK3',[];
                '7DA','RDK4',[];
                '7DC','RDK5',[];
                '7DE','RDK6',[];
                '528','Menue1',[]};
		case 'oxford'
			msgs={	...
				'080','HCU1',struct(	...
					'signal',{'F_CltDisInhC','F_CltEnInhC','F_RCvtEnRqC','F_IscOnC'	...
						,'F_EngIdlStpRqC','F_NEngIdlEnRqC','F_TqEngEnRqC'	...
						,'R_NCvtRpmRqC','R_NEngIdlRpmRqC','R_TqEngRqC'	...
						,'F_InjEnC','F_InjCutC'}	...
                    ,'byte',{1,1,1,1,1,1,1,[3 2],[5 4],[7 6],8,8} ...
                    ,'bit',{0,1,2,4,5,6,7,0:15,0:15,0:15,6,7}  ...
                    ,'scale',{1,1,1,1,1,1,1,1,1,-0.1,1,1}  ...
                    );
				'081','HCU2',struct(	...
					'signal',{'R_TqMotRqC','R_NMotRpmRqC','F_HcuPrunBit00C'	...
						,'F_HcuPrunBit01C','F_BmsRqC','F_NMotEnRqC'	...
						,'F_TqMotEnRqC','F_McuRlyRqC','R_DTqMotC'	...
						,'R_HcuSum'}	...
					,'byte',{[2 1],[4 3],5,5,5,5,5,5,6,8}	...
					,'bit',{0:15,0:15,0,1,4,5,6,7,0:7,0:7}	...
					,'scale',{-0.1,1,1,1,1,1,1,1,1,1}	...
					);
				'0b0','HCU3',struct(	...
					'signal',{'R_TqVehC','F_ClbChgRdyC','F_StrCrkC'	...
						,'F_FmedCrkC','F_IdlStpSttC','F_MotMtrC'	...
						,'F_MotGenC','F_EleDnC','F_HcuRdyC'	...
						,'F_BmsFltC','F_McuFltC','F_TcuFltC'	...
						,'F_EcuFltC','F_HcuFltC'}	...
					,'byte',{[2 1],3,3,3,3,3,3,3,3,4,4,4,4,4}	...
					,'bit',{0:15,0,1,2,3,4,5,6,7,3,4,5,6,7}	...
					,'scale',{-0.1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'330','ECU1',struct(    ...
                    'signal',{'R_TqEngC','R_RApsC','R_RTpsC'	...
						,'R_NEngRpmC','R_TeEngC'}	...
					,'byte',{[2 1],3,4,[6 5],7} ...
					,'bit',{[0:15],[0:7],[0:7],[0:15],[0:7]}  ...
					,'scale',{-0.1,0.4,0.4,1,0.6}    ...
					);	...
				'331','ECU2',struct(	...
					'signal',{'F_EleOnC','F_AcnOnC','F_EngIdlStpC'	...
						,'F_EcuWrnC','F_EcuFltC','F_EcuRdyC'	...
						,'F_EngStlC','F_EngNorC','F_EngCrkC'	...
						,'F_EngIniC','F_EngWotC','F_EngPlodC'	...
						,'F_EngIdlC','F_ApsFltC','F_WtsFltC'	...
						'F_TpsFltC'}	...
					,'byte',{1,1,1,1,1,1,2,2,2,2,2,2,2,3,3,3}	...
					,'bit',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'332','ECU3',struct(	...
					'signal',{'R_TqIndCorC','R_TqIndTgC','R_TqFrcC'	...
						,'R_TqIndIdlC'	...
						}	...
					,'byte',{[1 2],[3 4],[5 6],[7 8]}	...
					,'bit',{0:15,0:15,0:15,0:15}	...
					,'scale',{-0.1,-0.1,-0.1,-0.1}	...
					);
				'230','MCU1',struct(	...
					'signal',{'R_NMotRpmC','R_TqMotMsrC','R_TqMotInvLmtC'	...
						,'F_McuPrunBit00C','F_McuPrunBit01C','F_McuOffRdyC'	...
						,'F_McuWrnC','F_McuFltC','F_McuRlyOnC'	...
						,'F_McuRdyC','R_TeMotC','R_McuSum'}	...
					,'byte',{[2 1],[4 3],5,6,6,6,6,6,6,6,7,8}	...
					,'bit',{0:15,0:15,0:7,0,1,3,4,5,6,7,0:7,0:7}	...
					,'scale',{-1,-0.1,0.1,1,1,1,1,1,1,1,-2,1}	...
					);
				'231','MCU2',struct(	...
					'signal',{'R_IMotC','R_VMotCapC','R_TeInvC'	...
						,'F_CanFltC','F_PwsFltC','F_SnsNMotFltC'	...
						,'F_SnsIMotFltC','F_IInvHgC','F_TeMotHgC'	...
						,'F_TeInvHgC','F_VInvHgC','F_McuIsoFltC'	...
						,'F_VInvLwC','F_SnsVCapFltC','F_SnsTeMotFltC'	...
						,'F_SnsTeInvFltC'}	...
					,'byte',{[2 1],[4 3],5,6,6,6,6,6,6,6,6,7,7,8,8,8}	...
					,'bit',{0:15,0:15,0:7,0,1,2,3,4,5,6,7,6,7,5,6,7}	...
					,'scale',{0.1,0.1,-2,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'430','TCU1',struct(	...
					'signal',{'R_SVehTcuC','R_RSVehTcuC','R_TqDnC'	...
						,'F_TeTcuLw','F_TeCvtHg','F_CltEnC'	...
						,'F_CltLokC','F_GenStpRqC','F_TcuWrnC'	...
						,'F_TcuFltC','F_TcuRdyC','F_TcuFlt01C'	...
						,'F_TcuFlt02C','F_TcuWrn01C','F_SVehErr'	...
						,'F_NEngErr','F_TpsErr','F_ShfMsgFlt'	...
						,'F_DrvMsgFlt','R_TeCvtC'}	...
					,'byte',{1,2,[4 3],5,5,5,5,5,5,5,5,6,6,7,7,7,7,7,7,8}	...
					,'bit',{0:7,0:7,0:15,0,1,2,3,4,5,6,7,6,7,2,3,4,5,6,7,0:7}	...
					,'scale',{1,1,-0.1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'1b0','BMS1',struct(	...
					'signal',{'R_SocBatC','R_WBatChgLmtC','R_WBatDchLmtC'	...
						,'F_BmsFltC','F_BmsWrnC','F_BmsNorC'	...
						,'F_BmsRdyC'}	...
					,'byte',{1,2,3,4,4,4,4}	...
					,'bit',{0:7,0:7,0:7,4,5,6,7}	...
					,'scale',{0.5,1,1,1,1,1,1}	...
					);
				'1b1','BMS2',struct(	...
					'signal',{'R_IBatC','R_VBatC','R_TeBatMxC'	...
						,'R_TeBatMnC','R_VBatMdlMxC','R_VBatMdlMnC'}	...
					,'byte',{[2 1],[4 3],5,6,7,8}	...
					,'bit',{0:15,0:15,0:7,0:7,0:7,0:7}	...
					,'scale',{1,1,1,1,1,1}	...
					);
				};
		case 'oxford01'
			msgs={	...
				'200','HCU1',struct(	...
					'signal',{'F_CltDisInhC','F_CltEnInhC','F_RCvtEnRqC','F_IscOnC'	...1:4
						,'F_EngIdlStpCmdC','F_NEngIdlModC','F_EtcModC'	...5:7
						,'R_NEngCmdC','R_NEngIdlCmdC','R_SVehC'	...8:10
						,'F_PBstLwC','F_SrvRqCluC','F_AcnOffCmdC'	...
						,'F_FcnInhC','F_InjEnC','F_RwtInhC'}	...
                    ,'byte',{1,1,1,1,1,1,1,2:3,4:5,6:7,8,8,8,8,8,8} ...
                    ,'bit',{0,1,2,4,5,6,7,0:15,0:15,0:15,2,3,4,5,6,7}  ...
                    ,'scale',{1,1,1,1,1,1,1,1,1,0.1,1,1,1,1,1,1}  ...
                    );
				'201','HCU2',struct(	...
					'signal',{'F_BmsFan1C','F_BmsFan2C','R_TqMotCmdC'	...
						,'R_NMotCmdC','F_CasVlvACmdC'	...
						,'F_CasVlvBCmdC','F_NMotEnCmdC','F_TqMotEnCmdC'	...
						,'F_McuRlyCmdC','R_DTqMotC','R_CasVlvCmdC'	...
						}	...
					,'byte',{1,1,2:3,4:5,6,6,6,6,6,7,8}	...
					,'bit',{4,5,0:15,0:15,3,4,5,6,7,0:7,0:7}	...
					,'scale',{1,1,-0.1,-1,1,1,1,1,1,0.749,0.3922}	...
					);
				'202','HCU3',struct(	...
					'signal',{'R_TqMotRefC','F_StrCrkC','F_MotCrkC'	...
						,'F_IdlStpSttC','F_MotMtrC'	...
						,'F_MotGenC','F_EleSysDnC','F_HcuRdyC'	...
						,'F_HcuAliveC','F_BrkOnC','F_GarFwdC'	...
						,'F_BmsFltC','F_McuFltC','F_TcuFltC'	...
						,'F_EcuFltC','F_HcuFltC','R_PBstTgC'	...
						,'R_TqEngIdlDnCmdC'	....
						}	...
					,'byte',{1:2,3,3,3,3,3,3,3	...1:8
						,4,4,4,4,4,4,4,4,5:6,7:8}	...
					,'bit',{0:15,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7	...
						0:15,0:15}	...
					,'scale',{-0.1,1,1,1,1,1,1,1	...1:8
						,1,1,1,1,1,1,1,1,-0.0386456,-0.1	...
						}	...
					);
				'316','EMS1',struct(    ...
                    'signal',{'F_N_ENG','PLUC_STAT','RLY_AC','F_SUB_TQI'	...
						,'TQI_ACOR','N','TQI','TQFR'}	...
					,'byte',{1,1,1,1,2,3:4,5,6} ...
					,'bit',{1,3,6,7,0:7,0:15,0:7,0:7}  ...
					,'scale',{1,1,1,1,1,0.25,1,1}    ...
					);	...
				'329','EMS2',struct(	...
					'signal',{'TEMP_ENG','TPS'}	...
					,'byte',{2,6}	...
					,'bit',{0:7,0:7}	...
					,'scale',{0.75,0.4695}	...
					,'offset',{-48,-15.024}	...
					);
				'545','EMS4',struct(	...
					'signal',{'L_MIL','FCO'}	...
					,'byte',{1,2}	...
					,'bit',{1,0:15}	...
					,'scale',{1,0.5961}	...
					);
				'2A0','EMS5',struct(	...
					'signal',{'R_TqIndIdlC','IntAirTemp'}	...
					,'byte',{2,3}	...
					,'bit',{0:7,0:7}	...
					,'scale',{1,0.4695}	...
					,'offset',{0,-15.024}	...
					);
				'290','EMS_H1',struct(	...
					'signal',{'R_NengIdlTgC','F_EngWotC','F_EngPlodC'	...1:3
						,'F_EngIdlC','F_EngTqFltC','F_TpsPwmFltC'	... 4:6
						,'F_AicFltC','F_IscFltC','F_WtsFltC'	... 7:9
						,'F_TpsFltC','R_PEngMapC','R_TqEngPManiC'	...10:12
						,'F_EngIdlStpC','F_TqDnInhC','F_EcuWrnC'	...13:15
						,'F_EcuFltC','F_EcuRdyC','F_AcnSwiC'	...16:18
						,'F_FctRdyC','F_NMotRwtC'}	...19,20
					,'byte',{1,2,2,2,3,3,3,3,3,3	...1:10
						,4:5,6:7,8,8,8,8,8,8,8,8}	...
					,'bit',{0:7,5,6,7,0,1,2,3,5,6	...1:9
						,0:15,0:15,0,1,2,3,4,5,6,7}	...
					,'scale',{10,1,1,1,1,1,1,1,1,1	...
						,39.0014,-0.1,1,1,1,1,1,1,1,1}	...
					);
				'2A1','MCU1',struct(	...
					'signal',{'R_NMotRpmC','R_TqMotMsrC','R_TqMotInvLmtC'	...
						,'F_McuOffRdyC','F_McuWrnC','F_McuFltC'	...
						,'F_McuRlyOnC','F_McuRdyC','R_TeMotC'}	...
					,'byte',{1:2,3:4,5,6,6,6,6,6,7}	...
					,'bit',{0:15,0:15,0:7,3,4,5,6,7,0:7}	...
					,'scale',{-1,-0.1,2,1,1,1,1,1,2}	...
					);
				'291','MCU2',struct(	...
					'signal',{'R_IMotC','R_VMotCapC','R_TeInvC'	...
						,'F_McuCanFltC','F_McuPwsFltC','F_NMotSnsFltC'	...
						,'F_IMotSnsFltC','F_IInvHgC','F_TeMotHgC'	...
						,'F_TeInvHgC','F_VInvHgC','F_MotCabOpnFltC'	...
						,'F_MotCabShrtFltC','F_McuPreChgFltC','F_McuCpuFltC'	...
						,'F_McuSubCpuFltC','F_McuIsoFltC','F_VInvLwC'	...
						,'F_McuPwsWrnC','F_McuRsvCalFltC'	...
						,'F_McuIsoSnsFltC','F_SnsVCapFltC','F_TeMotSnsFltC'	...
						,'F_SnsTeInvFltC'}	...
					,'byte',{1:2,3:4,5,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,8,8,8,8,8,8}	...
					,'bit',{0:15,0:15,0:7,0,1,2,3,4,5,6,7,1,2,3,4,5,6,7,2,3,4,5,6,7}	...
					,'scale',{-0.1,0.1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'43F','TCU1',struct(	...
					'signal',{'G_SEL_DISP','F_TCU','TEMP_AT'}	...
					,'byte',{2,2,5}	...
					,'bit',{0:3,4:5,0:7}	...
					,'scale',{1,1,1}	...
					,'offset',{0,0,-40}	...
					);
				'292','TCU_H1',struct(	...
					'signal',{'R_SVehTcuC','R_RGarTcuC','R_TqDnC'	...1:3
						,'R_TqCvtRqC','F_TeCvtLwC','F_TeCvtHgC'	...4:6
						,'F_CltEnC','CltLLokC','F_GenStpRqC'	...7:9
						,'F_TcuWrnC','F_TcuRdyC','F_TqDnRqC'	...10:12
						,'F_TcuFlt01C','F_TcuFlt02C','F_TcuWrn01C'	...13:15
						,'F_SVehErrC','F_NEngErrC','F_TpsErrC'	...16:18
						,'F_ShfMsgFltC','F_DrvMsgFlt'	...19:20
						}	...
					,'byte',{1,2,3,4,5,5,5,5,5,5,5	...1:11
						,6,6,6,7,7,7,7,7,7}	...
					,'bit',{0:7,0:7,0:7,0:7	...1:4
						,0,1,2,3,4,5,7	...5:11
						,0,6,7,2,3,4,5,6,7}	...
					,'scale',{1,0.3922,0.5,0.1	...1:4
						,1,1,1,1,1,1,1	...5:11
						,1,1,1,1,1,1,1,1,1}	...
					);
				'670','BMS1',struct(	...
					'signal',{'R_WBatChgLmtC','R_WbmsDchLmtC','R_VBmsMdlMnC'	...
						,'R_VBmsMdlMnC','R_TeBmsMnC','R_TeBmsMxC'}	...
					,'byte',{1:2,3:4,5,6,7,8}	...
					,'bit',{0:15,0:15,0:7,0:7,0:7,0:7}	...
					,'scale',{0.01,0.01,0.1,0.1,1,1}	...
					);
				'671','BMS2',struct(	...
					'signal',{'F_BmsFltC','F_BmsWrnC','F_BmsNorC'	...
						,'F_BmsRdyC','R_SocC','R_IBmsC'	...
						,'R_VBmsC'}	...
					,'byte',{3,3,3,3,4,5:6,7:8}	...
					,'bit',{4,5,6,7,0:7,0:15,0:15}	...
					,'scale',{1,1,1,1,0.5,-0.1,0.1}	...
					);
				'620','BMS3',struct(	...
					'signal',{'F_VBmsSnsBlkOpnWrnC','F_VBmsSnsOpnWrnC','F_VBmsSnsOpnWrn2'	...
						,'F_VBmsHgWrnC','F_BmsLwWrnC','F_VBmsBlkHgFltC'	...
						,'F_VBmsBlkLwFltC','F_TeBmsSnsOpnFltC','F_TeBmsSnsGndFltC'	...
						,'F_TeBmsSnsAllOpnFltC','F_TeBmsAirSnsOpnFltC','F_TeBmsAirSnsGndFltC'	...
						,'F_TeBmsDifWrnC','F_IBmsSnsOpnFltC','F_IBmsCirFltC'	...
						,'F_IBmsDifFltC','F_IBmsOfsFltC'}	...
					,'byte',{1,1,1,2,2,2,2,3,3,3,3,3,4,5,5,5,5}	...
					,'bit',{0,1,2,2,3,4,5,0,1,2,3,4,1,0,2,4,7}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'621','BMS4',struct(	...
					'signal',{'F_BmsCellVccFltC','F_RBmsBlkDifFltC','F_VBmsBlkDifFltC'	...
						,'F_SocVryHgWrnC','F_SocHgWrnC','F_SocLwWrnC'	...
						,'F_SocVryLwWrnC','F_TeBmsHgFltC','F_TeBmsHgWrnC'	...
						,'F_Bms12VopnWrnC','F_WBmsInHgWrnC','F_WBmsOutHgWrnC'	...
						,'F_IBmsHgFltC','F_VBms12VHgWrnC','F_RBmsHgFltC'	...
						,'F_BmsCanWrnC','F_TeBmsLwWrnC','F_SocBlkDifWrnC'	...
						,'F_VBms12VLwWrnC'}	...
					,'byte',{1,1,1,2,2,2,2,5,5,5,5,5,6,6,6,6,6,7,7}	...
					,'bit',{4,5,7,2,3,4,5,0,1,2,5,6,2,3,4,5,6,0,2}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'580','ABS1',struct(	...
					'signal',{'ABS_DEF','ABS_ACT','CAS_DEF'	...
						,'ODOMETER_FL','ODOMETER_FR','WHEEL_FL'	...
						,'WHEEL_FR','WHEEL_RL','WHEEL_RR'}	...
					,'byte',{1,1,1,2,2,3:4,4:5,6:7,7:8}	...
					,'bit',{0,2,7,0:3,4:7,0:11,4:15,0:11,4:15}	...
					,'scale',{1,1,1,10,10,0.125,0.125,0.125,0.125}	...
					);
				};
		case 'oxford02'	% !!VT1F-implementatie
			msgs={	...
				'200','HCU1',struct(	...
					'signal',{'F_CltDisInhC','F_CltEnInhC','F_RCvtEnRqC','F_IscOnC'	...1:4
						,'F_EngIdlStpCmdC','F_NEngIdlModC','F_EtcModC'	...5:7
						,'R_NEngCmdC','R_NEngIdlCmdC','R_SVehC'	...8:10
						,'F_PBstLwC','F_SrvRqCluC','F_AcnOffCmdC'	...
						,'F_FcnInhC','F_InjEnC','F_RwtInhC'}	...
                    ,'byte',{1,1,1,1,1,1,1,2:3,4:5,6:7,8,8,8,8,8,8} ...
                    ,'bit',{0,1,2,4,5,6,7,0:15,0:15,0:15,2,3,4,5,6,7}  ...
                    ,'scale',{1,1,1,1,1,1,1,1,1,0.1,1,1,1,1,1,1}  ...
                    );
				'201','HCU2',struct(	...
					'signal',{'F_BmsFan1C','F_BmsFan2C','R_TqMotCmdC'	...
						,'R_NMotCmdC','F_CasVlvACmdC'	...
						,'F_CasVlvBCmdC','F_NMotEnCmdC','F_TqMotEnCmdC'	...
						,'F_McuRlyCmdC','R_DTqMotC','R_CasVlvCmdC'	...
						}	...
					,'byte',{1,1,2:3,4:5,6,6,6,6,6,7,8}	...
					,'bit',{4,5,0:15,0:15,3,4,5,6,7,0:7,0:7}	...
					,'scale',{1,1,-0.1,-1,1,1,1,1,1,0.749,0.3922}	...
					);
				'202','HCU3',struct(	...
					'signal',{'R_TqMotRefC','F_StrCrkC','F_MotCrkC'	...
						,'F_IdlStpSttC','F_MotMtrC'	...
						,'F_MotGenC','F_EleSysDnC','F_HcuRdyC'	...
						,'F_HcuAliveC','F_BrkOnC','F_GarFwdC'	...
						,'F_BmsFltC','F_McuFltC','F_TcuFltC'	...
						,'F_EcuFltC','F_HcuFltC','R_PBstTgC'	...
						,'R_TqEngIdlDnCmdC'	....
						}	...
					,'byte',{1:2,3,3,3,3,3,3,3	...1:8
						,4,4,4,4,4,4,4,4,5:6,7:8}	...
					,'bit',{0:15,1,2,3,4,5,6,7,0,1,2,3,4,5,6,7	...
						0:15,0:15}	...
					,'scale',{-0.1,1,1,1,1,1,1,1	...1:8
						,1,1,1,1,1,1,1,1,-0.0386456,-0.1	...
						}	...
					);
				'2F0','HCU4',struct(	...
					'signal',{'R_RTqMotCluC','R_TqAcnApvHcuC'	...
						,'CR_Eng_ShfPwrAvl_Pc','F_EolCmdC','F_EolRstC'	...
						}	...
					,'byte',{1,2,3,4,4}	...
					,'bit',{0:7,0:7,0:7,0,1}	...
					,'scale',{-1,0.1,0.3921569,1,1}	...
					);
				'316','EMS1',struct(    ...
                    'signal',{'F_N_ENG','PLUC_STAT','RLY_AC','F_SUB_TQI'	...
						,'TQI_ACOR','N','TQI','TQFR'}	...
					,'byte',{1,1,1,1,2,3:4,5,6} ...
					,'bit',{1,3,6,7,0:7,0:15,0:7,0:7}  ...
					,'scale',{1,1,1,1,1,0.25,1,1}    ...
					);	...
				'329','EMS2',struct(	...
					'signal',{'TEMP_ENG','TPS'}	...
					,'byte',{2,6}	...
					,'bit',{0:7,0:7}	...
					,'scale',{0.75,0.4695}	...
					,'offset',{-48,-15.024}	...
					);
				'545','EMS4',struct(	...
					'signal',{'L_MIL','FCO'}	...
					,'byte',{1,2}	...
					,'bit',{1,0:15}	...
					,'scale',{1,0.5961}	...
					);
				'2A0','EMS5',struct(	...
					'signal',{'CR_EngFctTcNorDAc_Pc','IntAirTemp','CTR_IG_CYC_OBD'}	...
					,'byte',{2,3,5:6}	...
					,'bit',{0:7,0:7,0:15}	...
					,'scale',{0.390625,0.75,1}	...
					,'offset',{0,-48,0}	...
					);
				'290','EMS_H1',struct(	...
					'signal',{'R_NengIdlTgC','F_EngWotC','F_EngPlodC'	...1:3
						,'F_EngIdlC','F_EngTqFltC','F_TpsPwmFltC'	... 4:6
						,'F_AicFltC','F_IscFltC','F_WtsFltC'	... 7:9
						,'F_TpsFltC','R_PEngMapC','R_TqEngPManiC'	...10:12
						,'F_EngIdlStpC','F_TqDnInhC','F_EcuWrnC'	...13:15
						,'F_EcuFltC','F_EcuRdyC','F_AcnSwiC'	...16:18
						,'F_FctRdyC','F_NMotRwtC'}	...19,20
					,'byte',{1,2,2,2,3,3,3,3,3,3	...1:10
						,4:5,6:7,8,8,8,8,8,8,8,8}	...
					,'bit',{0:7,5,6,7,0,1,2,3,5,6	...1:9
						,0:15,0:15,0,1,2,3,4,5,6,7}	...
					,'scale',{10,1,1,1,1,1,1,1,1,1	...
						,39.0014,-0.1,1,1,1,1,1,1,1,1}	...
					);
				'69F','EMS_H2',struct(	...
					'signal',{'R_TqAcnApv','R_PAcnC'}	...
					,'byte',{1,2}	...
					,'bit',{0:7,0:7}	...
					,'scale',{0.125,0.1}	...
					);
				'2A1','MCU1',struct(	...
					'signal',{'R_NMotRpmC','R_TqMotMsrC','R_TqMotInvLmtC'	...
						,'F_McuOffRdyC','F_McuWrnC','F_McuFltC'	...
						,'F_McuRlyOnC','F_McuRdyC','R_TeMotC'}	...
					,'byte',{1:2,3:4,5,6,6,6,6,6,7}	...
					,'bit',{0:15,0:15,0:7,3,4,5,6,7,0:7}	...
					,'scale',{-1,-0.1,2,1,1,1,1,1,2}	...
					);
				'291','MCU2',struct(	...
					'signal',{'R_IMotC','R_VMotCapC','R_TeInvC'	...
						,'F_McuCanFltC','F_McuPwsFltC','F_NMotSnsFltC'	...
						,'F_IMotSnsFltC','F_IInvHgC','F_TeMotHgC'	...
						,'F_TeInvHgC','F_VInvHgC','F_MotCabOpnFltC'	...
						,'F_MotCabShrtFltC','F_McuPreChgFltC','F_McuCpuFltC'	...
						,'F_McuSubCpuFltC','F_McuIsoFltC','F_VInvLwC'	...
						,'F_McuPwsWrnC','F_McuRsvCalFltC'	...
						,'F_McuIsoSnsFltC','F_SnsVCapFltC','F_TeMotSnsFltC'	...
						,'F_SnsTeInvFltC'}	...
					,'byte',{1:2,3:4,5,6,6,6,6,6,6,6,6,7,7,7,7,7,7,7,8,8,8,8,8,8}	...
					,'bit',{0:15,0:15,0:7,0,1,2,3,4,5,6,7,1,2,3,4,5,6,7,2,3,4,5,6,7}	...
					,'scale',{-0.1,0.1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'43F','TCU1',struct(	...
					'signal',{'G_SEL_DISP','F_TCU','TEMP_AT'}	...
					,'byte',{2,2,5}	...
					,'bit',{0:3,4:5,0:7}	...
					,'scale',{1,1,1}	...
					,'offset',{0,0,-40}	...
					);
				'292','TCU_H1',struct(	...
					'signal',{'R_SVehTcuC','R_RGarTcuC','R_TqDnC'	...1:3
						,'R_TqCvtRqC','F_TeCvtLwC','F_TeCvtHgC'	...4:6
						,'F_CltEnC','CltLLokC','F_GenStpRqC'	...7:9
						,'F_TcuWrnC','F_TcuRdyC','F_TqDnRqC'	...10:12
						,'F_TcuFlt01C','F_TcuFlt02C','F_TcuWrn01C'	...13:15
						,'F_SVehErrC','F_NEngErrC','F_TpsErrC'	...16:18
						,'F_ShfMsgFltC','F_DrvMsgFlt'	...19:20
						}	...
					,'byte',{1,2,3,4,5,5,5,5,5,5,5	...1:11
						,6,6,6,7,7,7,7,7,7}	...
					,'bit',{0:7,0:7,0:7,0:7	...1:4
						,0,1,2,3,4,5,7	...5:11
						,0,6,7,2,3,4,5,6,7}	...
					,'scale',{1,0.3922,0.5,0.1	...1:4
						,1,1,1,1,1,1,1	...5:11
						,1,1,1,1,1,1,1,1,1}	...
					);
				'670','BMS1',struct(	...
					'signal',{'R_WBatChgLmtC','R_WbmsDchLmtC','R_VBmsMdlMnC'	...
						,'R_VBmsMdlMnC','R_TeBmsMnC','R_TeBmsMxC'}	...
					,'byte',{1:2,3:4,5,6,7,8}	...
					,'bit',{0:15,0:15,0:7,0:7,0:7,0:7}	...
					,'scale',{0.01,0.01,0.1,0.1,1,1}	...
					);
				'671','BMS2',struct(	...
					'signal',{'F_BmsFltC','F_BmsWrnC','F_BmsNorC'	...
						,'F_BmsRdyC','R_SocC','R_IBmsC'	...
						,'R_VBmsC'}	...
					,'byte',{3,3,3,3,4,5:6,7:8}	...
					,'bit',{4,5,6,7,0:7,0:15,0:15}	...
					,'scale',{1,1,1,1,0.5,-0.1,0.1}	...
					);
				'620','BMS3',struct(	...
					'signal',{'F_VBmsSnsBlkOpnWrnC','F_VBmsSnsOpnWrnC','F_VBmsSnsOpnWrn2'	...
						,'F_VBmsHgWrnC','F_BmsLwWrnC','F_VBmsBlkHgFltC'	...
						,'F_VBmsBlkLwFltC','F_TeBmsSnsOpnFltC','F_TeBmsSnsGndFltC'	...
						,'F_TeBmsSnsAllOpnFltC','F_TeBmsAirSnsOpnFltC','F_TeBmsAirSnsGndFltC'	...
						,'F_TeBmsDifWrnC','F_IBmsSnsOpnFltC','F_IBmsCirFltC'	...
						,'F_IBmsDifFltC','F_IBmsOfsFltC'}	...
					,'byte',{1,1,1,2,2,2,2,3,3,3,3,3,4,5,5,5,5}	...
					,'bit',{0,1,2,2,3,4,5,0,1,2,3,4,1,0,2,4,7}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'621','BMS4',struct(	...
					'signal',{'F_BmsCellVccFltC','F_RBmsBlkDifFltC','F_VBmsBlkDifFltC'	...
						,'F_SocVryHgWrnC','F_SocHgWrnC','F_SocLwWrnC'	...
						,'F_SocVryLwWrnC','F_TeBmsHgFltC','F_TeBmsHgWrnC'	...
						,'F_Bms12VopnWrnC','F_WBmsInHgWrnC','F_WBmsOutHgWrnC'	...
						,'F_IBmsHgFltC','F_VBms12VHgWrnC','F_RBmsHgFltC'	...
						,'F_BmsCanWrnC','F_TeBmsLwWrnC','F_SocBlkDifWrnC'	...
						,'F_VBms12VLwWrnC'}	...
					,'byte',{1,1,1,2,2,2,2,5,5,5,5,5,6,6,6,6,6,7,7}	...
					,'bit',{4,5,7,2,3,4,5,0,1,2,5,6,2,3,4,5,6,0,2}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					);
				'580','ABS1',struct(	...
					'signal',{'ABS_DEF','ABS_ACT','CAS_DEF'	...
						,'ODOMETER_FL','ODOMETER_FR','WHEEL_FL'	...
						,'WHEEL_FR','WHEEL_RL','WHEEL_RR'}	...
					,'byte',{1,1,1,2,2,3:4,4:5,6:7,7:8}	...
					,'bit',{0,2,7,0:3,4:7,0:11,4:15,0:11,4:15}	...
					,'scale',{1,1,1,10,10,0.125,0.125,0.125,0.125}	...
					);
				};
		case 'ecu'
			fprintf('niet klaar\n');
		case 'tucson'
			msgs={	...
				'153','asc1',struct(	...
					'signal',{'B_ASC','B_MSR','ASC_PAS','ASC_SBE','S_BLS','L_BAS','L_EBV','L_ABS'	...
						,'L_ASC','ASC_REG','F_V1','V1','MD_IND_ASC','MD_IND_MSR','W_VDK'}	...
					,'byte',{1,1,1,1,1,1,1,1,2,2,2,2:3,4,5,6}	...
					,'bit',{0,1,2,3,4,5,6,7,0,2,3,3:15,0:7,0:7,0:7}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,0.0625076,0.392163,0.390625,0.390625}	...
					);	...
				'1f0','asc2',struct(	...
					'signal',{'VRD_LV_ASC','VRD_RV_ASC','VRD_LH_ASC','VRD_RH_ASC'}	...
					,'byte',{1:2,3:4,5:6,7:8}	...
					,'bit',{0:12,0:12,0:12,0:12}	...
					,'scale',{0.0625076,0.0625076,0.0625076,0.0625076}	...
					);	...
				'1f8','asc4',struct(	...
					'signal',{'S_RRd','B_TW_MSR','B_TW_ASR','TW_IND_ASR','TW_IND_MSR'}	...
					,'byte',{1,2,2,5:6,7:8}	...
					,'bit',{0:7,5,6,0:15,0:15}	...
					,'scale',{0.08,1,1,1.5259e-3,1.5259e-3}	...
					);	...
				'316','dme1',struct(    ...
                    'signal',{'MD_IND_NE','N_MOT','MD_IND','MD_REIB'	...
						,'TP_SW','L_TP_SW','MD_IND_LM'}    ...
                    ,'byte',{2,[3 4],5,6,7,7,8} ...
                    ,'bit',{0:7,[0:15],0:7,0:7,4,5,0:7}  ...
                    ,'scale',{0.3906251,0.15625,0.3906251,0.3906251,1,1,0.3906251}    ...
                    );	...
				'329','dme2',struct(	...
					'signal',{'MUL_INFO','MUL_COD','T_MOT','P_LUFT'	...
						,'W_VPDK','S_KD','W_FPDK_MOD'}	...
					,'byte',{1,1,2,3,6,7,8}	...
					,'bit',{0:5,6:7,0:7,0:7,0:7,1,0:7}	...
					,'scale',{1,1,1,1,1,1,1}	...
					);	...
				'336','dme6',struct(	...
					'signal',{'CAN_TQ_AT_WHEELS','CAN_TW_NORM','LV_CAN_TW_FLT','LV_TCS_TW_ACK','xx',	...
						'CAN_TW_TQ_LOSS','CAN_TW_TQI_TREQ_TRA'}	...
					,'byte',{1:2,3,4,4,4,5:6,7:8}	...
					,'bit',{0:15,0:7,0,1,2:7,0:15,0:15}	...
					,'scale',{1.5259e-3,20.0787,1,1,1,1.5259e-3,1.5259e-3}	...
					);	...
				'43f','egs1',struct(	...
					'signal',{'GANG_INF','S_SHALT','OBD_F','S_GTS','S_WK',	...
						'GANG_WHL_ANZ','PRG_INF_ANZ','MD_IND_GS','N_ABTR'}	...
					,'byte',{1,1,1,1,1,2,3,4,5}	...
					,'bit',{0:2,3,4,5,6:7,0:3,5:7,0:7,0:7}	...
					,'scale',{1,1,1,1,1,1,1,0.390625,1}	...
					);	...
			'44f','cvt1',struct(    ...
                    'signal',{'POS_MOT','CLU_RAT','P_DUTY_SEC','S_STAT_L','S_STAT_H'	...
						,'MOT_COND','CLU_COND','SEC_COND'	...
						,'PRNDM_DRIVE','PRNDM_FAULT'}    ...
                    ,'byte',{[3 4],5:6,7:8,1,2,4,6,8,4,6} ...
                    ,'bit',{[0:8],0:8,0:8,0:7,0:7,1:3,1:3,1:3,4:7,4:7}  ...
                    ,'scale',{1,0.1961,0.1961,1,1,1,1,1,1,1}    ...
                    );	...
				'45f','egs2',struct(	...
					'signal',{'CAN_TOIL_GB','CAN_N_TUR_CONV','CAN_TQ_P_MAX'}	...
					,'byte',{1,2:3,4}	...
					,'bit',{0:7,0:15,0:7}	...
					,'scale',{1,0.1248474,0.390625}	...
					,'offset',{-40,0,0}	...
					);
				'545','dme4',struct(	...
					'signal',{'VERBRAUCH','M_OEL_TEMP','BEDARF_EKP'}	...
					,'byte',{2:3,5,7}	...
					,'bit',{0:15,0:7,0:7}	...
					,'scale',{1,1,1}	...
					);	...
				'565','dme5',struct(	...
					'signal',{'MOT_POS','CLUTCH_RAT','SEC_P_RAT','P_MAP_G'}	...
					,'byte',{1:2,3:4,5:6,8}	...
					,'bit',{0:8,0:8,0:8,0:7}	...
					,'scale',{1,0.1961,0.1961,1}	...
					);	...
				'613','instr2',struct(	...
					'signal',{'CAN_DIST','CAN_F2TL','S_FST','REL_ZEIT'}	...
					,'byte',{1:2,3,3,4:5}	...
					,'bit',{0:15,0:6,7,0:15}	...
					,'scale',{10,1,1,1}	...
					);
				'615','instr3',struct(	...
					'signal',{'LM_KK','S_NTKW','S_KO','S_AC','S_HZL','S_ANH','S_TNS','N_ZL'	...
						,'T_UMG','S_DOOR','S_HBR','S_SUSP','S_TDL','S_REGIME'	...
						,'F_K_ACC','BLINKER','A_EKP_CRASH','F_K_OBD'}	...
					,'byte',{1,1,1,1,2,2,2,2,4,5,5,5,5,5,6,6,6,6}	...
					,'bit',{0:4,5,6,7,0,1,2,4:7,0:7,0,1,2:3,4,5:7,0,1:2,3:4,7}	...
					,'scale',{1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}	...
					,'offset',{0,0,0,0,0,0,0,0,-126,0,0,0,0,0,0,0,0,0}	...
					);
				'618','instr4',struct(	...
					'signal',{'V_FGS','S_GEAR','T_EVAP'}	...
					,'byte',{1,2,3}	...
					,'bit',{0:7,0:3,0:7}	...
					,'scale',{1,1,0.364}	...
					,'offset',{0,0,-30}	...
					);
				};
		otherwise
			fprintf('onbekend project\n');
		end	% switch
	end	% ~iscell(x2)
	for i=1:size(msgs,1)
		if ischar(msgs{i})
	        msgs{i,1}=sscanf(msgs{i,1},'%x');
		end
		if ~isfield(msgs{i,3},'offset')
			% Voeg offset-veld toe omdat in deze file soms
			%    een gelijk aantal velden in de structuur
			%    verwacht.
			for j=1:length(msgs{i,3})
				msgs{i,3}(j).offset=msgs{i,3}(j).scale*0;
			end
		end
	end
	if strcmp(x,'init')
		return
	end
end
msgl=cat(1,msgs{:,1});
msgnames=lower(msgs(:,2));
if ischar(x)
	x={x};
elseif isstruct(x)
	xx=cell(1,length(x));
	[xx{:}]=deal(x.naam);
	x=xx;
end
if iscell(x)
	ongeschaald=exist('x3','var')&&~isempty(x3)&&x3;
	if isempty(x)
		ids=canmsgs(x2);
		x=sort(lower({ids.naam}));
	end
	[i_ID,i_Tijd,i_Data]=bepiCAN(x2);
	IDS=cell(1,length(x));
	info=cell(3,length(x));
	for i=1:length(x)
		str=[];
		if ischar(x{i})
			if strcmp(x{i}(1:min(end,3)),'x0x')
				id=sscanf(x{i}(4:end),'%x');
			else
				iMsg=strmatch(lower(x{i}),msgnames,'exact');
				if isempty(iMsg)
					fprintf('-----!!!!---- geen informatie over msg %s gevonden.\n',x{i});
					id=-1;
				else
					%(?)via x2?
					id=msgs{iMsg,1};
					str=msgs{iMsg,3};
				end
			end
		else
			id=x{i};
		end
		j=find(x2(:,i_ID)==id);
		if ~isempty(j)
			if isempty(str)
				IDS{i}=x2(j,[i_Tijd i_Data]);
			else
				info{1,i}=id;
				info{2,i}=msgs{iMsg,2};
				info{3,i}=str;
				IDS{i}=[x2(j,i_Tijd) zeros(length(j),length(str))];
				for k=1:length(str)
					if B_OLDCANSPEC
						% kept like this to so that old definition is possible
						d=x2(j,i_Data(str(k).byte(1)));
						dd=256;
						for l=2:length(str(k).byte)
							d=d+x2(j,i_Data(str(k).byte(l)))*dd;
							dd=dd*256;
						end
						d=bitand(d,sum(2.^str(k).bit))/2^min(str(k).bit);
						schaal=str(k).scale;
						if schaal<0
							schaal=-schaal;
							d=d-dd*(d>=dd/2);
						end
						offset=str(k).offset;
					else	% new spec (bit based)
						b=str(k).bit(1);
						nb=str(k).bit(2);
						d=zeros(length(j),1);
						while nb>0
							iB=floor(b/8);
							iB0=iB*8;
							iBl=iB0;
							B=x2(j,i_Data(iB+1));
							if b-iBl+1>nb
								iBl=b-nb+1;
								B=bitshift(B,iB0-iBl);
							end
							nb1=b-iBl+1;
							if b-iB0<7
								B=bitand(B,bitshift(1,nb1)-1);
							end
							d=d*bitshift(1,nb1)+B;
							nb=nb-nb1;
							b=iB0+15;
						end
						schaal=str(k).scale(1);
						offset=str(k).scale(2);
					end
					if ~ongeschaald
						if schaal~=1
							d=d*schaal;
						end
						if offset~=0
							d=d+offset;
						end
					end
					IDS{i}(:,k+1)=d;
				end	% alle data
			end	% struct data
		end
	end	% x
	if nargout>1
		if nargout>2
			sINFO=cell(size(IDS));
			for i=1:length(sINFO)
				if isstruct(info{3,i})
					sINFO{i}={info{3,i}.signal;info{3,i}.sExtra};
				end
			end
		end
	end
	INFO=info;
	return
end	% iscell(x)
i_ID=bepiCAN(x);
ids_tot=x(:,i_ID);
ids=unique(ids_tot);
if nargout
    IDS=struct('ID',num2cell(ids),'naam',[],'n',[],'structure',[]);
end
for i=1:length(ids)
    j=find(ids(i)==msgl);
    if ~isempty(j)
        if nargout
            IDS(i).naam=msgs{j,2};
            IDS(i).structure=msgs{j,3};
		else
	        fprintf('%03x : %s\n',ids(i),msgs{j,2});
        end
	elseif nargout==0
        fprintf('--%03x ??\n',ids(i))
	else
		IDS(i).naam=sprintf('x0x%03x',ids(i));
    end
    if nargout
        IDS(i).n=sum(ids_tot==ids(i));
    end
end

function [iID,iTijd,iData]=bepiCAN(x)
if min(size(x))==1
	iID=1;
	iTijd=[];
	iData=[];
elseif size(x,2)==10
	if any(diff(x(:,10))<0)
		error('?Dalende tijd?')
	end
	iTijd=10;
	iID=1;
	iData=2:9;
elseif size(x,2)==11
	if any(diff(x(:,1))<0)
		error('?dalende tijd?')
	end
	iTijd=1;
	iID=2;
	iData=4:11;
else
	error('Onbekende vorm van CAN-data')
end
