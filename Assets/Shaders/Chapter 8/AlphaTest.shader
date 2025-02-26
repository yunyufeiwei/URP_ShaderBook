Shader "URP/Chapter 8/AlphaTest"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _BaseMap ("BaseMap", 2D) = "white" {}
        _Cutoff("Alpha CutOff" , Range(0,1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "RenderType" = "TransparentCutout" "Queue" = "AlphaTest"}
        LOD 100

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
                float2 texcoord     : TEXCOORD0;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
            };

            TEXTURE2D(_BaseMap);SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _BaseMap_ST;
                float  _Cutoff;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.normalWS = normalize(TransformObjectToWorldNormal(v.normalOS)); 

                o.uv = TRANSFORM_TEX(v.texcoord, _BaseMap);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap , sampler_BaseMap , i.uv);

                half4 diffuse = half4(lightColor * baseMap * max(0.0,dot(worldNormal,worldLightDir) * 0.5 + 0.5));

                //Alpha测试
                clip(baseMap.a - _Cutoff);
                //等价于
                // if((baseMap.a - _Cutoff) < 0)
                // {
                //     discard;
                // }

                

                FinalColor = diffuse;

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
