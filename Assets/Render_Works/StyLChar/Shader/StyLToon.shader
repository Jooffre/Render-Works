Shader "Universal Render Pipeline/Non-Photorealistic Rendering/StyLToon"
{
    Properties
    {
        // ======================================== Render Mode ========================================
        [Header(Render Mode)]
        [Space(10)]
        [KeywordEnum(Common, Hair, Face, Body, Metal)] _RENDERMODE("Render Mode", float) = 0
        [Space(20)]


        // ====================================== Color & Textures =====================================
        [Header(Color and Textures)]
        [Space(10)]
        [HDR] _BaseColor("Base Tint", Color) = (0.5, 0.5, 0.5, 1)
        [NoScaleOffset] _BaseMap("Base Texture", 2D) = "white" {}
        [NoScaleOffset] _LightMap("Light Map", 2D) = "white" {}
        [NoScaleOffset] _MetalMap("Metal Map", 2D) = "white" {}
        [NoScaleOffset] _RampMap("Ramp Map", 2D) = "white" {}
        [Space(20)]


        // ========================================= Time Shift =========================================
        [Header(Environment)]
        [Space(10)]
        [Enum(Day,2,Night,1)] _TimeShift("Time Mode", int) = 2
        [Space(20)]


        // ======================================== Ramp Setting =======================================
        [Header(Rampmap Config)]
        [Space(10)]
        _Ramp_V("★ Sampling Vertical Component", Range(0, 1)) = 0.35
        
        [Space(5)]
        [Header(Mapping From Lambert To RampMap)]
        [Space(5)]
        _RampIntv1("Initial Lightness Interval Left Value", Range(0, 1)) = 0.2
        _RampIntv2("Initial Lightness Interval Right Value", Range(0, 1)) = 0.45

        _RampIntvA("Target RampMap Interval Left Value", Range(0, 1)) = 0.75
        _RampIntvB("Target RampMap Interval Right Value", Range(0, 1)) = 0.9
        
        _RampDarkVal("Rampmap Dark Value", Range(0, 1)) = 0.25
        _RampBrightVal("Rampmap Bright Value", Range(0, 1)) = 0.96
        [Space(20)]


        // ========================================== Outline ==========================================
        [Header(Outline Config)]
        [Space(10)]
        _OutlineColor("Outline Base Color", Color) = (0, 0, 0)
        _OutlineWidth("Outline Width", Range(0.01, 10)) = 1

        _OutlineZOffset("● Outline Z-Offset", Range(0, 1)) = 0.0
        [Space(20)]

        
        // ========================================== Emission =========================================
        [Header(Emission Config)]
        [Space(10)]
        [ToggleOff] _EnableEmission("Enable Emission", Float) = 1
        // [HDR]_EmissionColor("Emission Color", Color) = (0, 0, 0)
        _EmissionIntensity("Emission Intensity", range(0.0, 10.0)) = 1
        [Space(20)]


        // ========================================== Shadow ===========================================
        [Header(Shadow Config)]
        [Space(10)]
        _FaceShadowPow("[Face] Shadow Pow", Range(0.01, 0.5)) = 0.1
        _FaceShadowOffset("[Face] Shadow Offset", Range(0.01, 0.5)) = 0.1
        [HDR] _ShadowTint("Shadow Tint", Color) = (1, 1, 1, 1)
        _ShadowTintDark("Shadow Tint Dark", Color) = (1, 1, 1, 1)
        _BoundaryIntensity("Boundary Intensity", range(0.0, 1.0)) = 0.1
        _ShadowOffset("Shadow Offset", range(-1.0, 1.0)) = 0
        _ShadowRampWidth("Shadow Ramp Width", range(0.0, 1.0)) = 0.1
        _ShadowRampThreshold("Shadow Ramp Threshold",range(0.0,1.0))=0
        [Space(20)]


        // ========================================= Specular ==========================================
        [Header(Specular Config)]
        [Space(10)]
        [Toggle] _EnableSpecular("Enable Specular", float) = 1
        [HDR] _SpecularColor("Specular Color", color) = (0.8, 0.8, 0.8, 1)
        [Space(5)]
        [Header(Non Metal)]
        [Space(5)]
        _ContrastLayer_L("Smoothstep Interval Left", range(0, 1)) = 0.0
        _ContrastLayer_R("Smoothstep Interval Right", range(0, 1)) = 0.4
        _NonMetalSpecIntensity("Non-Metal Specular Intensity", range(0.0, 100.0)) = 0.5
        _NonMetalIntvL("Non-Metal Mask Interval Left", range(-1.0, 1.0)) = 0.0
        _NonMetalIntvR("Non-Metal Mask Interval Right", range(-1.0, 1.0)) = 0.0
        _ViewSpecWidth("View Specular Width",range(0.0, 0.99))=0.5
        [Space(5)]
        [Header(Metal)]
        [Space(5)]
        [PowerSlider(2)] _Smoothness("Smoothness (x^2)", range(0.01, 128)) = 1.0
        _MetalSampRange("MetalTex Sampling Range", range(0, 1)) = 1
        _MetalSampRange2("MetalTex Sampling Range2", range(0, 1)) = 0.72
        _MetalSpecIntensity("Metal Specular Intensity", range(0.0, 100.0)) = 0.5
        _MetalSpecIntensity2("Metal Specular Intensity2", range(0.0, 100.0)) = 0.5
        _MetalIntvL("Metal Mask Interval Left", range(-1.0, 1.0)) = 0.48
        _MetalIntvR("Metal Mask Interval Right", range(-1.0, 1.0)) = 0.52
        _MetalIntvL2("Metal Mask2 Interval Left", range(-1.0, 1.0)) = 0.69
        _MetalIntvR2("Metal Mask2 Interval Right", range(-1.0, 1.0)) = 0.71
        [Space(20)]


        // ========================================= Rim Light =========================================
        [Header(Rim Light Config)]
        [Space(10)]
        [Toggle]_EnableRim ("Enable Rim", float) = 1
        [HDR]_RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimWidth("Rim Light Width",range(-1, 1)) = 0.01
        _RimLightThreshold("Rim Light Threshold",range(0.0, 1.0)) = 0.6
        _RimLightIntensity("Rim Light Intensity",range(0.0, 1.0)) = 1
        [Space(20)]

        /*
        // ======================================== Hair Shadow ========================================
        [Header(Stencil)]
        [Space(5)]
        _StencilRef ("Stencil Reference", Range(0, 255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)]_StencilComp ("Stencil Comparison", Float) = 0
        [Space(20)]
        */


        // =========================================== Alpha ===========================================
        [Header(Alpha Clipping)]
        [Space(10)]
        [ToggleOff] _UseAlphaClipping("Use Alpha Clipping", Float) = 0
        _Cutoff("Alpha Cut Off", Range(0.0, 1.0)) = 0

    }
    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            // "IgnoreProjector" = "True"
        }

        LOD 100

        HLSLINCLUDE

        #pragma shader_feature_local_fragment _RENDERMODE_COMMON _RENDERMODE_HAIR _RENDERMODE_FACE _RENDERMODE_BODY _RENDERMODE_METAL
        // apply following keywords to all passes
        #pragma shader_feature_local_fragment _UseAlphaClipping
        
        #pragma multi_compile_instancing

        ENDHLSL

        Pass
        {
            Name "ForwardLit"
            Tags{"LightMode" = "UniversalForward"}

            /* // Stencil Test
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass replace
            }
            */
            
            Cull Back

            HLSLPROGRAM

            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // ---------------------------------------------------------------------------------------------

            #pragma multi_compile_fog

            #pragma vertex VertexStage
            #pragma fragment FragmentStage

            #include "StyLToonLitForward.hlsl"

            ENDHLSL
        }
        

        Pass
        {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM

            #pragma vertex VertexStage
            #pragma fragment ApplyShadowBiasFix2

            #define ApplyShadowBiasFix

            #include "StyLToonLitForward.hlsl"

            ENDHLSL
        }


        // write depth
        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            // Required to compile gles 2.0 with standard srp library
            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x
            #pragma target 2.0

            #pragma vertex DepthOnlyVertex
            #pragma fragment DepthOnlyFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature _ALPHATEST_ON
            #pragma shader_feature _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing

            #include "StyLToonParams.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/DepthOnlyPass.hlsl"
            ENDHLSL
        }


        Pass
        {
            Name "DepthNormalsOnly"
            Tags{"LightMode" = "DepthNormalsOnly"}

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM

            #pragma vertex VertexStage
            #pragma fragment DepthOnlyFragment

            #define MakeOutline

            #include "StyLToonLitForward.hlsl"

            ENDHLSL
        }
        

        Pass
        {
            Name "Outline"
            Tags{"LightMode" = "SRPDefaultUnlit"}

            /*
            Stencil
            {
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass replace
            }
            */

            Cull Front

            HLSLPROGRAM

            // ---------------------------------------------------------------------------------------------
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // ---------------------------------------------------------------------------------------------


            // Unity defined keywords
            #pragma multi_compile_fog

            #pragma vertex VertexStage
            #pragma fragment FragmentStage

            #define MakeOutline

            #include "StyLToonLitForward.hlsl"

            ENDHLSL
        }
    }
    FallBack "Hidden/Universal Render Pipeline/FallbackError"
}
