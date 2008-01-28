% illustration of the volume under a surface

function main()
   L=5;  % box size
   N=100; % number of points in a lot of places
   lw=2; % width of lines
   alphatop=1; % transparency
   alphaside=0.82;
   alphabot=0.8;
   bluetop =[0, 1, 0.8];
   blueside=[0.2, 0.9, 0.8]; %bluetop;%[0, 0, 1];
   bluebot=[0.5, 0.5, 0.5]; %bluetop;%[0, 0, 1];
   black=[0, 0, 0];

   % the function whose surface we will plot
   f=inline('10-(x.^2-y.^2)/8', 'x', 'y');
   XX=linspace(-L, L, N);
   YY=XX;
   [X, Y]=meshgrid(XX, YY);
   Z=f(X, Y);

   % the surface of the side
   XS = [XX, 0*XX+L invert_vector(XX), 0*XX-L];
   YS = [0*XX-L, YY, 0*XX+L, invert_vector(YY)];

   XS = [XS' XS']';
   YS = [YS' YS']';

   ZS = 0*XS;
   ZS(2, :) = f(XS(2, :), YS(2, :));

% the contour of the bottom
   XD=[-L, L, L, -L, -L];
   YD=[-L, -L, L, L, -L];
   ZD=XD*0;

%  prepare figure 1 for plotting
   figure(1); clf; hold on; axis equal; axis off;
 
%  plot the function u
   surf(X, Y, Z, 'FaceColor', bluetop, 'EdgeColor','none', 'FaceAlpha', alphatop); % top
   surf(X, Y, 0*Z, 'FaceColor', bluebot, 'EdgeColor','none', 'FaceAlpha', alphabot); % bottom 
   surf(XS, YS, ZS, 'FaceColor', blueside, 'EdgeColor','none', 'FaceAlpha', alphaside); % sides

   phi = -68; theta = 28;
   view (phi, theta);

   camlight headlight; lighting phong; % make nice lightning

   
   
figure(1); print('-dpng',  '-r200', 'Trace1.png') % save to file.

function Z = invert_vector(X)

   N=length(X);
   Z = X;
   for i=1:N
      Z(i)=X(N-i+1);
   end
  
