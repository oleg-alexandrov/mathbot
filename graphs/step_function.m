% illustration of an indicator function in two dimensions
function main()

   % the number of data points. More points means prettier picture.
   N = 400;

   % a function close to what we want, but not smooth
   Z = get_step_function (N);

% plot the surface
   figure(2); clf; hold on; axis equal; axis off;
   scale = 100;
   surf(scale*Z);
   
% make the surface beautiful
   shading interp;
   colormap autumn;

% add in a source of light
   camlight (-50, 54);
   
% viewing angle
   view(-40, 38);

   % save as png
   print('-dpng', '-r200', 'Indicator_function_illustration.png');

  
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

