function y=vectorXOR(x)
%vectorXOR - calculate XOR of values in vector
%     y=vectorXOR(x) (bitxor is used)

y=x(1);
for i=2:length(x)
	y=bitxor(y,x(i));
end
