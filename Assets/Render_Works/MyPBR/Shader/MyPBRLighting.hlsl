#ifndef MY_PBR_LIGHTING_INCLUDED
#define MY_PBR_LIGHTING_INCLUDED

#include "MyPBRParams.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

half ReMap(half minmum, half maxmum, half x)
{
    return saturate((x - minmum) / (maxmum - minmum));
}

half3 DirectStylizedBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    float3 halfVec = SafeNormalize(float3(lightDirectionWS) + float3(viewDirectionWS));

    float NxH = saturate(dot(normalWS, halfVec));
    half LxH = saturate(dot(lightDirectionWS, halfVec));

    float d = NxH * NxH * brdfData.roughness2MinusOne + 1.00001f;

    half LxH2 = LxH * LxH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LxH2) * brdfData.normalizationTerm);

#if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
    specularTerm = specularTerm - HALF_MIN;
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = lerp(ReMap( _SpecularThreshold - _SpecularSmooth, _SpecularThreshold + _SpecularSmooth, specularTerm ), specularTerm, _GGXSpecular) * brdfData.specular * max(0,_SpecularIntensity) + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

half3 LightingStylizedPhysicallyBased(BRDFData brdfData, half3 radiance, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    return  DirectStylizedBDRF(brdfData, normalWS, normalize(lightDirectionWS + _SpecularLightOffset.xyz), viewDirectionWS) * radiance;
}

half3 LightingStylizedPhysicallyBased(BRDFData brdfData, half3 radiance, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingStylizedPhysicallyBased(brdfData, radiance, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}

half3 EnvironmentBRDFCustom(BRDFData brdfData, half3 radiance, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)  
{
    half3 c = indirectDiffuse * brdfData.diffuse * _GIIntensity;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(brdfData.specular * radiance, brdfData.grazingTerm, fresnelTerm);   
    return c;
}

half3 StylizedGlobalIllumination(BRDFData brdfData, half3 radiance, half3 bakedGI, half occlusion, half3 normalWS, half3 viewDirectionWS, half metallic, half nxl)
{
    half3 reflectVector = reflect(-viewDirectionWS, normalWS);
    half fresnelTerm = ReMap( _FresnelThreshold - _FresnelSmooth, _FresnelThreshold += _FresnelSmooth, 1.0 - saturate(dot(normalWS, viewDirectionWS))) * max(0,_FresnelIntensity) * nxl;

    half3 indirectDiffuse = bakedGI * occlusion;
    half3 indirectSpecular = GlossyEnvironmentReflection(reflectVector, brdfData.perceptualRoughness, occlusion) * lerp(max(0,_ReflProbeIntensity), max(0,_MetalReflProbeIntensity), metallic) ;

    return EnvironmentBRDFCustom(brdfData, radiance, indirectDiffuse, indirectSpecular, fresnelTerm);
}

half3 CalculateRadiance(Light light, half3 normalWS, half3 artTex, half3 texStrengthRGB)
{
    half NxL = dot(normalWS, light.direction);

    #if _USEARTTEX_ON
        half halfLambertMed = NxL * lerp(0.5, artTex.r, texStrengthRGB.r) + 0.5;
        half halfLambertShadow = NxL * lerp(0.5, artTex.g, texStrengthRGB.g) + 0.5;
        half halfLambertRefl = NxL * lerp(0.5, artTex.b, texStrengthRGB.b) + 0.5;
    #else
        half halfLambertMed = NxL * 0.5 + 0.5;
        half halfLambertShadow = halfLambertMed;
        half halfLambertRefl = halfLambertMed;
    #endif
    
    half smoothMedTone = ReMap( _MedThreshold - _MedSmooth, _MedThreshold + _MedSmooth, halfLambertMed);
    half3 MedToneColor = lerp(_MedColor.rgb , 1 , smoothMedTone);
    half smoothShadow = ReMap ( _ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, halfLambertShadow * (lerp(1,light.distanceAttenuation * light.shadowAttenuation,_ReceiveShadows) ));
    half3 ShadowColor = lerp(_ShadowColor.rgb, MedToneColor, smoothShadow );
    half smoothReflect = ReMap( _ReflectThreshold - _ReflectSmooth, _ReflectThreshold + _ReflectSmooth, halfLambertRefl);
    half3 ReflectColor = lerp(_ReflectColor.rgb , ShadowColor , smoothReflect);
    half3 radiance = light.color * ReflectColor;    //lightColor * (lightAttenuation * NxL);
    return radiance;
}


half4 UniversalFragmentStylizedPBR(InputData inputData, half3 albedo, half metallic, half3 specular,
half smoothness, half occlusion, half3 emission, half alpha, half2 uv)
{
    BRDFData brdfData;
    InitializeBRDFData(albedo, metallic, specular, smoothness, alpha, brdfData);
    
    Light mainLight = GetMainLight(inputData.shadowCoord);
#ifdef _USEARTTEX_ON
    float3 artTex = SAMPLE_TEXTURE2D(_ArtTex, sampler_ArtTex, uv * _ArtTex_ST.xy + _ArtTex_ST.zw).rgb;
    float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, artTex, float3(_MedArtTexStrength, _ShadowArtTexStrength, _ReflArtTexStrength));
#else
    float3 radiance = CalculateRadiance(mainLight, inputData.normalWS, 0.5, float3(0, 0, 0));
    //float3 radiance = 0;
#endif
    

    MixRealtimeAndBakedGI(mainLight, inputData.normalWS, inputData.bakedGI, half4(0, 0, 0, 0));

    float nxl = ReMap( _ShadowThreshold - _ShadowSmooth, _ShadowThreshold + _ShadowSmooth, dot(mainLight.direction, inputData.normalWS) * 0.5 + 0.5 );

    half3 color = StylizedGlobalIllumination(brdfData, radiance, inputData.bakedGI, occlusion, inputData.normalWS, inputData.viewDirectionWS, metallic, lerp(1,nxl, _DirectionalFresnel)  );
    color += LightingStylizedPhysicallyBased(brdfData, radiance, mainLight, inputData.normalWS, inputData.viewDirectionWS);

#ifdef _ADDITIONAL_LIGHTS
    uint pixelLightCount = GetAdditionalLightsCount();
    for (uint lightIndex = 0u; lightIndex < pixelLightCount; ++lightIndex)
    {
        Light light = GetAdditionalLight(lightIndex, inputData.positionWS);
        color += LightingPhysicallyBased(brdfData, light, inputData.normalWS, inputData.viewDirectionWS);
    }
#endif

#ifdef _ADDITIONAL_LIGHTS_VERTEX
    color += inputData.vertexLighting * brdfData.diffuse;
#endif

    color += emission;
    return half4(color, alpha);
}

#endif