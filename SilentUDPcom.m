classdef SilentUDPcom < handle
	%SilentUDPcom - generic UDP communicator
	%      Usage:
	%           c = SilentUDPcom()	% (optional arguments are possible...)
	%           ....
	%           c.send('start_message',<IP-address>,<portnr>)
	%           ....
	%           while ...
	%               [msg,n_still_in_buffer] = c.getReceived();
	%               if ~isempty(msg)
	%                   [msgData,msgFromIP,msgFromPort] = deal(msg{:});
	%                   ....
	%           end
	%           ...
	%           c.stop()
	%
	%     Or without polling:
	%           c = SilentUDPcom('fcnReceived',@fcnReceived)
	%           ....
	%           function fcnReceived(msg,rcvIP,rcvPort)
	%               % handle msg
	%           end   % function fcnReceived
	
	properties
		tim
		socket
		addr

		myAddress = 'localhost'
		myPort = 50004
		tgtIP = '127.0.0.1'
		tgtPort = 50002
		maxRcvLen = 512

		fcnReceived
	end		% properties

	properties
		RCVD
	end		% properties

	methods
		function c = SilentUDPcom(varargin)
			% Code borrowed from O'Reilly Learning Java, edition 2, chapter 12.
			import java.io.*
			import java.net.DatagramSocket
			import java.net.InetAddress

			if nargin
				setoptions(c,varargin{:})
			end

			c.addr = InetAddress.getByName(c.myAddress);
			c.socket = DatagramSocket(c.myPort);
			c.socket.setSoTimeout(1);
			c.socket.setReuseAddress(1);

			c.tim = timer('Name','myUDPtimer','Period',0.01,'ExecutionMode','fixedDelay','TimerFcn',@c.rcvChecker);
			start(c.tim)
		end

		function rcvChecker(c,varargin)
			import java.net.DatagramPacket
			try
        		packet = DatagramPacket(zeros(1,c.maxRcvLen,'int8'),c.maxRcvLen);
        		c.socket.receive(packet);
        		mssg = packet.getData;
        		mssg = mssg(1:packet.getLength);     
        		inetAddress = packet.getAddress;
				inetPort = packet.getPort;
        		sourceHost = char(inetAddress.getHostAddress);
				if isempty(c.fcnReceived)
					%fprintf('Received from %s.%d: %d bytes\n',inetAddress,inetPort,length(mssg))
					msg = {mssg,sourceHost,inetPort};
					if isempty(c.RCVD)
						c.RCVD = {msg};
					else
						c.RCVD{1,end+1} = msg;
					end
				else
					c.fcnReceived(mssg,sourceHost,inetPort)
				end
			catch err %#ok<NASGU> 
			end
		end		% rcvChecker

		function send(c,message,tgtIP,tgtPort)
			import java.net.DatagramPacket
			import java.net.InetAddress
			if nargin<3 || isempty(tgtIP)
				tgtIP = c.tgtIP;
			end
			if nargin<4 || isempty(tgtPort)
				tgtPort = c.tgtPort;
			end
			if ischar(message)
				mssg = uint8(message);
			elseif isstring(message)
				mssg = uint8(char(message));
			else
				mssg = typecast(message,'uint8');
			end
			ADDR = InetAddress.getByName(tgtIP);
			packet = DatagramPacket(mssg, length(mssg), ADDR, tgtPort);
			c.socket.send(packet);
			%fprintf('Message is sent! (#%d bytes to %s@%d)\n',length(message),tgtIP,tgtPort)
		end		% send

		function [M,nAvail] = getReceived(c,n)
			if nargin<2 || isempty(n)
				n = 1;
			end
			if n<0	% "peek" - get without removing from buffer
				n = min(-n,length(c.RCVD));
				if n==1
					M = c.RCVD{1};
				else
					M = c.RCVD(1:n);
				end
			elseif n==0
				M = []; % do nothing (can be used to check the availability)
			elseif isempty(c.RCVD)
				M = [];
			else
				if n==1
					M = c.RCVD{1};
					c.RCVD(1) = [];
				else
					n = min(n,length(c.RCVD));
					M = c.RCVD(1:n);
					c.RCVD(1:n) = [];
				end
			end
			nAvail = length(c.RCVD);
		end		% getReceived

		function stop(c)
			if ~isempty(c.tim)
				if c.tim.Running=="on"
					stop(c.tim)
				end
				delete(c.tim)
				c.tim = [];
			end
			if ~isempty(c.socket)
				c.socket.close()
				c.socket = [];
			end
		end		% stop

		function close(c)
			c.stop()
		end		% close

		function delete(c)
			%fprintf('UDP-communicator started to be stopped.\n')
			c.stop()
			%fprintf('UDP-communicator is stopped.\n')
		end		% delete
	end		% methods
end		% SilentUDPcom
