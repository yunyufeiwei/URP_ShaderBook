Shader "URP/ShaderBook/Chapter 10/Refraction"
{
    Properties
    {
        _Color("Color",Color) = (1,1,1,1)
        _RefractColor("RefractColor",Color) = (1,1,1,1)
        _RefractAmount("RefractAmount",Range(0,1)) = 1
        _RefractRatio("RefractRatio",Range(0,1)) = 0.5
        _Cubemap("Cubemap Reflection",Cube) = "_Skybox"{}
    }
    SubShader
    {
        Tags {"RenderPipeline" = "UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
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
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float3 positionWS   : TEXCOORD0;
                float3 normalWS     : TEXCOORD1;
                float3 viewDirWS    : TEXCOORD2;
                float3 worldRef1    : TEXCOORD3;
            };

            TEXTURECUBE(_Cubemap);SAMPLER(sampler_Cubemap);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float4 _RefractColor;
                float  _RefractAmount;
                float  _RefractRatio;
            CBUFFER_END

            Varyings vert (Attributes v)
            {
                Varyings o=(Varyings)0;
                o.positionHCS = TransformObjectToHClip(v.positionOS.xyz);
                o.positionWS = TransformObjectToWorld(v.positionOS.xyz);
                o.normalWS = TransformObjectToWorldNormal(v.normalOS);
                o.viewDirWS = GetWorldSpaceViewDir(o.positionWS);
                o.worldRef1 = refract(-normalize(o.viewDirWS) , normalize(o.normalWS) , _RefractRatio);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {
                half4 FinalColor;

                Light light = GetMainLight();
                half3 lightColor = light.color * light.distanceAttenuation;
                half3 worldLightDir = light.direction;

                half3 worldNormal = normalize(i.normalWS);
                half3 worldViewDir = normalize(i.viewDirWS);

                half3 diffuse = lightColor.rgb *_Color.rgb * max(0 , dot(worldNormal , worldLightDir));

                half3 refractionTex = SAMPLE_TEXTURECUBE(_Cubemap, sampler_Cubemap, i.worldRef1).rgb * _RefractColor.rgb;

                FinalColor = half4(lerp(diffuse , refractionTex , _RefractAmount).rgb , 1.0);

                return FinalColor;
            }
            ENDHLSL
        }
    }
}
