function str=getblcks(sys,l,nr)
% GETBLCKS - Geeft structuur van model (of blok), samen met parameters.
%  str = getblcks(sys,s,l)
%    met sys de naam van het model.
%            indien niet gegeven, wordt het actieve blok genomen
%        l het niveau

% nog niet geimplementeerd
%      v valve : ResetIntegrator
%         Area of 1st half moon : Lookup


if ~exist('sys');sys=[];end
if ~exist('nr');nr=[];end
if isempty(sys)
  sys=get_param(0,'CurrentSystem');
end
if ~exist('l')
  l=0;
end

nPerNiveau=3;
n=80; % kleinste aantal karakters per lijn

bMask = false;

b=get_param(sys,'blocks');
str=[];
ruimte=blanks(l*nPerNiveau);
nr1=0;
while ~isempty(b)
	b1=sprintf('%s',b{1});
	b1=strrep(b1,'/','//');
	ssub=[sys '/' b1];
	bType=get_param(ssub,'BlockType');
	lb1=b1;
	ib1=find(b1==10);
	lb1(ib1)=setstr(' '*ones(size(ib1)));
	doesub=0;
	isSub=0;
	v=[];
	vn=' ';
	v2=[];
	v2n=' ';
	if strcmp(bType,'Constant')
		v=get_param(ssub,'Value');
	elseif strcmp(bType,'S-Function')
		v=sprintf('%s(%s)',get_param(ssub,'function name')      ...
		, get_param(ssub,'parameters'));
	elseif strcmp(bType,'Fcn')
		v=get_param(ssub,'Expr');
	elseif strcmp(bType,'Sum')
		v=get_param(ssub,'inputs');
	elseif strcmp(bType,'Inport')
		v=get_param(ssub,'Port');
	elseif strcmp(bType,'Outport')
		v=get_param(ssub,'Port');
	elseif strcmp(bType,'Gain')
		v=get_param(ssub,'Gain');
	elseif strcmp(bType,'Integrator')
		v=get_param(ssub,'initial');
	elseif strcmp(bType,'Switch')
		v=get_param(ssub,'Threshold');
	elseif strcmp(bType,'Saturate')	% Vroeger : Saturation
		v=get_param(ssub,'Lower Limit');
		vn='Lower ';
		v2=get_param(ssub,'Upper Limit');
		v2n='Upper ';
	elseif strcmp(bType,'Logical Operator')
		v=get_param(ssub,'Operator');
	elseif strcmp(bType,'RelationalOperator')	% Vroeger met spatie
		v=get_param(ssub,'Operator');
	elseif strcmp(bType,'Look Up Table')
		v=get_param(ssub,'Input_Values');
		vn='In  ';
		v2=get_param(ssub,'Output_Values');
		v2n='Out ';
	elseif strcmp(bType,'Mux')
		v=get_param(ssub,'inputs');
	elseif strcmp(bType,'Product')
		v=get_param(ssub,'inputs');
	elseif strcmp(bType,'SubSystem')	% verandert tov versie 1.3 (hoofdletter)
		if ~isempty(get_param(ssub,'MaskDisplay'))
			bMask = true;
			if false
				doesub=0;
				Mtran=get_param(ssub,'MaskTranslate');
				Mentr=get_param(ssub,'MaskEntries');
				ie=[-1 find((Mentr(1:length(Mentr)-1)=='\')&(Mentr(2:length(Mentr))=='/'))];
				die=2;
				if length(ie)==1
					die=1;
					ie=[0 find(Mentr=='|') length(Mentr)+1];
				end
				entrs=[];
				for i=1:length(ie)-1
					entrs=addstr(entrs,Mentr(ie(i)+die:ie(i+1)-1));
				end
				it=find(Mtran=='@');
				for i=length(it):-1:1
					k=it(i)+1;
					while (Mtran(k)>='0')&(Mtran(k)<='9')
						k=k+1;
					end
					Mtran=[Mtran(1:it(i)-1) deblank(entrs(str2num(Mtran(it(i)+1:k-1)),:)) Mtran(k:length(Mtran))];
				end
				v=Mtran;
			end		% removed
		else
			isSub=1;
			doesub=1;
		end
	elseif strcmp(bType, 'ToWorkspace')	% was zonder spatie
		v=sprintf('%s (%s)'  ...
			, get_param(ssub,'mat-name')       ...
			, get_param(ssub,'buffer')  ...
			);
	elseif strcmp(bType, 'From File')
		v=get_param(ssub,'File name');
	elseif strcmp(bType, 'To File')
		v=get_param(ssub,'File name');
	elseif strcmp(bType, 'Sine Wave')
		v=get_param(ssub,'amplitude');
		vn='Amplitude ';
		v2=get_param(ssub,'frequency');
		v2n='Frequency ';
	elseif strcmp(bType, 'Discrete Transfer Fcn')
		v=['(' get_param(ssub,'Denominator') ') / (' get_param(ssub,'Numerator') ')'];
		v2=get_param(ssub,'Sample time');
		v2n='Tsample ';
	elseif strcmp(bType, 'TransferFcn')	% was zonder spatie
		v=['(' get_param(ssub,'Denominator') ') / (' get_param(ssub,'Numerator') ')'];
	elseif strcmp(bType, 'Step Fcn')
		v=get_param(ssub,'Time');
		vn='Time ';
		v2=[get_param(ssub,'Before') ' --> ' get_param(ssub,'After')];
		v2n='Values ';
	elseif strcmp(bType, 'Rate Limiter')
		v=get_param(ssub,'Rising Slew Limit');
		vn='Rising Slew Limit ';
		v2=get_param(ssub,'Falling Slew Limit');
		v2n='Falling Slew Limit ';
	elseif strcmp(bType, 'MATLABFcn')	% was zonder spatie
		v=get_param(ssub,'MATLAB Fcn');
	end
	if isSub
		nr1=nr1+1;
		if isempty(nr)
			snr=sprintf('%d.',nr1);
		else
			snr=sprintf('%s%d.',nr,nr1);
		end
		if length(snr)>=length(ruimte)
			str=[str sprintf('%s%s : %s\n',snr, lb1, bType)];
		else
			str=[str sprintf('%s%s%s : %s\n'   ...
				, blanks(length(ruimte)-length(snr))      ...
				, snr  ...
				, lb1  ...
				, bType)];
		end
	else
		str=[str sprintf('%s%s : %s\n',ruimte, lb1, bType)];
	end
	if ~isempty(v)
		if isstr(v)
			str=[str sprintf('%s  %s= %s\n',ruimte, vn, v)];
		else
			str=[str sprintf('%s  %s= %f\n',ruimte, vn, v)];
		end
	end
	if ~isempty(v2)
		if isstr(v2)
			str=[str sprintf('%s  %s= %s\n',ruimte, v2n, v2)];
		else
			str=[str sprintf('%s  %s= %f\n',ruimte, v2n, v2)];
		end
	end
	if doesub
		str=[str getblcks(ssub,l+1,snr)];
	end
	b=b(2:end);
end    % while ~isempty(b)

if bMask
	warning('Masked subsystems functionality is removed due to incompatibility with current Simulink versions!!!')
end
