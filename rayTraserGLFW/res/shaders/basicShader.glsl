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
	float delta = b * b - 4.0 * a * c;	
	if(delta < 0){
		return -1.0;
	}
	float x1 = (-b + sqrt(delta)) / (2.0 * a);
	float x2 = (-b - sqrt(delta)) / (2.0 * a); 
	
	return min(x1, x2);
}

float sphereIntersection(vec3 p0, vec3 v, vec4 sphere){
	vec3 o = sphere.xyz;
	float r = sphere.w;
			
	float a = length(v) * length(v);
	float b = 2.0 * dot(v, (p0 - o));
	float c = (length(p0 - o) * length(p0 - o)) - (r * r);
	
	return quadraticEquation(a, b, c);
}

float planeIntersection(vec3 p0, vec3 v, vec4 plane){
	vec3 n = plane.xyz;
	float d = plane.w;
	
	float distance = -(d + p0.z * n.z + p0.y * n.y + p0.x * n.x)/(v.z * n.z + v.y * n.y + v.x * n.x);
	if(distance <  0){
		return -1.0;
	} else{
		return distance;
	}
}

bool isSphere(vec4 obj){
	return obj.w > 0;
}

float intersection(vec3 p0, vec3 v, vec4 obj)
{
	if(isSphere(obj)){
		return sphereIntersection(p0, v, obj);
	} else{
		return planeIntersection(p0, v, obj);
	}
}

bool quart1_3(vec3 p){
	return p.x * p.y > 0;
}

bool squareCoefficient(vec3 p){
	return mod(int(1.5*p.x),2) == mod(int(1.5*p.y),2);
}

vec3 colorCalc(vec3 intersectionPoint)
{
	vec3 p0 = intersectionPoint;
	vec3 v = normalize(position1 - p0);
	
	float distance = 1000000;
	float t_obj;
	int minIndex = -1;
	float coefficient = 1.0;
	
	for(int i=0; i<sizes.x; i++){
		t_obj = intersection(p0, v, objects[i]);
		if(t_obj < distance && t_obj != -1){
			distance = t_obj;
			minIndex = i;
		}
	}
	vec3 p = p0 + distance * v;
	if(!isSphere(objects[minIndex]) && ((squareCoefficient(p) && quart1_3(p)) || !(squareCoefficient(p) || quart1_3(p)))){
		coefficient = 0.5;
	}
	
	vec3 color = coefficient * objColors[minIndex].xyz;
	//vec3 color = vec3(1, 0, 1);
	
    return color;
}

void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}
 

