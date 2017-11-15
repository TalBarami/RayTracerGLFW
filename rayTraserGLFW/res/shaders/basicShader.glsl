#version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;
uniform vec4[10] lightsDirection;
uniform vec4[10] lightsIntensity;
uniform vec4[10] lightPosition;
uniform ivec3 sizes; //number of objects & number of lights

in vec3 position1;

float quadraticEquation(float a, float b, float c){
	float delta = b * b - 4 * a * c;	
	if(delta < 0){
		return -1;
	}
	float x1 = (-b + sqrt(delta)) / (2 * a);
	float x2 = (-b - sqrt(delta)) / (2 * a); 
	
	return min(x1, x2);
}

float sphereIntersection(vec3 p0, vec3 v, vec3 o, float r){
	float a = length(v);
	float b = 2 * dot(v, (p0 - o));
	float c = length(p0 - o) - (r * r);
	
	return quadraticEquation(a, b, c);
}

bool isSphere(vec4 obj){
	return obj.w > 0;
}

bool isPlane(vec4 obj){
	return !isSphere(obj);
}

float intersection(vec3 sourcePoint,vec3 v)
{
	for(int i=0; i<sizes.x; i++){
		if(isSphere(objects[i])){
			vec3 o = objects[i].xyz;
			float r = objects[i].w;
			return sphereIntersection(sourcePoint, normalize(v), o, r);
		}
	}
	
	return 0;
}

vec3 colorCalc(vec3 intersectionPoint)
{	
	vec3 color = vec3(1, 0, 1);
	
    return color;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}
 

