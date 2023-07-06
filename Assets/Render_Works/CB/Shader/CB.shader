Shader "Universal Render Pipeline/Celestial Body"
{
    Properties
    {
        _Texture1("Noise Texture", 2D) = "black" {}
        _Texture2("Color Texture", 2D) = "black" {}
        _HazeColor("Haze Color", Color) = (0, 0, 0)
        _SkyCube("Skybox Cube", Cube) = "defauttexture" {}
        _Speed("Rotation Speed", Range(-0.5, 0.5)) = 0.1
        _DiskRadius("Disk Radius", Range(2, 10)) = 3.2
        _DiskWidth("Disk Width", Range(0, 20)) = 5.3

        _Obliquity("Obliquity", Range(-0.99, 0.99)) = 0.0
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue" = "Transparent"
            "RenderPipeline" = "UniversalPipeline"
        }

        ZTest Always
        ZWrite Off
        Cull Front

        HLSLINCLUDE
        
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        #include "./utils.hlsl"
        
        #define MainColor (1, 1, 1)
        #define ITERATIONS 400
        #define Max_Dist 30

        struct Attributes
        {
            float4  positionOS   : POSITION;
            float2  uv           : TEXCOORD0;
        };

        struct Varyings
        {
            float4  positionCS  : SV_POSITION;
            float2  uv          : TEXCOORD0;
            float3  targetPos   : TEXCOORD2;
        };

        sampler2D   _Texture1;
        float4      _Texture1_ST;
        sampler2D   _Texture2;
        float4      _Texture2_ST;
        samplerCUBE _SkyCube;

        half3       _HazeColor;
        float       _Speed;
        float       _DiskRadius;
        float       _DiskWidth;

        float       _Obliquity;

        // ==================================================================================

        float noise(float3 x)
        {
            float3 p = floor(x);
            float3 f = frac(x);
            f = f * f * (3.2- 3 * f);
            float2 uv = (p.xy + float2(30.0, 20.0) * p.z) + f.xy;
            //float2 rg = textureLod(iChannel0, (uv + 0.5)/256.0, 0.0 ).yx;
            float2 rg = tex2Dlod(_Texture1, float4((uv + 0.5)/250.0, 0, 0)).gr;
            return -0.75 + 2.55 * lerp(rg.x, rg.y, f.z);
            //return -1 + 2 * lerp(rg.x, rg.y, f.z);
        }

        void GasDisc(inout float3 color, inout float alpha, float3 pos)
        {
            float discRadius = _DiskRadius;
            float discWidth = _DiskWidth;
            float discInner = discRadius - discWidth * 0.5;
            float discOuter = discRadius + discWidth * 0.5;
            
            float3 origin = float3(0.0, 0.0, 0.0);

            float3 discNormal = normalize(float3(0.0, 1.0, 0.0));
            float discThickness = 0.1;

            float distFromCenter = distance(pos, origin);
            float distFromDisc = dot(discNormal, (pos - origin) * 1.2); // disk divergence
            
            float radialGradient = 1.0 - saturate((distFromCenter - discInner) / discWidth * 0.5);

            float coverage = pcurve(radialGradient, 4.0, 0.96);

            discThickness *= radialGradient;
            coverage *= saturate(1.0 - abs(distFromDisc) / discThickness);

            float3 dustColorLit = MainColor;
            float3 dustColorDark = float3(0.0, 0.0, 0.0);

            float dustGlow = 1.0 / (pow(1.0 - radialGradient, 2.0) * 290.0 + 0.002);
            float3 dustColor = dustColorLit * dustGlow * 8.2;

            coverage = saturate(coverage * 0.7);

            float fade = pow((abs(distFromCenter - discInner) + 0.4), 4.0) * 0.04;
            float bloomFactor = 1.0 / (pow(distFromDisc, 2.0) * 40.0 + fade + 0.00002);
            float3 b = dustColorLit * pow(bloomFactor, 1.5);
            
            b *= lerp(float3(1.3, 0.9, 1.0), float3(0.5, 0.6, 1.2), pow(radialGradient, 2.0));
            b *= lerp(float3(1.7, 0.5, 0.1), float3(1.1, 0.8, 0.75), pow(radialGradient, 0.5));

            dustColor = lerp(dustColor, b * 100.0, saturate(1 - coverage));
            coverage = saturate(coverage + bloomFactor * bloomFactor * 0.1);
            
            if (coverage < 0.01)
            {
                return;   
            }
            
            float3 radialCoords;
            radialCoords.x = distFromCenter * 2.5 + 0.5;
            radialCoords.y = atan2(pos.z, pos.x) * 2.126;
            //radialCoords.y = saturate(degrees(atan2(pos.x, pos.z)) / 360 + 0.5);
            radialCoords.z = distFromDisc * 2.5;

            radialCoords *= 0.5;
            
            float speed = _Speed;
            
            float noise1 = 1.0;
            float3 rc = radialCoords;                   rc.y += _Time.y * speed;
            noise1 *= noise(rc * 3) * 0.5 + 0.5;        rc.y -= _Time.y * speed;
            noise1 *= noise(rc * 6) * 0.5 + 0.5;        rc.y += _Time.y * speed;
            noise1 *= noise(rc * 12) * 0.5 + 0.5;       rc.y -= _Time.y * speed;
            //noise1 *= noise(rc * 24) * 0.5 + 0.5;       rc.y += _Time.y * speed;

            float noise2 = 2.0;
            rc = radialCoords + 30.0;
            noise2 *= noise(rc * 3) * 0.5 + 0.5;      rc.y += _Time.y * speed;
            noise2 *= noise(rc * 6) * 0.5 + 0.5;      rc.y -= _Time.y * speed;
            noise2 *= noise(rc * 12) * 0.5 + 0.5;     rc.y += _Time.y * speed;
            noise2 *= noise(rc * 24) * 0.5 + 0.5;     rc.y -= _Time.y * speed;
            //noise2 *= noise(rc * 48) * 0.5 + 0.5;     rc.y += _Time.y * speed;
            //noise2 *= noise(rc * 96) * 0.5 + 0.5;     rc.y -= _Time.y * speed;

            dustColor *= noise1;
            coverage *= noise2;
            
            radialCoords.y += _Time.y * speed * 0.5;
            
            dustColor *= pow(tex2D(_Texture2, radialCoords.yx * float2(0.15, 0.27)).rgb, float3(2, 2, 2)) * 4.0;

            coverage = saturate(coverage * 2400/ITERATIONS);
            dustColor = max(float3(0, 0, 0), dustColor);

            coverage *= pcurve(radialGradient, 4.0, 0.96);

            color = (1.0 - alpha) * dustColor * coverage + color;

            alpha = (1.0 - alpha) * coverage + alpha;
        }


        half4 SampleSky(float3 rd)
        {
            if (length(rd) < 5)
                return half4(0, 0, 0, 1);

            float3 rdWS = TransformObjectToWorld(float4(rd, 1));
            //rdWS.x = abs(rdWS.x);
            rdWS.x += 0;
            rdWS.y += 20;
            rdWS.z -= 0;
            
            rdWS.x += 2 * _Time.y;
            rdWS.yz -= 1.5 * _Time.y;
            float3 sky = texCUBE(_SkyCube, rdWS.xyz).rgb * 5;

            sky = smoothstep (0.0, 0.26, sky) * 1.2;
            sky = pow(sky, 2);

            //sky.r *= 0.6; sky.g *= 0.5; sky.b *= 1.5;
            sky.g *= 0.7;
            return half4(sky, 1);
        }


        // ==================================================================================

        Varyings vert (Attributes input)
        {
            Varyings output;

            output.positionCS = TransformObjectToHClip(input.positionOS);
            output.uv = input.uv;

            output.targetPos = TransformObjectToWorld(input.positionOS);

            return output;
        }

        half4 frag (Varyings input) : SV_Target
        {
            float2 uv = input.uv;
            
            //float4 ScreenParams = GetScaledScreenParams();
            //float aspect = ScreenParams.x / ScreenParams.y;
            //float2 uveye = uv;

            half3 color = 0;
            half alpha = 0;

            //float3 rayOrigin = float3(0.0, 0.0, 5.0);
            float3 rayOrigin = _WorldSpaceCameraPos.xyz;
            //float3 rayDir = normalize(float3((uveye * 2.0 - 1.0) * float2(1, 1.0), 6.0)); // aspect
            float3 rayDir = normalize(input.targetPos - rayOrigin);

            //RotateCamera(rayOrigin, rayDir, _Obliquity);

            float dither = rand(uv);
            
            //float3 rayPos = rayOrigin + rayDir * Max_Dist / float(ITERATIONS);
            float3 rayPos = rayOrigin + dither * rayDir * Max_Dist / float(ITERATIONS);
            //float3 rayPos = rayOrigin + (_SinTime.y + dither) * rayDir * Max_Dist / float(ITERATIONS);
            
            // ray marching

            for (int i = 0; i < ITERATIONS; i++)
            {   
                WarpSpace(ITERATIONS, rayDir, rayPos);
                rayPos += rayDir * Max_Dist / float(ITERATIONS);
                GasDisc(color, alpha, rayPos);
                Haze(color, rayPos, alpha, _HazeColor, ITERATIONS);
                
                //closest = GetDist(rayPos);
                //cur += closest;
                

                //if (closest < 0.01 || closest > Max_Dist)
                //break;
            }

            /*if (cur < Max_Dist)
            {
               float3 rayPos = rayOrigin + cur * rayDir;
               //float3 n = GetNormal(rayPos);
               //color.rgb = n;
               //GasDisc(color, alpha, rayPos);
               color.rgb = 0;
            }
            else discard;*/

            color *= 0.03;
            color += SampleSky(rayPos);

            //clip(alpha - 0.1);
            
            return half4(color, 1);
        }

        ENDHLSL

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            ENDHLSL
        }
    }
}