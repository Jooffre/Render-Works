#ifndef STYLIZED_TOON_LIT_FORWARD_PASS_INCLUDED
#define STYLIZED_TOON_LIT_FORWARD_PASS_INCLUDED

#include "StyLToonParams.hlsl"
#include "StyLToonComp.hlsl"

/*★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

============================================================================================
||                                  Define Structures                                     ||
============================================================================================*/

// --------------------------------- Attributes & Varyings ---------------------------------

struct Attributes
{
    float3 positionOS               : POSITION;
    float2 uv0                      : TEXCOORD0;
    //half4 vertColor                 : COLOR0;
    float3 normalOS                  : NORMAL;
    float4 tangentOS                 : TANGENT;

    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct Varyings
{
    float4 positionCS               : SV_POSITION;
    float2 uv0                      : TEXCOORD0;
    float4 positionWSAndFogFactor   : TEXCOORD1;    // xyz: positionWS, w: vertex fog factor
    float3 normalWS                 : TEXCOORD2;
    float3 positionVS               : TEXCOORD3;
    float4 positionNDC              : TEXCOORD4;
    //float4 color                    : COLOR0;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    UNITY_VERTEX_OUTPUT_STEREO
};


// ---------------------------------- Custom Structures ----------------------------------

struct DirectionData
{
    // common
    float3    lightDirWS;
    float3    viewDirWS;
    float3    normalVS;

    // face
    float3    Up;
    float3    Forward;
    float3    Left;
    float3    Right;
};

struct DotProductData
{
    // common
    float     NxL;
    float     NxH;
    float     NxV;
    float     LxV;

    // face
    float     FxL;
    float     LxL;
    float     RxL;
};

struct MapFeatureData
{
    float metalSpecMask;
    float nonMetalSpecMask;
    float shadowMask;
    float AOMask;
    float specIntensity;
    float MatID;
    float emissionMask;
};

struct ToonLightingData
{
    // light info
    half4       mainLightColor;
    float4      shadowCoord;
};

struct ToonSurfaceData
{
    half4       textureColor;
    half4       emission;
};



/*★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

============================================================================================
|                                       VertexStage                                        |
============================================================================================*/

Varyings VertexStage(Attributes input)
{
    Varyings output;

    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    //output.color = input.vertColor;

    VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs normalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);

    float4 positionCS = vertexInput.positionCS;
    output.positionCS = positionCS;
    float3 positionWS = vertexInput.positionWS;
    output.positionNDC = ComputeScreenPos(positionCS);
    output.positionVS = vertexInput.positionVS;

    output.uv0 = TRANSFORM_TEX(input.uv0, _BaseMap);

    output.normalWS = normalInput.normalWS;

    // Computes fog factor per-vertex.
    float fogFactor = ComputeFogFactor(vertexInput.positionCS.z);

    output.positionWSAndFogFactor = float4(positionWS, fogFactor);

#ifdef MakeOutline

    // outline logics: vert-expansion + scaling
    float3 tangentWS = normalInput.tangentWS;
    // Make the initial outline
    output.positionCS = OutputPositionWithOutline(output.positionCS, tangentWS, _OutlineWidth);

    // Get Z-Offset Mask
    // float outlineZOffsetMask = GetZOffsetMask(_OutlineZOffsetMaskTexture, input.uv0, _OutlineZOffsetMaskRemapStart, _OutlineZOffsetMaskRemapEnd);
    
    // Get New Clip Position With processed Z-Offset
    output.positionCS = GetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset);
    // output.positionCS = GetNewClipPosWithZOffset(output.positionCS, _OutlineZOffset * outlineZOffsetMask );

#endif

#ifdef ApplyShadowBiasFix

    Light mainLight = GetMainLight();

    positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, output.normalWS, mainLight.direction));

    #if UNITY_REVERSED_Z
    positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
    positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    output.positionCS = positionCS;

#endif

    return output;
}



/*★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

============================================================================================
|                                      PreProcessing                                       |
============================================================================================*/

// ---------------------------------- Initialize Data ----------------------------------
DirectionData ComputeDirData(Varyings input)
{
    DirectionData output;

    Light light = GetMainLight();
    
    // common
    output.lightDirWS = normalize(light.direction);
    output.viewDirWS = SafeNormalize(_WorldSpaceCameraPos.xyz - input.positionWSAndFogFactor.xyz);
    //output.viewDirWS = normalize(GetCameraPositionWS() - input.positionWSAndFogFactor.xyz);
    output.normalVS = TransformWorldToViewDir(input.normalWS, true);

    // face
    // [Important]
    // Due to Blend's coordinate is different and it needs to rotate -90d anticlockwise around x to switch to that in Unity
    // [Original Ver.]
    
    //float3 up = normalize(TransformObjectToWorldDir(float3(0, 1, 0)));
    //float3 fwd = normalize(TransformObjectToWorldDir(float3(0, 0, 1)));
    
    float3 fwd = unity_ObjectToWorld._m02_m12_m22;
    //float3 Right = unity_ObjectToWorld._m00_m10_m20;
    float3 up = unity_ObjectToWorld._m01_m11_m21;

    /*
        original:               Blend:

                up
                ↑
                x -→ fwd    ===>    x -→ up
                                    ↓
                                    wd
    */
    //float3 up = normalize(TransformObjectToWorldDir(float3(0, 0, 1)));
    //float3 fwd = normalize(TransformObjectToWorldDir(float3(0, -1, 0)));
    output.Up = up;
    output.Forward = fwd;
    output.Left = - cross(up, fwd);
    output.Right = cross(up, fwd);

    return output;
}

DotProductData ComputeDotProdData(Varyings input, DirectionData dir)
{
    DotProductData output;

    // common
    output.NxL = dot(normalize(input.normalWS), normalize(dir.lightDirWS));
    output.NxH = dot(input.normalWS, normalize(dir.lightDirWS + dir.viewDirWS));
    output.NxV = dot(input.normalWS, dir.viewDirWS);
    output.LxV = dot(dir.lightDirWS, dir.viewDirWS);

    // face
    output.FxL = dot(normalize(dir.Forward.xz), normalize(dir.lightDirWS.xz));
    output.LxL = dot(normalize(dir.Left.xz), normalize(dir.lightDirWS.xz));
    output.RxL = dot(normalize(dir.Right.xz), normalize(dir.lightDirWS.xz));
    
    return output;
}

MapFeatureData SeparateFeatures(half4 baseMap, float4 lightMap)
{
    MapFeatureData output;

    output.metalSpecMask = lightMap.r;
    output.nonMetalSpecMask = abs(1 - lightMap.r);
    
    output.shadowMask = lightMap.g;
    output.AOMask = saturate(lightMap.g * 2.0);

    output.specIntensity = lightMap.b;
    
    // output.MatID = lightMap.a * 0.45;
    output.MatID = lightMap.a;

    output.emissionMask=step(0.5, baseMap.a);

    return output;
}

/*
half4 GetEmissionColor(Varyings input)
{
    half4 emissionColor = 0;
    if(_EnableEmission)
    {
        emissionColor = _EmissionColor;
        // emissionColor = tex2D(_EmissionMap, input.uv).rgb * _EmissionMapChannelMask * _EmissionColor.rgb;
    }

    return emissionColor;
}
*/

void DoClipTestToTargetAlphaValue(half alpha) 
{
#if _UseAlphaClipping
    clip(alpha - _Cutoff);
#endif
}

// ==========================================================================================

// compute k and b of the mapping equation kx+b for the follwing mapping
// [intv1, intv2] --> [intvA, intvB]
float2 ComputeMapEq(float intv1, float intv2, float intvA, float intvB)
{
    float d1 = intv2 - intv1;
    float d2 = intvB - intvA;
    float k = d2 / d1;
    float b = intvA - k * intv1;
    return float2(k, b);
}


float TripplePhaseMap(float x, float boundary1, float boundary2, float fstVal, float secVal, float k, float b)
{
    if (x <= boundary1) return fstVal;
    else if (x >= boundary2) return secVal;
    else return k * x + b;
}


float MetalFilter(float MatID, float intvL, float intvR)
{
    if (MatID >= intvL && MatID < intvR) return 1;
    else return 0;
}


half3 ComputeOutlineColor(half3 surfaceColor)
{
    return surfaceColor * _OutlineColor;
}


float4 TransformHClipToViewPortPos(float4 positionCS)
 {
     float4 o = positionCS * 0.5f;
     o.xy = float2(o.x, o.y * _ProjectionParams.x) + o.w;
     o.zw = positionCS.zw;
     return o / o.w;
 }


// -----------------------------------------------------------------------------


/*★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

============================================================================================
|                                     Fragment Stage                                       |
============================================================================================*/

half4 FragmentStage(Varyings input) : SV_Target
{
    UNITY_SETUP_INSTANCE_ID(input);
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

    // ---------------------------------- Initialize Data -----------------------------------

    half4 color = 0;

    float4 shadowCoord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);

    Light mainLight = GetMainLight(shadowCoord);
    float4 mainLightColor = float4(mainLight.color, 1);

    DirectionData dir = ComputeDirData(input);
    DotProductData prod = ComputeDotProdData(input, dir);


    // ---------------------------------- Sample Textures -----------------------------------
    
    half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);
    float4 lightMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv0);


#if _RENDERMODE_COMMON

    // ------------------------------- Separate Map Channels --------------------------------

    MapFeatureData mData = SeparateFeatures(baseMap, lightMap);


    // ------------------------------------ Emission ---------------------------------------

    half4 emission = _EnableEmission * _EmissionIntensity * baseMap;


    // -------------------------------- Lighting & RampMap ----------------------------------

    baseMap.rgb *= _BaseColor;

    float lambert = clamp(prod.NxL + mData.AOMask - 1, -1, 1);
    float halfLambert = lambert * 0.5 + 0.5;

    //float rampSampler = ReMap(halfLambert, 0, 1, _ShadowRampThreshold, 1);
    halfLambert = pow(halfLambert, 3);
    float2 kb = ComputeMapEq(_RampIntv1, _RampIntv2, _RampIntvA, _RampIntvB);
    float halfLambertRemap = TripplePhaseMap(halfLambert, _RampIntv1, _RampIntv2, _RampDarkVal, _RampBrightVal, kb.x, kb.y);

    float2 rampUV = float2(halfLambertRemap , _Ramp_V + (_TimeShift - 1.0) * 0.5 - 0.05);
    

    // sampling rampMap
    float4 rampShadow = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

    float lambertRemap = smoothstep(-_ShadowOffset, -_ShadowOffset + _ShadowRampWidth, lambert);

    //half4 softLayer = lerp(rampShadow, mainLightColor * rampShadow + emission * 4, lambertRemap) * baseMap;
    //half4 contrastLayer = (step(0.3, halfLambert) + max(mainLightColor, rampShadow)) * baseMap;
    half4 softLayer = rampShadow * baseMap * _ShadowTint;
    half4 contrastLayer = (smoothstep(_ContrastLayer_L, _ContrastLayer_R, halfLambert) * emission + rampShadow) * baseMap;

    half4 diffuse = lerp(softLayer, contrastLayer, lambertRemap);

    float mask = step(0.05, mData.shadowMask);
    diffuse = lerp(baseMap * _ShadowTintDark, softLayer, mask);
    //half4 diffuse = rampShadow;

    // ------------------------------------ Specular --------------------------------------

    // non-metal spec
    //float nonMetalSpecCtrl = step(1 - _ViewSpecWidth, saturate(prod.NxV) * step(0, lambert));
    //float nonMetalSpec = _NonMetalSpecIntensity * nonMetalSpecCtrl;
    //nonMetalSpec += pow(saturate(prod.NxH), _Smoothness);

    // metal spec
    float metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, dir.viewDirWS.xy * 0.5 + 0.5).r;
    float metalSpec = _MetalSpecIntensity * mData.metalSpecMask * mData.specIntensity * metalMap;

    //half4 specular = _EnableSpecular * lerp(nonMetalSpec * baseMap, metalSpec * baseMap, mData.specIntensity);
    //half4 specular = _EnableSpecular * metalSpec * baseMap;
    half4 specular = _NonMetalSpecIntensity * contrastLayer * baseMap;

    // -------------------------------------- SSD Rim ------------------------------------------

    float2 screenUV = float2(input.positionCS.x / _ScreenParams.x, input.positionCS.y / _ScreenParams.y);
    // ★ it's important that if offset is divided by positionNDC.w: 
    //    -  yes, the rim width changes with camera's distance;
    //    -  No, the rim width remains a constant.
    float2 offsetUV = screenUV + float2(dir.normalVS.xy * _RimWidth * clamp(prod.NxV, 0.5, 1) / input.positionNDC.w);
    
    //float offsetDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, offsetUV), _ZBufferParams);
    //float originalDepth = LinearEyeDepth(SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, screenUV), _ZBufferParams);
     
    float originalDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
    float offsetDepth = LinearEyeDepth(SampleSceneDepth(offsetUV), _ZBufferParams);

    float rimMask = step(0.25, smoothstep(0, _RimLightThreshold, offsetDepth - originalDepth));
    
    half4 rimLight = _EnableRim * rimMask * _RimLightIntensity * _RimColor;


    // -------------------------------------- Color ----------------------------------------

    //color = _EnableRim * rimMask;
    color = diffuse + specular + emission * 0.5 + rimLight;


#elif _RENDERMODE_METAL

    // ------------------------------- Separate Map Channels --------------------------------

    MapFeatureData mData = SeparateFeatures(baseMap, lightMap);


    // ------------------------------------ Emission ---------------------------------------

    half4 emission = _EnableEmission * _EmissionIntensity * baseMap;


    // -------------------------------- Lighting & RampMap ----------------------------------

    baseMap.rgb *= _BaseColor;

    float lambert = clamp(prod.NxL + mData.AOMask - 1, -1, 1);
    float halfLambert = lambert * 0.5 + 0.5;

    //float rampSampler = ReMap(halfLambert, 0, 1, _ShadowRampThreshold, 1);
    halfLambert = pow(halfLambert, 3);
    float2 kb = ComputeMapEq(_RampIntv1, _RampIntv2, _RampIntvA, _RampIntvB);
    float halfLambertRemap = TripplePhaseMap(halfLambert, _RampIntv1, _RampIntv2, _RampDarkVal, _RampBrightVal, kb.x, kb.y);

    float2 rampUV = float2(halfLambertRemap , _Ramp_V + (_TimeShift - 1.0) * 0.5 - 0.05);
    
    // sampling rampMap
    float4 rampShadow = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

    float lambertRemap = smoothstep(-_ShadowOffset, -_ShadowOffset + _ShadowRampWidth, lambert);

    half4 softLayer = rampShadow * baseMap * _ShadowTint;
    half4 contrastLayer = (smoothstep(0.0, 0.4, halfLambert) * emission + rampShadow) * baseMap;

    half4 diffuse = lerp(softLayer, contrastLayer, lambertRemap);

    //half4 diffuse = smoothstep(0.0, 0.5, halfLambert);
    //diffuse = lerp(baseMap * _ShadowTintDark, diffuse, step(0.05, mData.shadowMask));


    // ------------------------------------ Specular --------------------------------------

    // non-metal spec
    float NonmetalArea = MetalFilter(mData.MatID, _NonMetalIntvL, _NonMetalIntvR);
    //float nonMetalSpecCtrl = step(1 - _ViewSpecWidth, saturate(prod.NxV) * step(0, lambert));
    //float nonMetalSpec =  _NonMetalSpecIntensity * mData.nonMetalSpecMask * mData.specIntensity * nonMetalSpecCtrl;
    //nonMetalSpec += pow(saturate(prod.NxH), _Smoothness) * mData.nonMetalSpecMask * mData.specIntensity;
    
    
    // metal spec
    float spec = pow(saturate(prod.NxH * 1.08), _Smoothness);
    //float2 metalMapUV = float2(spec, dir.viewDirWS.y * 0.5 + 0.5);
    float2 metalMapUV = float2(clamp(spec, 0, _MetalSampRange), clamp(spec, 0, _MetalSampRange));
    float metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, metalMapUV).r;
    //float metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, dir.viewDirWS.xy * 0.5 + 0.5).r;
    float metalArea = MetalFilter(mData.MatID, _MetalIntvL, _MetalIntvR);

    float2 metalMapUV2 = float2(clamp(spec, 0, _MetalSampRange2), clamp(spec, 0, _MetalSampRange2));
    float metalMap2 = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, metalMapUV2).r;
    float metalArea2 = MetalFilter(mData.MatID, _MetalIntvL2, _MetalIntvR2);

    float metalSpec = _MetalSpecIntensity * mData.metalSpecMask * metalMap * metalArea;
    float metalSpec2 = _MetalSpecIntensity2 * mData.metalSpecMask * metalMap2 * metalArea2;
    float metalSpec3 = _NonMetalSpecIntensity * contrastLayer * NonmetalArea;

    metalSpec += metalSpec2 + metalSpec3;
    
    //half4 baseLamb = spec * baseMap;

    //half4 specular = lerp(nonMetalSpec, metalSpec * baseMap, saturate(mData.specIntensity + 0.3));
    half4 specular = metalSpec * baseMap * saturate(mData.specIntensity + 0.3);

    //specular *= baseLamb;

    // ------------------------------------- SSD Rim -----------------------------------------

    float2 screenUV = float2(input.positionCS.x / _ScreenParams.x, input.positionCS.y / _ScreenParams.y);
    float2 offsetUV = screenUV + float2(dir.normalVS.xy * _RimWidth * clamp(prod.NxV, 0.5, 1) / input.positionNDC.w);
    
    float originalDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
    float offsetDepth = LinearEyeDepth(SampleSceneDepth(offsetUV), _ZBufferParams);

    float rimMask = step(0.25, smoothstep(0, _RimLightThreshold, offsetDepth - originalDepth));
    
    half4 rimLight = _EnableRim * rimMask * baseMap * _RimLightIntensity * _RimColor;


    // -------------------------------------- Color ----------------------------------------

    //color = mData.metalSpecMask ;
    color = diffuse + _EnableSpecular * specular + emission * 0.5 + rimLight;



#elif _RENDERMODE_HAIR

    // ------------------------------- Separate Map Channels --------------------------------

    MapFeatureData mData = SeparateFeatures(baseMap, lightMap);


    // ------------------------------------ Emission ---------------------------------------

    half4 emission = _EnableEmission * _EmissionIntensity * baseMap;


    // -------------------------------- Lighting & RampMap ----------------------------------

    baseMap.rgb *= _BaseColor;

    float lambert = clamp(prod.NxL + mData.AOMask - 1, -1, 1);
    float halfLambert = prod.NxL * 0.5 + 0.5;
    halfLambert = pow(halfLambert, 3);
    float2 kb = ComputeMapEq(_RampIntv1, _RampIntv2, _RampIntvA, _RampIntvB);
    float halfLambertRemap = TripplePhaseMap(halfLambert, _RampIntv1, _RampIntv2, _RampDarkVal, _RampBrightVal, kb.x, kb.y);

    //float _Ramp_U = smoothstep(0.05, 1, halfLambert);
    //float _Ramp_U_Gradient = ShadowGradient(_Ramp_U, 0.82, 0.95);
    
    float2 rampUV = float2(halfLambertRemap, _Ramp_V + (_TimeShift - 1.0) * 0.5 + 0.02);

    // sampling rampMap
    float4 hairRamp = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

    float lambertRemap = smoothstep(-_ShadowOffset, -_ShadowOffset + _ShadowRampWidth, lambert);
    //half4 normalLayer = lerp(hairRamp, hairRamp + emission, lambertRemap) * baseMap;
    //half4 litLayer =  lerp(hairRamp + emission, max(mainLightColor, hairRamp), 1 - _BoundaryIntensity) * baseMap;

    half4 softLayer = hairRamp * baseMap * _ShadowTint;
    half4 contrastLayer = (smoothstep(0.5, 0.75, halfLambert) * emission + hairRamp) * baseMap;

    half4 diffuse = lerp(softLayer, contrastLayer, lambertRemap);

    //diffuse = lerp(_ShadowTint * diffuse, diffuse, halfLambert);
    diffuse = lerp(baseMap * _ShadowTintDark, diffuse, step(0.05, mData.shadowMask));

    // ------------------------------------ Specular --------------------------------------

    // non-metal spec
    float SpecCoef = step(1 - _ViewSpecWidth, saturate(prod.NxV) * step(0, lambert));
    float nonMetalSpec =  _NonMetalSpecIntensity * mData.nonMetalSpecMask * mData.specIntensity * SpecCoef;
    nonMetalSpec += pow(saturate(prod.NxH), _Smoothness) * mData.nonMetalSpecMask * mData.specIntensity;

    // metal spec
    float metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, dir.viewDirWS.xy * 0.5 + 0.5).r;
    float metalSpec = _MetalSpecIntensity * mData.metalSpecMask * mData.specIntensity * metalMap;

    half4 specular = _EnableSpecular * lerp(metalSpec * baseMap, nonMetalSpec, mData.specIntensity);


    // ------------------------------------- SSD Rim -----------------------------------------

    float2 screenUV = float2(input.positionCS.x / _ScreenParams.x, input.positionCS.y / _ScreenParams.y);
    float2 offsetUV = screenUV + float2(dir.normalVS.xy * _RimWidth * clamp(prod.NxV, 0.5, 1) / input.positionNDC.w);
    
    float originalDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
    float offsetDepth = LinearEyeDepth(SampleSceneDepth(offsetUV), _ZBufferParams);

    float rimMask = step(0.25, smoothstep(0, _RimLightThreshold, offsetDepth - originalDepth));
    
    half4 rimLight = _EnableRim * rimMask * baseMap * _RimLightIntensity * _RimColor;


    // -------------------------------------- Color ----------------------------------------

    //color = rimLight;
    color = diffuse + specular + rimLight + emission * 0.5;


#elif _RENDERMODE_FACE

    // ------------------------------------ Emission ---------------------------------------

    half4 emission = _EnableEmission * _EmissionIntensity * baseMap;

    // =================================== Face Lighting ====================================

    //float lambert = clamp(prod.NxL, -1, 1);

    float2 face_uv = float2(lerp(input.uv0.x, 1 - input.uv0.x, step(0, prod.RxL)) , input.uv0.y);
    float faceShadowtMap = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, face_uv).r;

    faceShadowtMap = pow(faceShadowtMap, _FaceShadowPow);

    // rotate facial shadow manually
    float sinx = sin(_FaceShadowOffset);
    float cosx = cos(_FaceShadowOffset);
    float2x2 rotationOffset1 = float2x2(cosx, sinx, -sinx, cosx); // clockwise rot
    float2x2 rotationOffset2 = float2x2(cosx, -sinx, sinx, cosx); // anticlockwise  rot
    float2 faceLightDir = lerp(mul(rotationOffset1, dir.lightDirWS.xz), mul(rotationOffset2, dir.lightDirWS.xz), step(0, prod.RxL));
    
    float FxL = dot(normalize(dir.Forward.xz), normalize(faceLightDir));


    //float shadowState = step(0, shadowMap - (1 - -prod.FxL)/2); // (1 - -prod.FxL)/2 : [0, 1]
    //float shadowState = shadowMap - (1 - prod.FxL)/2;

    float shadowBinaryGraph = step((1 - FxL)/2, faceShadowtMap); // 0 : shadow   1 : light 

    float2 rampUV = float2(clamp(shadowBinaryGraph, 0.05, 0.95), _Ramp_V + (_TimeShift - 1.0) * 0.5);
    half4 faceColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

    //float shadowGradient = smoothstep(-_ShadowOffset, -_ShadowOffset + _ShadowRampWidth, shadowState);


    // -------------------------------------- SSD Rim ------------------------------------------

    float2 screenUV = float2(input.positionCS.x / _ScreenParams.x, input.positionCS.y / _ScreenParams.y);
    float2 offsetUV = screenUV + float2(dir.normalVS.xy * _RimWidth * clamp(prod.NxV, 0.5, 1) / input.positionNDC.w);
    
    float originalDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
    float offsetDepth = LinearEyeDepth(SampleSceneDepth(offsetUV), _ZBufferParams);

    float rimMask = step(0.25, smoothstep(0, _RimLightThreshold, offsetDepth - originalDepth));
    
    half4 rimLight = _EnableRim * rimMask * baseMap * _RimLightIntensity * _RimColor;


    // -------------------------------------- Color ----------------------------------------

    //color = shadowBinaryGraph;
    color = lerp(faceColor * _ShadowTint, faceColor + emission, shadowBinaryGraph) * baseMap * _BaseColor + rimLight;
    

#elif _RENDERMODE_BODY

    // ------------------------------- Separate Map Channels --------------------------------

    MapFeatureData mData = SeparateFeatures(baseMap, lightMap);


    // ------------------------------------ Emission ---------------------------------------

    half4 emission = _EnableEmission * _EmissionIntensity * baseMap;

    // -------------------------------- Lighting & RampMap ----------------------------------

    baseMap.rgb *= _BaseColor;

    float lambert = clamp(prod.NxL + mData.AOMask - 1, -1, 1);
    //float lambert = prod.NxL;
    float halfLambert = prod.NxL * 0.5 + 0.5;

    //float rampSampler = ReMap(halfLambert, 0, 1, _ShadowRampThreshold, 1);
    halfLambert = pow(halfLambert, 3);

    float lambertRemap = smoothstep(-_ShadowOffset, -_ShadowOffset + _ShadowRampWidth, lambert);

    float2 kb = ComputeMapEq(_RampIntv1, _RampIntv2, _RampIntvA, _RampIntvB);
    float halfLambertRemap = TripplePhaseMap(halfLambert, _RampIntv1, _RampIntv2, _RampDarkVal, _RampBrightVal, kb.x, kb.y);

    float2 rampUV = float2(halfLambertRemap , _Ramp_V + (_TimeShift - 1.0) * 0.5 - 0.1);

    // sampling rampMap
    float4 rampShadow = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, rampUV);

    //half4 softLayer = lerp(rampShadow, max(mainLightColor, rampShadow), lambertRemap) * baseMap;
    half4 softLayer = rampShadow * baseMap * _ShadowTint;
    half4 contrastLayer = (smoothstep(0.5, 0.75, halfLambert) * emission + rampShadow) * baseMap;

    half4 diffuse = lerp(softLayer, contrastLayer, lambertRemap);

    //float mask = step(0.05, mData.shadowMask);
    diffuse = lerp(baseMap * _ShadowTintDark, diffuse, step(0.05, mData.shadowMask));
    diffuse = lerp(diffuse * _ShadowTint, diffuse, mainLight.shadowAttenuation.x);

    // ------------------------------------ Specular --------------------------------------

    // non-metal spec
    float nonMetalSpecCtrl = step(1 - _ViewSpecWidth, saturate(prod.NxV) * step(0, lambert));
    float nonMetalSpec =  _NonMetalSpecIntensity * mData.nonMetalSpecMask * mData.specIntensity * nonMetalSpecCtrl;
    nonMetalSpec += pow(saturate(prod.NxH), _Smoothness) * mData.nonMetalSpecMask * mData.specIntensity;

    // metal spec
    float metalMap = SAMPLE_TEXTURE2D(_MetalMap, sampler_MetalMap, dir.viewDirWS.xy * 0.5 + 0.5).r;
    float metalSpec = _MetalSpecIntensity * mData.metalSpecMask * mData.specIntensity * metalMap;

    half4 specular = _EnableSpecular * lerp(nonMetalSpec, metalSpec * baseMap, mData.specIntensity);


    // -------------------------------------- SSD Rim ------------------------------------------

    float2 screenUV = float2(input.positionCS.x / _ScreenParams.x, input.positionCS.y / _ScreenParams.y);
    float2 offsetUV = screenUV + float2(dir.normalVS.xy * _RimWidth * clamp(prod.NxV, 0.5, 1) / input.positionNDC.w);
    
    float originalDepth = LinearEyeDepth(SampleSceneDepth(screenUV), _ZBufferParams);
    float offsetDepth = LinearEyeDepth(SampleSceneDepth(offsetUV), _ZBufferParams);

    float rimMask = step(0.25, smoothstep(0, _RimLightThreshold, offsetDepth - originalDepth));
    
    half4 rimLight = _EnableRim * rimMask * baseMap * _RimLightIntensity * _RimColor;


    // -------------------------------------- Color ----------------------------------------

    //color = baseMap * _ShadowTint;
    color = diffuse + specular + emission * 0.5 + rimLight;


#endif


#ifdef MakeOutline

    color.rgb = ComputeOutlineColor(color.rgb);

#endif

    return color;
}


// ============================== For Shadow And Depth Pass ==============================

void ApplyShadowBiasFix2(Varyings input)
{
    half4 col = _BaseColor * SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv0);
    DoClipTestToTargetAlphaValue(col.a);
}


half4 DepthOnlyFragment(Varyings input) : SV_TARGET
{
    UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
    
    Alpha(SampleAlbedoAlpha(input.uv0, TEXTURE2D_ARGS(_BaseMap, sampler_BaseMap)).a, _BaseColor, _Cutoff);
    
    return 0;
}

#endif