classdef cPlanet < handle
	%cPlanet - class definition of orbital calculations of a planet
	%     this is just started (mainly "only an idea")
	%  the goal is to use it in a flexible way, e.g. in combination with
	%  calcposhemel

	% see https://newton.spacedys.com/astdys

	properties	(Constant, Access = private)
		mu0 = 1.32712440041e20
		AU = unitcon('AU')
		degree = pi/180;
	end		% properties

	properties (Access = private)
		mu
	end		% private properties

	properties
		name
		elem_epoch	% MJD
		elem_a	% semimajor axis [m]
		elem_e	% eccentricity [-]
		elem_i	% inclination [rad]
		elem_O	% longitude of the ascending node [rad]
		elem_o	% argument of periapsis [rad]
		elem_M	% mean anomaly [rad]
		other
		% (add "proper elements"?)
	end		% properties

	methods
		function c = cPlanet(varargin)
			if ischar(varargin{1})
				c.name = varargin{1};
				El = GetElements(c.name);
			elseif isstruct(varargin{1})
				El = varargin{1};
			else
				error('Unknown input')
			end
			c.mu = c.mu0;
			c.other = struct();
			fn = fieldnames(El);
			for i=1:length(fn)
				switch fn{i}
					case {'epoch','e'}
						c.(['elem_',fn{i}]) = El.(fn{i});
					case 'a'
						c.(['elem_',fn{i}]) = El.(fn{i})*c.AU;
					case {'i','O','o','M'}
						c.(['elem_',fn{i}]) = El.(fn{i})*c.degree;
					otherwise
						c.other.(fn{i}) = El.(fn{i});
				end
			end
		end		% cPlanet

		function [p,v] = CalcPos(c,t)
			%cPlanet/CalcPos - calculate position (and speed) in cart. coors.
			%      [p,v] = c.CalcPos(t)
			if t(1)<1	% expecting julian century(!)
				t = calcjd(t);
			end
			%CalcPos - Calculates position at time (t - JD)
			if size(t,1)~=1
				p = zeros(size(t,1),3);
				if nargout>1
					v = zeros(size(t,1),3);
					for i=1:size(t,1)
						[p(i,:),v(i,:)] = c.CalcPos(t(i,:));
					end
				else
					for i=1:size(t,1)
						p(i,:) = c.CalcPos(t(i,:));
					end
				end
				return
			end
			dt = 86400*(t-c.elem_epoch);
			M = c.elem_M+dt*sqrt(c.mu/c.elem_a^3);
			E = CalcEccAnom(M,c.elem_e);
			nu = 2*atan2(sqrt(1+c.elem_e)*sin(E/2),sqrt(1-c.elem_e)*cos(E/2));
			r = c.elem_a*(1-c.elem_e*cos(E));
			% position in orbital frame
			ox = r*cos(nu);
			oy = r*sin(nu);
			p = [ox*(cos(c.elem_o)*cos(c.elem_O)-sin(c.elem_o)*cos(c.elem_i)*sin(c.elem_O))	...
					- oy*(sin(c.elem_o)*cos(c.elem_O)+cos(c.elem_o)*cos(c.elem_i)*sin(c.elem_O)),	...
				ox*(cos(c.elem_o)*sin(c.elem_O)+sin(c.elem_o)*cos(c.elem_i)*cos(c.elem_O))	...
					+ oy*(cos(c.elem_o)*cos(c.elem_i)*cos(c.elem_O)-sin(c.elem_o)*sin(c.elem_O)),	...
				ox*sin(c.elem_o)*sin(c.elem_i)+oy*cos(c.elem_o)*sin(c.elem_i)];
			if nargout>1
				f = sqrt(c.mu*c.elem_a)/r;
				vx = -f*sin(E);
				vy = f*sqrt(1-c.elem_e^2)*cos(E);
				v = [vx*(cos(c.elem_o)*cos(c.elem_O)-sin(c.elem_o)*cos(c.elem_i)*sin(c.elem_O))	...
						- vy*(sin(c.elem_o)*cos(c.elem_O)+cos(c.elem_o)*cos(c.elem_i)*sin(c.elem_O)),	...
					vx*(cos(c.elem_o)*sin(c.elem_O)+sin(c.elem_o)*cos(c.elem_i)*cos(c.elem_O))	...
						+ vy*(cos(c.elem_o)*cos(c.elem_i)*cos(c.elem_O)-sin(c.elem_o)*sin(c.elem_O)),	...
					vx*sin(c.elem_o)*sin(c.elem_i)+vy*cos(c.elem_o)*sin(c.elem_i)];
			end
		end		% CalcPos

		function El = GetElements(c)
			% Get elements of this instance
			El = struct('epoch',c.elem_epoch,'a',c.elem_a/c.AU,'e',c.elem_e	...
				,'i',c.elem_i/c.degree,'O',c.elem_O/c.degree,'o',c.elem_o/c.degree,'M',c.elem_M/c.degree);
		end		% GetElements

	end		% methods
end		% cPlanet

function El = GetElements(name)
% GetElements - Function to get orbital elements (based on name)
%   El = GetElements(name)
%      the idea is to have a collection of files with elements
%  distance in AU
%  angles in degrees

switch lower(name)
	case '16 psyche'
		El = struct('epoch',{{56703.6,'MJD'}},'a',2.92303,'e',0.136518,'i',3.099,'O',150.277,'o',227.128,'M',276.213);
	case '20 massalia'
		El = struct('epoch',{{60600.0,'MJD'}},'a',2.40792,'e',0.143731,'i',0.709,'O',205.979,'o',257.457,'M',284.31);
	case 'mars'
		El = struct('epoch',{{60600.0,'MJD'}},'a',1.5237,'e',0.0934,'i',1.850	...
			,'O',0,'o',0,'M',0);	%!!!!!!!!!!!!!!!!
	case 'venus'
		El = struct('epoch',{{60600.0,'MJD'}},'a',0.72333,'e',0.0068,'i',3.39	...
			,'O',0,'o',0,'M',0);	%!!!!!!!!!!!!!!!!!!
	case 'earth'
		El = struct('epoch',{{2451545.0,'JD'}},'a',1,'e',0.016786	...
			,'i',1.578690	...???????????
			,'O',174.9,'o',288.1	... correct?
			,'M',0	...
			,'extra',struct('diam',12756.26e3)	...
			);	% !!!!!!!!
	case 'moon'	% vooral voor "extra gegevens"!!!!
		El = struct(	... Epoch J2000
			'a',384399e3, 'e',0.054, 'i',5.1459	... (1/384 AU)
			,'extra',struct('diam',3476.26e3	...
				,'longAscNode',1/18.61	... 1 rev/18.61 year (from https://en.wikipedia.org/wiki/Moon)
				,'ArgPerigee',1/8.85	... 1 rev/8.85 year
				)	...
			);
	otherwise
		%El = struct('epoch',{{60600.0,'MJD'}},'a',,'e',,'i',,'O',,'o',,'M',);
		error('Unknown element')
end
if iscell(El.epoch)
	t = El.epoch{1};
	switch El.epoch{2}
		case 'JD'
			El.epoch = t;
		case 'MJD'	% modified Julian Day
			El.epoch = t+2400000.5;
		otherwise
			error('Unknown epoch-unit')
	end
end
end		% GetElements

function E = CalcEccAnom(M,e)
%quickly written solution of Keppler's equation
E = M;
En = E-(E-e*sin(E)-M)/(1-e*cos(E));
while abs(E-En)>1e-7
	E = En;
	En = E-(E-e*sin(E)-M)/(1-e*cos(E));
end
E = En;
end % CalcEccAnom
