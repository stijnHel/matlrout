classdef cCANnavHandler < handle
%cCANnavHandler - class to easily browse through data from MapCANDBC
%            c = cCANnavHandler(A) - with A result of MapCANDBC
%
%        browsing can be started with:
%           c.navmsrs()
%
%   see also MapCANDBC, cnavmsrs

	properties
		CAN		% CAN-data
		IDXmsgs	% indices of last signal in a message

		lastIdx
	end

	methods
		function c = cCANnavHandler(CANdata)
			c.CAN = CANdata;
			c.IDXmsgs = cumsum(cellfun('length',{CANdata.signals}));
			c.lastIdx = 0;
		end

		function [e,ne] = get(c, nr)
			iMsg = find(c.IDXmsgs>=nr,1);
			if iMsg==1
				j = nr;
			else
				j = nr-c.IDXmsgs(iMsg-1);
			end
			e = [c.CAN(iMsg).t,c.CAN(iMsg).X(:,j)];
			ne = {'t',c.CAN(iMsg).signals(j).signal};
			c.lastIdx = nr;
			% extend with unit - and maybe all signal data, and maybe
			%                    message data?
		end

		function [msg,sig] = getSignalInfo(c, nr)
			iMsg = find(c.IDXmsgs>=nr,1);
			if iMsg==1
				j = nr;
			else
				j = nr-c.IDXmsgs(iMsg-1);
			end
			msg = c.CAN(iMsg);
			sig = msg.signals(j);
		end		% getSignalInfo

		function [e,ne] = getMsg(c,iMsg)
			e = [c.CAN(iMsg).t,c.CAN(iMsg).X];
			ne = [{'t'},{c.CAN(iMsg).signals.signal}];
		end		% getMsg

		function n = length(c)
			n = c.IDXmsgs(end);
		end

		function RemoveConstantSignals(c)
			Bmsg = false(1,length(c.CAN));
			for i=1:length(c.CAN)
				B = false(1,length(c.CAN(i).signals));
				for j=1:length(B)
					mx = max(c.CAN(i).X(:,j));
					mn = min(c.CAN(i).X(:,j));
					if mx==mn
						B(j) = true;
					end
				end
				if all(B)
					Bmsg(i) = true;
				elseif any(B)
					c.CAN(i).signals(B) = [];
					c.CAN(i).X(:,B) = [];
				end
			end
			if any(Bmsg)
				c.CAN(Bmsg) = [];
			end
			c.IDXmsgs = cumsum(cellfun('length',{c.CAN.signals}));
			c.lastIdx = 0;
		end		% RemoveConstantSignals

		function navmsrs(c)
			cnavmsrs(num2cell(1:c.length()), @c.get, 'bVarSignames',true)
			%!!!!!!!!!!!! figure title is not correct!!!!!!
			% more info should be extracted (to be put in the figure name
			% or axis title):
			%       message idx/name/ID
			%           also signal unit?
		end

		% also make it possible to browse through full messages?
	end		% methods
end		% cCANnavHandler


