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

float sphereIntersection(vec3 p0, vec3 v, vec4 sphere){
	vec3 o = sphere.xyz;
	float r = sphere.w;
	vec3 d = p0-o;
	float a = dot(v, v);
	float b = 2.0 * dot(v, d);
	float c = dot(d, d) - (r * r);
	
	float delta = b * b - 4.0 * a * c;	
	if(delta < 0.0){
		return -1.0;
	}
	float x1 = (-b + sqrt(delta)) / (2.0 * a);
	float x2 = (-b - sqrt(delta)) / (2.0 * a); 
	
	if(x1 > 0.001 && x2 > 0.001){
		return min(x1, x2);
	} else if(x1 < 0.001 && x2 < 0.001){
		return -1;
	} else return max(x1, x2);
}

float planeIntersection(vec3 p0, vec3 v, vec4 plane){
	vec3 N = plane.xyz;
	float d = plane.w;
	vec3 q = N * (-d);
	
	float distance = dot(N, (q-p0)/dot(N, v));

	if(distance <  0){
		return -1.0;
	} else{
		return distance;
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

bool isBlockedBySphere(vec3 p, vec3 dir, vec4 sphere, int light){
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
	
	if(x1 > 0.001 || x2 > 0.001){
		if(isDirectional(lightsDirection[light])){
			return true;
		} else {
			vec3 p1 = p + dir * x1;
			vec3 p2 = p + dir * x2;
			vec3 lightPos = lightPosition[light].xyz;
			
			float lightDistance = distance(lightPos, p);
			float d1 = distance(lightPos, p1) + distance(p1, p);
			float d2 = distance(lightPos, p2) + distance(p2, p);
			float delta2 = 0.001;
			
			if((d1 + delta2 > lightDistance && d1 - delta2 < lightDistance) || (d2 + delta2 > lightDistance && d2 - delta2 < lightDistance)){
				return true;
			}
		}
	}
	return false;
}

bool isBlockedByPlane(vec3 p, vec3 dir, vec4 plane, int light){
	return false;
}

bool isBlockedBy(vec3 p, vec3 dir, vec4 obj, int light){
	if(isSphere(obj)){
		return isBlockedBySphere(p, dir, obj, light);
	} else{
		return isBlockedByPlane(p, dir, obj, light);
	}
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
		if(t_obj < distance && t_obj >= 0){
			distance = t_obj;
			intersection = i;
		}
	}

	vec3 p = p0 + distance * v;
	float coefficient = (!isSphere(objects[intersection]) && ((squareCoefficient(p) && !quart1_3(p)) || (!squareCoefficient(p) && quart1_3(p)))) ? 1.0 : 0.5;
	
	/******** Lighting *********/
	// Ambient calculations
	vec3 ambient = (ambient.xyz * objColors[intersection].xyz);
	// Diffuse and Specular calculations
	vec3 diffuse = vec3(0.0, 0.0, 0.0);
	vec3 specular = vec3(0.0, 0.0, 0.0);
	
	vec3 N = normalize(isSphere(objects[intersection]) ? (objects[intersection].xyz - p) : objects[intersection].xyz);
	vec3 Kd = objColors[intersection].xyz;
	vec3 Ks = vec3(0.7, 0.7, 0.7);
	float n = objColors[intersection].w;
	
	for(int i=0; i<lightsCount(); i++){
		vec3 L = vec3(0,0,0);
		bool addLight = true;
		
		if(isDirectional(lightsDirection[i])){
			L = normalize(lightsDirection[i].xyz);
		} else if(lightPosition[i].w < dot(normalize(lightsDirection[i].xyz), normalize(p - lightPosition[i].xyz))) {
			L = normalize(p - lightPosition[i].xyz);
		} else {
			addLight = false;
		}
		
		for(int j=0; j<objectsCount(); j++){
			if(isSphere(objects[j]) && isBlockedBy(p, -L, objects[j], i)){
				addLight = false;
			}
		}
		
		
		if(addLight){
			vec3 I = lightsIntensity[i].xyz;
			vec3 R = normalize(L - (2 * N) * dot(L, N));
			
			diffuse += (Kd * dot(N, L)) * I;
			specular += ((Ks * pow(dot(R, v), n)) * I);
		}
	}
	
	if(!isSphere(objects[intersection])){
		diffuse *= coefficient;
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
 

