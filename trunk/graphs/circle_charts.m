% prepare the screen
clf; hold on; axis equal; axis off;

N=100; % just a big integer
Arc_size=0.4; % an angle, determining how big the arcs will be

small_radius=12; medium_radius=12.8; big_radius=13.5; % circle radii

thin_line=2.8; thick_line=3.0;

% plot the black circle
Theta=linspace(0, 2*pi, N);
plot(small_radius*cos(Theta), small_radius*sin(Theta), 'color', 'k', 'linewidth', thin_line);

% plot the red piece
Theta=linspace(Arc_size, pi-Arc_size, N);
plot(medium_radius*cos(Theta), medium_radius*sin(Theta), 'color', [1 0 0], 'linewidth', thick_line);

% plot the brown piece
Theta=linspace(-Arc_size, -pi+Arc_size, N);
%plot(medium_radius*cos(Theta), medium_radius*sin(Theta), 'color', [0.8, 0.5, 0.2], 'linewidth', thick_line);

% well, now it is instead yellow
plot(medium_radius*cos(Theta), medium_radius*sin(Theta), 'color', [255 255   0]/256, 'linewidth', thick_line);

% plot the blue piece
Theta=linspace(pi/2-Arc_size, -pi/2+Arc_size, N);
plot(big_radius*cos(Theta), big_radius*sin(Theta), 'color', [0 0 1], 'linewidth', thick_line);

% plot the green piece
Theta=linspace(3*pi/2-Arc_size, 3*pi/2-pi+Arc_size, N);
plot(big_radius*cos(Theta), big_radius*sin(Theta), 'color', [0, 1, 0], 'linewidth', thick_line);

% a hack to create some whitespace around the picture
fr=1.4;
plot(small_radius*fr, small_radius*fr, 'color', [1, 1, 1, ], 'linewidth', 1)
plot(-small_radius*fr, -small_radius*fr, 'color', [1, 1, 1, ], 'linewidth', 1)

%saveas(gcf, 'circle_charts.eps', 'psc2');
print('-dpsc2','-r900', 'circle_charts.eps')

% after that, I open the picture in the Gimp, make sure it gets antialiased, then I crop and resize