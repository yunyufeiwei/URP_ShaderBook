Shader "URP/Chapter 14/Hatching"
{
    Properties
    {  
        _Color("Color",Color) = (1,1,1,1)
		_TileFactor("Tile", Float) = 8
        _HatchTex0("Hatch Tex 0", 2D) = "white" {}
		_HatchTex1("Hatch Tex 1", 2D) = "white" {}
		_HatchTex2("Hatch Tex 2", 2D) = "white" {}
		_HatchTex3("Hatch Tex 3", 2D) = "white" {}
		_HatchTex4("Hatch Tex 4", 2D) = "white" {}
		_HatchTex5("Hatch Tex 5", 2D) = "white" {}

        [Space(20)]
        [Header(OutlineProperty)]
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline Width", Range(0, 1)) = 0.2
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType" = "Opaque" "Queue" = "Geometry"}
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
                float4 tangent      : TANGENT;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 hatchWeights0: TEXCOORD2;
                float3 hatchWeights1: TEXCOORD3;
            };

            TEXTURE2D(_HatchTex0);SAMPLER(sampler_HatchTex0);
            TEXTURE2D(_HatchTex1);SAMPLER(sampler_HatchTex1);
            TEXTURE2D(_HatchTex2);SAMPLER(sampler_HatchTex2);
            TEXTURE2D(_HatchTex3);SAMPLER(sampler_HatchTex3);
            TEXTURE2D(_HatchTex4);SAMPLER(sampler_HatchTex4);
            TEXTURE2D(_HatchTex5);SAMPLER(sampler_HatchTex5);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                half _TileFactor;
            CBUFFER_END
            
            Varyings vert (Attributes v)
            {
                Varyings o = (Varyings)0;

                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);

                o.uv = v.texcoord * _TileFactor;

                Light light = GetMainLight();
                half4 lightColor = half4(light.color * light.distanceAttenuation , 1.0);
                half3 worldLightDir = light.direction;

                half3 normalWS = normalize(TransformObjectToWorldNormal(v.normalOS));

                o.hatchWeights0 = half3(0,0,0);
                o.hatchWeights1 = half3(0,0,0);
                half lambert = max(0.0 , dot(worldLightDir,normalWS));
                half hatchFactor = lambert * 7.0;   //将Lambert缩放到[0,7]区间

                if (hatchFactor > 6.0)
                {
                    //最亮的部分，用留白表示
                }
                else if (hatchFactor > 5.0)
                {
                    o.hatchWeights0.x = hatchFactor - 5.0;
                }
                else if(hatchFactor > 4.0)
                {
                    o.hatchWeights0.x = hatchFactor - 4.0;
                    o.hatchWeights0.y = 1.0 - o.hatchWeights0.x;
                }
                else if(hatchFactor > 3.0)
                {
                    o.hatchWeights0.y = hatchFactor - 3.0;
                    o.hatchWeights0.z = 1 - o.hatchWeights0.y;
                }
                else if(hatchFactor > 2.0)
                {
                    o.hatchWeights0.z = hatchFactor - 2.0;
                    o.hatchWeights1.x = 1 - o.hatchWeights0.z;
                }
                else if(hatchFactor > 1.0)
                {
                    o.hatchWeights1.x = hatchFactor - 1.0;
                    o.hatchWeights1.y = 1 - o.hatchWeights1.x;
                }
                else
                {
                    o.hatchWeights1.y = hatchFactor;
                    o.hatchWeights1.z = 1 - o.hatchWeights1.y;
                }

                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;
                half4 hatch0 = SAMPLE_TEXTURE2D(_HatchTex0, sampler_HatchTex0, i.uv) * i.hatchWeights0.x;
                half4 hatch1 = SAMPLE_TEXTURE2D(_HatchTex1, sampler_HatchTex1, i.uv) * i.hatchWeights0.y;
                half4 hatch2 = SAMPLE_TEXTURE2D(_HatchTex2, sampler_HatchTex2, i.uv) * i.hatchWeights0.z;
                half4 hatch3 = SAMPLE_TEXTURE2D(_HatchTex3, sampler_HatchTex3, i.uv) * i.hatchWeights1.x;
                half4 hatch4 = SAMPLE_TEXTURE2D(_HatchTex4, sampler_HatchTex4, i.uv) * i.hatchWeights1.y;
                half4 hatch5 = SAMPLE_TEXTURE2D(_HatchTex5, sampler_HatchTex5, i.uv) * i.hatchWeights1.z;
                half4 white = half4(1, 1, 1, 1) * (1 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);

                FinalColor = (hatch0 + hatch1 + hatch2 + hatch3 + hatch4 + hatch5 + white) * _Color;
                return FinalColor;
            }
            ENDHLSL
        }

        UsePass "URP/Chapter 14/ToonShading/Outline"
    }
}
