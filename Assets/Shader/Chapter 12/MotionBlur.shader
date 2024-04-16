Shader "URP/ShaderBook/Chapter 12/MotionBlur"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurAmount("BlurRange",Float) = 1.0
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        struct Attributes
        {
            float4 positionOS   : POSITION;
            float2 texcoord     : TEXCOORD0;
        };

        struct Varyings
        {
            float4 positionHCS : SV_POSITION;
            float2 uv : TEXCOORD0;
        };

        TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            float _BlurAmount; 
        CBUFFER_END

        Varyings vert(Attributes v)
        {
            Varyings o = (Varyings)0;
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
            o.uv = v.texcoord;
            return o;
        }

        //更新渲染纹理的RGB通道部分
        half4 fragRGB(Varyings i) : SV_Target
        {
            return half4(SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv).rgb,_BlurAmount);
        }
        //更新渲染纹理的A通道部分
        half4 fragA(Varyings i) : SV_Target
        {
            return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
        }
        ENDHLSL

        ZTest Always
        Cull Off
        ZWrite Off

        Pass
        {
            NAME"Pass01"
            Blend SrcAlpha OneMinusSrcAlpha
            ColorMask RGB
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragRGB
            ENDHLSL
        }

        Pass
        {
            NAME"Pass02"
            Blend One Zero
            ColorMask A
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment fragA
            ENDHLSL
        }
    }
}
