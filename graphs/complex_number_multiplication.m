function main ()

% set up the plotting window
thickness=2.8; fs=30; d=0.005;
red=[1, 0, 0]; green=[0, 1, 0]; blue=[0, 0, 1];
figure(1); clf; hold on; axis equal; axis off; 
i=sqrt(-1);

z1=0; z2=1; z3=1+i;
draw_segment(z1, z2, red, thickness); 
draw_segment(z2, z3, green, thickness);
draw_segment(z3, z1, blue, thickness);

place_text_smartly (z1, fs, 5, d, '0'); 
place_text_smartly (z2, fs, 7, d, '1');
place_text_smartly (z3, fs, 1, d, 'A');

z1=0; z2=2*i; z3=2*i*(1+i);
draw_segment(z1, z2, red, thickness);
draw_segment(z2, z3, green, thickness);
draw_segment(z3, z1, blue, thickness);

place_text_smartly (z2, fs, 1, d, 'B');
place_text_smartly (z3, fs, 3, d, 'X');

saveas(gcf, 'Complex_numbers_multiplication.eps', 'psc2')

function draw_segment(z1, z2, color, thickness);
  plot( [real(z1), real(z2)], [imag(z1), imag(z2)], 'color', color, 'linewidth', thickness );

function place_text_smartly (z, fs, pos, d, tx)
 p=cos(pi/4)+sqrt(-1)*sin(pi/4);
 z = z + p^pos * d * fs; 
 shiftx=0.0003;
 shifty=0.002;
 x = real (z); y=imag(z); 
 H=text(x+shiftx*fs, y+shifty*fs, tx); set(H, 'fontsize', fs, 'HorizontalAlignment', 'c', 'VerticalAlignment', 'c')

