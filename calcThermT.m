function [T,dT]=calcThermT(R)
%calcThermT - Calculates thermister temperature
%    T=calcThermT(R)
%         calculates temperature from resister value
%    calcThermT type
%         initializes the sensor
%    calcThermT list for a list of sensors

global THERMdata

if nargin==0
	if nargout
		if isempty(THERMdata)
			setup KTY84/130
		end
		T=THERMdata;
	else
		setup KTY84/130
	end
	return
elseif ischar(R)
	if strcmp(R,'plot')
		getmakefig('ThermistorSpec');
		subplot 311
		plot(THERMdata(:,1),THERMdata(:,3:5));grid
		title 'min/max/typical resistor values'
		xlabel 'T [^oC]'
		ylabel 'R [\Omega]'
		subplot 312
		plot(THERMdata(:,1),THERMdata(:,2));grid
		title 'sensitivity'
		xlabel 'T [^oC]'
		ylabel 'dR/dT [%/K]'
		subplot 313
		plot(THERMdata(:,1),THERMdata(:,6));grid
		title 'accuracy'
		xlabel 'T [^oC]'
		ylabel '\deltaT [^oC]'
	else
		setup(R)
	end
	return
elseif isempty(THERMdata)
	error('Before using this function for conversion, it must be initialized!')
end
T=interp1(THERMdata(:,3),THERMdata(:,1),R);
if nargout>1
	dT=interp1(THERMdata(:,1),THERMdata(:,6),T);
end

function setup(typ)
global THERMdata

bList=strcmp(typ,'list');
fid=fopen('ThermSensors.txt');
if fid<3
	error('Can''t open sensor file')
end

bSet=false;
while ~feof(fid)
	l=fgetl(fid);
	if ~ischar(l)
		break
	end
	l=deblank(l);
	THERMdata=zeros(0,6);
	if ~isempty(l)
		if strncmp(l,'sensor',6)&&any(l==':')
			iSensor=0;
			nSensors=0;
			while strncmp(l,'sensor',6)&&any(l==':')
				nSensors=nSensors+1;
				i=find(l==':',1);
				sens=l(i+1:end);
				while sens(1)==' '||sens(1)==9
					sens(1)=[];
				end
				if bList
					disp(sens)
				elseif iSensor==0&&strcmp(sens,typ)
					iSensor=nSensors;
					bSet=true;
				end
				l=fgetl(fid);
			end		%  while sensor name
			l=fgetl(fid);
			if length(l)<1||~ischar(l)||l(1)~='T'
				warning('!!!!error in sensor-file!!!!')
				break
			end
			l=fgetl(fid);
			while ~isempty(l)&&ischar(l)
				if iSensor>0
					[temp,n,err,iN]=sscanf(l,'%g',[1 3]);
					if n<3
						continue	%?!!
					end
					l=l(iN:end);
					for iS=1:iSensor
						[R,n,err,iN]=sscanf(l,'%g',[1 3]);
						if n<3
							R=[];
							break
						end
						l=l(iN:end);
						while l(1)==' '||l(1)==9
							l(1)=[];
						end
						if l(1)>'9'
							l(1)=[];
						end
						[R4,n,err,iN]=sscanf(l,'%g',1);
						if n==1
							R(4)=R4;
						end
						l=l(iN:end);
					end		% for iS
					if length(R)==4
						THERMdata(end+1,:)=[temp([1 3]) R];
					end
				end		% if iSensor>0
				l=fgetl(fid);
			end		% while ~isempty(l) - end of table
			if ~bList&&iSensor
				break
			end
		end		% sensor list
	end
end
fclose(fid);
if bList
	return
end
if bSet
	if isempty(THERMdata)
		warning('sensor data read but empty!!!???')
	end
else
	error('Sensor could''nt be found!!')
end
