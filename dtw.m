function [Dist,D,k,w]=dtw(t,r)
%DTW Dynamic Time Warping Algorithm
%   Detailed explanation goes here
% Input:
% t - the vector you are testing against
% r - the vector you are testing
% Output:
% Dist - unnormalized distance between t and r
% D - the accumulated distance matrix
% k - the normalizing factor
% w - the optimal path
%


[rows,N]=size(t);
[rows,M]=size(r);

dM = repmat(t(:),1,M);
dN = repmat(r(:)',N,1);
d=(dM-dN).^2; %this replaces the nested for loops from above Thanks Georg Schmitz 

% special for units
d(d>1) = 1;

D=zeros(size(d));
D(1,1)=d(1,1);

for n=2:N
    D(n,1)=d(n,1)+D(n-1,1);
end
for m=2:M
    D(1,m)=d(1,m)+D(1,m-1);
end
for n=2:N
    for m=2:M
        D(n,m)=d(n,m)+min([D(n-1,m),D(n-1,m-1),D(n,m-1)]);
    end
end

Dist=D(N,M);
n=N;
m=M;
k=1;
w=[];
w(1,:)=[N,M];
while ((n+m)~=2)
    if (n-1)==0
        m=m-1;
    elseif (m-1)==0
        n=n-1;
    else 
      [values,number]=min([D(n-1,m),D(n,m-1),D(n-1,m-1)]);
      switch number
      case 1
        n=n-1;
      case 2
        m=m-1;
      case 3
        n=n-1;
        m=m-1;
      end
  end
    k=k+1;
    w=cat(1,w,[n,m]);
end

w = w(end:-1:1, :);

end