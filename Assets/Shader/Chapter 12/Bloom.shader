Shader "URP/ShaderBook/Chapter 12/Bloom"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BlurSize("BlurRange",Float) = 1.0
        _LuminanceThreshold("LuminanceThreshold",Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        LOD 100
        
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //顶点
        struct Attributes
        {
            float4 positionOS   : POSITION;
            float2 texcoord     : TEXCOORD0;
        };

        struct Varyings_Exrtact
        {
            float4 positionHCS      : SV_POSITION;
            float2 uv               : TEXCOORD0;
        };

        struct Varyings_Bloom
        {
            float4 positionHCS   : SV_POSITION;
            float4 uv            : TEXCOORD0;
        };

        TEXTURE2D(_MainTex);SAMPLER(sampler_MainTex);
        TEXTURE2D(_BloomTex);SAMPLER(sampler_BloomTex);
        
        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_TexelSize;
            float  _BlurSize;
            float  _LuminanceThreshold;
        CBUFFER_END

        float2 CorrectUV(in float2 uv , in float4 texelSize)
        {
            float2 result = uv;
            #if UNITY_UV_STARTS_AT_TOP
                if(texelSize.y<0.0)
                    result.y = 1.0 - uv.y;
            #endif

            return result;
        }
        
        float luminance(in float3 color)
        {
            return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
        }

        Varyings_Exrtact vertExtract(Attributes v)
        {
            Varyings_Exrtact o = (Varyings_Exrtact)0;
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
            o.uv = CorrectUV(v.texcoord,_MainTex_TexelSize);
            return o;
        }

        half4 fragExtract(Varyings_Exrtact i) : SV_Target
        {
            half4 FinalColor;
            half4 baseMap = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv);
            half val = clamp(luminance(baseMap.rgb) - _LuminanceThreshold,0.0,1.0);
            FinalColor = baseMap * val;
            return  FinalColor;
        }

        Varyings_Bloom vertBloom(Attributes v)
        {
            Varyings_Bloom o = (Varyings_Bloom)0;
            o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
            o.uv.xy = v.texcoord;
            o.uv.zw  = CorrectUV(v.texcoord,_MainTex_TexelSize);
            return o;
        }

        half4 fragBloom(Varyings_Bloom i) : SV_Target
        {
            return SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,i.uv.xy) +SAMPLE_TEXTURE2D(_BloomTex,sampler_BloomTex,i.uv.zw); 
        }

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertExtract;
            #pragma fragment fragExtract
            ENDHLSL
        }

        UsePass "URP/ShaderBook/Chapter 12/GaussianBlur/GAUSSIAN_BLUR_HORIZONTAL"   //引用shader的路径名
        UsePass "URP/ShaderBook/Chapter 12/GaussianBlur/GAUSSIAN_BLUR_VERTICAL"     //引用shader的路径名
        
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vertBloom;
            #pragma fragment fragBloom
            ENDHLSL
        }
    }
}
