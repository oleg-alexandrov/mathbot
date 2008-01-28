% illustration of mollification
function main()

   % the number of data points. More points means prettier picture.
   N = 200;

   % a step function
   Z = get_step_function (N);

% Do a loop mollifying Z more and more

   K = [100 50 25 10  5.4  3.0  2.0  1.0];
   count = 1;
   for kernel = K

      % a smooth function with small support, that will serve as mollifier
      W = get_mollifier     (kernel, N);

      % get the convolution of the two, so a mollified step function
      S = conv2(Z, W);

      % truncate S at the edges, and scale it
      p=0.2;
      [m, n] = size(S);
      m1 = floor(p*m)+1; m2=floor((1-p)*m)-1;
      n1 = floor(p*n)+1; n2=floor((1-p)*n)-1;
      S = S(m1:m2, n1:n2);
      S = 0.25*(m2-m1)*S/max(max(S));
      
      % plot the surface
      figure(2); clf; hold on; axis equal; axis off;
      surf(S);
   
      % make the surface beautiful
      shading interp;
      colormap autumn;

      % add in a source of light
      camlight (-50, 54);
   
      % viewing angle
      view(-40, 38);

      frame_str = sprintf('Frame%d.png', 1000+count)
      count = count+1;

      [m, n] = size(S); mx=max(max(S));
      axis([1 m 1 n 0 mx]); 
      
      % save as png
      print('-dpng', '-r100', frame_str);
      
      pause(1);
   end
  
  % put into a gif with the following command on Unix
  %!  convert -antialias -loop 10000  -delay 100 -compress LZW Frame100* Mollifier_movie.gif
    
% get a function which is 1 on a set, and 0 outside of it
function Z = get_step_function(N)
   XX = linspace(-1.5, 4, N);
   YY = linspace(-4, 4, N);
   [X, Y] = meshgrid(XX, YY);
   
   c = 2;
   k=1.2;
   shift=10;
   Z = (c^2-X.^2-Y.^2).^2 + k*(c-X).^3-shift;
   
   Z =1-max(sign(Z), 0);

function W = get_mollifier(kernel, N)
% now try to get a function with compact support
% as a mollifier
% We will cheat by using a gaussian

   a = 4;
   XX = linspace(-a, a, N);
   YY = linspace(-a, a, N);
   [X, Y] = meshgrid(XX, YY);
   
   W = exp(-kernel*(X.^2+Y.^2));

   % truncate the Gaussian to make it with compact support
   trunc = 1e-2;
   W = max(W-trunc, 0);
