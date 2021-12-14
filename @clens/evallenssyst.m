function [EptOut,IntPts]=evallenssyst(L,Lpos,varargin)%evallenssyst - Evalueert een lens-systeem%  !!!!niet klaar% werk voorlopig enkel met sferische lenzen% en werk voorlopig volledig "cirkel-symmetrisch" (enkel Y pos en richting)sPts=[];nDirs=11;xEnd=1;bPlot=nargin==0;bHoldMis=false;	% houd stralen die niet door alle lenzen gaaniArrange=1;if ~isempty(varargin)	setoptions({'sPts','nDirs','xEnd','bPlot','bHoldMis','iArrange'},varargin{:});endif isempty(sPts)	sPts=[-1e4 0;-1e4 1];endnPts=size(sPts,1);if isstruct(Lpos)	LposS=Lpos;	Lpos=zeros(3,2,length(LposS));	for i=1:length(LposS)		if i==1			if LposS(i).lens~=1				warning('!!!supposed here to have lens 1,2,3,...!!! (%d)',i)			end		elseif LposS(i).lens~=LposS(i-1).lens+1			warning('!!!supposed here to have lens 1,2,3,...!!! (%d)',i)		end		Lpos(:,1,i)=LposS(i).pos;		Lpos(:,2,i)=LposS(i).orientatie;	end		% for iend		% if isstruct(Lpos)d1=L(1).D.D;rays=struct('pts',cell(nDirs,nPts),'ok',true);Epts=zeros(3,2,nDirs,nPts);rUse=d1/2.002;for iPt=1:nPts	x0=sPts(iPt,:)';	if length(x0)<3		x0(3)=0;	end	dmin=(Lpos(2)-x0(2)-rUse)/(Lpos(1)-x0(1));	dmax=(Lpos(2)-x0(2)+rUse)/(Lpos(1)-x0(1));	d=dmin:(dmax-dmin)/(nDirs-1):dmax;		for jDir=1:nDirs		x1=x0;		d1=[1;d(jDir);0];		rays(jDir,iPt).pts=x1;		bMis=false;		for kLens=1:length(L)			[Xuit,Xintern]=straal(L(kLens),[x1 d1],Lpos(:,:,kLens));			if isempty(Xintern)	% not through lens - stop				bMis=true;				rays(jDir,iPt).ok=false;				break;			end			rays(jDir,iPt).pts(:,end+1:end+size(Xintern,2))=Xintern(1:3,:);			x1=Xuit(:,1);			d1=Xuit(:,2);		end		if ~bMis			rays(jDir,iPt).pts(:,end+1)=x1;		end		rays(jDir,iPt).pts(:,end+1)=x1+(xEnd-x1(1))/d1(1)*d1;		Epts(:,:,jDir,iPt)=[x1 d1];	end	% for jDirend	% for iPtif bPlot	delete(plot(0,0));	% default plot-settings	grid	for i=1:length(L)		plot(L(i),Lpos(:,2,i),Lpos(:,1,i));	end	rays(1,1).l=[];	for i=1:numel(rays)		if rays(i).ok			rays(i).l=line(rays(i).pts(1,:),rays(i).pts(2,:));		end	end	switch iArrange	case 1	% color per point		for iPt=1:nPts			cc=[1 0 0]*(iPt-1)/(nPts-1)+[0 1 0]*(nPts-iPt)/(nPts-1);			for jDir=1:nDirs				if rays(jDir,iPt).l					set(rays(jDir,iPt).l,'color',cc)				end			end		end	case 2	% color per dir		for jDir=1:nDirs			cc=[1 0 0]*(jDir-1)/(nDirs-1)+[0 1 0]*(nDirs-jDir)/(nDirs-1);			for iPt=1:nPts				if rays(jDir,iPt).l					set(rays(jDir,iPt).l,'color',cc)				end			end		end	end	% switch iArrangeend	% if bPlotif nargout	EptOut=Epts;	if nargout>1		IntPts=rays;	endend