function [D,NE,V,G,X] = AnalyseGPSdata(X,varargin)
%AnalyseGPSdata - Analyse GPS data
%   Analyses GPS-data (e.g. from ReadFIT or ReadGPX)
%        to make it usable for other file types.
%    [D,G] = AnalyseGPSdata(X,...)
%
%     X: array with in first 3 columns T, latitude, longitude
%
% See also ReadFIT, ReadGPX, cGPStrack

% !!!!! review of functionality of this function, and cGPStrack is
%       necessary!!!
% NaN's are discarded when separating blocks? (also causing short
%    "non-block") being "glued" to the next (or previous) block?!
%    --> solved(?)

[bDispAnal] = true;	% display analysis-results (if analysed)
[bRemoveNonBlocks] = true;	% remove "non-blocks" - too short blocks (currently only start and end)
[bGPX] = false;
[Vgps] = [];
[iVgps] = [];
[Altitude] = [];
[iAltitude] = [];
fileGPX = [];
maxStandStillTime = 5/1440;
minKeepBlockInterTime = 3/24;
minDistBlock = 500;
minVedges = 0.1;
Z1 = [];
[bPlot] = nargout==0;
[bBelgiPlot] = false;
[bFixedFigures] = false;
[bUseGeoaxes] = false;	% use geoaxes
figTagNEtime = [];
figTagVHD = [];
figTagNE = [];
fTitle = '';
if nargin>1
	setoptions({'Z1','bRemoveNaNs'	...
		,'bPlot','maxStandStillTime','minKeepBlockInterTime','minDistBlock','minVedges','bBelgiPlot'	...
		,'Vgps','iVgps','Altitude','iAltitude'	...
		,'bDispAnal','bRemoveNonBlocks','bFixedFigures','bUseGeoaxes'	...
		,'figTagNEtime','figTagVHD','figTagNE','fTitle'	...
		},varargin{:})
end
bGPX=bGPX||ischar(fileGPX);
if bFixedFigures
	figTagNEtime = 'NEtimePlot';
	figTagVHD = 'VHDplot';
	figTagNE = 'NEplot';
end

if bPlot && bBelgiPlot	% (put here to have Z1)
	if isempty(figTagNE)
		nfigure
	else
		getmakefig(figTagNE)
	end
	[l,~,Z1]=PlotGemeentes();
	set(l,'Hittest','off')
	Z1 = Z1([2 1]);
end
[NE,V,~,Z1]=ProjGPS2XY(X(:,1:3),'Z1',Z1);
dPts = sqrt(sum(diff(NE).^2,2));
Dtot=sum(dPts(~isnan(dPts)));
if isempty(Vgps)
	if isempty(iVgps)
		Vgps = [V(1);middlepoints(V);V(end)];
	else
		Vgps = X(:,iVgps);
	end
end
if isempty(Altitude)
	if ~isempty(iAltitude)
		Altitude = X(:,iAltitude);
	end
end
if bGPX
	Sxml=CreateGPX(X);
	if isempty(fileGPX)
		D=Sxml;
	end
	if ~isempty(fileGPX)
		fid=fopen(fileGPX,'w');
		if fid<3
			error('Can''t open the file!!')
		end
		fwrite(fid,Sxml);
		fclose(fid);
	end
end
t0X = X(1);
t0Data = datenum(1989,12,31,1,0,0);
t0 = t0X/86400+t0Data;
if isDST(t0)
	t0 = t0+1/24;
end
dD = dPts;
dD(isnan(dD)) = 0;
cumD = [0;cumsum(dD)];

% Short blocks in the file (not start/end) result in extension of
% blocks of data.  This is not "expected behaviour".
% Better to extend removing first/last block to remove all
% "nonblocks" (with a larger standstill-time than
% maxStandStillTime).
% Now the "internal non-blocks" are kept.
Bnan = isnan(X(:,1));
BnanFirst = Bnan;
BnanFirst(find(Bnan(1:end-1)&Bnan(2:end))+1) = false;
%jj = [0;find(diff(X(:,1))>maxStandStillTime);size(X,1)];
jj = [0;find(diff(X(:,1))>maxStandStillTime|BnanFirst(1:end-1));size(X,1)];
lBlock = cumD(jj(2:end))-cumD(jj(1:end-1)+1);
dtGap = (X(jj(2:end-1)+1)-X(jj(2:end-1)));
BshortStop = [true;dtGap(1:end-1)<minKeepBlockInterTime;true];
	% short-stop is a quick help to avoid blocks extended with
	% non-blocks a long time after the block)
%Bshort = lBlock<minDistBlock;
Bshort = lBlock<minDistBlock & BshortStop;
jj0 = jj;	% if last part has to be removed
jj(Bshort) = [];
if isempty(jj)
	warning('No valid block?!')
else
	if bRemoveNonBlocks && ~isempty(jj)
		if Bshort(1)	% remove starting samples
			X(1:jj(1),:) = [];
			NE(1:jj(1),:) = [];
			V(1:jj(1)) = [];
			if ~isempty(Altitude)
				Altitude(1:jj(1)) = [];
			end
			if ~isempty(Vgps)
				Vgps(1:jj(1)) = [];
			end
			dPts(1:jj(1)) = [];
			cumD = cumD(jj(1)+1:end)-cumD(jj(1)+1);
			jj0 = jj0-jj(1);
			jj = jj-jj(1);
		end
		if Bshort(end)
			jEnd = jj0(find(~Bshort,1,'last')+1);
			jj(end) = jEnd;
			X(jEnd+1:end,:) = [];
			NE(jEnd+1:end,:) = [];
			V(jEnd:end) = [];
			if ~isempty(Altitude)
				Altitude(jEnd+1:end) = [];
			end
			if ~isempty(Vgps)
				Vgps(jEnd+1:end) = [];
			end
			dPts(jEnd:end) = [];
			cumD(jEnd+1:end) = [];
		end
		Dtot = cumD(end);
	end
	jjStart = jj(1:end-1)+1;
	jjEnd = jj(2:end);
	nBlock = length(jjStart);
	for ix = 1:nBlock
		BlowSpeed = Vgps(jjStart(ix):jjEnd(ix))<minVedges;
		if all(BlowSpeed(1:end-1)|BlowSpeed(2:end))
			% block with only very low speed!!
			% just keep the block...
		else
			while any(Vgps(jjStart(ix)+[0 1])<minVedges)
				jjStart(ix) = jjStart(ix)+1;
			end
			while any(Vgps(jjEnd(ix)+[-1 0])<minVedges)
				jjEnd(ix) = jjEnd(ix)-1;
			end
		end
	end
	lBlock = cumD(jjEnd)-cumD(jjStart);
	dtBlock = (X(jjEnd)-X(jjStart))*86400;
	Vblock = lBlock./dtBlock*3.6;	% (!) km/h
	if ~isempty(Altitude)
		DH = diff(Altitude);
		dH = Altitude(jjEnd)-Altitude(jjStart);
		dHasc = zeros(1,nBlock);
		dHdesc = zeros(1,nBlock);
		for ix=1:nBlock
			DH_i = DH(jjStart(ix):jjEnd(ix)-1);
			dHasc(ix) = sum(max(0,DH_i));
			dHdesc(ix) = -sum(min(0,DH_i));
		end
	end

	D.Tblock = [X(jjStart,1),X(jjEnd,1)];
	D.lBlock = lBlock';
	D.dtBlock = dtBlock';
	D.Vblock = Vblock';
	if ~isempty(Altitude)
		D.dH = dH';
		D.dHasc = dHasc;
		D.dHdesc = dHdesc;
	end
	if bDispAnal
		for ix=1:nBlock
			fprintf('%s..%s - %5.1f km, %5.2f hr, %6.2f km/h\n'	...
				,datestr(D.Tblock(ix)),datestr(D.Tblock(ix,2))	...
				,lBlock(ix)/1000,dtBlock(ix)/3600,Vblock(ix)	...
				)
		end
	end
end
t0_ts = datetime(t0,'ConvertFrom','datenum');
G = var2struct(Dtot,Z1,t0,t0_ts,dPts,cumD);

if bPlot
	if bBelgiPlot
		line(NE(:,2),NE(:,1),'Color',[1 0 0],'LineWidth',1.5)
		ax1 = gca;
		ax1.ButtonDownFcn = @PointClicked;
		G.cGEO = CreateGeography('country','Belgium','-bStoreCoors');
		axis equal;
	elseif bUseGeoaxes
		if isempty(figTagNE)
			nfigure;
		else
			[~,bN] = getmakefig(figTagNE);
			if ~bN
				clf;	% to make it easy... (and prevent multiple axes)
			end
		end
		ax1 = geoaxes;
		geobasemap streets
		plot(ax1,X(:,2),X(:,3),'LineWidth',2);
	else
		ax1 = plotmat(NE,1,2,[],[],'fig',figTagNE);
		axis equal;
	end
	title(fTitle,'Interpreter','none')
	ax2=plotmat(NE/1000,[],X(:,1),{'North','East'},{'km','km'}	...
		,'-btna','fig',figTagNEtime);
	xlabel(fTitle,'Interpreter','none')
	fig2 = ancestor(ax2(1),'figure');
	if isempty(figTagVHD)
		fig3 = nfigure;
		bNew3 = true;
	else
		[fig3,bNew3] = getmakefig(figTagVHD);
	end
	if isempty(Altitude)
		nP = 2;
		ax3 = gobjects(1,nP);
	else
		nP = 3;
		ax3 = gobjects(1,nP);
		ax3(2) = subplot(nP,1,2);
		plot(X(:,1),Altitude);grid
		ylabel('[m]')
		title('Altitude')
	end
	ax3(1) = subplot(nP,1,1);
	bLoop = true;
	while bLoop
		bLoop = false;
		[mxV,iMx] = max(V);
		if mxV<1
			break
		elseif iMx==1
			if V(2)<mxV/4
				V(1) = V(2);
				bLoop = true;
			end
		elseif iMx==length(V)
			if V(end-1)<mxV/4
				V(end) = V(end-1);
				bLoop = true;
			end
		elseif all(V(iMx+[-1 1])<mxV/4)
			V(iMx) = mean(V(iMx+[-1 1]));
			bLoop = true;
		end
	end
	plot([X(1);middlepoints(X(:,1))],V([1 1:end])*3.6);grid
		% extended with one point, so that the link with volglijn works
		% correctly
	title 'Speed'
	ylabel '[km/h'
	ax3(nP) = subplot(nP,1,nP);
	plot(X(:,1),cumD/1000);grid
	title 'Cumulative distance'
	if ~isempty(fTitle)
		xlabel(fTitle,'Interpreter','none')
	end
	ylabel '[km]'
	if bNew3
		navfig
		navfig(char(4))
	end
	navfig X
	if ~isempty(Altitude)
		for ix=1:min(10,length(dH))
			navfig(fig2,'addkey',num2str(rem(ix,10)),1,{1,D.Tblock(ix,:)})
			if ~isempty(fig3)
				navfig(fig3,'addkey',num2str(rem(ix,10)),1,{1,D.Tblock(ix,:)})
			end
		end
	end
	tFigs = [fig2,fig3];
	figXY = ancestor(ax1,'figure');
	volglijn(tFigs,figXY)
	set([ancestor(ax1,'figure'),tFigs],'UserData',var2struct(X,NE,V,G))
	if isempty(Vgps)
		Vjj1 = V(jj(1:end-1)+1);
		Vjj2 = V(min(jj(2:end),end));
	else
		Vjj1 = Vgps(jj(1:end-1)+1);
		Vjj2 = Vgps(jj(2:end));
	end
	line(D.Tblock(:,1),Vjj1*3.6,'Color',[0 0.75 0]	...
		,'HitTest','off','PickableParts','none'		...
		,'Linestyle','none','Marker','o','Tag','blockData','Parent',ax3(1))
	line(D.Tblock(:,2),Vjj2*3.6,'Color',[1 0 0]	...
		,'HitTest','off','PickableParts','none'		...
		,'Linestyle','none','Marker','x','Tag','blockData','Parent',ax3(1))
	if nP==3
		line(D.Tblock(:,1),Altitude(jj(1:end-1)+1),'Color',[0 0.75 0]	...
			,'HitTest','off','PickableParts','none'		...
			,'Linestyle','none','Marker','o','Tag','blockData','Parent',ax3(2))
		line(D.Tblock(:,2),Altitude(jj(2:end)),'Color',[1 0 0]	...
			,'HitTest','off','PickableParts','none'		...
			,'Linestyle','none','Marker','x','Tag','blockData','Parent',ax3(2))
	end
	line(D.Tblock(:,1),cumD(jj(1:end-1)+1)/1000,'Color',[0 0.75 0]	...
		,'HitTest','off','PickableParts','none'		...
		,'Linestyle','none','Marker','o','Tag','blockData','Parent',ax3(nP))
	line(D.Tblock(:,2),cumD(jj(2:end))/1000,'Color',[1 0 0]	...
		,'HitTest','off','PickableParts','none'		...
		,'Linestyle','none','Marker','x','Tag','blockData','Parent',ax3(nP))
	navfig('link',tFigs)
	volglijn('setKeyFun',@MyKeyHandling)
	setappdata(figXY,'GPSdata',D)
end

end		% AnalyseGPSdata

function Sxml=CreateGPX(X)
Cbase=struct('type',2,'tag','','fields',[],'data',[],'children',[]);
CptBase=Cbase;
CptBase.tag='trkpt';
CptBase.fields={'lat',0;'lon',0};
CptBase.children=Cbase([1,1]);
CptBase.children(1).tag='ele';
CptBase.children(2).tag='time';

C=Cbase([1 1]);
C(1).tag='xml';
C(1).type=1;
C(1).fields={	...
	'version','1.0';
	'encoding','UTF-8';
	'standalone','no'};
C(2).tag='gpx';
C(2).fields={	... what's required?
	'xmlns'              'http://www.topografix.com/GPX/1/1'
	'xmlns:gpxx'         'http://www.garmin.com/xmlschemas/GpxExtensions/v3'
	'xmlns:gpxtrkx'      'http://www.garmin.com/xmlschemas/TrackStatsExtension/v1'
	'xmlns:wptx1'        'http://www.garmin.com/xmlschemas/WaypointExtension/v1'
	'xmlns:gpxtpx'       'http://www.garmin.com/xmlschemas/TrackPointExtension/v1'
	'creator'            'Oregon 700'
	'version'            '1.1'
	'xmlns:xsi'          'http://www.w3.org/2001/XMLSchema-instance'
	'xsi:schemaLocation' 'http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd http://www.garmin.com/xmlschemas/GpxExtensions/v3 http://www8.garmin.com/xmlschemas/GpxExtensionsv3.xsd http://www.garmin.com/xmlschemas/TrackStatsExtension/v1 http://www8.garmin.com/xmlschemas/TrackStatsExtension.xsd http://www.garmin.com/xmlschemas/WaypointExtension/v1 http://www8.garmin.com/xmlschemas/WaypointExtensionv1.xsd http://www.garmin.com/xmlschemas/TrackPointExtension/v1 http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd'
	};

Cc=Cbase;
Cc.tag='trk';
Ctrk=Cbase([1 1]);
Ctrk(1).tag='name';
Ctrk(1).data={GetStime(X(1))};
	% expecting that extensions are not necessary
Ctrk(2).tag='trkseg';	% more segments?
nPts=size(X,1);
Ctrk(2).children=CptBase(1,ones(1,nPts));
Bok=false(1,nPts);
for i=1:nPts
	if ~any(isnan(X(i,2:3)))
		Bok(i)=true;
		Ctrk(2).children(i).fields{1,2}=sprintf('%.6f',X(i,2));
		Ctrk(2).children(i).fields{2,2}=sprintf('%.6f',X(i,3));
		if isnan(X(i,8))
			Ctrk(2).children(i).children(1).data={'0'};
		else
			Ctrk(2).children(i).children(1).data={sprintf('%.2f',X(i,8))};
		end
		Ctrk(2).children(i).children(2).data={GetStimeUTC(X(i))};
	end
end
if ~all(Bok)
	Ctrk(2).children=Ctrk(2).children(Bok);
end
Cc.children=Ctrk;

C(2).children=Cc;
Xxml=struct('type',0,'tag','root','from','fileXXXXX','data',[]	...
	,'children',C);
Sxml=writexml(Xxml);
end		% CreateXML

function s=GetStime(X)
persistent t0
if isempty(t0)
	t0=datenum(1989,12,31);
end
s=datestr(X/86400+t0);
end		% GetStime

function s=GetStimeUTC(X)
persistent t0
if isempty(t0)
	t0=datenum(1989,12,31);
end
s=datestr(X/86400+t0,'yyyy-mm-ddTHH:MM:SSZ');
end		% GetStimeUTC

function PointClicked(ax,ev)
f = ancestor(ax,'figure');
xl = xlim(ax);
yl = ylim(ax);
pt = ev.IntersectionPoint;
if pt(1)<xl(1) || pt(1)>xl(2) || pt(2)<yl(1) || pt(2)>yl(2)
	% do nothing if clicked outside the axes-space
	return
end
D = f.UserData;
p = ProjGPS2XY(pt([2 1]),'Z1',D.G.Z1,'-bInverse');
[name,cntry] = D.G.cGEO.FindCommunity(p);
if ~isempty(name)
	if ~strcmpi(cntry,'BEL')
		name = [cntry,':',name];
	end
end
xlabel(name)
end		% PointClicked

function MyKeyHandling(S,c)
if c=='W'
	FPOS = {'NEplot',[1036 390 872 653];
		'NEtimePlot',[29 497 945 539];
		'VHDplot',[29 5 944 598];
		};
	for i=1:size(FPOS,1)
		f = getmakefig(FPOS{i},false,false);
		if ~isempty(f)
			set(f,'Position',FPOS{i,2})
		end
	end
elseif c==1	% ctrl-A - analyse based on markers
	m1 = getappdata(S.fvast,'marker1');
	m2 = getappdata(S.fvast,'marker2');
	if isempty(m1) || isempty(m2)
		errordlg('Two markers are required (use ctrl-P and ctrl-Q to set them)')
		return
	elseif m1==m2
		errordlg('Two markers must be different!!')
		return
	elseif m1>m2
		[m2,m1] = deal(m1,m2);
	end
	D = get(S.fvast,'UserData');
	disp([m1,m2])
	l = D.G.cumD(m2)-D.G.cumD(m1);
	dt = (D.X(m2)-D.X(m1))*86400;
	v = l/dt;
	%!!!!!!!!!!!!?????????????? fit <-> gpx data !!!!!!!!!!!!!
	if l<2000
		fprintf('%s..%s - %4.0f m, %5.0f sec, %6.2f km/h\n'	...
			,datestr(D.X(m1)),datestr(D.X(m2))	...
			,l,dt,v*3.6	...
			)
	else
		fprintf('%s..%s - %5.1f km, %5.2f hr, %6.2f km/h\n'	...
			,datestr(D.X(m1)),datestr(D.X(m2))	...
			,l/1000,dt/3600,v*3.6	...
			)
	end
end
end		% MyKeyHandling
