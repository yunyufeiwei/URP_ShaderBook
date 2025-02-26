Shader "URP/Chapter 10/Mirror"
{
    Properties
    {
        _BaseMap ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags{"LightMode" = "UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag           

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 texcoord     : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS  : POSITION;
                float2 uv           : TEXCOORD0;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv = v.texcoord;

                //翻转X轴
                o.uv.x = 1-o.uv.x;
                
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {                        
                half4 FinalColor;

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);
                
                FinalColor = baseMap;
                
                return FinalColor;
            }
            ENDHLSL
        }
    }
}
