function level_set_method()
   figure(1); clf; % pop up a figure, and clean it up
for i=1:3 % make a loop to draw the six pictures in pairs
   level_disp(i);
end

print('-djpeg100',  '-r100', 'level_set_method.jpg') % save to file. 

function level_disp(p)

   Lx=2.5; Ly=2.5; % box is [-Lx Lx] x [-Ly, Ly]
   N=60;  % number of points (don't make it big, code will be slow)
   heights=[0.7+eps, 0.00001, -0.7+eps]; % cut the surface at these heights 
   height=heights(p); % current cut

   [X, Y]=meshgrid(-Lx:(1/N):Lx, -Ly:(1/N):Ly);     % X and Y coordinates
   Z=height-0.5*(X-1.78).*X.^2.*(X+1.78)-Y.^2;  % Z=f(X, Y) -surface

   lowest=-4;
   [m, n]=size(Z); 
   for i=1:m
      for j=1:n
	 if Z(i, j)< lowest; % truncate the surface somewhere
	    Z(i, j)=NaN;
	 end
      end
   end

% draw the sufrace and the plane cut
   figure(1); subplot('Position', [(p-1)/3, 0., 0.33, 0.5]); hold on; 
   surf(X, Y, Z, 'FaceColor','red', 'EdgeColor','none', 'FaceAlpha', 1); 
   surf(X, Y, zeros(m, n), 'FaceColor','blue', 'EdgeColor','none', 'FaceAlpha', 0.3); 
   camlight left;lighting phong; % make nice lightning 
   axis([-Lx Lx -Ly Ly lowest 1.8]); axis equal;  axis off; %the coordinate box
   view(-23, 34)        % angle of view (polar coordinates)

% draw the shape (cross-section)
   figure(1); subplot('Position', [(p-1)/3, 0.5, 0.33, 0.5]); % subwindow
   [c, stuff] = contour(X, Y, Z, [0, 0]); % draw the contours.
   l=c(2, 1);
   x=c(1,2:(l+1));  y=c(2,2:(l+1)); % get x and y of contours
   H=fill(x, y, 0.6*[1, 1, 1]); set(H, 'EdgeColor', 'none'); % draw the shape

   [u, v]=size(c);
   if v > l+2 % special case: two connected components
      x=c(1,(l+3):(2*l)); y=c(2,(l+3):(2*l)); % contours
      hold on; % hold the graph for the second component
      H=fill(x, y, 0.6*[1, 1, 1]); set(H, 'EdgeColor', 'none'); 
   end
   axis equal; axis off; axis([-Lx Lx -Ly Ly]); % frame size
