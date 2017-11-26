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
float epsilon = 0.005;

float sphereIntersection(vec3 p0, vec3 v, vec4 sphere){
	vec3 o = sphere.xyz;
	float r = sphere.w;
	vec3 d = p0-o;
	float a = dot(v, v);
	float b = 2.0 * dot(v, d);
	float c = dot(d, d) - (r * r);
	
	float delta = b * b - 4.0 * a * c;
	
	if(delta < epsilon){
		return -1.0;
	}
	float x1 = (-b + sqrt(delta)) / (2.0 * a);
	float x2 = (-b - sqrt(delta)) / (2.0 * a); 
	
	
	if(x1 > epsilon && x2 > epsilon){
		return min(x1, x2);
	} else if(x1 < epsilon && x2 < epsilon){
		return -1.0;
	} else return max(x1, x2);
}

float planeIntersection(vec3 p0, vec3 v, vec4 plane){
	vec3 N = normalize(plane.xyz);
	float d = plane.w;
	vec3 q = N * (-d);
	
	float t = dot(N, (q-p0)/dot(N, v));

	if(t <  epsilon){
		return -1.0;
	} else{
		return t;
	}
}

bool isSphere(vec4 obj){
	return obj.w > 0;
}

bool isDirectional(vec4 light){
	return light.w == 0.0;
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


int lightsCount(){
	return sizes.y;
}

int objectsCount(){
	return sizes.x;
}

bool isLightBlockedBySphere(vec3 p, vec3 dir, vec4 sphere, int light){
	vec3 o = sphere.xyz;
	float r = sphere.w;
			
	float a = dot(dir, dir);
	float b = dot(2 * dir, (p - o));
	float c = dot(p - o, p - o) - (r * r);
	
	float delta = b * b - 4.0 * a * c;	
	if(delta < 0.0){
		return false;
	}
	
	float x1 = (-b + sqrt(delta)) / (2.0 * a);
	float x2 = (-b - sqrt(delta)) / (2.0 * a); 
	
	if(x1 > epsilon){
		if(isDirectional(lightsDirection[light])){
			return true;
		} else{
			vec3 xIntersection = p + dir * x1;
			vec3 lightPositon = lightPosition[light].xyz;
			
			float lightDistance = distance(lightPositon, p);
			float actualDistance = distance(lightPositon, xIntersection) + distance(xIntersection, p);
			
			if(actualDistance + epsilon > lightDistance && actualDistance - epsilon < lightDistance) {
				return true;
			}
		}
	}
	return false;
}

bool isLightBlockedByPlane(vec3 p, vec3 dir, vec4 plane, int light){
	return false;
}

/*
	Check if light with direction -dir to point p is blocked by object obj.
*/
bool isLightBlockedBy(vec3 p, vec3 dir, vec4 obj, int light){
	if(isSphere(obj)){
		return isLightBlockedBySphere(p, -dir, obj, light);
	} else{
		return isLightBlockedByPlane(p, dir, obj, light);
	}
}

vec3 colorCalc(vec3 intersectionPoint)
{
	bool addReflection = (int(eye.w) & 1) == 1;
	bool addTransparency = (int(eye.w) & 2) == 2;
	
	vec3 v = normalize(position1 - intersectionPoint);
	
	float distance = 100000000;
	float t_obj;
	int intersection = -1;
	
	// find intersection between the eye and an object.
	for(int i=0; i<objectsCount(); i++){
		t_obj = intersection(intersectionPoint, v, objects[i]);
		if(t_obj < distance && t_obj >= epsilon){
			distance = t_obj;
			intersection = i;
		}
	}
	
	if(intersection == -1){
		return vec3(0.0,0.0,0.0);
	}
	
	
	// p represents the point in space of the relevant pixel.
	vec3 p = intersectionPoint + distance * v;
	
	vec3 intersectionColor = objColors[intersection].xyz;
	
	// planes are divided to squares. this boolean will determine the pixel color according to the square.
	float coefficient = (!isSphere(objects[intersection]) &&
							((squareCoefficient(p) && !quart1_3(p)) ||
							 (!squareCoefficient(p) && quart1_3(p))))
						 ? 1.0 : 0.5;
	
	int firstPlane = 0;
	while(isSphere(objects[firstPlane])){
		firstPlane++;
	}
	if(addReflection && intersection == firstPlane){
		intersectionColor = vec3(0.0, 0.0, 0.0);
		coefficient = 1.0;
	}
						 
	
	/******** Lighting *********/
	// Ambient calculations
	vec3 ambient = (ambient.xyz * intersectionColor);
	// Diffuse and Specular calculations
	vec3 diffuse = vec3(0.0, 0.0, 0.0);
	vec3 specular = vec3(0.0, 0.0, 0.0);
	
	vec3 N = normalize(isSphere(objects[intersection]) ? (objects[intersection].xyz - p) : objects[intersection].xyz);
	vec3 Kd = intersectionColor.xyz;
	vec3 Ks = vec3(0.7, 0.7, 0.7);
	float n = objColors[intersection].w;
	
	for(int i=0; i<lightsCount(); i++){
		vec3 L = vec3(0.0,0.0,0.0); // light's direction
		bool isBlocked = false; // for shadow
		
		if(isDirectional(lightsDirection[i])){
			L = normalize(lightsDirection[i].xyz);
		} else if(lightPosition[i].w < dot(normalize(lightsDirection[i].xyz), normalize(p - lightPosition[i].xyz))) {
			L = normalize(p - lightPosition[i].xyz);
		} else {
			isBlocked = true;
		}
		
		for(int j=0; j<objectsCount(); j++){
			if(isLightBlockedBy(p, L, objects[j], i)){
				isBlocked = true;
			}
		}
		
		
		if(!isBlocked){
			vec3 I = lightsIntensity[i].xyz;
			vec3 R = normalize(reflect(L, N));
			
			diffuse += (Kd * dot(N, L)) * I;
			specular += (Ks * pow(dot(R, v), n)) * I;
		}
	}
	
	if(!isSphere(objects[intersection])){
		diffuse *= coefficient;
	}
	
	// Reflection:
	vec3 reflection = vec3(0,0,0);
	if(addReflection){
		if(intersection == firstPlane){
			vec3 mirror = normalize(reflect(p, N));
			
			float distance = 100000000;
			float t_object;
			int mirroredObject = -1;	
			for(int i=0; i<objectsCount(); i++){
				if(i != intersection){
					t_object = intersection(p, mirror, objects[i]);
					if(t_object < distance && t_object >= epsilon){
						distance = t_object;
						mirroredObject = i;
					}
				}
			}
			if(mirroredObject != -1){
				reflection += objColors[mirroredObject].xyz * 0.6;	
			}
		}
	}
	
	// Transparency:
	vec3 transparency = vec3(0,0,0);
	if(addTransparency){
		vec3 refraction = normalize(refract(p, N, 1.0));
		
		float distance = 100000000;
		float t_object;
		int refractedObject = -1;
		for(int i=0; i<objectsCount(); i++){
			if(i != intersection){
				t_object = intersection(p, refraction, objects[i]);
				if(t_object < distance && t_object >= epsilon){
					distance = t_object;
					refractedObject = i;
				}
			}
		}
		if(refractedObject != -1){
			transparency += objColors[refractedObject].xyz * 0.3;	
		}
	}
	
	
	
	// Phong model:
	vec3 result = vec3(0.0, 0.0, 0.0);
	result += ambient;
	result += diffuse;
	result += specular;
	result += reflection;
	result += transparency;

    return result;
}


void main()
{  
   gl_FragColor = vec4(colorCalc(eye.xyz),1);      
}
 

