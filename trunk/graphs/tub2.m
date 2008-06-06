% illustration of tubular neighborhood
function main()

   f=inline('sin(x)', 'x'); % will construct a tubular neighborhood of this curve

   a=0; b=2*pi; N = 1000; X = linspace(a, b, N); % consider N points in the interval [a, b]
   Y = f(X); % the curve
   ll = 3; % length of lines perpendicular to the curve
   lls = 0.3; % smaller subsegments
   
   thin_line = 2;
   thick_line = 4;
   
%  will draw lines perpendicular to the graph of Y=f(X) at
%  points separted by length of 'spacing'
   spacing = 0.015;
   M = floor(spacing*N); 

% colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   
   figure(1); clf; hold on; axis equal; axis off;


   % plot the lines
   for k=1:N

	  p = (k-1)*M+2;
	  if p >= N
		 break;
	  end

	  % the normal to the curve at (X(p), Y(p))
	  Normal = [-(Y(p+1)-Y(p-1)), X(p+1)-X(p-1)]; Normal = Normal/norm(Normal);  

	  plot([X(p)-lls*Normal(1), X(p)+lls*Normal(1)], [Y(p)-lls*Normal(2),...
					Y(p)+lls*Normal(2)], 'color', red, 'linewidth', 0.7*thick_line)

   end

   % plot the curve
   plot(X, Y, 'linewidth', thick_line, 'color', blue);
   saveas(gcf, 'Tubular_neighborhood2.eps', 'psc2')