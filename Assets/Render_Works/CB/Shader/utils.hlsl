float saturate(float x)
{
    return clamp(x, 0, 1);
}

float3 saturate(float3 x)
{
    return clamp(x, float3(0, 0, 0), float3(1, 1, 1));
}

float rand(float2 coord)
{
    return saturate(frac(sin(dot(coord, float2(12.9898, 78.223))) * 43758.5453));
}


float pcurve(float x, float a, float b)
{
    //float k = pow(a + b, a + b) / (pow(a, a) * pow(b, b));
    //float k = 7.379519;
    return 9 * pow(x, a) * pow(1.0 - x, b);
    // return 5.5 * pow(x, 4) * pow(1.0 - x, 0.95); 
    // k determine the dark cloud's coverage, a is for smoothness and b is for grainy
}


float3 rotate(float3 p, float x, float y, float z)
{
    float3x3 matx = float3x3(1.0, 0.0, 0.0,
                            0.0, cos(x), -sin(x),
                            0.0, sin(x), cos(x));

    float3x3 maty = float3x3(cos(y), 0.0, sin(y),
                            0.0, 1.0, 0.0,
                            -sin(y), 0.0, cos(y));

    float3x3 matz = float3x3(cos(z), -sin(z), 0.0,
                            sin(z), cos(z), 0.0,
                            0.0, 0.0, 1.0);

    p = mul(matx, p);
    p = mul(matz, p);
    p = mul(maty, p);

    return p;
}


void RotateCamera(inout float3 eyevec, inout float3 eyepos, float obliquity)
{
    //float mousePosY = iMouse.y / iResolution.y;
    //float mousePosX = iMouse.x / iResolution.x;

    //float3 angle = float3(mousePosY * 0.05 + 0.05, 1.0 + mousePosX * 1.0, -0.45);
    float3 angle = float3(0, 0, obliquity);

    eyevec = rotate(eyevec, angle.x, angle.y, angle.z);
    eyepos = rotate(eyepos, angle.x, angle.y, angle.z);
}


// ==================================================================================


void WarpSpace(float maxSteps, inout float3 viewDir, inout float3 rayPos)
{
    float3 origin = float3(0.0, 0.0, 0.0);

    float singularityDist = length(rayPos - origin);
    
    /*float warpFactor = 1.0 / (pow(singularityDist, 2.0) + 0.000001);

    float3 singularityVector = normalize(origin - rayPos);
    
    float warpAmount = 10.0;*/

    //viewDir = normalize(viewDir + singularityVector * warpFactor * warpAmount / float(maxSteps));   
    //viewDir = normalize(direction - position * stepSize / pow(distance, 3) * SCHWARZSCHILD);

    viewDir = normalize(viewDir - rayPos * (10 / maxSteps) / pow(singularityDist, 3.15));
}


float sdf_Torus(float3 p, float2 t)
{
    return length(float2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdSphere(float3 p, float r)
{
  return length(p) - r;
}


void Haze(inout float3 color, float3 pos, float alpha, half3 HazeColor, float maxSteps)
{
    float2 t = float2(0.75, 0.02);

    float torusDist = sdf_Torus(pos + float3(0.0, -0.05, 0.0), t);

    float bloomDisc = 1.0 / (pow(torusDist, 2.0) + 0.001);
    //float3 col = MainColor;
    bloomDisc *= length(pos) < 0.5 ? 0.0 : 1.0;

    color += bloomDisc * (3.5 / float(maxSteps)) * (1.0 - alpha * 1.0) * HazeColor;
}

float GetDist(float3 p)
{
    //float d1 = sdf_Torus(p, float2(1.2, 0.1));
    float d2 = sdSphere(p, 3);

    return d2;
}

float3 GetNormal(float3 p)
{
    float2 e = float2(1e-2, 0);
    float3 n = GetDist(p) - float3(GetDist(p - e.xyy), GetDist(p - e.yxy), GetDist(p - e.yyx));
    return normalize(n);
}