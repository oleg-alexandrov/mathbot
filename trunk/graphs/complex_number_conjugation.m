function main ()

% set up the plotting window
thickness=2.8; fs=30; d=0.005;
red=[1, 0, 0]; green=[0, 1, 0]; blue=[0, 0, 1];
figure(1); clf; hold on; axis equal; axis off; 
i=sqrt(-1);

z1=0; z2=1; z3=2+i;
plot_seg(z1, z2, red, thickness); 
plot_seg(z2, z3, green, thickness);
plot_seg(z3, z1, blue, thickness);

pt (z1, fs, 4, d, '0'); 
pt (z2, fs, 0, d, '1');
pt (z3, fs, 1, d, 'A');

z1=0; z2=1; z3=2-i;
plot_seg(z1, z2, red, thickness);
plot_seg(z2, z3, green, thickness);
plot_seg(z3, z1, blue, thickness);

pt (z3, fs, 7, d, 'X');

saveas(gcf, 'Complex_numbers_conjugation.png')
saveas(gcf, 'Complex_numbers_conjugation.eps', 'psc2')

function plot_seg(z1, z2, color, thickness);
  plot( [real(z1), real(z2)], [imag(z1), imag(z2)], 'color', color, 'linewidth', thickness );

function pt (z, fs, pos, d, tx)
 p=cos(pi/4)+sqrt(-1)*sin(pi/4);
 z = z + p^pos * d * fs; 
 shiftx=0.0003;
 shifty=0.002;
 x = real (z); y=imag(z); 
 H=text(x+shiftx*fs, y+shifty*fs, tx); set(H, 'fontsize', fs, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')
