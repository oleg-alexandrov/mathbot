% Illustration of five-point stencil in one and two dimensions.

function main ()

   figure(1); clf; hold on; axis equal; axis off;
   
% make nice lightning
   camlight right; lighting phong;

% draw both stencils on the same picture, with the second one
% shifted down
   shift=[0, -13];
   for type=1:2
      draw_stencil(type, shift(type))
   end
   
% save to disk. High resolution is very important here, that's why r400
print('-dpng',  '-r400', 'Five_point_stencil_illustration.png', '-opengl');
		 

function draw_stencil (type, shift)

% the "type" argument above determines if the stencil is 1D or 2D

   % N= number of points in each surface. The more, the smoother the surfaces are.
   N = 100; 
   
   h=5; % grid size

   if type == 1
	  % 1D
      Stencilx=[-2*h, -h, 0, h, 2*h];
      Stencily=[0,     0, 0, 0, 0];
   else
	  % 2D
      Stencilx=[-h, 0, h, 0, 0];
      Stencily=[0,  0, 0, -h, h];
   end
   
% draw the points in the stencil as spheres
   [X, Y, Z] =sphere(N);
   for i=1:length(Stencilx)
      
% draw the spheres
      H=surf(X+Stencilx(i), Y+Stencily(i)+shift, Z, 'FaceColor', 'blue', ...
			 'EdgeColor','none', 'AmbientStrength', 0.3, ...
	  'SpecularStrength', 1, 'DiffuseStrength', 0.8);
      
% make the center of the stencil red
      if Stencilx(i) == 0 & Stencily(i) == 0
	 set(H, 'FaceColor', 'red');
      end
      
   end
   
% create a cylinder which connects the points in the stencil
   [X, Y, Z] = cylinder([1, 1], N);
   L=4*h; rad=0.3;
   X=rad*X; Y=rad*Y; Z=L*Z-L/2;
   Tmp = Z; Z=X; X = Tmp;
   
% draw the cylinders, depending on type. A very convoluted code
   for k=1:2

      if type == 1 & k == 2
		 break;
      end
	  
      if type == 2
		 
		 if k == 1
			X = X/2;
		 else 
			Tmp = X; X = Y; Y = Tmp;
		 end;
		 
      end
      
      gray = 0.5*[1, 1, 1]; 
      H=surf(X, Y+shift, Z, 'FaceColor', gray, 'EdgeColor','none', ...
			 'AmbientStrength', 0.7, 'SpecularStrength', 1, 'DiffuseStrength', 0.8);
      
      
   end
   