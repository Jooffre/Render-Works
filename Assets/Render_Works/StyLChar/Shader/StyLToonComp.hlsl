#ifndef STYLIZED_TOON_COMPUTATION_INCLUDED
#define STYLIZED_TOON_COMPUTATION_INCLUDED

float ReMap(float x, float minimum, float maximum, float lower, float upper)
{
    return (x - minimum) / (maximum - minimum) * (upper - lower) + lower;
}

half invLerp(half from, half to, half value) 
{
    return (value - from) / (to - from);
}
half invLerpClamp(half from, half to, half value)
{
    return saturate(invLerp(from,to,value));
}

float4 OutputPositionWithOutline(float4 positionCS, float3 tangentWS, float outlineWidth)
{
    // transform tangent from WS to CS
    float3 tangentCS = TransformWorldToHClipDir(tangentWS);

    float2 extendOutline = normalize(tangentCS.xy) * (outlineWidth * 0.01);
    
    // eliminate the effect of aspect ratio (set to 1:1) 
    float4 ScreenParams = GetScaledScreenParams();
    float Scaler = abs(ScreenParams.x / ScreenParams.y);

    extendOutline.x /= Scaler;
    
    // clamp the outline width
    float ctrl = clamp(1/positionCS.w, 0, 1);
    
    // multiplied component w of CS to prevent from scaling (pos will be divided by this w in later stage)
    positionCS.xy += extendOutline * positionCS.w * ctrl;

    return positionCS;
}

float GetZOffsetMask(sampler2D _OutlineZOffsetMaskTexture, float2 uv, half outlineZOffsetMaskRemapStart, half outlineZOffsetMaskRemapEnd, int lod = 0)
{
    // note tex2D() cannot be used in the vertex stage
    float outlineZOffsetMask = tex2Dlod(_OutlineZOffsetMaskTexture, float4(uv, 0, lod)).r;

    // flip texture data so that default black area represents applying ZOffset
    // since by convention, the black area is used to "erase" something when painting a mask.
    // outlineZOffsetMask = 1-outlineZOffsetMask;
    outlineZOffsetMask = invLerpClamp(outlineZOffsetMaskRemapStart, outlineZOffsetMaskRemapEnd, outlineZOffsetMask);
    
    return outlineZOffsetMask;
}

float4 GetNewClipPosWithZOffset(float4 originalPositionCS, float viewSpaceZOffsetAmount)
{
    float2 ProjM_ZRow_ZW = UNITY_MATRIX_P[2].zw;
    float modifiedPositionVS_Z = -originalPositionCS.w + -viewSpaceZOffsetAmount; // push imaginary vertex
    float modifiedPositionCS_Z = modifiedPositionVS_Z * ProjM_ZRow_ZW[0] + ProjM_ZRow_ZW[1];
    originalPositionCS.z = modifiedPositionCS_Z * originalPositionCS.w / (-modifiedPositionVS_Z); // overwrite positionCS.z
    return originalPositionCS; 
}

#endif