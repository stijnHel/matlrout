function l=plot(r,varargin)
% CRIJCYCLUS/PLOT - plot de rijcyclus
%    Snelheid wordt geplot in km/h

l1=plot(r.Vlijst(:,1),r.Vlijst(:,2)*3.6,varargin{:});	% plot in km/h
if nargout
	l=l1;
end
