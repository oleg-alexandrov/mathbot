#include "colors.inc"    // The include files contain
#include "shapes.inc"    // pre-defined scene elements
#include "textures.inc"

camera {
  location  <3, 4, -5>
  look_at   <0, 0,  3>
}

light_source { <4, 6, 1> color White}

background {
   color White
}

sphere {
  <0, 0, 2>, 2
  texture {
    pigment {color Green}  // Yellow is pre-defined in COLORS.INC
  }

   finish { reflection { 0.05 } ambient 0.1 diffuse 0.4 phong 0.6 phong_size 10}
   //finish { reflection {0.0} ambient 0.9 diffuse 0.0 }
}

    

cone {
    <0,3,0>,0.3    // Center and radius of one end
    <1,3,3>,1.0    // Center and radius of other end
    pigment {DMFWood4  scale 4 }
    finish {Shiny}  
}

//sphere {
//  <0, 1, 2>, 2
//  texture {
 //   pigment {
 //     wood
 //     color_map {
 //       [0.0 color DarkTan]
 //       [0.9 color DarkBrown]
  //      [1.0 color VeryDarkBrown]
  //    }
  //    turbulence 0.05
  //    scale <0.2, 0.3, 1>
  //  }
  //        finish {phong 1}
 // }
//}



// povray +W800 +H600 +P +X +D0 -V -Ipovone.pov  
