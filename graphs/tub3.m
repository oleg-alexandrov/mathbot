% illustration of tubular neighborhood
function main()

   a=0; b=2*pi; N = 100;
   X=linspace(a, b, N);
   Y=sin(X);
   ll = 4; % length of lines perpendicular to the curve
   
   thin_line = 2;
   thick_line = 4;
   
%  will draw lines perpendicular to the graph of Y=f(X) at
%  points separted by length of 'spacing'
   spacing = 0.04;
   M = floor(spacing*N); 

% colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   gray=0.8*[1, 1, 1];
   
   figure(1); clf; hold on; axis equal; axis off;
   view(23, 36);

   % plot the lines
   for k=1:N
      
      p = (k-1)*M+2;
      if p >= N
		 break;
      end
      
      plot3([X(p), X(p)], [Y(p), Y(p)], [-ll, ll], 'color', red, 'linewidth', thin_line)
	  
   end

   % plot the curve
   plot3(X, Y, 0*X, 'linewidth', thick_line, 'color', blue);

   saveas(gcf, 'Tubular_neighborhood3.eps', 'psc2')

