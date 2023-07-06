#ifndef STYLIZED_TOON_PARAMS_INCLUDED
#define MY_PBR_PARAMS_INCLUDED

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceInput.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

CBUFFER_START(UnityPerMaterial)

    // Color & Textures
    half4       _BaseColor;
    float4      _BaseMap_ST;
    float4      _LightMap_ST;
    float4      _MetalMap_ST;
    float4      _RampMap_ST;
    float       _Cutoff;

    // TimeShift
    int         _TimeShift;

    // RampMap
    float       _Ramp_V;

    float       _RampIntv1;
    float       _RampIntv2;
    float       _RampIntvA;
    float       _RampIntvB;

    float       _RampDarkVal;
    float       _RampBrightVal;

    // Emission
    float       _EnableEmission;
    //half4     _EmissionColor;
    float       _EmissionIntensity;

    // Outline
    half3       _OutlineColor;
    float       _OutlineWidth;
    float       _OutlineZOffset;
    //float4    _OutlineZOffsetMaskTexture_ST;
    //float     _OutlineZOffsetMaskRemapStart;
    //float     _OutlineZOffsetMaskRemapEnd;

    // Specular
    float       _EnableSpecular;
    half4       _SpecularColor;

    float       _ContrastLayer_L;
    float       _ContrastLayer_R;
    float       _NonMetalSpecIntensity;
    float       _NonMetalIntvL;
    float       _NonMetalIntvR;

    float       _MetalSampRange;
    float       _MetalSampRange2;
    float       _MetalSpecIntensity;
    float       _MetalSpecIntensity2;
    float       _MetalIntvL;
    float       _MetalIntvR;
    float       _MetalIntvL2;
    float       _MetalIntvR2;

    float       _Smoothness;
    float       _ViewSpecWidth;

    // Rim
    float       _EnableRim;
    half4       _RimColor;
    float       _RimWidth;
    float       _RimLightThreshold;
    float       _RimLightIntensity;

    // Shadow
    float       _FaceShadowPow;
    float       _FaceShadowOffset;
    half4       _ShadowTint;
    half4       _ShadowTintDark;

    float       _BoundaryIntensity;
    float       _ShadowOffset;
    float       _ShadowRampWidth;
    half4       _ShadowRampThreshold;

CBUFFER_END

sampler2D _OutlineZOffsetMaskTexture;

//TEXTURE2D(_BaseMap);                                SAMPLER(sampler_BaseMap);
TEXTURE2D(_LightMap);                               SAMPLER(sampler_LightMap);
TEXTURE2D(_MetalMap);                               SAMPLER(sampler_MetalMap);
TEXTURE2D(_RampMap);                                SAMPLER(sampler_RampMap);

//TEXTURE2D_X_FLOAT(_CameraDepthTexture);             SAMPLER(sampler_CameraDepthTexture);

#endif