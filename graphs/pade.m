function main()

   a=0.45*pi;
   x=-a:0.01:a;
   xx=-pi*0.01:pi;
   
   Y=tan(x);
   Z=xx + Power(xx,3)/3. + (2*Power(xx,5))/15. + (17*Power(xx,7))/315. + (62*Power(xx,9))/2835.;
   
   figure(1); clf; hold on; axis equal;axis off;
   plot(x, Y, 'b')
   plot(xx, Z, 'g')
   
   plot(x, Y*0, 'k');
   plot(0*x, Y, 'k');


   
   
   
   axis([-1.1*pi/2, 1.1*pi/2, -10, 10]);

   saveas(gcf, 'Pade_illustration.eps', 'psc2')
function z=Power(x, y)
   
   z=x.^y;
   