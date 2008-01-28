function main ()

% init stuff
   M=3;  lw=2.5;
   h=0.05; ii = sqrt(-1);
   XX = (-M):h:M; YY = (-M):h:M;
   [X, Y] = meshgrid (XX, YY);

% the surfce determining the contour
   type = 2; % the contour is a circle for type == 1 and something more complex otherwise

   if type == 1
      height = 2;
      Z=height - X.^2-Y.^2;
   else
      height = 0.7;
      Z=height-0.5*(X-1.78).*X.^2.*(X+1.78)-Y.^2;  % Z=f(X, Y) -surface
   end

% find the contour
%figure(1); subplot(2, 1, 1);
   figure(1); clf;
   [C, H] = contour(X, Y, Z, [0, 0]);
   set(H, 'linewidth', lw, 'EdgeColor', [0;0;156]/256);

% draw the region inside the contour
%   figure(1); subplot(2, 1, 1);
   figure(1); 
   clf; hold on; axis equal; axis off; 
   
   l=C(2, 1);
   CX=C(1,2:(l+1));  CY=C(2,2:(l+1)); % get x and y of contours
   H=fill(CX, CY, 0.6*[1, 1, 1]); set(H, 'EdgeColor', 'none'); % draw the shap

   % a hack to make the box look bigger
   white = 0.99*[1, 1, 1]; scale=1.4;
   plot(-scale*M, -scale*M, '*', 'color', white)
   plot(scale*M, scale*M, '*', 'color', white)
   
% calc the unsigned distance function
   Dist = 0*Z+1000;
   for i=1:length(XX)
      for j=1:length(YY)
	 x=X(i, j); y=Y(i, j);
	 for k=1:length(CX)
	    x0=CX(k);
	    y0=CY(k);
	    Dist(i, j) = min(Dist(i, j), sqrt((x-x0)^2+(y-y0)^2));
	 end
      end
   end
   

% signed distance
   Dist = sign(Z).*Dist;
   
% draw the signed distance
%   figure(1); subplot(2, 1, 2);
   figure(2); clf;
   hold on; axis equal; axis off;
   surf(X, Y, Dist, 'FaceColor','red', 'EdgeColor','none', 'FaceAlpha', 1);

% draw the x-y plane (the intersection of the surface above and this plane is the contour of our set)
   surf(X, Y, zeros(length(XX), length(YY)), 'FaceColor','blue', 'EdgeColor','none', 'FaceAlpha', 0.4)
   
   camlight left;lighting phong; % make nice lightning
   view(42, 22)        % angle of view (polar coordinates)

% save to file
   figure(1);   saveas(gcf, sprintf('Set%d.eps', type), 'psc2');
   figure(2);   saveas(gcf, sprintf('Function%d.eps', type), 'psc2');

% then use the following to convert to png
%   convert -append Set2.eps Function2.eps signed_distance2.png
   
