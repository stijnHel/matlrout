function [msgs,X]=leesdbc(f)
% LEESDBC  - Leest can-DBC-file
%    msgs=leesdbc(f)
%       msgs te gebruiken als input voor init van 'canmsg'-functie

persistent UnknownCodes
if ~iscell(UnknownCodes)
	UnknownCodes = {};
end

fid=file(f);

lineNr=1;
msgs=cell(0,7);
% [msgID  msgName  signals #bytes target(?) extended combSig]
inblok=0;	% not in a block, block types:
% 1: NS_
% 2: BO_
% 3: CM_ BU_
% 4: CM_ BO_
% 5: CM_ SG_
X=struct('VERSION',[],'VAL',struct('ID',cell(1,0),'signal',[],'values',[])	...
	,'VAL_TABLE',struct('name',cell(1,0),'values',[])	...
	,'CM',struct('type',cell(1,0),'CANID',[],'data',[])	...
	,'BA_DEF',struct('type',cell(1,0),'sig',[],'spec',[])	...
	,'BA_DEF_DEF',struct('sig',cell(1,0),'value',[])	...
	,'BA',struct('sig',cell(1,0),'value',[])	...
	,'SIG_VAL_TYPES',struct('ID',cell(1,0),'signal',[],'val_type',[])	...
	,'BO_TX_BU',struct('ID',cell(1,0),'units',[])	...
	,'NS',{{}});
while ~feof(fid)
	ll=0;
	a=fgetl(fid);
	lineNr=lineNr+1;
	while ~feof(fid)&&isempty(a)
		ll=1;
		a=fgetl(fid);
		lineNr=lineNr+1;
	end
	a = deblank(a);
	if isempty(a)
		break;
	end
	if inblok
		if ll
			inblok=0;
		end
	end
	switch inblok
		case 0
			C = ReadLine(a);
			a3 = C{1};
			if ~isempty(a3) && a3(end)==':'
				a3(end) = [];
			end
			switch a3
				case 'NS_'	% naamlijst
					inblok=1;
				case 'BS_'	% bus configuration
					aaaaaaaaaaaaaa=1;
				case 'BU_'	% CAN-nodes
					X.BU = C(2:end);
				case 'BO_'	% can-boodschap
					inblok=2;
					n = size(msgs,1)+1;
					msgs{n,3}=struct('signal',{},'M',{},'byte',{},'bit',{}	...
						,'bitorder',{},'bSigned',{},'bBigEndian',{}	...
						,'scale',{},'unit',{},'ob',{},'Mplx',[]);
					ID = C{2};
					msgs{n,1}=bitand(ID,2^30-1);
					msgs{n,6}=ID>=2^31;
					msgs{n,2}=C{3};
					msgs{n,4}=C{4};
					msgs{n,5}=C{5};
				case 'CM_'	% ?config / comment? ("Description field")
					if ischar(C{2}) && C{2}(end)=='_'
						CMtype = C{2}(1:end-1);
						if isnumeric(C{3})
							ID = C{3};
							switch CMtype
								case 'SG'
									data = struct('signal',C{4},'desc',C{5});
								otherwise
									if length(C)==4
										data = C{4};
									else
										data = C(4:end);
									end
							end
						else
							ID = [];
							data = struct('unit',C{3},'desc',C{4});
						end
					elseif length(C)<3
						CMtype = 'ROOT';
						ID = [];
						data = C{2};
					else
						warning('Unknown CM-type?! (#%d: %s)',lineNr,a)
						data = [];
					end
					if ~isempty(data)
						n = length(X.CM)+1;
						X.CM(1,n).type = CMtype;
						X.CM(n).CANID = ID;
						X.CM(n).data = data;
					end
				case 'BA_DEF_'	% attribute definition
					if C{2}(end)=='_'
						typ = C{2}(1:end-1);
						sig = C{3};
						spec = C(4:end);
					else
						typ = 'const';
						sig = C{2};
						spec = C(3:end);
					end
					n = length(X.BA_DEF)+1;
					X.BA_DEF(1,n).type = typ;
					X.BA_DEF(n).sig = sig;
					X.BA_DEF(n).spec = spec;
				case 'BA_DEF_DEF_'	% attribute default value
					n = length(X.BA_DEF_DEF)+1;
					X.BA_DEF_DEF(1,n).sig = C{2};
					X.BA_DEF_DEF(1,n).value = C{3};
					if length(C)>3
						warning('Expected only one value for BA_DEF_DEF?! (#%d: %s)',lineNr,a)
					end
				case 'BA_'	% attribute format
					n = length(X.BA)+1;
					X.BA(1,n).sig = C{2};
					if length(C)==3
						v = C{3};
					else
						v = C(3:end);
					end
					X.BA(1,n).value = v;
				case 'VAL_TABLE_'% Value table definition for signals
					n = length(X.VAL_TABLE)+1;
					X.VAL_TABLE(1,n).name=C{2};
					X.VAL_TABLE(n).values=reshape(C(3:end),2,[])';
				case 'VAL_'	% Value definitions for signals
					n = length(X.VAL)+1;
					X.VAL(1,n).ID = C{2};
					X.VAL(n).signal = C{3};
					X.VAL(n).values = reshape(C(4:end),2,[])';
				case 'VERSION'
					X.VERSION = C{2};
				case '//'
					%neglect comment
				case 'BO_TX_BU_'
					n = length(X.BO_TX_BU)+1;
					X.BO_TX_BU(1,n).ID = C{2};
					if strcmp(C{3},':')
						units = C(4:end);
					else
						units = C(3:end);
					end
					if isscalar(units)
						units = units{1};
					end
					X.BO_TX_BU(1,n).units = units;
				case 'SIG_VALTYPE_'
					n = length(X.SIG_VAL_TYPES)+1;
					X.SIG_VAL_TYPES(1,n).ID = C{2};
					X.SIG_VAL_TYPES(1,n).signal = C{3};
					if ischar(C{4})
						if ~strcmp(C{4},':')
							warning('Unexpected format of signal-val-type?! (#%d: %s)',lineNr,a)
							val_type = C{end};
						else
							val_type = C{5};
						end
					else
						val_type = C{4};
					end
					% val_types: 0: integer, 1: 32-bit float, 2: 64-bit float
					X.SIG_VAL_TYPES(1,n).val_type = val_type;
				case 'EV_'	% Environment Variable
					[env_var_name,~,env_var_type,minmax,unit,initial_value,ev_id,access_type,access_node]	...
						= deal(C{2:end});
					EV1 = var2struct(env_var_name,env_var_type,minmax,unit,initial_value,ev_id,access_type,access_node);
					if isfield(X,'EV')
						X.EV(1,end+1) = EV1;
					else
						X.EV = EV1;
					end
				case 'SIG_GROUP_'
					[message_id,signal_group_name,repetitions] = deal(C{2:4});
					if ~strcmp(C{5},':')
						warning('Unexpected format signal group?! (#%d: %s)',lineNr,a)
					end
					if length(C)==5
						signal_name = C{5};
					elseif length(C)>5	% not expected to be possible
						signal_name = C(5:end);
					else
						signal_name = [];
					end
					SIG_GROUP1 = var2struct(message_id,signal_group_name,repetitions,signal_name);
					if isfield(X,'SIG_GROUP')
						X.SIG_GROUP(1,end+1) = SIG_GROUP1;
					else
						X.SIG_GROUP = SIG_GROUP1;
					end
				case 'SG_MUL_VAL_'
					[message_id,multiplexed_signal_name,multiplexor_switch_name] = deal(C{2:4});
					multiplexor_value_ranges = C(5:end);
					for i=1:length(multiplexor_value_ranges)-1
						if multiplexor_value_ranges{i}(end)~=','
							warning('Something wrong?! (#%d: %s)',lineNr,a)
						else
							multiplexor_value_ranges{i}(end) = [];
						end
					end
					SG_MUL_VAL1 = var2struct(message_id,multiplexed_signal_name,multiplexor_switch_name,multiplexor_value_ranges);
					if isfield(X,'SG_MUL_VAL')
						X.SG_MUL_VAL(1,end+1) = SG_MUL_VAL1;
					else
						X.SG_MUL_VAL = SG_MUL_VAL1;
					end
				otherwise
					if ~any(strcmp(UnknownCodes,C{1}))
						fprintf('onbekende code %s\n',a);
						UnknownCodes{1,end+1} = C{1}; %#ok<AGROW> 
					end
			end
		case 1	% ns
			X.NS{1,end+1} = strtrim(a);
		case 2	% bo
			C = ReadLine(a);
			bSigned = [];	% unknown
			Mplx = [];
			if ~strcmp(C{1},'SG_')
				warning('onbekende info bij "BO_" (#%d: %s)',lineNr,C{1})
				continue;
			end
			M='';
			nm = C{2};
			if ~strcmp(C{3},':')
				if C{3}(1)=='m' || strcmp(C{3},'M')
					Mplx = C{3};
					C(3) = [];
				else
					warning('verkeerde vorm signaal-info (#%d: %s)',lineNr,a)
					continue
				end
			end
			w = C{4};
			[binfo,~,~,next]=sscanf(w,'%d|%d',2);
			if w(next)=='@'
				bextra = w(next+1:end);
				if length(bextra)==2
					bSigned = bextra(2)=='-';
					bBigEndian = bextra(1)=='0';
				else
					bBigEndian = false;
					warning('extra signal-info not as expected! (#%d: "%s")',lineNr,bextra)
				end
			else
				bBigEndian = false;
				warning('extra signal-info not as expected! (#%d: "%s")',lineNr,w)
			end
			byte=floor(binfo(1)/8);
			if bBigEndian
				bitLast = binfo(1)-binfo(2)+1;
				byteLast = floor(bitLast/8);
				if byteLast<byte
					byteLast = 2*byte-byteLast;
				end
			else
				byteLast = floor((binfo(1)+binfo(2)-1)/8);
			end
			byte = byte:byteLast;
			schaal = [sscanf(C{5},'(%g,%g)',[1 2]),sscanf(C{6},'[%g|%g]',[1 2])];
			unit = C{7};
			ob = C{8};
			if ~isempty(msgs{end,3})
				nmPrev = msgs{end,3}(end).signal;
				if endsWith(nmPrev,'_high','IgnoreCase',true)	...
						&& endsWith(nm,'_low','IgnoreCase',true)		...
						&& strncmpi(nm,nmPrev,length(nm)-4)
					link1 = struct('link',length(msgs{end,3})+[0 1]	...
						,'factor',[1;1]	...
						,'name',nm(1:end-4));
					if isempty(msgs{end,7})
						msgs{end,7} = link1;
					else
						msgs{end,7}(1,end+1) = link1;
					end
				elseif endsWith(nmPrev,'_low','IgnoreCase',true)	...
						&& endsWith(nm,'_high','IgnoreCase',true)		...
						&& strncmpi(nm,nmPrev,length(nm)-5)
					link1 = struct('link',length(msgs{end,3})+[0 1]	...
						,'factor',[1;1]	...
						,'name',nm(1:end-5));
					if isempty(msgs{end,7})
						msgs{end,7} = link1;
					else
						msgs{end,7}(1,end+1) = link1;
					end
				end
			end
			msgs{end,3}(end+1)=struct('signal',nm,'M',M,'byte',byte,'bit',binfo'	...
				,'bitorder',bextra,'bSigned',bSigned,'bBigEndian',bBigEndian	...
				,'scale',schaal','unit',unit,'ob',ob,'Mplx',Mplx);
		otherwise
			error('Not implemented block type (%d)!',inblok)
	end
end
fclose(fid);

% (if nargout>1) group data per message(?)
%       ID, msg-name, signals, message attributes (e.g. send-type, send-time, ...)
%            for signals include signal attributes / description data

	function [C,bEndMark] = ReadLine(l)
			% maybe include reading l!!!
		C = cell(1,10);
		nC = 0;
		il = 1;
		while true
			while il<=length(l) && (l(il)==' ' || l(il)==9)
				il = il+1;
			end
			if il>length(l)
				bEndMark = false;
				break
			elseif l(il)==';'
				bEndMark = true;
				break
			end
			i1 = il;
			if l(il)=='"'
				il = il+1;
				bLoop = true;
				while bLoop
					if il>length(l)
						l1 = fgetl(fid);
						lineNr=lineNr+1;
						l = [l newline l1]; %#ok<AGROW> 
					end
					if l(il)=='"'
						bLoop = false;
					end
					il = il+1;
				end		% while bLoop
			elseif l(il)==':'
				il = il+1;	% take ':' as separate word
			else
				while il<=length(l) && all(l(il)~=[' ;:' 9])
					il = il+1;
				end
				if il==i1
					il = il+1;	% (for "standalone ;"?)
				end
			end
			w = l(i1:il-1);
			if all(w>='0' & w<='9')
				w = str2double(w);
			elseif length(w)>1 && w(1)=='"' && w(end)=='"'
				w = string(w(2:end-1));
			end
			nC = nC+1;
			C{nC} = w;
		end		% while true
		C = C(1:nC);
	end		% ReadLine

end		% leesdbc
