classdef cGenKeyPressHandler < handle
	%cGenKeyPressHandler - Generic key-press-handler
	%
	% examples:
	%   1. set keys(/chars) one by one
	%        c = cGenKeyPressHandler(fig)
	%        c.AddKey('a',@(fig,k) fprintf('Key pressed: "%s" in figure %g\n',k,double(fig)))
	%        ---> something will be printed when pressing 'a'
	%   2. direct configuration
	%        cGenKeyPressHandler(fig,'Keys',{<key>,<fcn>,<mod>,<help-text>;...})
	%
	%       mod: if empty - discard modifier keys
	%           !!!!!!!!!!!!!!!!!!!!!!!!!!! this is not yet implemented !!!!!!!!!!!!!!
	%                      !!!!     (implemented but not tested)  !!!!
	%            if numeric: only handle without any modifier
	%            if char: this modifier key must have been pressed
	%            if cell-vector: all given modifier keys must be pressed
	%
	%  by default, a "help-functionality" is implemented ("F1")
	%     can be overridden (by adding Key-handler for 'F1')
	%
	% other possibility
	%      create subclass with "internal handling"
	%
	% Warnings:
	%      numeric keys on the numpad have 'numpad[0-9]' as key
	%         for reaction on digits (independent of the type of key), use
	%         'char' rather than 'key'!
	%      ctrl-keys can be handled in two ways (only one that currently
	%      works):
	%          - ctrl-<letter> ---> char codes 1-26
	%             only works for letters
	%          - modifier values (not working yet)

	% to do:
	%     - some code is made to handle modifiers (shift, ctrl, ...) but
	%       (possibly) not fully functional
	%     - Keys handle multiple modifiers better thanb Chars!

	% ideas:
	%     - add property to make help-window a modal dialog
	%     - add the possibility for "default handling"
	%         (not implemented keys)

	properties
		name = 'KeyPress'
		Keys = struct('key',cell(1,0),'fcn',[],'mod',[],'help','')
		Chars = struct('ch',cell(1,0),'fcn',[],'mod',[],'help','')
	end

	methods

		function c = cGenKeyPressHandler(fig,varargin)
			%cGenKeyPressHandler - constructor
			%       c = cGenKeyPressHandler(<fig>,<options>)
			%           if fig supplied - keypress-handler "installed"
			%           options:
			%               keys - cell array with key-handlers in rows
			%               chars - cell array with char-handlers in rows
			%               name - used in help-fcn
			keys = [];
			chars = [];
			name = [];
			if ~isempty(varargin)
				setoptions({'keys','chars','name'},varargin{:})
			end
			if nargin && ~isempty(fig)
				set(fig,'KeyPressFcn',@c.HandleEvent)
			end
			for i=1:size(keys,1)
				c.AddKey(keys{i,:});
			end
			for i=1:size(chars,1)
				c.AddChar(chars{i,:});
			end
			if ~isempty(name)
				c.name = name;
			end
		end		% cGenKeyPressHandler

		function AddKey(c,k,f,mod,help)
			%AddKey - Add (or replace) key handler
			%       c.AddKey(<key>,<function>,<modifier>,<help-string>)
			K = struct('key',k,'fcn',f,'mod',[],'help','');
			if nargin>3
				if isstringlike(mod)
					mod = {mod};
				end
				K.mod = mod;
			end
			if nargin>4
				K.help = help;
			end
			if isempty(c.Keys)
				c.Keys = K;
			else
				B = strcmp({c.Keys.key},k);
				if any(B)
					Bm = CheckModifiers(c.Keys(B),K);
					if any(Bm)
						ii = find(B);
						c.Keys(ii(Bm)) = K;
					else
						c.Keys(end+1) = K;
					end
				else
					c.Keys(end+1) = K;
				end
			end
		end		% AddKey

		function AddChar(c,ch,f,mod,help)
			%AddChar - Add (or replace) char-handler
			%       c.AddChar(<char>,<function>,<modifier>,<help-string>)
			if isnumeric(ch)	% assuming ASCII code
				ch = char(ch);
			end
			C = struct('char',ch,'fcn',f,'mod',[],'help','');
			if nargin>3
				if isstringlike(mod)
					mod = {mod};
				end
				C.mod = mod;
			end
			if nargin>4
				C.help = help;
			end
			if isempty(c.Chars)
				c.Chars = C;
			else
				B = strcmp({c.Chars.char},ch);
				if any(B)
					if sum(B)>1
						error('Sorry, chars with different modifiers is not (yet) implemented!\n')
					else
						%(!!) check modifiers!
						c.Chars(B) = C;
					end
				else
					c.Chars(end+1) = C;
				end
			end
		end		% AddChar

		function RmKey(c,k)
			%RmKey - remove handling of a certain key
			B = strcmp({c.Keys.key},k);
			if any(B)
				c.Keys(B) = [];
			else
				fprintf('Key not found!\n')
			end
		end		% RmKey

		function RmChar(c,ch)
			%RmChar - remove handling of a certain char
			B = strcmp({c.Chars.char},ch);
			if any(B)
				c.Chars(B) = [];
			else
				fprintf('Character not found!\n')
			end
		end		% RmChar

		function HandleEvent(c,fig,ev)
			%HandleEvent - the base functionality of key-handling
			if ~isempty(c.Keys)
				B = strcmp({c.Keys.key},ev.Key);
				if any(B) && HandleEvent(fig,c.Keys(B),ev)
					return
				end
			end
			if ~isempty(c.Chars) && ~isempty(ev.Character)
				B = strcmp({c.Chars.char},ev.Character);
				if any(B) && HandleEvent(fig,c.Chars(B),ev)
					return
				end
			end
			if strcmp(ev.Key,'f1')	% help
				c.HelpFig()
			end
		end		% HandleEvent

		function HelpFig(c)
			%HelpFig - Default display of (basic!) help-figure
			C = cell(1,1+length(c.Keys)+length(c.Chars));
			KK = c.Keys;
			HH = {KK.help};
			BB = ~cellfun(@isempty,HH);
			HH = HH(BB);
			if isempty(HH)
				j = 0;
			else
				C{1} = ['keycodes:',newline];
				j = 1;
				[C,j] = AddHelpLines(C,j,{KK(BB).key},HH);
			end
			CC = c.Chars;
			HH = {CC.help};
			BB = ~cellfun(@isempty,HH);
			HH = HH(BB);
			if ~isempty(HH)
				j = j+1;
				C{j} = ['char-codes',newline];
				[C,j] = AddHelpLines(C,j,{CC(BB).char},HH);
			end
			if j==0
				warndlg('No help-info available!')
			else
				C{j}(end) = [];	% remove last newline
				helpdlg([C{1:j}],[c.name,' - help'])
			end
		end		% HelpFig
	end		% methods
end		% cGenKeyPressHandler

function [C,j] = AddHelpLines(C,j,CC,HH)
for i=1:length(CC)
	if isempty(HH{i})
		continue	% already included
	end
	K = CC{i};
	ii = [0,find(strcmp(HH(i+1:end),HH{i}))];
	if isscalar(K) && abs(K)>0 && abs(K)<=26
		K = ['ctrl-',char(K+64)];
	end
	if length(ii)>1
		ii = ii+i;
		[HH{ii(2:end)}] = deal([]);
		for j=ii(2:end)
			ch = CC{j};
			if isscalar(ch) && abs(ch)>0 && abs(ch)<=26
				ch = ['ctrl-',char(ch+64)];
			end
			K = [K,'","',ch]; %#ok<AGROW> 
		end
	end
	j = j+1;
	C{j} = sprintf('"%s": %s\n',K,HH{i});
end
end		% AddHelpLines

% why is this a local function (and not of ../HandleEvent)?
function bHandled = HandleEvent(fig,spec,ev)
	bHandled = false;
	if isscalar(spec) && isempty(spec.mod)
		spec.fcn(fig,ev);
		bHandled = true;
	else
		for i=1:length(spec)
			if (isnumeric(spec(i).mod) && isempty(ev.Modifier))	...allow any modifier(!!)
					|| isequal(sort(ev.Modifier),sort(spec(i).mod))
				spec(i).fcn(fig,ev)
				bHandled = true;
				break
			end		% match found
		end		% for i
	end
end		% HandleEvent

function B = CheckModifiers(Sold, Snew)
if isempty(Snew.mod)
	B = cellfun('isempty',{Sold.mod});
else
	B = false(1,length(Sold));
	for i=1:length(Sold)
		if length(intersect(Sold(i).mod,Snew(i).mod))==length(Snew.mod)
			B(i) = true;
			break
		end
	end
end
end		% CheckModifiers
