% an illustration of a circle as a convex metric space
function main()
   

   N=100;
   
   
   figure(1); clf; hold on; axis equal; axis off;
   lw=2; blue=[0, 0, 1]; red=[1, 0, 0];
   
   rad1=1.01; Theta=linspace(0, 1.2*pi, N); X=rad1*cos(Theta);  Y=rad1*sin(Theta);
   plot(X, Y, 'color', blue, 'linewidth', lw)

   rad2=1; Theta=linspace(1.1*pi, 2.2*pi, N); X=rad2*cos(Theta);  Y=rad2*sin(Theta);
   plot(X, Y, 'color', red, 'linewidth', lw)
   

%   % a phony box to avoid matlab bugs in saving to eps
%   h0=0.3; 
%   white=0.99*[1, 1, 1];
%   plot(0, 1+h0, 'color', white);
%   plot(0, -(1+h0), 'color', white);
   
   saveas(gcf, 'Arcs_illustration.eps', 'psc2');
   
