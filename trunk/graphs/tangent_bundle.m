% illustration of tangent bundle
function main()

   a=0; b=2*pi; N = 100;
   X=linspace(a, b, N);
   Y=sin(X);    % the function to plot
   XT = 0*X+1;
   YT = cos(X); % derivative

   Theta = linspace(a, b, N);
   X =   cos(Theta); Y  = sin(Theta);
   XT = -sin(Theta); YT = cos(Theta);
   ll = 2.5; % length of lines perpendicular to the curve
   
   thin_line = 2;
   thick_line = 4;
   
%  will draw lines tangent to the graph of Y=f(X) at
%  points separted by length of 'spacing'
   spacing = 0.04;
   M = floor(spacing*N); 

% colors
   red=[0.867 0.06 0.14];
   blue = [0, 129, 205]/256;
   green = [0, 200,  70]/256;
   gray=0.8*[1, 1, 1];
   
   figure(1); clf; hold on; axis equal; axis off;
   figure(2); clf; hold on; axis equal; axis off; view(18, 36);

% plot the curve
   figure(1); s=0.95; plot (s*X, s*Y,      'linewidth', thick_line, 'color', blue);
   figure(2); plot3(X, Y, 0*X, 'linewidth', thick_line, 'color', blue);

% plot the lines
   for k=1:N
      
      p = (k-1)*M+2;
      if p >= N
	 break;
      end

      figure(1);
      x0 = X(p); y0=Y(p); mx = XT(p); my = YT(p);
      plot([x0-mx*ll, x0+mx*ll], [y0-my*ll, y0+my*ll], 'color', red, 'linewidth', thin_line)
      
      
      figure(2);
      plot3([X(p), X(p)], [Y(p), Y(p)], [-ll, ll], 'color', red, 'linewidth', thin_line)
	  
   end


   % save to disk as eps and svg
   figure(1); saveas(gcf, 'Tangent_bundle1.eps', 'psc2'); plot2svg('Tangent_bundle1.svg')
   figure(2); saveas(gcf, 'Tangent_bundle2.eps', 'psc2'); plot2svg('Tangent_bundle2.svg')

