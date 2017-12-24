# RayTraserGLFW
Computer Graphics - Assignment1

Implementation of a ray tracer using openGL. 

Provide input in file /res/scene.txt using the followig format:
* The first line in the file will start with the letter "e" flowing by camera (eye) coordinates. The fourth coordinate is used to activate mirrored-plane (1) or transparency (2) or both (3).
* Second line starts with "a" followed by (R,G,B,A) coordinate represents the ambient light.

From the third row we will describe the object and lights in scene:
* Light direction will describe by "d" letter followed by light direction (x, y, z, w). 'w' value will be 0.0 for directional light and 1.0 for spotlight.
* For spotlights the position will appease afterwards after the letter "p" (x,y,z,w).
* Light intensity will describe by "i" followed by light intensity (R, G, B, A).
* Spheres and planes will description will appear after "o". For spheres (x,y,z,r) when (x,y,z) is the center position and r is the radius (always positive, greater than zero). For planes (a,b,c,d) which represents the coefficients of the plane equation when 'd' gets is a non positive value.  
* The color of an object will appears after "c" and will represent the ambient and diffuse values (R,G,B,A). 'A' represents the shininess parameter value.
