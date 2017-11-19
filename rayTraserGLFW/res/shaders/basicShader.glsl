#version 130 

uniform vec4 eye;
uniform vec4 ambient;
uniform vec4[20] objects;
uniform vec4[20] objColors;// Ka = Kd for every object[i]
uniform vec4[10] lightsDirection;// w = 0.0 => directional light; w = 1.0 => spotlight
uniform vec4[10] lightsIntensity;// (R,G,B,A)
uniform vec4[10] lightPosition;// Positions for spotlights, w = shine
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

bool occulded(vec4 light_ray, vec4 light){
	return true;
}

bool isDirectional(vec4 lightDirection){
	return lightDirection.w == 0;
}

int lightsCount(){
	return sizes.y;
}

int objectsCount(){
	return sizes.x;
}


vec3 colorCalc(vec3 intersectionPoint)
{
	vec3 p0 = intersectionPoint;
	vec3 v = normalize(position1 - p0);
	
	float distance = 100000000;
	float t_obj;
	int intersection = -1;
	
	for(int i=0; i<objectsCount(); i++){
		t_obj = intersection(p0, v, objects[i]);
		if(t_obj < distance && t_obj != -1){
			distance = t_obj;
			intersection = i;
		}
	}

	vec3 p = p0 + distance * v;
	float coefficient = (!isSphere(objects[intersection]) && ((squareCoefficient(p) && !quart1_3(p)) || (!squareCoefficient(p) && quart1_3(p)))) ? 1.0 : 0.5;
	
	/******** Lighting *********/
	// Ambient calculations
	vec3 ambient = coefficient * (vec3(0.1, 0.2, 0.3) * objColors[intersection].xyz);
	// Diffuse and Specular calculations
	vec3 diffuse = vec3(0.0, 0.0, 0.0);
	vec3 specular = vec3(0.0, 0.0, 0.0);
	
	for(int light=0; light<lightsCount(); light++){
		vec3 Kd = objColors[intersection].xyz;
		vec3 N = normalize(isSphere(objects[intersection]) ? -(p - objects[intersection].xyz) : objects[intersection].xyz);
		vec3 L = normalize(lightPosition[light].xyz - p);
		vec3 I = lightsIntensity[light].xyz * dot(lightsDirection[light].xyz, L);
		
		diffuse = diffuse + (Kd * (dot(N, L) / (length(N) * length(L))) * I);
		
		vec3 Ks = vec3(0.7, 0.7, 0.7);
		vec3 R = normalize(L - (2 * N) * dot(L, N));
		float n = objColors[intersection].w;
		
		specular = specular + (Ks.xyz * pow(dot(R, -v), n) * (-I));
	}
	
	// Phong model:
	vec3 result = vec3(0.0, 0.0, 0.0);
	result += ambient;
	result += diffuse;
	result += specular;
	
    return result;
}


void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}
 

